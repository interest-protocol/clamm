module clamm::interest_clamm_stable {
  // === Imports ===

  use std::type_name::{Self, TypeName};

  use sui::clock::Clock;
  use sui::bag::{Self, Bag};
  use sui::coin::{Self, Coin};
  use sui::versioned::{Self, Versioned};
  use sui::balance::{Self, Supply, Balance};

  use suitears::math256::min;
  use suitears::coin_decimals::{scalar, decimals, CoinDecimals};

  use clamm::utils;
  use clamm::errors;
  use clamm::curves::Stable;
  use clamm::pool_admin::PoolAdmin;
  use clamm::pool_events as events;
  use clamm::stable_fees::{Self, StableFees};
  use clamm::stable_math::{y, y_lp, a as get_a, invariant_};
  use clamm::interest_pool::{Self, InterestPool, HooksBuilder};
  use clamm::utils::{empty_vector, make_coins_vec_set_from_vector};

  use fun coin::take as Balance.take;
  use fun utils::to_u64 as u256.to_u64;
  use fun utils::to_u256 as u64.to_u256;
  use fun coin::from_balance as Balance.to_coin;

  // === Constants ===

  const STATE_V1_VERSION: u64 = 1;
  const MAX_A: u256 = 1_000_000;
  const MAX_A_CHANGE: u256 = 10;
  /// @dev 1 day in milliseconds
  const MIN_RAMP_TIME: u64 = 86_400_000;
  /// @dev 1e18 
  const PRECISION: u256 = 1_000_000_000_000_000_000; 

  // === Structs ===

  public struct CoinState<phantom CoinType> has store {
    /// Decimals of the `sui::coin::Coin`
    decimals: u256,
    /// The index of the `sui::coin::Coin` in the state balances vector.  
    index: u64,
    /// Balance of the coin
    balance: Balance<CoinType>
  }

  public struct StateV1<phantom LpCoin> has key, store {
    id: UID,
    /// The supply of the pool's `LpCoin`.
    lp_coin_supply: Supply<LpCoin>,
    /// The decimal precision of the `LpCoin`.
    lp_coin_decimals_scalar: u256,
    /// The balances of the coin in the pool based in the coin index.   
    balances: vector<u256>,
    /// The initial amplifier factor.
    initial_a: u256,
    /// The new amplifier factor.
    /// We need to update the amplifier overtime to prevent impermanent loss. 
    future_a: u256,
    /// The initial ramp time.
    initial_a_time: u256,
    /// The future_a_time - initial_a_time gives us the duration of the ramp time to linearly update initial_a to future_a. 
    future_a_time: u256,
    /// Number of coins in the pool.   
    n_coins: u64,
    /// Holds the fee settings for the pool.  
    fees: StableFees,
    /// TypeName => CoinState
    coins: Bag,
    /// TypeName => Balance
    admin_balances: Bag
  }  

  // === Public-Mutative Functions ===

  public fun new_2_pool<CoinA, CoinB, LpCoin>(
    clock: &Clock,
    initial_a: u256,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_decimals: &CoinDecimals,     
    lp_coin_supply: Supply<LpCoin>,
    ctx: &mut TxContext
  ): (InterestPool<Stable>, PoolAdmin, Coin<LpCoin>)  {
    let coins = vector[type_name::get<CoinA>(), type_name::get<CoinB>()];

    let (pool, pool_admin) = new_pool<LpCoin>( 
      coin_decimals,
      initial_a, 
      lp_coin_supply, 
      coins,
      ctx
    );
    
    let (pool, lp_coin) = new_2_pool_impl<CoinA, CoinB, LpCoin>(
      pool,
      clock, 
      coin_a, 
      coin_b, 
      coin_decimals, 
      ctx
    );

    (pool, pool_admin, lp_coin)
  }

  public fun new_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    clock: &Clock,
    initial_a: u256,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_decimals: &CoinDecimals,     
    lp_coin_supply: Supply<LpCoin>,
    ctx: &mut TxContext
  ): (InterestPool<Stable>, PoolAdmin, Coin<LpCoin>) {
    let coins = vector[type_name::get<CoinA>(), type_name::get<CoinB>(), type_name::get<CoinC>()];

    let (pool, pool_admin) = new_pool<LpCoin>( 
      coin_decimals,
      initial_a, 
      lp_coin_supply, 
      coins,
      ctx
    );

    let (pool, lp_coin) = new_3_pool_impl<CoinA, CoinB, CoinC, LpCoin>(
      pool,
      clock, 
      coin_a, 
      coin_b,
      coin_c, 
      coin_decimals, 
      ctx
    );

    (pool, pool_admin, lp_coin)        
  }

  public fun new_4_pool<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    clock: &Clock,
    initial_a: u256,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    coin_decimals: &CoinDecimals,      
    lp_coin_supply: Supply<LpCoin>,
    ctx: &mut TxContext
  ): (InterestPool<Stable>, PoolAdmin, Coin<LpCoin>) {
    let coins = vector[
      type_name::get<CoinA>(), 
      type_name::get<CoinB>(), 
      type_name::get<CoinC>(), 
      type_name::get<CoinD>()
    ];

    let (pool, pool_admin) = new_pool<LpCoin>( 
      coin_decimals,
      initial_a, 
      lp_coin_supply, 
      coins,
      ctx
    );

    let (pool, lp_coin) = new_4_pool_impl<CoinA, CoinB, CoinC, CoinD, LpCoin>(
      pool,
      clock, 
      coin_a, 
      coin_b,
      coin_c, 
      coin_d,
      coin_decimals, 
      ctx
    );

    (pool, pool_admin, lp_coin)      
  }

  public fun new_5_pool<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    clock: &Clock,
    initial_a: u256,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    coin_e: Coin<CoinE>,
    coin_decimals: &CoinDecimals,      
    lp_coin_supply: Supply<LpCoin>,
    ctx: &mut TxContext
  ): (InterestPool<Stable>, PoolAdmin, Coin<LpCoin>) {
    let coins = vector[
      type_name::get<CoinA>(), 
      type_name::get<CoinB>(), 
      type_name::get<CoinC>(), 
      type_name::get<CoinD>(),
      type_name::get<CoinE>()
    ];

    let (pool, pool_admin) = new_pool<LpCoin>( 
      coin_decimals,
      initial_a, 
      lp_coin_supply, 
      coins,
      ctx
    );

    let (pool, lp_coin) = new_5_pool_impl<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
      pool,
      clock, 
      coin_a, 
      coin_b,
      coin_c, 
      coin_d,
      coin_e,
      coin_decimals, 
      ctx
    );

    (pool, pool_admin, lp_coin)   
  }

  public fun swap<CoinIn, CoinOut, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    coin_in: Coin<CoinIn>,
    min_amount: u64,
    ctx: &mut TxContext
  ): Coin<CoinOut> {
    assert!(!pool.has_swap_hook(), errors::this_pool_has_hooks());
    swap_impl<CoinIn, CoinOut, LpCoin>(pool, clock, coin_in, min_amount, ctx)
  }

  public fun add_liquidity_2_pool<CoinA, CoinB, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    assert!(!pool.has_add_liquidity_hook(), errors::this_pool_has_hooks());
    add_liquidity_2_pool_impl<CoinA, CoinB, LpCoin>(pool, clock, coin_a, coin_b, lp_coin_min_amount, ctx)
  }  

  public fun add_liquidity_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    assert!(!pool.has_add_liquidity_hook(), errors::this_pool_has_hooks());
    add_liquidity_3_pool_impl<CoinA, CoinB, CoinC, LpCoin>(
      pool, 
      clock, 
      coin_a, 
      coin_b, 
      coin_c,
      lp_coin_min_amount, 
      ctx
    )
  }

  public fun add_liquidity_4_pool<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    assert!(!pool.has_add_liquidity_hook(), errors::this_pool_has_hooks());
    add_liquidity_4_pool_impl<CoinA, CoinB, CoinC, CoinD, LpCoin>(
      pool, 
      clock, 
      coin_a, 
      coin_b, 
      coin_c,
      coin_d,
      lp_coin_min_amount, 
      ctx
    )    
  }

  public fun add_liquidity_5_pool<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    coin_e: Coin<CoinE>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    assert!(!pool.has_add_liquidity_hook(), errors::this_pool_has_hooks());
    add_liquidity_5_pool_impl<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
      pool, 
      clock, 
      coin_a, 
      coin_b, 
      coin_c,
      coin_d,
      coin_e,
      lp_coin_min_amount, 
      ctx
    )      
  }

  public fun remove_liquidity_2_pool<CoinA, CoinB, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>) {
    assert!(!pool.has_remove_liquidity_hook(), errors::this_pool_has_hooks());
    remove_liquidity_2_pool_impl(pool, clock, lp_coin, min_amounts, ctx)
  }

  public fun remove_liquidity_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>, Coin<CoinC>) {
    assert!(!pool.has_remove_liquidity_hook(), errors::this_pool_has_hooks());
    remove_liquidity_3_pool_impl(pool, clock, lp_coin, min_amounts, ctx)
  }

  public fun remove_liquidity_4_pool<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    lp_coin: Coin<LpCoin>,
    clock: &Clock,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>, Coin<CoinC>, Coin<CoinD>) {
    assert!(!pool.has_remove_liquidity_hook(), errors::this_pool_has_hooks());
    remove_liquidity_4_pool_impl(pool, clock, lp_coin, min_amounts, ctx)    
  }

  public fun remove_liquidity_5_pool<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>, Coin<CoinC>, Coin<CoinD>, Coin<CoinE>) {
    assert!(!pool.has_remove_liquidity_hook(), errors::this_pool_has_hooks());
    remove_liquidity_5_pool_impl(pool, clock, lp_coin, min_amounts, ctx)       
  }

  public fun remove_one_coin_liquidity<CoinType, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amount: u64,
    ctx: &mut TxContext    
  ): Coin<CoinType> {
    assert!(!pool.has_remove_liquidity_hook(), errors::this_pool_has_hooks());
    remove_one_coin_liquidity_impl(pool, clock, lp_coin, min_amount, ctx)
  }

  // === Public-View Functions ===

  public fun balances<LpCoin>(pool: &mut InterestPool<Stable>): vector<u256> {
    load<LpCoin>(pool.state_mut()).balances
  }

  public fun initial_a<LpCoin>(pool: &mut InterestPool<Stable>): u256 {
    load<LpCoin>(pool.state_mut()).initial_a
  }

  public fun future_a<LpCoin>(pool: &mut InterestPool<Stable>): u256 {
    load<LpCoin>(pool.state_mut()).future_a
  }  

  public fun initial_a_time<LpCoin>(pool: &mut InterestPool<Stable>): u256 {
    load<LpCoin>(pool.state_mut()).initial_a_time
  }    

  public fun future_a_time<LpCoin>(pool: &mut InterestPool<Stable>): u256 {
    load<LpCoin>(pool.state_mut()).future_a_time
  }    

  public fun a<LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
  ): u256 {
    let state = load<LpCoin>(pool.state_mut());
    get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock)
  }

  public fun lp_coin_supply<LpCoin>(pool: &mut InterestPool<Stable>): u64 {
    load<LpCoin>(pool.state_mut()).lp_coin_supply.supply_value()
  }

  public fun lp_coin_decimals_scalar<LpCoin>(pool: &mut InterestPool<Stable>): u256 {
    load<LpCoin>(pool.state_mut()).lp_coin_decimals_scalar
  }  

  public fun n_coins<LpCoin>(pool: &mut InterestPool<Stable>): u64 {
    load<LpCoin>(pool.state_mut()).n_coins
  }

  public fun fees<LpCoin>(pool: &mut InterestPool<Stable>): StableFees {
    load<LpCoin>(pool.state_mut()).fees
  }

  public fun admin_balance<CoinType, LpCoin>(pool: &mut InterestPool<Stable>): u64 {
    load<LpCoin>(pool.state_mut()).admin_balances.borrow<TypeName, Balance<CoinType>>(type_name::get<CoinType>()).value()
  } 

  public fun coin_decimals<CoinType, LpCoin>(pool: &mut InterestPool<Stable>): u8 {
    let (_, decimals) = coin_state_metadata<CoinType, LpCoin>(load(pool.state_mut()));
    (decimals as u8)
  } 

  public fun coin_index<CoinType, LpCoin>(pool: &mut InterestPool<Stable>): u8 {
    let (index, _) = coin_state_metadata<CoinType, LpCoin>(load(pool.state_mut()));
    (index as u8)
  }  

  public fun coin_balance<CoinType, LpCoin>(pool: &mut InterestPool<Stable>): u64 {
    coin_state_balance<CoinType, LpCoin>(load<LpCoin>(pool.state_mut())).value()
  }     
  
  // @dev Price is returned in 1e18
  public fun virtual_price<LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
  ): u256 {
    virtual_price_impl(load<LpCoin>(pool.state_mut()), clock)
  }

  public fun quote_swap<CoinIn, CoinOut, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    amount: u64    
  ): (u64, u64, u64) {
    let state = load<LpCoin>(pool.state_mut());

    let (coin_in_index, coin_in_decimals) = coin_state_metadata<CoinIn, LpCoin>(state);
    let (coin_out_index, coin_out_decimals) = coin_state_metadata<CoinOut, LpCoin>(state);

    let fee_in = stable_fees::calculate_fee_in_amount(&state.fees, amount);

    let normalized_value = ((amount - fee_in).to_u256() * PRECISION) / coin_in_decimals;

    let new_out_balance = y(
      get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock),
      coin_in_index.to_u256(),
      coin_out_index.to_u256(),
      *&state.balances[coin_in_index] + normalized_value,
      state.balances
    );

    let amount_out = *&state.balances[coin_out_index] - new_out_balance;
    let amount_out = (amount_out * coin_out_decimals / PRECISION).to_u64();

    let fee_out = stable_fees::calculate_fee_out_amount(&state.fees, amount_out);

    (amount_out - fee_out, fee_in, fee_out)
  }

  // === Admin Functions ===

  public fun ramp<LpCoin>(pool: &mut InterestPool<Stable>, pool_admin: &PoolAdmin, clock: &Clock, future_a: u256, future_a_time: u256) {
    pool.assert_pool_admin(pool_admin);
    let current_timestamp = clock.timestamp_ms();
    let pool_address = pool.addy();
    let state = load_mut<LpCoin>(pool.state_mut());

    assert!(current_timestamp > state.initial_a_time.to_u64() + MIN_RAMP_TIME, errors::wait_one_day());
    assert!(future_a_time >= (current_timestamp + MIN_RAMP_TIME).to_u256(), errors::future_ramp_time_is_too_short());

    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock); 

    assert!(future_a != 0 && future_a < MAX_A, errors::invalid_amplifier());
    assert!((future_a > amp && amp * MAX_A_CHANGE >= future_a) || (amp > future_a && future_a * MAX_A_CHANGE >= amp), errors::invalid_amplifier());

    state.initial_a = amp;
    state.initial_a_time = current_timestamp.to_u256();
    state.future_a = future_a;
    state.future_a_time = future_a_time;

    events::emit_ramp_a<LpCoin>(pool_address, amp, future_a, future_a_time, current_timestamp);
  }

  public fun stop_ramp<LpCoin>(pool: &mut InterestPool<Stable>, pool_admin: &PoolAdmin, clock: &Clock) {
    pool.assert_pool_admin(pool_admin);
    let current_timestamp = clock.timestamp_ms();

    let pool_address = pool.addy();
    let state = load_mut<LpCoin>(pool.state_mut());

    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock); 

    state.initial_a = amp;
    state.initial_a_time = current_timestamp.to_u256();
    state.future_a = amp;
    state.future_a_time = current_timestamp.to_u256();

    events::emit_stop_ramp_a<LpCoin>(pool_address, amp, current_timestamp);
  }

  public fun update_fee<LpCoin>(
    pool: &mut InterestPool<Stable>,
    pool_admin: &PoolAdmin,
    fee_in_percent: Option<u256>,
    fee_out_percent: Option<u256>, 
    admin_fee_percent: Option<u256>,  
  ) {
    pool.assert_pool_admin(pool_admin);
    let pool_address = pool.addy();
    let state = load_mut<LpCoin>(pool.state_mut());

    stable_fees::update_fee_in_percent(&mut state.fees, fee_in_percent);
    stable_fees::update_fee_out_percent(&mut state.fees, fee_out_percent);  
    stable_fees::update_admin_fee_percent(&mut state.fees, admin_fee_percent);

    events::emit_update_stable_fee<Stable, LpCoin>(
      pool_address, 
      stable_fees::fee_in_percent(&state.fees), 
      stable_fees::fee_out_percent(&state.fees), 
      stable_fees::admin_fee_percent(&state.fees)
    );
  }

  public fun take_fees<CoinType, LpCoin>(
    pool: &mut InterestPool<Stable>,
    pool_admin: &PoolAdmin,
    ctx: &mut TxContext
  ): Coin<CoinType> {
    pool.assert_pool_admin(pool_admin);
    let pool_address = pool.addy();

    let admin_balance = admin_balance_mut<CoinType, LpCoin>(load_mut(pool.state_mut()));
    let amount = admin_balance.value();

    events::emit_take_fees<Stable, CoinType, LpCoin>(pool_address, amount);

    admin_balance.take(amount, ctx)
  }

  // === Public-Package Functions ===

  fun new_state_v1<LpCoin>(
    coin_decimals: &CoinDecimals,  
    initial_a: u256,
    lp_coin_supply: Supply<LpCoin>,
    n_coins: u64,
    ctx: &mut TxContext    
  ): StateV1<LpCoin> {
    assert!(lp_coin_supply.supply_value() == 0, errors::supply_must_have_zero_value());
    assert!(decimals<LpCoin>(coin_decimals) == 9, errors::must_have_9_decimals());

    StateV1 {
        id: object::new(ctx),
        balances: empty_vector(n_coins.to_u256()),
        initial_a,
        future_a: initial_a,
        initial_a_time: 0,
        future_a_time: 0,
        lp_coin_supply,
        lp_coin_decimals_scalar: scalar<LpCoin>(coin_decimals).to_u256(),
        n_coins,
        fees: stable_fees::new(),
        coins: bag::new(ctx),
        admin_balances: bag::new(ctx)
    }  
  }

  public(package) fun new_pool_with_hooks<LpCoin>(
    hooks_builder: HooksBuilder,
    coin_decimals: &CoinDecimals,  
    initial_a: u256,
    lp_coin_supply: Supply<LpCoin>,
    coins: vector<TypeName>,
    ctx: &mut TxContext
  ): (InterestPool<Stable>, PoolAdmin) {
    let state_v1 = new_state_v1(
      coin_decimals,
      initial_a,
      lp_coin_supply,
      coins.length(),
      ctx
    );

    interest_pool::new_with_hooks<Stable>(
      make_coins_vec_set_from_vector(coins),
      versioned::create(STATE_V1_VERSION, state_v1, ctx), 
      hooks_builder,
      ctx
    )
  }

  public(package) fun new_2_pool_impl<CoinA, CoinB, LpCoin>(
    mut pool: InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_decimals: &CoinDecimals,     
    ctx: &mut TxContext
  ): (InterestPool<Stable>, Coin<LpCoin>)  {
    assert!(coin_a.value() != 0 && coin_b.value() != 0, errors::no_zero_liquidity_amounts());

    let state = load_mut<LpCoin>(pool.state_mut());      

    // * IMPORTANT Make sure the indexes and CoinTypes match the make_coins vector and they are in the correct order
    add_coin<CoinA, LpCoin>(state, coin_decimals, 0);
    add_coin<CoinB, LpCoin>(state, coin_decimals, 1);

    let lp_coin = add_liquidity_2_pool_impl(&mut pool, clock, coin_a, coin_b, 0, ctx);

    events::emit_new_2_pool<Stable, CoinA, CoinB, LpCoin>(pool.addy());

    (pool, lp_coin)
  }

  public(package) fun new_3_pool_impl<CoinA, CoinB, CoinC, LpCoin>(
    mut pool: InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_decimals: &CoinDecimals,     
    ctx: &mut TxContext
  ): (InterestPool<Stable>, Coin<LpCoin>) {
    assert!(coin_a.value() != 0 && coin_b.value() != 0 && coin_c.value() != 0, errors::no_zero_liquidity_amounts());

    let state = load_mut<LpCoin>(pool.state_mut());      

    // * IMPORTANT Make sure the indexes and CoinTypes match the make_coins vector and they are in the correct order
    add_coin<CoinA, LpCoin>(state, coin_decimals, 0);
    add_coin<CoinB, LpCoin>(state, coin_decimals, 1);
    add_coin<CoinC, LpCoin>(state, coin_decimals, 2);

    let lp_coin = add_liquidity_3_pool_impl(&mut pool, clock, coin_a, coin_b, coin_c, 0, ctx);

    events::emit_new_3_pool<Stable, CoinA, CoinB, CoinC, LpCoin>(pool.addy());

    (pool, lp_coin)
  }

  public(package) fun new_4_pool_impl<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    mut pool: InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    coin_decimals: &CoinDecimals,      
    ctx: &mut TxContext
  ): (InterestPool<Stable>, Coin<LpCoin>) {
    assert!(
      coin_a.value() != 0 
      && coin_b.value() != 0 
      && coin_c.value() != 0
      && coin_d.value() != 0,
      errors::no_zero_liquidity_amounts()
    );

    let state = load_mut<LpCoin>(pool.state_mut());    

    // * IMPORTANT Make sure the indexes and CoinTypes match the make_coins vector and they are in the correct order
    add_coin<CoinA, LpCoin>(state, coin_decimals, 0);
    add_coin<CoinB, LpCoin>(state, coin_decimals, 1);
    add_coin<CoinC, LpCoin>(state, coin_decimals, 2);
    add_coin<CoinD, LpCoin>(state, coin_decimals, 3);

    let lp_coin = add_liquidity_4_pool_impl(&mut pool, clock, coin_a, coin_b, coin_c, coin_d, 0, ctx);

    events::emit_new_4_pool<Stable, CoinA, CoinB, CoinC, CoinD, LpCoin>(pool.addy());

    (pool, lp_coin)
  }

  public(package) fun new_5_pool_impl<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    mut pool: InterestPool<Stable>,    
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    coin_e: Coin<CoinE>,
    coin_decimals: &CoinDecimals,      
    ctx: &mut TxContext
  ): (InterestPool<Stable>, Coin<LpCoin>) {
    assert!(
      coin_a.value() != 0 
      && coin_b.value() != 0 
      && coin_c.value() != 0
      && coin_d.value() != 0
      && coin_e.value() != 0,
      errors::no_zero_liquidity_amounts()
    );

    let state = load_mut<LpCoin>(pool.state_mut());

    // * IMPORTANT Make sure the indexes and CoinTypes match the make_coins vector and they are in the correct order
    add_coin<CoinA, LpCoin>(state, coin_decimals, 0);
    add_coin<CoinB, LpCoin>(state, coin_decimals, 1);
    add_coin<CoinC, LpCoin>(state, coin_decimals, 2);
    add_coin<CoinD, LpCoin>(state, coin_decimals, 3);
    add_coin<CoinE, LpCoin>(state, coin_decimals, 4);

    let lp_coin = add_liquidity_5_pool_impl(&mut pool, clock, coin_a, coin_b, coin_c, coin_d, coin_e, 0, ctx);

    events::emit_new_5_pool<Stable, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(pool.addy());


    (pool, lp_coin)
  }

  public(package) fun swap_impl<CoinIn, CoinOut, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    mut coin_in: Coin<CoinIn>,
    min_amount: u64,
    ctx: &mut TxContext
  ): Coin<CoinOut> {
    assert!(type_name::get<CoinIn>() != type_name::get<CoinOut>(), errors::cannot_swap_same_coin());
    
    let coin_in_value = coin_in.value();
    assert!(coin_in_value != 0, errors::cannot_swap_zero_value());

    let pool_address = pool.addy();
    let state = load_mut<LpCoin>(pool.state_mut());

    let (coin_in_index, coin_in_decimals) = coin_state_metadata<CoinIn, LpCoin>(state);
    let (coin_out_index, coin_out_decimals) = coin_state_metadata<CoinOut, LpCoin>(state);

    let fee_in = stable_fees::calculate_fee_in_amount(&state.fees, coin_in_value);
    let  admin_fee_in = stable_fees::calculate_admin_amount(&state.fees, fee_in);

    let admin_coin_in = coin_in.split(admin_fee_in, ctx);

    // Has no fees to properly calculate new out balance
    let normalized_value = (coin_in_value - fee_in - admin_fee_in).to_u256() * PRECISION / coin_in_decimals;

    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock);

    let prev_k = invariant_(amp, state.balances);

    let new_out_balance = y(
      amp,
      coin_in_index.to_u256(),
      coin_out_index.to_u256(),
      *&state.balances[coin_in_index] + normalized_value,
      state.balances
    );

    let normalized_amount_out = *&state.balances[coin_out_index] - new_out_balance;
    let amount_out = (normalized_amount_out * coin_out_decimals / PRECISION).to_u64();
    
    let fee_out = stable_fees::calculate_fee_out_amount(&state.fees, amount_out);
    let admin_fee_out = stable_fees::calculate_admin_amount(&state.fees, fee_out);

    let amount_out = amount_out - fee_out - admin_fee_out;

    assert!(amount_out >= min_amount, errors::slippage());

    let coin_in_balance = &mut state.balances[coin_in_index];
    *coin_in_balance = *coin_in_balance + normalized_value + ((fee_in - admin_fee_in).to_u256() * PRECISION / coin_in_decimals);

    let coin_out_balance = &mut state.balances[coin_out_index];
    // We need to remove the admin fee from balance
    *coin_out_balance = *coin_out_balance - (amount_out + admin_fee_out).to_u256() * PRECISION / coin_out_decimals; 

    // * Invariant must hold after all balances updates
    assert!(invariant_(amp, state.balances) >= prev_k, errors::invalid_invariant());

    /*
    * The admin fees are not part of the liquidity (do not accrue swap fees) and not counted on the invariant calculation
    * Fees are applied both on coin in and coin out to keep the balance in the pool
    * 1 - Deposit coin_in (without admin fees) to balance
    * 2 - Deposit coin_admin_in (admin fees on coin)
    * 3 - Deposit coin_admin_out (admin fees on coin out)
    * 4 - Take coin_out for user
    */
    coin_state_balance_mut<CoinIn, LpCoin>(state).join(coin_in.into_balance());
    admin_balance_mut<CoinIn, LpCoin>(state).join(admin_coin_in.into_balance());

    let coin_out_balance = coin_state_balance_mut<CoinOut, LpCoin>(state);

    let admin_balance_in = coin_out_balance.split(admin_fee_out);

    let coin_out = coin_out_balance.take(amount_out, ctx);

    admin_balance_mut<CoinOut, LpCoin>(state).join(admin_balance_in);

    events::emit_swap<Stable, CoinIn, CoinOut, LpCoin>(pool_address, coin_in_value, amount_out);

    coin_out
  }

  public(package) fun add_liquidity_2_pool_impl<CoinA, CoinB, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    assert!(pool.are_coins_ordered(vector[type_name::get<CoinA>(), type_name::get<CoinB>()]), errors::coins_must_be_in_order());

    let pool_address = pool.addy();
    let state = load_mut<LpCoin>(pool.state_mut());

    let prev_invariant = virtual_price_impl(state, clock);
    
    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock);    

    let prev_k = invariant_(amp, state.balances);

    let coin_a_value = deposit_coin<CoinA, LpCoin>(state, coin_a);
    let coin_b_value = deposit_coin<CoinB, LpCoin>(state, coin_b);

    let mint_amount = calculate_mint_amount(state, amp, prev_k, lp_coin_min_amount);

    events::emit_add_liquidity_2_pool<Stable, CoinA, CoinB, LpCoin>(
      pool_address, 
      coin_a_value, 
      coin_b_value, 
      mint_amount
    );

    let lp_coin = state.lp_coin_supply.increase_supply(mint_amount).to_coin(ctx);

    assert!(virtual_price_impl(load<LpCoin>(pool.state_mut()), clock) >= prev_invariant, errors::invalid_invariant());

    lp_coin
  }

  public(package) fun add_liquidity_3_pool_impl<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    assert!(pool.are_coins_ordered(vector[type_name::get<CoinA>(), type_name::get<CoinB>(), type_name::get<CoinC>()]), errors::coins_must_be_in_order());

    let pool_address = pool.addy();
    let state = load_mut<LpCoin>(pool.state_mut());

    let prev_invariant = virtual_price_impl(state, clock);
    
    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock);    

    let prev_k = invariant_(amp, state.balances);

    let coin_a_value = deposit_coin<CoinA, LpCoin>(state, coin_a);
    let coin_b_value = deposit_coin<CoinB, LpCoin>(state, coin_b);
    let coin_c_value = deposit_coin<CoinC, LpCoin>(state, coin_c);

    let mint_amount = calculate_mint_amount(state, amp, prev_k, lp_coin_min_amount);

    events::emit_add_liquidity_3_pool<Stable, CoinA, CoinB, CoinC, LpCoin>(
      pool_address, 
      coin_a_value, 
      coin_b_value, 
      coin_c_value, 
      mint_amount
    );

    let lp_coin = state.lp_coin_supply.increase_supply(mint_amount).to_coin(ctx);

    assert!(virtual_price_impl(load<LpCoin>(pool.state_mut()), clock) >= prev_invariant, errors::invalid_invariant());

    lp_coin
  }

  public(package) fun add_liquidity_4_pool_impl<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    assert!(
      pool.are_coins_ordered(
        vector[type_name::get<CoinA>(), type_name::get<CoinB>(), type_name::get<CoinC>(), type_name::get<CoinD>()]
      ), 
      errors::coins_must_be_in_order()
    );
    
    let pool_address = pool.addy();
    let state = load_mut<LpCoin>(pool.state_mut());
    let prev_invariant = virtual_price_impl(state, clock);
    
    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock);    
    let prev_k = invariant_(amp, state.balances);

    let coin_a_value = deposit_coin<CoinA, LpCoin>(state, coin_a);
    let coin_b_value = deposit_coin<CoinB, LpCoin>(state, coin_b);
    let coin_c_value = deposit_coin<CoinC, LpCoin>(state, coin_c);
    let coin_d_value = deposit_coin<CoinD, LpCoin>(state, coin_d);

    let mint_amount = calculate_mint_amount(state, amp, prev_k, lp_coin_min_amount);

    events::emit_add_liquidity_4_pool<Stable, CoinA, CoinB, CoinC, CoinD, LpCoin>(
      pool_address, 
      coin_a_value, 
      coin_b_value, 
      coin_c_value,
      coin_d_value, 
      mint_amount
    );

    let lp_coin = state.lp_coin_supply.increase_supply(mint_amount).to_coin(ctx);

    assert!(virtual_price_impl(load<LpCoin>(pool.state_mut()), clock) >= prev_invariant, errors::invalid_invariant());

    lp_coin
  }

  public(package) fun add_liquidity_5_pool_impl<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    coin_e: Coin<CoinE>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    assert!(
      pool.are_coins_ordered( 
        vector[type_name::get<CoinA>(), type_name::get<CoinB>(), type_name::get<CoinC>(), type_name::get<CoinD>(), type_name::get<CoinE>()]
      ), 
      errors::coins_must_be_in_order()
    );

    let pool_address = pool.addy();
    let state = load_mut<LpCoin>(pool.state_mut());

    let prev_invariant = virtual_price_impl(state, clock);
    
    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock);    
    let prev_k = invariant_(amp, state.balances);

    let coin_a_value = deposit_coin<CoinA, LpCoin>(state, coin_a);
    let coin_b_value = deposit_coin<CoinB, LpCoin>(state, coin_b);
    let coin_c_value = deposit_coin<CoinC, LpCoin>(state, coin_c);
    let coin_d_value = deposit_coin<CoinD, LpCoin>(state, coin_d);
    let coin_e_value = deposit_coin<CoinE, LpCoin>(state, coin_e);

    let mint_amount = calculate_mint_amount(state, amp, prev_k, lp_coin_min_amount);

    events::emit_add_liquidity_5_pool<Stable, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
      pool_address, 
      coin_a_value, 
      coin_b_value, 
      coin_c_value,
      coin_d_value,
      coin_e_value, 
      mint_amount
    );

    let lp_coin = state.lp_coin_supply.increase_supply(mint_amount).to_coin(ctx);

    assert!(virtual_price_impl(load<LpCoin>(pool.state_mut()), clock) >= prev_invariant, errors::invalid_invariant());

    lp_coin
  }

  public(package) fun remove_one_coin_liquidity_impl<CoinType, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amount: u64,
    ctx: &mut TxContext    
  ): Coin<CoinType> {
    let lp_coin_value = lp_coin.value();
    assert!(lp_coin_value != 0, errors::no_zero_coin());

    let pool_address = pool.addy();
    let state = load_mut<LpCoin>(pool.state_mut());

    let prev_invariant = virtual_price_impl(state, clock);

    let (index, decimals) = coin_state_metadata<CoinType, LpCoin>(state);

    let balances = state.balances;

    let current_coin_balance = &mut state.balances[index]; 
    let initial_coin_balance = *current_coin_balance;
    
    *current_coin_balance = y_lp(
      get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock),
      index.to_u256(),
      balances,
      lp_coin_value.to_u256(),
      state.lp_coin_supply.supply_value().to_u256(),
    ) + 1; // give an edge to the protocol

    let amount_to_take = ((initial_coin_balance - min(initial_coin_balance, *current_coin_balance)) * decimals / PRECISION).to_u64();

    assert!(amount_to_take >= min_amount, errors::slippage());

    state.lp_coin_supply.decrease_supply(lp_coin.into_balance());

    events::emit_remove_liquidity<Stable, CoinType, LpCoin>(pool_address, amount_to_take, lp_coin_value);

    let coin_out = coin_state_balance_mut<CoinType, LpCoin>(state).take(amount_to_take, ctx);

    assert!(virtual_price_impl(load<LpCoin>(pool.state_mut()), clock) >= prev_invariant, errors::invalid_invariant());

    coin_out
  }

  public(package) fun remove_liquidity_2_pool_impl<CoinA, CoinB, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>) {
    assert!(
      pool.are_coins_ordered( 
        vector[type_name::get<CoinA>(), type_name::get<CoinB>()]), 
      errors::coins_must_be_in_order()
    );

    let lp_coin_value = lp_coin.value();
    assert!(lp_coin_value != 0, errors::no_zero_coin());

    let pool_address = pool.addy();
    let state = load_mut<LpCoin>(pool.state_mut());

    let prev_invariant = virtual_price_impl(state, clock);

    let (coin_a, coin_b) = (
      take_coin<CoinA, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinB, LpCoin>(state, lp_coin_value, min_amounts, ctx),
    );

    state.lp_coin_supply.decrease_supply(lp_coin.into_balance());

    events::emit_remove_liquidity_2_pool<Stable, CoinA, CoinB, LpCoin>(
      pool_address, 
      coin_a.value(),
      coin_b.value(),
      lp_coin_value
    );

    assert!(virtual_price_impl(load<LpCoin>(pool.state_mut()), clock) >= prev_invariant, errors::invalid_invariant());

    (coin_a, coin_b)
  }

  public(package) fun remove_liquidity_3_pool_impl<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>, Coin<CoinC>) {
    assert!(
      pool.are_coins_ordered( 
        vector[type_name::get<CoinA>(), type_name::get<CoinB>(), type_name::get<CoinC>()]), 
      errors::coins_must_be_in_order()
    );

    let lp_coin_value = lp_coin.value();
    assert!(lp_coin_value != 0, errors::no_zero_coin());

    let pool_address = pool.addy();
    let state = load_mut<LpCoin>(pool.state_mut());

    let prev_invariant = virtual_price_impl(state, clock);

    let (coin_a, coin_b, coin_c) = (
      take_coin<CoinA, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinB, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinC, LpCoin>(state, lp_coin_value, min_amounts, ctx),
    );

    state.lp_coin_supply.decrease_supply(lp_coin.into_balance());

    events::emit_remove_liquidity_3_pool<Stable, CoinA, CoinB, CoinC, LpCoin>(
      pool_address, 
      coin_a.value(),
      coin_b.value(),
      coin_c.value(),
      lp_coin_value
    );

    assert!(virtual_price_impl(load<LpCoin>(pool.state_mut()), clock) >= prev_invariant, errors::invalid_invariant());

    (coin_a, coin_b, coin_c)
  }

  public(package) fun remove_liquidity_4_pool_impl<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>, Coin<CoinC>, Coin<CoinD>) {
    assert!(
      pool.are_coins_ordered( 
        vector[type_name::get<CoinA>(), type_name::get<CoinB>(), type_name::get<CoinC>(), type_name::get<CoinD>()]), 
      errors::coins_must_be_in_order()
    );

    let lp_coin_value = lp_coin.value();
    assert!(lp_coin_value != 0, errors::no_zero_coin());

    let pool_address = pool.addy();
    let state = load_mut<LpCoin>(pool.state_mut()); 

    let prev_invariant = virtual_price_impl(state, clock);

    let (coin_a, coin_b, coin_c, coin_d) = (
      take_coin<CoinA, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinB, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinC, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinD, LpCoin>(state, lp_coin_value, min_amounts, ctx),
    );

    state.lp_coin_supply.decrease_supply(lp_coin.into_balance());

    events::emit_remove_liquidity_4_pool<Stable, CoinA, CoinB, CoinC, CoinD, LpCoin>(
      pool_address, 
      coin_a.value(),
      coin_b.value(),
      coin_c.value(),
      coin_d.value(),
      lp_coin_value
    );

    assert!(virtual_price_impl(load<LpCoin>(pool.state_mut()), clock) >= prev_invariant, errors::invalid_invariant());

    (coin_a, coin_b, coin_c, coin_d)
  }

  public(package) fun remove_liquidity_5_pool_impl<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>, Coin<CoinC>, Coin<CoinD>, Coin<CoinE>) {
    assert!(
      pool.are_coins_ordered( 
        vector[type_name::get<CoinA>(), type_name::get<CoinB>(), type_name::get<CoinC>(), type_name::get<CoinD>(), type_name::get<CoinE>()]), 
      errors::coins_must_be_in_order()
    );

    let lp_coin_value = lp_coin.value();
    assert!(lp_coin_value != 0, errors::no_zero_coin());

    let pool_address = pool.addy();
    let state = load_mut<LpCoin>(pool.state_mut());

    let prev_invariant = virtual_price_impl(state, clock);

    let (coin_a, coin_b, coin_c, coin_d, coin_e) = (
      take_coin<CoinA, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinB, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinC, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinD, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinE, LpCoin>(state, lp_coin_value, min_amounts, ctx),
    );

    state.lp_coin_supply.decrease_supply(lp_coin.into_balance());

    events::emit_remove_liquidity_5_pool<Stable, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
      pool_address, 
      coin_a.value(),
      coin_b.value(),
      coin_c.value(),
      coin_d.value(),
      coin_e.value(),
      lp_coin_value
    );

    assert!(virtual_price_impl(load<LpCoin>(pool.state_mut()), clock) >= prev_invariant, errors::invalid_invariant());    

    (coin_a, coin_b, coin_c, coin_d, coin_e)
  }

  // === Private Functions ===

  fun new_pool<LpCoin>(
    coin_decimals: &CoinDecimals,  
    initial_a: u256,
    lp_coin_supply: Supply<LpCoin>,
    coins: vector<TypeName>,
    ctx: &mut TxContext
  ): (InterestPool<Stable>, PoolAdmin) {
    let state_v1 = new_state_v1(
      coin_decimals,
      initial_a,
      lp_coin_supply,
      coins.length(),
      ctx
    );

    interest_pool::new<Stable>(
      make_coins_vec_set_from_vector(coins),
      versioned::create(STATE_V1_VERSION, state_v1, ctx), 
      ctx
    )
  }

  fun calculate_mint_amount<LpCoin>(state: &StateV1<LpCoin>, amp: u256, prev_k: u256, lp_coin_min_amount: u64): u64 {
    let new_k = invariant_(amp, state.balances);

    assert!(new_k > prev_k, errors::invalid_invariant());

    let supply_value = state.lp_coin_supply.supply_value().to_u256();

    let mint_amount = if (supply_value == 0) (new_k / 1_000_000_000).to_u64() else (supply_value * (new_k - prev_k) / prev_k).to_u64();

    assert!(mint_amount >= lp_coin_min_amount, errors::slippage());

    mint_amount
  }

  fun deposit_coin<CoinType, LpCoin>(state: &mut StateV1<LpCoin>, coin_in: Coin<CoinType>): u64 {
    let coin_value = coin_in.value().to_u256();

    if (coin_value == 0) {
      coin_in.destroy_zero();
      return 0
    };

    let (index, decimals) = coin_state_metadata<CoinType, LpCoin>(state);

    // Update the balance for the coin
    let current_balance = &mut state.balances[index];
    *current_balance = *current_balance + (coin_value * PRECISION / decimals);

    coin_state_balance_mut<CoinType, LpCoin>(state).join(coin_in.into_balance())
  }

  fun take_coin<CoinType, LpCoin>(
    state: &mut StateV1<LpCoin>, 
    lp_coin_value: u64, 
    min_amounts: vector<u64>, 
    ctx: &mut TxContext
  ): Coin<CoinType> {
    let (index, decimals) = coin_state_metadata<CoinType, LpCoin>(state);    

    let current_balance = &mut state.balances[index];

    let denormalized_value = *current_balance * decimals / PRECISION;

    let balance_to_remove = denormalized_value * lp_coin_value.to_u256() / state.lp_coin_supply.supply_value().to_u256();

    assert!(balance_to_remove.to_u64() >= *&min_amounts[index], errors::slippage());

    *current_balance = *current_balance - (balance_to_remove * PRECISION / decimals);

    coin_state_balance_mut<CoinType, LpCoin>(state).take(balance_to_remove.to_u64(), ctx)
  }

  fun add_coin<CoinType, LpCoin>(state: &mut StateV1<LpCoin>, coin_decimals: &CoinDecimals, index: u64) {
    let coin_name = type_name::get<CoinType>();

    bag::add(&mut state.admin_balances, coin_name, balance::zero<CoinType>());
    bag::add(&mut state.coins, coin_name, CoinState {
      decimals: scalar<CoinType>(coin_decimals).to_u256(),
      balance: balance::zero<CoinType>(),
      index
    });
  }

  fun virtual_price_impl<LpCoin>(state: &StateV1<LpCoin>, clock: &Clock): u256 {
    let supply = state.lp_coin_supply.supply_value().to_u256();

    if (supply == 0) return 0;

    let k = invariant_(
      get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock), 
      state.balances
    );

    k * state.lp_coin_decimals_scalar / supply
  }

  fun load<LpCoin>(versioned: &mut Versioned): &StateV1<LpCoin> {
    maybe_upgrade_state_to_latest(versioned);
    versioned.load_value()
  }

  fun load_mut<LpCoin>(versioned: &mut Versioned): &mut StateV1<LpCoin> {
    maybe_upgrade_state_to_latest(versioned);
    versioned.load_value_mut()
  }

  fun maybe_upgrade_state_to_latest(versioned: &mut Versioned) {
    // * IMPORTANT: When new versions are added, we need to explicitly upgrade here.
    assert!(versioned.version() == STATE_V1_VERSION, errors::invalid_version());
  }  

  fun coin_state_balance<CoinType, LpCoin>(state: &StateV1<LpCoin>): &Balance<CoinType> {
    &state.coins.borrow<TypeName, CoinState<CoinType>>(type_name::get<CoinType>()).balance
  }  

  fun coin_state_balance_mut<CoinType, LpCoin>(state: &mut StateV1<LpCoin>): &mut Balance<CoinType> {
    &mut state.coins.borrow_mut<TypeName, CoinState<CoinType>>(type_name::get<CoinType>()).balance
  }

  fun coin_state_metadata<CoinType, LpCoin>(state: &StateV1<LpCoin>): (u64, u256) {
    let coin_state = state.coins.borrow<TypeName, CoinState<CoinType>>(type_name::get<CoinType>());
    (coin_state.index, coin_state.decimals)
  }

  fun admin_balance_mut<CoinType, LpCoin>(state: &mut StateV1<LpCoin>): &mut Balance<CoinType> {
    state.admin_balances.borrow_mut(type_name::get<CoinType>())
  } 
}