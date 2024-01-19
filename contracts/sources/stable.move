module clamm::interest_clamm_stable {
  // === Imports ===
  
  use std::vector;
  use std::option::Option;
  use std::type_name::{TypeName, get};
  
  use sui::coin::{Self, Coin};
  use sui::object::{Self, UID};
  use sui::clock::{Self, Clock};
  use sui::dynamic_field as df;
  use sui::tx_context::TxContext;
  use sui::dynamic_object_field as dof;
  use sui::transfer::public_share_object;
  use sui::balance::{Self, Supply, Balance};

  use suitears::math256::min;
  use suitears::coin_decimals::{scalar, decimals, CoinDecimals};

  use clamm::errors;
  use clamm::curves::Stable;
  use clamm::amm_admin::Admin;
  use clamm::pool_events as events;
  use clamm::stable_fees::{Self, StableFees};
  use clamm::interest_pool::{Self, InterestPool};
  use clamm::stable_math::{y, y_lp, a as get_a, invariant_};
  use clamm::utils::{empty_vector, are_coins_ordered, make_coins_from_vector};

  // === Consntants ===  

  const MAX_A: u256 = 1_000_000;
  const MAX_A_CHANGE: u256 = 10;
  // @dev 1 day in milliseconds
  const MIN_RAMP_TIME: u64 = 86_400_000;
  // @dev 1e18 
  const PRECISION: u256 = 1_000_000_000_000_000_000; 

  // === Structs ===  

  // @dev Dynamic field key to access stae {State} of a pool.
  struct StateKey has drop, copy, store {}

  // @dev Dynamic field key to access stae {CoinState} of a `sui::coin::Coin`
  struct CoinStatekey has drop, copy, store { type: TypeName }

  // @dev Dynamic field key to access the fees accrued for the admin. 
  struct AdminCoinBalanceKey has drop, copy, store { type: TypeName }

  struct CoinState<phantom CoinType> has store {
    // Decimals of the `sui::coin::Coin`
    decimals: u256,
    // The index of the `sui::coin::Coin` in the state balances vector.  
    index: u64,
    // Balance of the coin
    balance: Balance<CoinType>
  }

  struct State<phantom LpCoin> has key, store {
    id: UID,
    // The supply of the pool's `LpCoin`.
    lp_coin_supply: Supply<LpCoin>,
    // The decimal precision of the `LpCoin`.
    lp_coin_decimals_scalar: u256,
    // The balances of the coin in the pool based in the coin index.   
    balances: vector<u256>,
    // The initial amplifier factor.
    initial_a: u256,
    // The new amplifier factor.
    // We need to update the amplifier overtime to prevent impermanent loss. 
    future_a: u256,
    // The initial ramp time.
    initial_a_time: u256,
    // The future_a_time - initial_a_time gives us the duration of the ramp time to linearly update initial_a to future_a. 
    future_a_time: u256,
    // Number of coins in the pool.   
    n_coins: u64,
    // Holds the fee settings for the pool.  
    fees: StableFees
  }

  // === Public View Functions ===  

  public fun balances<LpCoin>(pool: &InterestPool<Stable>): vector<u256> {
    borrow_state<LpCoin>(interest_pool::borrow_uid(pool)).balances
  }

  public fun initial_a<LpCoin>(pool: &InterestPool<Stable>): u256 {
    let state = borrow_state<LpCoin>(interest_pool::borrow_uid(pool));
    state.initial_a
  }

  public fun future_a<LpCoin>(pool: &InterestPool<Stable>): u256 {
    let state = borrow_state<LpCoin>(interest_pool::borrow_uid(pool));
    state.future_a
  }  

  public fun initial_a_time<LpCoin>(pool: &InterestPool<Stable>): u256 {
    let state = borrow_state<LpCoin>(interest_pool::borrow_uid(pool));
    state.initial_a_time
  }    

  public fun future_a_time<LpCoin>(pool: &InterestPool<Stable>): u256 {
    let state = borrow_state<LpCoin>(interest_pool::borrow_uid(pool));
    state.future_a_time
  }    

  public fun a<LpCoin>(
    pool: &InterestPool<Stable>,
    c: &Clock,
  ): u256 {
    let state = borrow_state<LpCoin>(interest_pool::borrow_uid(pool));
    get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, c)
  }

  public fun lp_coin_supply<LpCoin>(pool: &InterestPool<Stable>): u64 {
    balance::supply_value(&borrow_state<LpCoin>(interest_pool::borrow_uid(pool)).lp_coin_supply)
  }

  public fun lp_coin_decimals_scalar<LpCoin>(pool: &InterestPool<Stable>): u256 {
    (borrow_state<LpCoin>(interest_pool::borrow_uid(pool)).lp_coin_decimals_scalar)
  }  

  public fun n_coins<LpCoin>(pool: &InterestPool<Stable>): u64 {
    borrow_state<LpCoin>(interest_pool::borrow_uid(pool)).n_coins
  }

  public fun fees<LpCoin>(pool: &InterestPool<Stable>): StableFees {
    borrow_state<LpCoin>(interest_pool::borrow_uid(pool)).fees
  }

  public fun admin_balance<CoinType, LpCoin>(pool: &InterestPool<Stable>): u64 {
    let state = borrow_state<LpCoin>(interest_pool::borrow_uid(pool));
    balance::value(df::borrow<AdminCoinBalanceKey, Balance<CoinType>>(&state.id, AdminCoinBalanceKey  { type: get<CoinType>() }))
  } 

  public fun coin_decimals<CoinType, LpCoin>(pool: &InterestPool<Stable>): u8 {
    let state = borrow_state<LpCoin>(interest_pool::borrow_uid(pool));
    (borrow_coin_state<CoinType>(&state.id).decimals as u8)
  } 

  public fun coin_index<CoinType, LpCoin>(pool: &InterestPool<Stable>): u8 {
    let state = borrow_state<LpCoin>(interest_pool::borrow_uid(pool));
    (borrow_coin_state<CoinType>(&state.id).index as u8)
  }  

  public fun coin_balance<CoinType, LpCoin>(pool: &InterestPool<Stable>): u64 {
    let state = borrow_state<LpCoin>(interest_pool::borrow_uid(pool));
    balance::value(&borrow_coin_state<CoinType>(&state.id).balance)
  }     
  
  // @dev Price is returned in 1e18
  public fun virtual_price<LpCoin>(
    pool: &InterestPool<Stable>,
    c: &Clock,
  ): u256 {
    virtual_price_impl(borrow_state<LpCoin>(interest_pool::borrow_uid(pool)), c)
  }

  public fun quote_swap<CoinIn, CoinOut, LpCoin>(
    pool: &InterestPool<Stable>,
    c: &Clock,
    amount: u64    
  ): (u64, u64, u64) {
    let state = borrow_state<LpCoin>(interest_pool::borrow_uid(pool));

    let coin_in_state = borrow_coin_state<CoinIn>(&state.id);
    let coin_out_state = borrow_coin_state<CoinOut>(&state.id);

    let fee_in = stable_fees::calculate_fee_in_amount(&state.fees, amount);

    let normalized_value = ((amount - fee_in) as u256) * PRECISION / coin_in_state.decimals;

    let new_out_balance = y(
      get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, c),
      (coin_in_state.index as u256),
      (coin_out_state.index as u256),
      *vector::borrow(&state.balances, coin_in_state.index) + normalized_value,
      state.balances
    );

    let amount_out = *vector::borrow(&state.balances, coin_out_state.index) - new_out_balance;
    let amount_out = ((amount_out * coin_out_state.decimals / PRECISION) as u64);

    let fee_out = stable_fees::calculate_fee_out_amount(&state.fees, amount_out);

    (amount_out - fee_out, fee_in, fee_out)
  }

  // === Public Create Pool Functions ===  

  #[lint_allow(share_owned)]
  public fun new_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    c: &Clock,
    initial_a: u256,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_decimals: &CoinDecimals,     
    lp_coin_supply: Supply<LpCoin>,
    ctx: &mut TxContext
  ): Coin<LpCoin> {
    assert!(coin::value(&coin_a) != 0 && coin::value(&coin_b) != 0 && coin::value(&coin_c) != 0, errors::no_zero_liquidity_amounts());

    let pool = interest_pool::new<Stable>(make_coins_from_vector(vector[get<CoinA>(), get<CoinB>(), get<CoinC>()]), ctx);
    // * IMPORTANT Make sure the n_coins argument is correct
    add_state<LpCoin>(
      interest_pool::borrow_mut_uid(&mut pool), 
      coin_decimals,
      initial_a, 
      lp_coin_supply, 
      3, 
      ctx
    );

    let state = borrow_mut_state<LpCoin>(interest_pool::borrow_mut_uid(&mut pool));

    // * IMPORTANT Make sure the indexes and CoinTypes match the make_coins vector and they are in the correct order
    add_coin<CoinA>(&mut state.id, coin_decimals, 0);
    add_coin<CoinB>(&mut state.id, coin_decimals, 1);
    add_coin<CoinC>(&mut state.id, coin_decimals, 2);

    let lp_coin = add_liquidity_3_pool(&mut pool, c, coin_a, coin_b, coin_c, 0, ctx);

    events::emit_new_3_pool<Stable, CoinA, CoinB, CoinC, LpCoin>(object::id(&pool));

    public_share_object(pool);

    lp_coin
  }

  #[lint_allow(share_owned)]
  public fun new_4_pool<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    c: &Clock,
    initial_a: u256,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    coin_decimals: &CoinDecimals,      
    lp_coin_supply: Supply<LpCoin>,
    ctx: &mut TxContext
  ): Coin<LpCoin> {
    assert!(
      coin::value(&coin_a) != 0 
      && coin::value(&coin_b) != 0 
      && coin::value(&coin_c) != 0
      && coin::value(&coin_d) != 0,
      errors::no_zero_liquidity_amounts()
    );

    let pool = interest_pool::new<Stable>(
      make_coins_from_vector(vector[get<CoinA>(), get<CoinB>(), get<CoinC>(), get<CoinD>()]), 
      ctx
    );

    // * IMPORTANT Make sure the n_coins argument is correct
    add_state<LpCoin>(
      interest_pool::borrow_mut_uid(&mut pool), 
      coin_decimals,
      initial_a, 
      lp_coin_supply, 
      4, 
      ctx
    );

    let state = borrow_mut_state<LpCoin>(interest_pool::borrow_mut_uid(&mut pool));

    // * IMPORTANT Make sure the indexes and CoinTypes match the make_coins vector and they are in the correct order
    add_coin<CoinA>(&mut state.id, coin_decimals, 0);
    add_coin<CoinB>(&mut state.id, coin_decimals, 1);
    add_coin<CoinC>(&mut state.id, coin_decimals, 2);
    add_coin<CoinD>(&mut state.id, coin_decimals, 3);

    let lp_coin = add_liquidity_4_pool(&mut pool, c, coin_a, coin_b, coin_c, coin_d, 0, ctx);

    events::emit_new_4_pool<Stable, CoinA, CoinB, CoinC, CoinD, LpCoin>(object::id(&pool));

    public_share_object(pool);

    lp_coin
  }

  #[lint_allow(share_owned)]
  public fun new_5_pool<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    c: &Clock,
    initial_a: u256,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    coin_e: Coin<CoinE>,
    coin_decimals: &CoinDecimals,      
    lp_coin_supply: Supply<LpCoin>,
    ctx: &mut TxContext
  ): Coin<LpCoin> {
    assert!(
      coin::value(&coin_a) != 0 
      && coin::value(&coin_b) != 0 
      && coin::value(&coin_c) != 0
      && coin::value(&coin_d) != 0
      && coin::value(&coin_e) != 0,
      errors::no_zero_liquidity_amounts()
    );

    let pool = interest_pool::new<Stable>(
      make_coins_from_vector(vector[get<CoinA>(), get<CoinB>(), get<CoinC>(), get<CoinD>(), get<CoinE>()]), 
      ctx
    );

    // * IMPORTANT Make sure the n_coins argument is correct
    add_state<LpCoin>(
      interest_pool::borrow_mut_uid(&mut pool), 
      coin_decimals,
      initial_a, 
      lp_coin_supply, 
      5, 
      ctx
    );

    let state = borrow_mut_state<LpCoin>(interest_pool::borrow_mut_uid(&mut pool));

    // * IMPORTANT Make sure the indexes and CoinTypes match the make_coins vector and they are in the correct order
    add_coin<CoinA>(&mut state.id, coin_decimals, 0);
    add_coin<CoinB>(&mut state.id, coin_decimals, 1);
    add_coin<CoinC>(&mut state.id, coin_decimals, 2);
    add_coin<CoinD>(&mut state.id, coin_decimals, 3);
    add_coin<CoinE>(&mut state.id, coin_decimals, 4);

    let lp_coin = add_liquidity_5_pool(&mut pool, c, coin_a, coin_b, coin_c, coin_d, coin_e, 0, ctx);

    events::emit_new_5_pool<Stable, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(object::id(&pool));

    public_share_object(pool);

    lp_coin
  }

  // === Public Swap Function ===  

  public fun swap<CoinIn, CoinOut, LpCoin>(
    pool: &mut InterestPool<Stable>,
    c: &Clock,
    coin_in: Coin<CoinIn>,
    min_amount: u64,
    ctx: &mut TxContext
  ): Coin<CoinOut> {
    assert!(get<CoinIn>() != get<CoinOut>(), errors::cannot_swap_same_coin());
    
    let coin_in_value = coin::value(&coin_in);
    assert!(coin_in_value != 0, errors::cannot_swap_zero_value());

    let state = borrow_mut_state<LpCoin>(interest_pool::borrow_mut_uid(pool));

    let coin_in_state = borrow_coin_state<CoinIn>(&state.id);
    let coin_out_state = borrow_coin_state<CoinOut>(&state.id);

    let fee_in = stable_fees::calculate_fee_in_amount(&state.fees, coin_in_value);
    let admin_fee_in = stable_fees::calculate_admin_amount(&state.fees, fee_in);

    let admin_coin_in = coin::split(
      &mut coin_in, 
      admin_fee_in, 
      ctx
    );

    // Has no fees to properly calculate new out balance
    let normalized_value = ((coin_in_value - fee_in - admin_fee_in) as u256) * PRECISION / coin_in_state.decimals;

    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, c);

    let prev_k = invariant_(amp, state.balances);

    let new_out_balance = y(
      amp,
      (coin_in_state.index as u256),
      (coin_out_state.index as u256),
      *vector::borrow(&state.balances, coin_in_state.index) + normalized_value,
      state.balances
    );

    let normalized_amount_out = *vector::borrow(&state.balances, coin_out_state.index) - new_out_balance;
    let amount_out = ((normalized_amount_out * coin_out_state.decimals / PRECISION) as u64);
    
    let fee_out = stable_fees::calculate_fee_out_amount(&state.fees, amount_out);
    let admin_fee_out = stable_fees::calculate_admin_amount(&state.fees, fee_out);

    let amount_out = amount_out - fee_out - admin_fee_out;

    assert!(amount_out >= min_amount, errors::slippage());

    // Update balances
    let coin_in_balance = vector::borrow_mut(&mut state.balances, coin_in_state.index);
    *coin_in_balance = *coin_in_balance + normalized_value + ((fee_in - admin_fee_in as u256) * PRECISION / coin_in_state.decimals);

    let coin_out_balance = vector::borrow_mut(&mut state.balances, coin_out_state.index);
    // We need to remove the admin fee from balance
    *coin_out_balance = *coin_out_balance - ((((amount_out + admin_fee_out) as u256) * PRECISION / coin_out_state.decimals) as u256); 

    // * Invariant must hold after all balances updates
    assert!(invariant_(amp, state.balances) >= prev_k, errors::invalid_invariant());

    let coin_in_state = borrow_mut_coin_state<CoinIn>(&mut state.id);

    /*
    * The admin fees are not part of the liquidity (do not accrue swap fees) and not counted on the invariant calculation
    * Fees are applied both on coin in and coin out to keep the balance in the pool
    * 1 - Deposit coin_in (without admin fees) to balance
    * 2 - Deposit coin_admin_in (admin fees on coin)
    * 3 - Deposit coin_admin_out (admin fees on coin out)
    * 4 - Take coin_out for user
    */
    balance::join(&mut coin_in_state.balance, coin::into_balance(coin_in));
    balance::join(borrow_mut_admin_balance<CoinIn>(&mut state.id), coin::into_balance(admin_coin_in));

    let coin_out_state = borrow_mut_coin_state<CoinOut>(&mut state.id);

    let coin_out_balance = &mut coin_out_state.balance;

    let admin_balance_in = balance::split(coin_out_balance, admin_fee_out);

    let coin_out = coin::take(coin_out_balance, amount_out, ctx);

    balance::join(borrow_mut_admin_balance<CoinOut>(&mut state.id), admin_balance_in);

    events::emit_swap<Stable, CoinIn, CoinOut, LpCoin>(object::id(pool), coin_in_value, amount_out);

    coin_out
  }

  // === Public Add Liquidity Functions ===  

  public fun add_liquidity_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Stable>,
    c: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    assert!(are_coins_ordered(pool, vector[get<CoinA>(), get<CoinB>(), get<CoinC>()]), errors::coins_must_be_in_order());
    let pool_id = object::id(pool);
    let state = borrow_mut_state<LpCoin>(interest_pool::borrow_mut_uid(pool));

    let prev_invariant = virtual_price_impl(state, c);
    
    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, c);    

    let prev_k = invariant_(amp, state.balances);

    let coin_a_value = deposit_coin<CoinA, LpCoin>(state, coin_a);
    let coin_b_value = deposit_coin<CoinB, LpCoin>(state, coin_b);
    let coin_c_value = deposit_coin<CoinC, LpCoin>(state, coin_c);

    let mint_amount = calculate_mint_amount(state, amp, prev_k, lp_coin_min_amount);

    events::emit_add_liquidity_3_pool<Stable, CoinA, CoinB, CoinC, LpCoin>(
      pool_id, 
      coin_a_value, 
      coin_b_value, 
      coin_c_value, 
      mint_amount
    );

    let lp_coin = coin::from_balance(
      balance::increase_supply(
        &mut state.lp_coin_supply, 
        mint_amount
      ), 
      ctx
    );

    assert!(virtual_price_impl(borrow_state<LpCoin>(interest_pool::borrow_uid(pool)), c) >= prev_invariant, errors::invalid_invariant());

    lp_coin
  }

  public fun add_liquidity_4_pool<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    pool: &mut InterestPool<Stable>,
    c: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    assert!(
      are_coins_ordered(
        pool, 
        vector[get<CoinA>(), get<CoinB>(), get<CoinC>(), get<CoinD>()]), 
      errors::coins_must_be_in_order()
    );
    
    let pool_id = object::id(pool);
    let state = borrow_mut_state<LpCoin>(interest_pool::borrow_mut_uid(pool));
    let prev_invariant = virtual_price_impl(state, c);
    
    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, c);    
    let prev_k = invariant_(amp, state.balances);

    let coin_a_value = deposit_coin<CoinA, LpCoin>(state, coin_a);
    let coin_b_value = deposit_coin<CoinB, LpCoin>(state, coin_b);
    let coin_c_value = deposit_coin<CoinC, LpCoin>(state, coin_c);
    let coin_d_value = deposit_coin<CoinD, LpCoin>(state, coin_d);

    let mint_amount = calculate_mint_amount(state, amp, prev_k, lp_coin_min_amount);

    events::emit_add_liquidity_4_pool<Stable, CoinA, CoinB, CoinC, CoinD, LpCoin>(
      pool_id, 
      coin_a_value, 
      coin_b_value, 
      coin_c_value,
      coin_d_value, 
      mint_amount
    );

    let lp_coin = coin::from_balance(
      balance::increase_supply(
        &mut state.lp_coin_supply, 
        mint_amount
      ), 
      ctx
    );

    assert!(virtual_price_impl(borrow_state<LpCoin>(interest_pool::borrow_uid(pool)), c) >= prev_invariant, errors::invalid_invariant());

    lp_coin
  }

  public fun add_liquidity_5_pool<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    pool: &mut InterestPool<Stable>,
    c: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    coin_e: Coin<CoinE>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    assert!(
      are_coins_ordered(
        pool, 
        vector[get<CoinA>(), get<CoinB>(), get<CoinC>(), get<CoinD>(), get<CoinE>()]), 
      errors::coins_must_be_in_order()
    );

    let pool_id = object::id(pool);
    let state = borrow_mut_state<LpCoin>(interest_pool::borrow_mut_uid(pool));

    let prev_invariant = virtual_price_impl(state, c);
    
    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, c);    
    let prev_k = invariant_(amp, state.balances);

    let coin_a_value = deposit_coin<CoinA, LpCoin>(state, coin_a);
    let coin_b_value = deposit_coin<CoinB, LpCoin>(state, coin_b);
    let coin_c_value = deposit_coin<CoinC, LpCoin>(state, coin_c);
    let coin_d_value = deposit_coin<CoinD, LpCoin>(state, coin_d);
    let coin_e_value = deposit_coin<CoinE, LpCoin>(state, coin_e);

    let mint_amount = calculate_mint_amount(state, amp, prev_k, lp_coin_min_amount);

    events::emit_add_liquidity_5_pool<Stable, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
      pool_id, 
      coin_a_value, 
      coin_b_value, 
      coin_c_value,
      coin_d_value,
      coin_e_value, 
      mint_amount
    );


    let lp_coin = coin::from_balance(
      balance::increase_supply(
        &mut state.lp_coin_supply, 
        mint_amount
      ), 
      ctx
    );

    assert!(virtual_price_impl(borrow_state<LpCoin>(interest_pool::borrow_uid(pool)), c) >= prev_invariant, errors::invalid_invariant());

    lp_coin
  }

  // === Public Remove Liquidity Functions ===    

  public fun remove_one_coin_liquidity<CoinType, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    c: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amount: u64,
    ctx: &mut TxContext    
  ): Coin<CoinType> {
    let lp_coin_value = coin::value(&lp_coin);
    assert!(lp_coin_value != 0, errors::no_zero_coin());

    let pool_id = object::id(pool);
    let state = borrow_mut_state<LpCoin>(interest_pool::borrow_mut_uid(pool));

    let prev_invariant = virtual_price_impl(state, c);

    let coin_state = borrow_mut_coin_state<CoinType>(&mut state.id);

    let balances = state.balances;

    let current_coin_balance = vector::borrow_mut(&mut state.balances, coin_state.index);
    let initial_coin_balance = *current_coin_balance;
    
    *current_coin_balance = y_lp(
      get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, c),
      (coin_state.index as u256),
      balances,
      (lp_coin_value as u256),
      (balance::supply_value(&state.lp_coin_supply) as u256),
    ) + 1; // give an edge to the protocol

    let amount_to_take = (((initial_coin_balance - min(initial_coin_balance, *current_coin_balance)) * coin_state.decimals / PRECISION) as u64);

    assert!(amount_to_take >= min_amount, errors::slippage());

    balance::decrease_supply(&mut state.lp_coin_supply, coin::into_balance(lp_coin));

    events::emit_remove_liquidity<Stable, CoinType, LpCoin>(pool_id, amount_to_take, lp_coin_value);

    let coin_out = coin::take(&mut coin_state.balance, amount_to_take, ctx);

    assert!(virtual_price_impl(borrow_state<LpCoin>(interest_pool::borrow_uid(pool)), c) >= prev_invariant, errors::invalid_invariant());

    coin_out
  }

  public fun remove_liquidity_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    lp_coin: Coin<LpCoin>,
    c: &Clock,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>, Coin<CoinC>) {
    assert!(
      are_coins_ordered(
        pool, 
        vector[get<CoinA>(), get<CoinB>(), get<CoinC>()]), 
      errors::coins_must_be_in_order()
    );

    let lp_coin_value = coin::value(&lp_coin);
    assert!(lp_coin_value != 0, errors::no_zero_coin());

    let state = borrow_mut_state<LpCoin>(interest_pool::borrow_mut_uid(pool));

    let prev_invariant = virtual_price_impl(state, c);

    let (coin_a, coin_b, coin_c) = (
      take_coin<CoinA, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinB, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinC, LpCoin>(state, lp_coin_value, min_amounts, ctx),
    );

    balance::decrease_supply(&mut state.lp_coin_supply, coin::into_balance(lp_coin));

    events::emit_remove_liquidity_3_pool<Stable, CoinA, CoinB, CoinC, LpCoin>(
      object::id(pool), 
      coin::value(&coin_a),
      coin::value(&coin_b),
      coin::value(&coin_c),
      lp_coin_value
    );

    assert!(virtual_price_impl(borrow_state<LpCoin>(interest_pool::borrow_uid(pool)), c) >= prev_invariant, errors::invalid_invariant());

    (coin_a, coin_b, coin_c)
  }

  public fun remove_liquidity_4_pool<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    lp_coin: Coin<LpCoin>,
    c: &Clock,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>, Coin<CoinC>, Coin<CoinD>) {
    assert!(
      are_coins_ordered(
        pool, 
        vector[get<CoinA>(), get<CoinB>(), get<CoinC>(), get<CoinD>()]), 
      errors::coins_must_be_in_order()
    );

    let lp_coin_value = coin::value(&lp_coin);
    assert!(lp_coin_value != 0, errors::no_zero_coin());

    let state = borrow_mut_state<LpCoin>(interest_pool::borrow_mut_uid(pool));

    let prev_invariant = virtual_price_impl(state, c);

    let (coin_a, coin_b, coin_c, coin_d) = (
      take_coin<CoinA, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinB, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinC, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinD, LpCoin>(state, lp_coin_value, min_amounts, ctx),
    );

    balance::decrease_supply(&mut state.lp_coin_supply, coin::into_balance(lp_coin));

    events::emit_remove_liquidity_4_pool<Stable, CoinA, CoinB, CoinC, CoinD, LpCoin>(
      object::id(pool), 
      coin::value(&coin_a),
      coin::value(&coin_b),
      coin::value(&coin_c),
      coin::value(&coin_d),
      lp_coin_value
    );

    assert!(virtual_price_impl(borrow_state<LpCoin>(interest_pool::borrow_uid(pool)), c) >= prev_invariant, errors::invalid_invariant());

    (coin_a, coin_b, coin_c, coin_d)
  }

  public fun remove_liquidity_5_pool<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    lp_coin: Coin<LpCoin>,
    c: &Clock,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>, Coin<CoinC>, Coin<CoinD>, Coin<CoinE>) {
    assert!(
      are_coins_ordered(
        pool, 
        vector[get<CoinA>(), get<CoinB>(), get<CoinC>(), get<CoinD>(), get<CoinE>()]), 
      errors::coins_must_be_in_order()
    );

    let lp_coin_value = coin::value(&lp_coin);
    assert!(lp_coin_value != 0, errors::no_zero_coin());

    let state = borrow_mut_state<LpCoin>(interest_pool::borrow_mut_uid(pool));

    let prev_invariant = virtual_price_impl(state, c);

    let (coin_a, coin_b, coin_c, coin_d, coin_e) = (
      take_coin<CoinA, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinB, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinC, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinD, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinE, LpCoin>(state, lp_coin_value, min_amounts, ctx),
    );

    balance::decrease_supply(&mut state.lp_coin_supply, coin::into_balance(lp_coin));

    events::emit_remove_liquidity_5_pool<Stable, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
      object::id(pool), 
      coin::value(&coin_a),
      coin::value(&coin_b),
      coin::value(&coin_c),
      coin::value(&coin_d),
      coin::value(&coin_e),
      lp_coin_value
    );

    assert!(virtual_price_impl(borrow_state<LpCoin>(interest_pool::borrow_uid(pool)), c) >= prev_invariant, errors::invalid_invariant());    

    (coin_a, coin_b, coin_c, coin_d, coin_e)
  }

  // === Admin Only Functions ===    

  public fun ramp<LpCoin>(pool: &mut InterestPool<Stable>, _: &Admin, c: &Clock, future_a: u256, future_a_time: u256) {
    let current_timestamp = clock::timestamp_ms(c);
    let pool_id = object::id(pool);
    let state = borrow_mut_state<LpCoin>(interest_pool::borrow_mut_uid(pool));

    assert!(current_timestamp > (state.initial_a_time as u64) + MIN_RAMP_TIME, errors::wait_one_day());
    assert!(future_a_time >= ((current_timestamp + MIN_RAMP_TIME) as u256), errors::future_ramp_time_is_too_short());

    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, c); 

    assert!(future_a > 0 && future_a < MAX_A, errors::invalid_amplifier());
    assert!((future_a > amp && amp * MAX_A_CHANGE >= future_a) || (amp > future_a && future_a * MAX_A_CHANGE >= amp), errors::invalid_amplifier());

    state.initial_a = amp;
    state.initial_a_time = (current_timestamp as u256);
    state.future_a = future_a;
    state.future_a_time = future_a_time;

    events::emit_ramp_a<LpCoin>(pool_id, amp, future_a, future_a_time, current_timestamp);
  }

  public fun stop_ramp<LpCoin>(pool: &mut InterestPool<Stable>, _: &Admin, c: &Clock) {
    let current_timestamp = clock::timestamp_ms(c);

    let pool_id = object::id(pool);
    let state = borrow_mut_state<LpCoin>(interest_pool::borrow_mut_uid(pool));

    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, c); 

    state.initial_a = amp;
    state.initial_a_time = (current_timestamp as u256);
    state.future_a = amp;
    state.future_a_time = (current_timestamp as u256);

    events::emit_stop_ramp_a<LpCoin>(pool_id, amp, current_timestamp);
  }

  public fun update_fee<LpCoin>(
    pool: &mut InterestPool<Stable>,
    _: &Admin,
    fee_in_percent: Option<u256>,
    fee_out_percent: Option<u256>, 
    admin_fee_percent: Option<u256>,  
  ) {
    let pool_id = object::id(pool);
    let state = borrow_mut_state<LpCoin>(interest_pool::borrow_mut_uid(pool));

    stable_fees::update_fee_in_percent(&mut state.fees, fee_in_percent);
    stable_fees::update_fee_out_percent(&mut state.fees, fee_out_percent);  
    stable_fees::update_admin_fee_percent(&mut state.fees, admin_fee_percent);

    events::emit_update_stable_fee<Stable, LpCoin>(
      pool_id, 
      stable_fees::fee_in_percent(&state.fees), 
      stable_fees::fee_out_percent(&state.fees), 
      stable_fees::admin_fee_percent(&state.fees)
    );
  }

  public fun take_fees<CoinType, LpCoin>(
    pool: &mut InterestPool<Stable>,
    _: &Admin,
    ctx: &mut TxContext
  ): Coin<CoinType> {
    let pool_id = object::id(pool);

    let state = borrow_mut_state<LpCoin>(interest_pool::borrow_mut_uid(pool));
    let admin_balance = borrow_mut_admin_balance<CoinType>(&mut state.id);
    let amount = balance::value(admin_balance);

    events::emit_take_fees<Stable, CoinType, LpCoin>(pool_id, amount);

    coin::take(admin_balance, amount, ctx)
  }

  // === Private Functions ===    

  fun calculate_mint_amount<LpCoin>(state: &State<LpCoin>, amp: u256, prev_k: u256, lp_coin_min_amount: u64): u64 {
    let new_k = invariant_(amp, state.balances);

    assert!(new_k > prev_k, errors::invalid_invariant());

    let supply_value = (balance::supply_value(&state.lp_coin_supply) as u256);

    let mint_amount = if (supply_value == 0) { ((new_k / 1_000_000_000)  as u64) } else { ((supply_value * (new_k - prev_k) / prev_k) as u64) };

    assert!(mint_amount >= lp_coin_min_amount, errors::slippage());

    mint_amount
  }

  fun deposit_coin<CoinType, LpCoin>(state: &mut State<LpCoin>, coin_in: Coin<CoinType>): u64 {
    let coin_value = (coin::value(&coin_in) as u256);

    if (coin_value == 0) {
      coin::destroy_zero(coin_in);
      return 0
    };

    let coin_state = borrow_mut_coin_state<CoinType>(&mut state.id);

    // Update the balance for the coin
    let current_balance = vector::borrow_mut(&mut state.balances, coin_state.index);
    *current_balance = *current_balance + (coin_value * PRECISION / coin_state.decimals);

    balance::join(&mut coin_state.balance, coin::into_balance(coin_in))
  }

  fun take_coin<CoinType, LpCoin>(
    state: &mut State<LpCoin>, 
    lp_coin_value: u64, 
    min_amounts: vector<u64>, 
    ctx: &mut TxContext
  ): Coin<CoinType> {
    let coin_state = borrow_mut_coin_state<CoinType>(&mut state.id);    

    let current_balance = vector::borrow_mut(&mut state.balances, coin_state.index);

    let denormalized_value = *current_balance * coin_state.decimals / PRECISION;

    let balance_to_remove = denormalized_value * (lp_coin_value as u256) / (balance::supply_value(&state.lp_coin_supply) as u256);

    assert!((balance_to_remove as u64) >= *vector::borrow(&min_amounts, coin_state.index), errors::slippage());

    *current_balance = *current_balance - (balance_to_remove * PRECISION / coin_state.decimals);

    coin::take(&mut coin_state.balance, (balance_to_remove as u64), ctx)
  }

  fun add_coin<CoinType>(id: &mut UID, coin_decimals: &CoinDecimals, index: u64) {
    let coin_name = get<CoinType>();

    df::add(id, AdminCoinBalanceKey { type: coin_name }, balance::zero<CoinType>());
    df::add(id, CoinStatekey { type: coin_name }, CoinState {
      decimals: (scalar<CoinType>(coin_decimals) as u256),
      balance: balance::zero<CoinType>(),
      index
    });
  }

  fun add_state<LpCoin>(
    id: &mut UID,
    coin_decimals: &CoinDecimals,  
    initial_a: u256,
    lp_coin_supply: Supply<LpCoin>,
    n_coins: u64,
    ctx: &mut TxContext
  ) {
    assert!(balance::supply_value(&lp_coin_supply) == 0, errors::supply_must_have_zero_value());
    let lp_coin_decimals = decimals<LpCoin>(coin_decimals);

    assert!(lp_coin_decimals == 9, errors::must_have_9_decimals());
    dof::add(id, StateKey {}, 
      State {
        id: object::new(ctx),
        balances: empty_vector((n_coins as u256)),
        initial_a,
        future_a: initial_a,
        initial_a_time: 0,
        future_a_time: 0,
        lp_coin_supply,
        lp_coin_decimals_scalar: (scalar<LpCoin>(coin_decimals) as u256),
        n_coins,
        fees: stable_fees::new()
      }
    );
  }

  fun virtual_price_impl<LpCoin>(state: &State<LpCoin>, c: &Clock): u256 {
    let supply = (balance::supply_value(&state.lp_coin_supply) as u256);

    if (supply == 0) return 0;

    let k = invariant_(
      get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, c), 
      state.balances
    );

    k * state.lp_coin_decimals_scalar / supply
  }

  fun borrow_state<LpCoin>(id: &UID): &State<LpCoin> {
    dof::borrow(id, StateKey {})
  }

  fun borrow_mut_state<LpCoin>(id: &mut UID): &mut State<LpCoin> {
    dof::borrow_mut(id, StateKey {})
  }

  fun borrow_coin_state<CoinType>(id: &UID): &CoinState<CoinType> {
    df::borrow(id, CoinStatekey { type: get<CoinType>() })
  }  

  fun borrow_mut_coin_state<CoinType>(id: &mut UID): &mut CoinState<CoinType> {
    df::borrow_mut(id, CoinStatekey { type: get<CoinType>() })
  }

  fun borrow_mut_admin_balance<CoinType>(id: &mut UID): &mut Balance<CoinType> {
    df::borrow_mut(id, AdminCoinBalanceKey  { type: get<CoinType>() })
  } 
}