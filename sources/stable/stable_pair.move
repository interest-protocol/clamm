module amm::stable_pair {
  use std::vector;
  use std::option::Option;
  use std::type_name::{TypeName, get};

  use sui::coin::{Self, Coin};
  use sui::object::{Self, UID};
  use sui::dynamic_field as df;
  use sui::tx_context::TxContext;
  use sui::vec_set::{Self, VecSet};
  use sui::transfer::public_share_object;
  use sui::balance::{Self, Supply, Balance};

  use suitears::math256::sqrt_down;
  use suitears::math64::{min, mul_div_down};
  use suitears::coin_decimals::{get_decimals_scalar, CoinDecimals};

  use amm::errors;
  use amm::amm_admin::Admin;
  use amm::curves::StablePair;
  use amm::pool_events as events;
  use amm::utils::are_coins_ordered;
  use amm::stable_fees::{
    Self, 
    StableFees,
  };
  use amm::stable_pair_math::{
    invariant_, 
    calculate_amount_out, 
    calculate_optimal_add_liquidity
  };
  use amm::interest_pool::{
    Self as core,
    Pool,
    new_pool,
  };

  const MINIMUM_LIQUIDITY: u64 = 100;

  struct StateKey has drop, copy, store {}

  struct SwapState has drop {
    coin_x_reserve: u64,
    coin_y_reserve: u64,
    decimals_x: u64,
    decimals_y: u64,
    fees: StableFees,
    is_x: bool,
  }

  struct State<phantom CoinX, phantom CoinY, phantom LpCoin> has store {
    lp_coin_supply: Supply<LpCoin>,
    balance_x: Balance<CoinX>,
    balance_y: Balance<CoinY>,
    decimals_x: u64,
    decimals_y: u64,
    // @dev We need to keep the fees seperate to prevent hooks from stealing the protocol
    admin_fee_balance_x: Balance<CoinX>,
    admin_fee_balance_y: Balance<CoinY>,
    seed_liquidity: Balance<LpCoin>,
    fees: StableFees  
  }

  public fun quote_swap<CoinIn, CoinOut, LpCoin>(pool: &Pool<StablePair>, amount_in: u64): (u64, u64, u64) {
    if (is_coin_x<CoinIn>(core::view_coins<StablePair>(pool))) 
      quote_swap_logic<CoinIn, CoinOut, LpCoin>(pool, amount_in, true)
    else
      quote_swap_logic<CoinOut, CoinIn, LpCoin>(pool, amount_in, false)
  }

  public fun get_amounts<CoinX, CoinY, LpCoin>(pool: &Pool<StablePair>): (u64, u64, u64) {
    let state = load_state<CoinX, CoinY, LpCoin>(core::borrow_uid(pool));
    get_amounts_internal(state)
  }

  public fun quote_add_liquidity<CoinX, CoinY, LpCoin>(
    pool: &Pool<StablePair>,
    amount_x: u64,
    amount_y: u64
  ): (u64, u64, u64) {
    let state = load_state<CoinX, CoinY, LpCoin>(core::borrow_uid(pool));
    let (coin_x_reserve, coin_y_reserve, supply) = get_amounts_internal(state);

    let (optimal_x_amount, optimal_y_amount) = calculate_optimal_add_liquidity(
      amount_x,
      amount_y,
      coin_x_reserve,
      coin_y_reserve
    );

    let share_to_mint = min(
      mul_div_down(amount_x, supply, coin_x_reserve),
      mul_div_down(amount_y, supply, coin_y_reserve)
    );

    (share_to_mint, optimal_x_amount, optimal_y_amount)
  }

  public fun quote_remove_liquidity<CoinX, CoinY, LpCoin>(
    pool: &Pool<StablePair>,
    amount: u64
  ): (u64, u64) {
    let state = load_state<CoinX, CoinY, LpCoin>(core::borrow_uid(pool));
    let (coin_x_reserve, coin_y_reserve, supply) = get_amounts_internal(state);

    (
      mul_div_down(amount, coin_x_reserve, supply),
      mul_div_down(amount, coin_y_reserve, supply)
    )
  }

  public fun new<CoinX, CoinY, LpCoin>(
    coin_x: Coin<CoinX>,
    coin_y: Coin<CoinY>,
    lp_coin_supply: Supply<LpCoin>,
    coin_decimals: &CoinDecimals,   
    ctx: &mut TxContext
  ): Coin<LpCoin> {
    let pool = new_pool<StablePair>(make_coins<CoinX, CoinY>(), ctx);

    events::emit_new_pair<StablePair, CoinX, CoinY, LpCoin>(object::id(&pool), coin::value(&coin_x), coin::value(&coin_y));

    let lp_coin = add_state(
      core::borrow_mut_uid(&mut pool),
      coin_x,
      coin_y,
      lp_coin_supply,
      coin_decimals,
      ctx  
    );

    public_share_object(pool);

    lp_coin
  }

  public fun swap<CoinIn, CoinOut, LpCoin>(
    pool: &mut Pool<StablePair>, 
    coin_in: Coin<CoinIn>,
    coin_min_value: u64,
    ctx: &mut TxContext    
  ): Coin<CoinOut> {
    assert!(coin::value(&coin_in) != 0, errors::cannot_swap_zero_value());

    if (is_coin_x<CoinIn>(core::view_coins<StablePair>(pool))) 
      swap_coin_x<CoinIn, CoinOut, LpCoin>(pool, coin_in, coin_min_value, ctx)
    else 
      swap_coin_y<CoinOut, CoinIn, LpCoin>(pool, coin_in, coin_min_value, ctx)

  }

  public fun add_liquidity<CoinX, CoinY, LpCoin>(
    pool: &mut Pool<StablePair>,
    coin_x: Coin<CoinX>,
    coin_y: Coin<CoinY>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext 
  ): (Coin<LpCoin>, Coin<CoinX>, Coin<CoinY>) {
    assert!(are_coins_ordered(pool, vector[get<CoinX>(), get<CoinY>()]), errors::coins_must_be_in_order());

    let coin_x_value = coin::value(&coin_x);
    let coin_y_value = coin::value(&coin_y);       

    assert!(coin_x_value != 0 && coin_y_value != 0, errors::no_zero_liquidity_amounts());

    let pool_id = object::id(pool);

    let state = load_mut_state<CoinX, CoinY, LpCoin>(core::borrow_mut_uid(pool));

    let (coin_x_reserve, coin_y_reserve, supply) = get_amounts_internal(state);

    let (optimal_x_amount, optimal_y_amount) = calculate_optimal_add_liquidity(
      coin_x_value,
      coin_y_value,
      coin_x_reserve,
      coin_y_reserve
    );   

    let extra_x = if (coin_x_value > optimal_x_amount) coin::split(&mut coin_x, coin_x_value - optimal_x_amount, ctx) else coin::zero<CoinX>(ctx); 
    let extra_y = if (coin_y_value > optimal_y_amount) coin::split(&mut coin_y, coin_y_value - optimal_y_amount, ctx) else coin::zero<CoinY>(ctx); 

    // round down to give the protocol an edge
    let shares_to_mint = min(
      mul_div_down(coin::value(&coin_x), supply, coin_x_reserve),
      mul_div_down(coin::value(&coin_y), supply, coin_y_reserve)
    );

    assert!(shares_to_mint >= lp_coin_min_amount, errors::slippage());

    events::emit_add_pair_liquidity<StablePair, CoinX, CoinY, LpCoin>(pool_id, optimal_x_amount, optimal_y_amount, shares_to_mint);

    balance::join(&mut state.balance_x, coin::into_balance(coin_x));
    balance::join(&mut state.balance_y, coin::into_balance(coin_y));

    (coin::from_balance(balance::increase_supply(&mut state.lp_coin_supply, shares_to_mint), ctx), extra_x, extra_y)
  }

  public fun remove_liquidity<CoinX, CoinY, LpCoin>(
    pool: &mut Pool<StablePair>,
    lp_coin: Coin<LpCoin>,
    coin_x_min_amount: u64,
    coin_y_min_amount: u64,
    ctx: &mut TxContext
  ): (Coin<CoinX>, Coin<CoinY>) {
    let lp_coin_value = coin::value(&lp_coin);

    assert!(lp_coin_value != 0, errors::no_zero_coin());

    let pool_id = object::id(pool);

    let state = load_mut_state<CoinX, CoinY, LpCoin>(core::borrow_mut_uid(pool));
    let (coin_x_reserve, coin_y_reserve, lp_coin_supply) = get_amounts_internal(state);

    // down to give the protocol an edge
    let coin_x_removed = mul_div_down(lp_coin_value, coin_x_reserve, lp_coin_supply);
    let coin_y_removed = mul_div_down(lp_coin_value, coin_y_reserve, lp_coin_supply);

    assert!(coin_x_removed >= coin_x_min_amount, errors::slippage());
    assert!(coin_y_removed >= coin_y_min_amount, errors::slippage());

    events::emit_remove_pair_liquidity<StablePair, CoinX, CoinY, LpCoin>(pool_id, coin_x_removed, coin_y_removed, lp_coin_value);

    balance::decrease_supply(&mut state.lp_coin_supply, coin::into_balance(lp_coin));

    (
      coin::take(&mut state.balance_x, coin_x_removed, ctx),
      coin::take(&mut state.balance_y, coin_y_removed, ctx)
    )
  }

  // * DAO Functions

  public fun update_fee<CoinX, CoinY, LpCoin>(
    _: &Admin,
    pool: &mut Pool<StablePair>,
    fee_in_percent: Option<u256>,
    fee_out_percent: Option<u256>, 
    admin_fee_percent: Option<u256>,  
  ) {
    let state = load_mut_state<CoinX, CoinY, LpCoin>(core::borrow_mut_uid(pool));

    stable_fees::update_fee_in_percent(&mut state.fees, fee_in_percent);
    stable_fees::update_admin_fee_percent(&mut state.fees, fee_out_percent);  
    stable_fees::update_admin_fee_percent(&mut state.fees, admin_fee_percent);
    
    let (fee_in_percent, fee_out_percent, admin_fee_percent) = stable_fees::view(&state.fees);

    events::emit_update_stable_fee<StablePair, LpCoin>(object::id(pool), fee_in_percent, fee_out_percent, admin_fee_percent);
  }

  public fun take_fees<CoinX, CoinY, LpCoin>(
    _: &Admin,
    pool: &mut Pool<StablePair>,
    ctx: &mut TxContext
  ): (Coin<CoinX>, Coin<CoinY>) {
    let pool_id = object::id(pool);

    let state = load_mut_state<CoinX, CoinY, LpCoin>(core::borrow_mut_uid(pool));
    let amount_x = balance::value(&state.admin_fee_balance_x);
    let amount_y = balance::value(&state.admin_fee_balance_y);

    events::emit_take_stable_pair_fees<CoinX, CoinY, LpCoin>(pool_id, amount_x, amount_y);

    (
      coin::take(&mut state.admin_fee_balance_x, amount_x, ctx),
      coin::take(&mut state.admin_fee_balance_y, amount_y, ctx)
    )
  }

  // * Private Functions

  fun swap_coin_x<CoinX, CoinY, LpCoin>(
    pool: &mut Pool<StablePair>, 
    coin_x: Coin<CoinX>,
    coin_y_min_value: u64,
    ctx: &mut TxContext
  ): Coin<CoinY> {
    let pool_id = object::id(pool);

    let state = load_mut_state<CoinX, CoinY, LpCoin>(core::borrow_mut_uid(pool));
    // * Important needs to be created before any mutations
    let swap_state = make_swap_state(state, true);

    let coin_in_amount = coin::value(&coin_x);
    
    let (amount_out, fee_x, fee_y) = swap_amounts(swap_state, coin_in_amount, coin_y_min_value);

    if (fee_x != 0) {
      balance::join(&mut state.admin_fee_balance_x, coin::into_balance(coin::split(&mut coin_x, fee_x, ctx)));
    };

    if (fee_y != 0) {
      balance::join(&mut state.admin_fee_balance_y, balance::split(&mut state.balance_y, fee_y));  
    };

    balance::join(&mut state.balance_x, coin::into_balance(coin_x));

    events::emit_swap<StablePair, CoinX, CoinY, LpCoin>(pool_id, coin_in_amount, amount_out);

    coin::take(&mut state.balance_y, amount_out, ctx) 
  }

  fun swap_coin_y<CoinX, CoinY, LpCoin>(
    pool: &mut Pool<StablePair>, 
    coin_y: Coin<CoinY>,
    coin_x_min_value: u64,
    ctx: &mut TxContext
  ): Coin<CoinX> {
    let pool_id = object::id(pool);

    let state = load_mut_state<CoinX, CoinY, LpCoin>(core::borrow_mut_uid(pool));
    // * Important needs to be created before any mutations
    let swap_state = make_swap_state(state, false);

    let coin_in_amount = coin::value(&coin_y);

    let (amount_out, fee_y, fee_x) = swap_amounts(swap_state, coin_in_amount, coin_x_min_value);

    if (fee_y != 0) {
      balance::join(&mut state.admin_fee_balance_y, coin::into_balance(coin::split(&mut coin_y, fee_y, ctx)));
    };
      

    if (fee_x != 0) {
      balance::join(&mut state.admin_fee_balance_x, balance::split(&mut state.balance_x, fee_x)); 
    };

    balance::join(&mut state.balance_y, coin::into_balance(coin_y));

    events::emit_swap<StablePair, CoinY, CoinX, LpCoin>(pool_id, coin_in_amount, amount_out);

    coin::take(&mut state.balance_x, amount_out, ctx) 
  }

  fun swap_amounts(
    state: SwapState,
    coin_in_amount: u64,
    coin_out_min_value: u64 
  ): (u64, u64, u64) {
    let prev_k = invariant_(state.coin_x_reserve, state.coin_y_reserve, state.decimals_x, state.decimals_y);

    let fee_in = stable_fees::calculate_fee_in_amount(&state.fees, coin_in_amount);
    let admin_fee_in = stable_fees::calculate_admin_amount(&state.fees, fee_in);

    let coin_in_amount = coin_in_amount - fee_in;

    let amount_out = calculate_amount_out(
      prev_k,
      coin_in_amount,  
      state.coin_x_reserve,  
      state.coin_y_reserve, 
      state.decimals_x, 
      state.decimals_y, 
      state.is_x
    );

    let fee_out = stable_fees::calculate_fee_out_amount(&state.fees, amount_out);
    let admin_fee_out = stable_fees::calculate_admin_amount(&state.fees, fee_out);

    let amount_out = amount_out - fee_out;

    assert!(amount_out >= coin_out_min_value, errors::slippage());

    // @dev Admin fees r not part of the variant
    let new_k = if (state.is_x) 
        invariant_(state.coin_x_reserve + coin_in_amount + fee_in - admin_fee_in, state.coin_y_reserve - amount_out - admin_fee_out, state.decimals_x, state.decimals_y)
      else
        invariant_(state.coin_x_reserve - amount_out - admin_fee_out, state.coin_y_reserve + fee_in + coin_in_amount - admin_fee_in, state.decimals_x, state.decimals_y);

    assert!(new_k >= prev_k, errors::invalid_invariant());

    // Protocol takes 1/5 of the fees
    (amount_out, admin_fee_in, admin_fee_out)    
  }

  fun get_amounts_internal<CoinX, CoinY, LpCoin>(state: &State<CoinX, CoinY, LpCoin>): (u64, u64, u64) {
    ( 
      balance::value(&state.balance_x), 
      balance::value(&state.balance_y),
      balance::supply_value(&state.lp_coin_supply)
    )
  }

  fun add_state<CoinX, CoinY, LpCoin>(
    id: &mut UID,
    coin_x: Coin<CoinX>,
    coin_y: Coin<CoinY>,
    lp_coin_supply: Supply<LpCoin>,
    coin_decimals: &CoinDecimals,    
    ctx: &mut TxContext   
  ): Coin<LpCoin> {
    assert!(balance::supply_value(&lp_coin_supply) == 0, errors::supply_must_have_zero_value());

    let coin_x_value = coin::value(&coin_x);
    let coin_y_value = coin::value(&coin_y);

    assert!(coin_x_value != 0 && coin_y_value != 0, errors::cannot_create_empty_pool());

    let shares = (sqrt_down((coin_x_value as u256) * (coin_y_value as u256)) as u64);

    let seed_liquidity = balance::increase_supply(&mut lp_coin_supply, MINIMUM_LIQUIDITY);

    let sender_balance = balance::increase_supply(&mut lp_coin_supply, shares);

    df::add(id, StateKey {},
      State<CoinX, CoinY, LpCoin> {
        lp_coin_supply,
        balance_x: coin::into_balance(coin_x),
        balance_y: coin::into_balance(coin_y),
        admin_fee_balance_x: balance::zero(),
        admin_fee_balance_y: balance::zero(),
        decimals_x: get_decimals_scalar<CoinX>(coin_decimals),
        decimals_y: get_decimals_scalar<CoinY>(coin_decimals),
        seed_liquidity,
        fees: stable_fees::new()    
      }
    );

    coin::from_balance(sender_balance, ctx)
  }

  fun load_state<CoinX, CoinY, LpCoin>(id: &UID): &State<CoinX, CoinY, LpCoin> {
    df::borrow(id, StateKey {})
  }

  fun load_mut_state<CoinX, CoinY, LpCoin>(id: &mut UID): &mut State<CoinX, CoinY, LpCoin> {
    df::borrow_mut(id, StateKey {})
  }

  fun make_swap_state<CoinX, CoinY, LpCoin>(state: &State<CoinX, CoinY, LpCoin>, is_x: bool): SwapState {
    let (coin_x_reserve, coin_y_reserve, _) = get_amounts_internal(state);
    SwapState {
      coin_x_reserve,
      coin_y_reserve,
      decimals_x: state.decimals_x,
      decimals_y: state.decimals_y,
      fees: state.fees,
      is_x
    }
  }

  fun is_coin_x<CoinType>(coins: vector<TypeName>): bool {
    *vector::borrow(&coins, 0) == get<CoinType>()
  }

  fun make_coins<CoinX, CoinY>(): VecSet<TypeName> {
    let coins = vec_set::singleton(get<CoinX>());
    vec_set::insert(&mut coins, get<CoinY>());
    coins
  }

  fun quote_swap_logic<CoinX, CoinY, LpCoin>(pool: &Pool<StablePair>, amount_in: u64, is_x: bool): (u64, u64, u64) {
    let state = load_state<CoinX, CoinY, LpCoin>(core::borrow_uid(pool));
    let (coin_x_reserve, coin_y_reserve, _) = get_amounts_internal(state);

    let fee_in = stable_fees::calculate_fee_in_amount(&state.fees, amount_in);
    
    let amount_out = calculate_amount_out(
      invariant_(coin_x_reserve, coin_y_reserve, state.decimals_x, state.decimals_y),
      amount_in - fee_in,  
      coin_x_reserve,  
      coin_y_reserve, 
      state.decimals_x, 
      state.decimals_y, 
      is_x
    );

    let fee_out = stable_fees::calculate_fee_out_amount(&state.fees, amount_out);
    ((amount_out - fee_out), fee_in, fee_out)
  }

  // * Test Only Functions

  #[test_only]
  public fun view_state<CoinX, CoinY, LpCoin>(pool: &Pool<StablePair>): (u64, u64, u64, u64, u64, u64, u64, u64, StableFees) {
    let state = load_state<CoinX, CoinY, LpCoin>(core::borrow_uid(pool));
    (
      balance::supply_value(&state.lp_coin_supply),
      balance::value(&state.balance_x),
      balance::value(&state.balance_y),
      balance::value(&state.admin_fee_balance_x),
      balance::value(&state.admin_fee_balance_y),
      state.decimals_x,
      state.decimals_y,
      balance::value(&state.seed_liquidity),
      state.fees
    )
  }
}   