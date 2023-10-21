module amm::stable_pair_core {
  use std::vector;
  use std::type_name::{TypeName, get};

  use sui::math::pow;
  use sui::object::UID;
  use sui::dynamic_field as df;
  use sui::tx_context::TxContext;
  use sui::vec_set::{Self, VecSet};
  use sui::coin::{Self, CoinMetadata, Coin};
  use sui::balance::{Self, Supply, Balance};

  use suitears::math256::sqrt;

  use amm::errors;
  use amm::asserts;
  use amm::curves::StablePair;
  use amm::stable_pair_math::{invariant_, calculate_amount_out};
  use amm::interest_pool::{
    Self as core,
    Pool,
    Nothing,
    new_pool,
    new_pool_hooks,
  };

  const MINIMUM_LIQUIDITY: u64 = 100;
  const INITIAL_FEE_PERCENT: u256 = 250000000000000; // 0.025%
  const MAX_FEE_PERCENT: u256 = 20000000000000000; // 2%

  struct StateKey has drop, copy, store {}

  struct SwapState has drop {
    coin_x_reserve: u64,
    coin_y_reserve: u64,
    decimals_x: u64,
    decimals_y: u64,
    fee_percent: u256,
    is_x: bool,
  }

  struct State<phantom CoinX, phantom CoinY, phantom LpCoin> has store {
    k_last: u256,
    lp_coin_supply: Supply<LpCoin>,
    balance_x: Balance<CoinX>,
    balance_y: Balance<CoinY>,
    decimals_x: u64,
    decimals_y: u64,
    fee: Balance<LpCoin>,
    seed_liquidity: Balance<LpCoin>,
    fee_percent: u256    
  }

  public fun get_amounts<Label, HookWitness, CoinX, CoinY, LpCoin>(pool: &Pool<StablePair, Label, HookWitness>): (u64, u64, u64) {
    let state = load_state<CoinX, CoinY, LpCoin>(core::borrow_uid(pool));
    get_amounts_internal(state)
  }

  public(friend) fun new<Label, CoinX, CoinY, LpCoin>(
    coin_x: Coin<CoinX>,
    coin_y: Coin<CoinY>,
    lp_coin_supply: Supply<LpCoin>,
    coin_x_metadata: &CoinMetadata<CoinX>,
    coin_y_metadata: &CoinMetadata<CoinY>,      
    ctx: &mut TxContext
  ): (Pool<StablePair, Label, Nothing>, Coin<LpCoin>) {
    let pool = new_pool<StablePair, Label>(make_coins<CoinX, CoinY>(), ctx);

    let lp_coin = add_state(
      core::borrow_mut_uid(&mut pool),
      coin_x,
      coin_y,
      lp_coin_supply,
      coin_x_metadata,
      coin_y_metadata,
      ctx  
    );

    (pool, lp_coin)
  }

  public(friend) fun new_with_hooks<HookWitness:drop, Label, CoinX, CoinY, LpCoin>(
    otw: HookWitness, 
    coin_x: Coin<CoinX>,
    coin_y: Coin<CoinY>,
    lp_coin_supply: Supply<LpCoin>,
    coin_x_metadata: &CoinMetadata<CoinX>,
    coin_y_metadata: &CoinMetadata<CoinY>,      
    ctx: &mut TxContext
  ): (Pool<StablePair, Label, HookWitness>, Coin<LpCoin>) {
    let pool = new_pool_hooks<HookWitness, StablePair, Label>(otw, make_coins<CoinX, CoinY>(), ctx);

    let lp_coin = add_state(
      core::borrow_mut_uid(&mut pool),
      coin_x,
      coin_y,
      lp_coin_supply,
      coin_x_metadata,
      coin_y_metadata,
      ctx  
    );

    (pool, lp_coin)
  }

  public(friend) fun swap<Label, HookWitness, CoinIn, CoinOut, LpCoin>(
    pool: &mut Pool<StablePair, Label, HookWitness>, 
    coin_in: Coin<CoinIn>,
    coin_min_value: u64,
    ctx: &mut TxContext    
  ): Coin<CoinOut> {
    asserts::assert_coin_has_value(&coin_in);

    if (is_coin_x<CoinIn>(core::view_coins<StablePair, Label, HookWitness>(pool))) 
      swap_coin_x<Label, HookWitness, CoinIn, CoinOut, LpCoin>(pool, coin_in, coin_min_value, ctx)
    else 
      swap_coin_y<Label, HookWitness, CoinOut, CoinIn, LpCoin>(pool, coin_in, coin_min_value, ctx)

  }

  fun swap_coin_x<Label, HookWitness, CoinX, CoinY, LpCoin>(
    pool: &mut Pool<StablePair, Label, HookWitness>, 
    coin_x: Coin<CoinX>,
    coin_y_min_value: u64,
    ctx: &mut TxContext
  ): Coin<CoinY> {
    let state = load_mut_state<CoinX, CoinY, LpCoin>(core::borrow_mut_uid(pool));
    // * Important needs to be created before any mutations
    let swap_state = make_swap_state(state, true);

    let coin_in_amount = coin::value(&coin_x);

    balance::join(&mut state.balance_x, coin::into_balance(coin_x));

    coin::take(&mut state.balance_y, swap_amount_out(swap_state, coin_in_amount, coin_y_min_value), ctx) 
  }

  fun swap_coin_y<Label, HookWitness, CoinX, CoinY, LpCoin>(
    pool: &mut Pool<StablePair, Label, HookWitness>, 
    coin_y: Coin<CoinY>,
    coin_x_min_value: u64,
    ctx: &mut TxContext
  ): Coin<CoinX> {
    let state = load_mut_state<CoinX, CoinY, LpCoin>(core::borrow_mut_uid(pool));
    // * Important needs to be created before any mutations
    let swap_state = make_swap_state(state, false);

    let coin_in_amount = coin::value(&coin_y);

    balance::join(&mut state.balance_y, coin::into_balance(coin_y));

    coin::take(&mut state.balance_x, swap_amount_out(swap_state, coin_in_amount, coin_x_min_value), ctx) 
  }

  fun swap_amount_out(
    state: SwapState,
    coin_in_amount: u64,
    coin_out_min_value: u64 
  ): u64 {
    let prev_k = invariant_(state.coin_x_reserve, state.coin_y_reserve, state.decimals_x, state.decimals_y);

    let amount_out = calculate_amount_out(
      prev_k,
      coin_in_amount,  
      state.coin_x_reserve,  
      state.coin_y_reserve, 
      state.decimals_x, 
      state.decimals_y, 
      state.fee_percent, 
      state.is_x
    );

    assert!(amount_out >= coin_out_min_value, errors::slippage());

    let new_k = if (state.is_x) 
        invariant_(state.coin_x_reserve + coin_in_amount, state.coin_y_reserve - amount_out, state.decimals_x, state.decimals_y)
      else
        invariant_(state.coin_x_reserve - amount_out, state.coin_y_reserve + coin_in_amount, state.decimals_x, state.decimals_y);

    assert!(new_k >= prev_k, errors::invalid_invariant());

    amount_out    
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
    coin_x_metadata: &CoinMetadata<CoinX>,
    coin_y_metadata: &CoinMetadata<CoinY>,  
    ctx: &mut TxContext   
  ): Coin<LpCoin> {
    asserts::assert_supply_has_zero_value(&lp_coin_supply);

    let decimals_x = pow(10, coin::get_decimals(coin_x_metadata));
    let decimals_y = pow(10, coin::get_decimals(coin_y_metadata));

    let coin_x_value = coin::value(&coin_x);
    let coin_y_value = coin::value(&coin_y);

    assert!(coin_x_value != 0 && coin_y_value != 0, errors::cannot_create_empty_pool());

    let shares = (sqrt((coin_x_value as u256) * (coin_y_value as u256)) as u64);

    let seed_liquidity = balance::increase_supply(&mut lp_coin_supply, MINIMUM_LIQUIDITY);

    let sender_balance = balance::increase_supply(&mut lp_coin_supply, shares);

    df::add(id, StateKey {},
      State<CoinX, CoinY, LpCoin> {
        k_last: 0,
        lp_coin_supply,
        balance_x: coin::into_balance(coin_x),
        balance_y: coin::into_balance(coin_y),
        decimals_x,
        decimals_y,
        fee: balance::zero(),
        seed_liquidity,
        fee_percent: INITIAL_FEE_PERCENT       
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
      fee_percent: state.fee_percent,
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

  // * DAO LOGIC

  public(friend) fun update_fee<Label, HookWitness: drop, CoinX, CoinY, LpCoin>(
    pool: &mut Pool<StablePair, Label, HookWitness>,
    fee_percent: u256
  ) {
    assert!(MAX_FEE_PERCENT >= fee_percent, errors::invalid_fee());
    let state = load_mut_state<CoinX, CoinY, LpCoin>(core::borrow_mut_uid(pool));
    state.fee_percent = fee_percent;
  }

  // * HOOK LOGIC

  // @dev The hook contract can mutate the state at will
  public(friend) fun hooks_get_mut_state<Label, HookWitness: drop, CoinX, CoinY, LpCoin>(
    _: HookWitness,
    pool: &mut Pool<StablePair, Label, HookWitness>
  ): (u256, &mut Supply<LpCoin>, &mut Balance<CoinX>, &mut Balance<CoinY>, u64, u64) {
    let state = load_mut_state<CoinX, CoinY, LpCoin>(core::borrow_mut_uid(pool));
    (state.k_last, &mut state.lp_coin_supply, &mut state.balance_x, &mut state.balance_y, state.decimals_x, state.decimals_y)
  }

  public(friend) fun hooks_borrow_mut_uid<Label, HookWitness: drop>(_: HookWitness, pool: &mut Pool<StablePair, Label, HookWitness>): &mut UID {
    core::borrow_mut_uid(pool)
  }
}   