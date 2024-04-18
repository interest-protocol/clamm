// CurveV2 in Move - All logic from Curve
// It is best to for the first coin to be a stable coin or Sui as all Coins are quoted from it
// https://etherscan.io/address/0xd51a44d3fae010294c616388b506acda1bfaae46#code
module clamm::interest_clamm_volatile {
  // === Imports ===

  use std::type_name::{Self, TypeName};

  use sui::clock::Clock;
  use sui::bag::{Self, Bag};
  use sui::coin::{Self, Coin};
  use sui::table::{Self, Table};
  use sui::vec_map::{Self, VecMap};
  use sui::versioned::{Self, Versioned};
  use sui::balance::{Self, Supply, Balance};
  
  use suitears::math256::{Self, min, sum, diff, mul_div_up};
  use suitears::coin_decimals::{scalar, decimals, CoinDecimals};
  use suitears::fixed_point_wad::{mul_down, div_down, div_up, mul_up};

  use clamm::utils;
  use clamm::errors;
  use clamm::volatile_math;
  use clamm::curves::Volatile;
  use clamm::pool_events as events;
  use clamm::pool_admin::PoolAdmin;
  use clamm::interest_pool::{Self, HooksBuilder, InterestPool};
  use clamm::utils::{
    empty_vector,
    vector_2_to_tuple,
    vector_3_to_tuple,
    make_coins_vec_set_from_vector,
  };

  use fun coin::take as Balance.take;
  use fun utils::head as vector.head;
  use fun utils::to_u64 as u256.to_u64;
  use fun utils::to_u256 as u64.to_u256;
  use fun coin::from_balance as Balance.to_coin;  

  // === Constants ===

  const STATE_V1_VERSION: u64 = 1;
  const ROLL: u256 = 1_000_000_000; // 1e9 - LpCoins have 9 decimals 
  const MIN_FEE: u256 = 5 * 100_000;
  const MAX_FEE: u256 = 10 * 1_000_000_000;
  const ONE_WEEK: u256 = 7 * 86400000; // 1 week in milliseconds
  const INF_COINS: u64 = 15;
  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18
  const ADMIN_FEE: u256 = 2 * 1_000_000_000; // 20%
  const NOISE_FEE: u256 = 100_000;
  const MIN_GAMMA: u256 = 10_000_000_000;
  const MAX_GAMMA: u256 = 10_000_000_000_000_000;
  const MAX_A_CHANGE: u256 = 10;
  const MIN_RAMP_TIME: u64 = 86400000; // 1 day in milliseconds
  const MAX_ADMIN_FEE: u256 = 10000000000;
  const MAX_U256: u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

  // === Structs ===

  public struct CoinState has store, copy, drop {
    index: u64,
    price: u256, // 1e18
    price_oracle: u256, // 1e18
    last_price: u256, // 1e18
    decimals_scalar: u256,
    type_name: TypeName
  }

  public struct AGamma has store, copy {
    a: u256,
    gamma: u256,
    future_a: u256,
    future_gamma: u256,
    initial_time: u64,
    future_time: u64
  }

  public struct RebalancingParams has store, copy {
    extra_profit: u256,
    adjustment_step: u256,
    ma_half_time: u256,
  }

  public struct Fees has store, copy {
    mid_fee: u256,
    out_fee: u256,
    gamma_fee: u256,
    admin_fee: u256,
  }

  public struct StateV1<phantom LpCoin> has key, store {
    id: UID,
    d: u256, // invariant
    lp_coin_supply: Supply<LpCoin>,
    n_coins: u256,
    balances: vector<u256>,
    a_gamma: AGamma,
    xcp_profit: u256,
    xcp_profit_a: u256,
    virtual_price: u256,
    rebalancing_params: RebalancingParams,
    fees: Fees,
    last_prices_timestamp: u64,
    min_a: u256,
    max_a: u256,
    not_adjusted: bool,
    version: u256,
    coin_states: Table<TypeName, CoinState>,
    coin_balances: Bag,
    admin_balance: Balance<LpCoin>
  }

  public struct BalancesRequest {
    coins: VecMap<TypeName, u256>,
    state_id: address,
    version: u256
  }

  // === Public-Mutative Functions ===

  public fun new_2_pool<CoinA, CoinB, LpCoin>(
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_decimals: &CoinDecimals,     
    lp_coin_supply: Supply<LpCoin>,
    initial_a_gamma: vector<u256>,
    rebalancing_params: vector<u256>,
    price: u256, // @ on a pool with 2 coins, we only need 1 price
    fee_params: vector<u256>, 
    ctx: &mut TxContext
  ): (InterestPool<Volatile>, PoolAdmin, Coin<LpCoin>) {
    let (mut pool, pool_admin) = new_pool<LpCoin>(
      clock,
      vector[type_name::get<CoinA>(), type_name::get<CoinB>()],
      coin_decimals,
      lp_coin_supply,
      vector[0, 0],
      initial_a_gamma,
      rebalancing_params,
      fee_params,
      ctx
    );

    let lp_coin = register_2_pool(
      &mut pool,
      clock,
      coin_a,
      coin_b,
      coin_decimals,
      price,
      ctx
    );

    events::emit_new_2_pool<Volatile, CoinA, CoinB, LpCoin>(pool.addy());

    (pool, pool_admin, lp_coin)
  }

  public fun new_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_decimals: &CoinDecimals,     
    lp_coin_supply: Supply<LpCoin>,
    initial_a_gamma: vector<u256>,
    rebalancing_params: vector<u256>,
    prices: vector<u256>, // @ on a pool with 3 coins, we only need 2 prices
    fee_params: vector<u256>, 
    ctx: &mut TxContext
  ): (InterestPool<Volatile>, PoolAdmin, Coin<LpCoin>) {
    let (mut pool, pool_admin) = new_pool<LpCoin>(
      clock,
      vector[type_name::get<CoinA>(), type_name::get<CoinB>(), type_name::get<CoinC>()],
      coin_decimals,
      lp_coin_supply,
      vector[0, 0, 0],
      initial_a_gamma,
      rebalancing_params,
      fee_params,
      ctx
    );

    let lp_coin = register_3_pool(
      &mut pool,
      clock,
      coin_a,
      coin_b,
      coin_c,
      coin_decimals,
      prices,
      ctx
    );    

    events::emit_new_3_pool<Volatile, CoinA, CoinB, CoinC, LpCoin>(pool.addy());

    (pool, pool_admin, lp_coin)
  }

  public fun swap<CoinIn, CoinOut, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    clock: &Clock,
    coin_in: Coin<CoinIn>,
    mint_amount: u64,
    ctx: &mut TxContext
  ): Coin<CoinOut> {
    assert!(!pool.has_swap_hook(), errors::this_pool_has_hooks());
    swap_impl<CoinIn, CoinOut, LpCoin>(pool, clock, coin_in, mint_amount, ctx)
  }

  public fun add_liquidity_2_pool<CoinA, CoinB, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext      
  ): Coin<LpCoin> {
    assert!(!pool.has_add_liquidity_hook(), errors::this_pool_has_hooks());
    add_liquidity_2_pool_impl(pool, clock, coin_a, coin_b, lp_coin_min_amount, ctx)
  }

  public fun add_liquidity_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext      
  ): Coin<LpCoin> {
    assert!(!pool.has_add_liquidity_hook(), errors::this_pool_has_hooks());
    add_liquidity_3_pool_impl(pool, clock, coin_a, coin_b, coin_c, lp_coin_min_amount, ctx)
  }

  public fun remove_liquidity_2_pool<CoinA, CoinB, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>) {
    assert!(!pool.has_remove_liquidity_hook(), errors::this_pool_has_hooks());
    remove_liquidity_2_pool_impl(pool, lp_coin, min_amounts, ctx)
  }

  public fun remove_liquidity_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>, Coin<CoinC>) {
    assert!(!pool.has_remove_liquidity_hook(), errors::this_pool_has_hooks());
    remove_liquidity_3_pool_impl(pool, lp_coin, min_amounts, ctx)
  }

  public fun remove_liquidity_one_coin<CoinOut, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amount: u64,
    ctx: &mut TxContext    
  ): Coin<CoinOut> {
    assert!(!pool.has_remove_liquidity_hook(), errors::this_pool_has_hooks());
    remove_liquidity_one_coin_impl(pool, clock, lp_coin, min_amount, ctx)
  }

  public fun balances_request<LpCoin>(pool: &mut InterestPool<Volatile>): BalancesRequest {
    let state = load<LpCoin>(pool.state_mut());
    let state_id = object::id_address(state);
    BalancesRequest {
      state_id,
      coins: vec_map::empty(),
      version: state.version
    }
  }

  public fun read_balance<LpCoin, CoinType>(pool: &mut InterestPool<Volatile>, request: &mut BalancesRequest) {
    let state = load<LpCoin>(pool.state_mut()); 
    let state_id = object::id_address(state);

    assert!(state_id == request.state_id, errors::wrong_pool_id());
    assert!(state.version == request.version, errors::version_was_updated());

    let coin_balance = coin_balance_impl<CoinType, LpCoin>(state);  
    let balance_val = coin_balance.value();
    let coin_state = coin_state<CoinType, LpCoin>(state);
    request.coins.insert(coin_state.type_name, div_down(balance_val.to_u256(), coin_state.decimals_scalar));
  }

  // === Public-View Functions ===

  public fun invariant_<LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    load<LpCoin>(pool.state_mut()).d
  }  

  public fun a<LpCoin>(pool: &mut InterestPool<Volatile>, clock: &Clock): u256 {
    let (a, _) = get_a_gamma(load<LpCoin>(pool.state_mut()), clock);
    a
  }

  public fun future_a<LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    load<LpCoin>(pool.state_mut()).a_gamma.future_a
  }  

  public fun min_a<LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    load<LpCoin>(pool.state_mut()).min_a
  }   

  public fun max_a<LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    load<LpCoin>(pool.state_mut()).max_a
  }   

  public fun initial_time<LpCoin>(pool: &mut InterestPool<Volatile>): u64 {
    load<LpCoin>(pool.state_mut()).a_gamma.initial_time
  }  

  public fun future_time<LpCoin>(pool: &mut InterestPool<Volatile>): u64 {
    load<LpCoin>(pool.state_mut()).a_gamma.future_time
  }    

  public fun gamma<LpCoin>(pool: &mut InterestPool<Volatile>, clock: &Clock): u256 {
    let state = load<LpCoin>(pool.state_mut());
    let (_, gamma) = get_a_gamma(state, clock);
    gamma
  }  

  public fun future_gamma<LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    load<LpCoin>(pool.state_mut()).a_gamma.future_gamma
  }    

  public fun lp_coin_supply<LpCoin>(pool: &mut InterestPool<Volatile>): u64 {
    let state = load<LpCoin>(pool.state_mut());  
    state.lp_coin_supply.supply_value()
  }

  public fun n_coins<LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    let state = load<LpCoin>(pool.state_mut());  
    state.n_coins
  }

  public fun balances<LpCoin>(pool: &mut InterestPool<Volatile>): vector<u256> {
    let state = load<LpCoin>(pool.state_mut());  
    state.balances
  }  

  public fun xcp_profit<LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    let state = load<LpCoin>(pool.state_mut());  
    state.xcp_profit
  }  

  public fun xcp_profit_a<LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    let state = load<LpCoin>(pool.state_mut());  
    state.xcp_profit_a
  }  

  public fun virtual_price<LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    let state = load<LpCoin>(pool.state_mut());  
    state.virtual_price
  }    

  public fun adjustment_step<LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    let state = load<LpCoin>(pool.state_mut());  
    state.rebalancing_params.adjustment_step
  }     

  public fun extra_profit<LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    let state = load<LpCoin>(pool.state_mut());  
    state.rebalancing_params.extra_profit
  }      

  public fun ma_half_time<LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    let state = load<LpCoin>(pool.state_mut());  
    state.rebalancing_params.ma_half_time
  } 

  public fun last_prices_timestamp<LpCoin>(pool: &mut InterestPool<Volatile>): u64 {
    let state = load<LpCoin>(pool.state_mut());  
    state.last_prices_timestamp
  } 

  public fun not_adjusted<LpCoin>(pool: &mut InterestPool<Volatile>): bool {
    let state = load<LpCoin>(pool.state_mut());  
    state.not_adjusted
  }  

  public fun admin_fee<LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    let state = load<LpCoin>(pool.state_mut());  
    state.fees.admin_fee
  } 

  public fun gamma_fee<LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    let state = load<LpCoin>(pool.state_mut());  
    state.fees.gamma_fee
  } 

  public fun mid_fee<LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    let state = load<LpCoin>(pool.state_mut());  
    state.fees.mid_fee
  }   

  public fun out_fee<LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    let state = load<LpCoin>(pool.state_mut());  
    state.fees.out_fee
  }  

  public fun coin_price<CoinType, LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    let state = load<LpCoin>(pool.state_mut());  
    coin_state<CoinType, LpCoin>(state).price
  }

  public fun coin_last_price<CoinType, LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    let state = load<LpCoin>(pool.state_mut());  
    coin_state<CoinType, LpCoin>(state).last_price
  }  

  public fun coin_index<CoinType, LpCoin>(pool: &mut InterestPool<Volatile>): u64 {
    let state = load<LpCoin>(pool.state_mut());  
    coin_state<CoinType, LpCoin>(state).index
  }  

  public fun coin_price_oracle<CoinType, LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    let state = load<LpCoin>(pool.state_mut());  
    coin_state<CoinType, LpCoin>(state).price_oracle
  }  

  public fun coin_decimals_scalar<CoinType, LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    let state = load<LpCoin>(pool.state_mut());  
    coin_state<CoinType, LpCoin>(state).decimals_scalar
  }  

  public fun coin_type<CoinType, LpCoin>(pool: &mut InterestPool<Volatile>): TypeName {
    let state = load<LpCoin>(pool.state_mut());  
    coin_state<CoinType, LpCoin>(state).type_name
  }  

  public fun coin_balance<LpCoin, CoinType>(pool: &mut InterestPool<Volatile>): u64 {
    let state = load<LpCoin>(pool.state_mut()); 
    coin_balance_impl<CoinType, LpCoin>(state).value()
  }          

  public fun balances_in_price<LpCoin>(pool: &mut InterestPool<Volatile>): vector<u256> {
    let (state, coin_states) = state_and_coin_states<LpCoin>(pool);
    balances_in_price_impl(state, coin_states)
  }

  public fun fee<LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    let balances_in_price = balances_in_price<LpCoin>(pool);
    let state = load<LpCoin>(pool.state_mut());
    fee_impl<LpCoin>(state, balances_in_price)
  }

  public fun lp_coin_price<LpCoin>(pool: &mut InterestPool<Volatile>): u256 {
    let (state, coin_states) = state_and_coin_states<LpCoin>(pool);
    let supply = state.lp_coin_supply.supply_value();
    ROLL * xcp_impl(state, coin_states, state.d) / supply.to_u256()
  }

  public fun quote_swap<CoinIn, CoinOut, LpCoin>(pool: &mut InterestPool<Volatile>, clock: &Clock, amount: u64): u64 {
    if (amount == 0) return 0;
    let (state, coin_states) = state_and_coin_states<LpCoin>(pool);
    let coin_in_state = coin_state<CoinIn, LpCoin>(state);
    let coin_out_state = coin_state<CoinOut, LpCoin>(state);
    let (a, gamma) = get_a_gamma(state, clock);

    let mut balances_price = vector<u256>[];

    {
      let mut index = 0;
      let n_coins = state.n_coins.to_u64();
    
      while(n_coins > index) {
        let mut bal = *&state.balances[index];
        let coin_state = coin_states[index];

        bal = if (index == coin_in_state.index) bal + div_down(amount.to_u256(), coin_in_state.decimals_scalar) else bal;
        balances_price.push_back(if (index == 0) bal else mul_down(bal, coin_state.price));

        index = index + 1;
      };
   };

   let y = volatile_math::y(a, gamma, &balances_price, state.d, coin_out_state.index) + 1;
   let current_out_balance = *&balances_price[coin_out_state.index];

   let mut coin_out_amount = current_out_balance - min(current_out_balance, y);

   let out_balance_price_mut = &mut balances_price[coin_out_state.index];
   *out_balance_price_mut = *out_balance_price_mut - coin_out_amount;

   if (coin_out_state.index != 0) coin_out_amount = div_down(coin_out_amount, coin_out_state.price);

   coin_out_amount = coin_out_amount - fee_impl(state, balances_price) * coin_out_amount / 10000000000;

   mul_down(coin_out_amount, coin_out_state.decimals_scalar).to_u64()
  }   

  public fun quote_add_liquidity<LpCoin>(pool: &mut InterestPool<Volatile>, clock: &Clock, amounts: vector<u64>): u64 {
    let (state, coin_states) = state_and_coin_states<LpCoin>(pool);

    let supply = state.lp_coin_supply.supply_value().to_u256() * ROLL;

    let mut balances = state.balances;
    let (a, gamma) = get_a_gamma(state, clock);
    let mut amounts_p = empty_vector(state.n_coins);

    let old_balances_price = balances_in_price_impl(state, coin_states);

    let old_d = if (state.a_gamma.future_time != 0) {
      volatile_math::invariant_(a, gamma, old_balances_price)
    } else  state.d;

    let mut balances_price = vector<u256>[];
    {
      let mut index = 0;
      let n_coins = state.n_coins.to_u64();
    
      while(n_coins > index) {
        let ref = &mut balances[index];
        let coin_state = &coin_states[index];
        let amount = div_down(*&amounts[index].to_u256(), coin_state.decimals_scalar);
        
        *ref = *ref + amount;

        let b_price = if (index == 0) *ref else mul_down(*ref, coin_state.price);

        balances_price.push_back(b_price);

        let b_price_old = *&old_balances_price[index];

        let diff = b_price - b_price_old;
        if (diff != 0) {
          let ref = &mut amounts_p[index];
          *ref = diff;
        };

        index = index + 1;
      };
   };

    let (a, gamma) = get_a_gamma(state, clock);
    let d = volatile_math::invariant_(a, gamma, balances_price);

    let mut d_token = if (old_d != 0)
      supply * d / old_d - supply
    else 
      xcp_impl(state, coin_states, d);

    // Remove decimals, otherwise, the first initial supply will be inconsistent.
    d_token = (d_token / ROLL) * ROLL; 
    
    d_token = d_token - mul_div_up(calculate_fee(state, amounts_p, balances_price), d_token, 10000000000);

    (d_token / ROLL).to_u64() 
  }

  public fun quote_remove_liquidity<LpCoin>(
    pool: &mut InterestPool<Volatile>,
    lp_coin_amount: u64  
  ): vector<u64> {
    let (state, coin_states) = state_and_coin_states<LpCoin>(pool);

    let supply = state.lp_coin_supply.supply_value().to_u256();

    let n_coins = state.n_coins.to_u64();
    let mut index = 0;

    let mut amounts = vector[];

    while(n_coins > index) {
      let d_balance = (lp_coin_amount - 1).to_u256() * *&state.balances[index] / supply;
      let coin_state = *&coin_states[index];
      amounts.push_back(mul_down(d_balance, coin_state.decimals_scalar).to_u64());

      index = index + 1;
    };

    amounts
  }

  public fun quote_remove_liquidity_one_coin<CoinOut, LpCoin>(pool: &mut InterestPool<Volatile>, clock:&Clock, lp_amount: u64): u64 {
    let (state, coin_states) = state_and_coin_states<LpCoin>(pool);
    let (a, gamma) = get_a_gamma(state, clock);
    let (amount_out, _, _, _, index_out) = calculate_remove_one_coin_impl<CoinOut, LpCoin>(
      state,
      a,
      gamma,
      coin_states,
      lp_amount.to_u256() * ROLL,
      true,
      false
    );

    mul_down(amount_out, *&coin_states[index_out].decimals_scalar).to_u64()
  }  

  // === Admin Functions ===

  public fun claim_admin_fees<LpCoin>(
    pool: &mut InterestPool<Volatile>, 
    pool_admin: &PoolAdmin, 
    clock: &Clock,
    request: BalancesRequest,
    ctx: &mut TxContext
  ): Coin<LpCoin> {
    pool.assert_pool_admin(pool_admin);
    let (state, coin_states) = state_and_coin_states_mut<LpCoin>(pool);

    claim_admin_fees_impl(state, clock, request, coin_states);
    
    increment_version(state);

    let value = state.admin_balance.value();

    events::emit_claim_admin_fees<LpCoin>(value);

    state.admin_balance.take(value, ctx)
  }

  public fun ramp<LpCoin>(
    pool: &mut InterestPool<Volatile>,
    pool_admin: &PoolAdmin, 
    clock: &Clock, 
    future_a: u256, 
    future_gamma: u256, 
    future_time: u64
  ) {
    pool.assert_pool_admin(pool_admin);
    let timestamp = clock.timestamp_ms();
    let pool_id = pool.addy();

    let state = load_mut<LpCoin>(pool.state_mut());
    assert!(timestamp >= state.a_gamma.initial_time + MIN_RAMP_TIME, errors::wait_one_day());
    assert!(future_time >= timestamp + MIN_RAMP_TIME, errors::future_ramp_time_is_too_short());

    let (a, gamma) = get_a_gamma(state, clock);

    assert!(future_a >= state.min_a, errors::future_a_is_too_small());
    assert!(state.max_a >= future_a, errors::future_gamma_is_too_big());
    assert!(future_gamma >= MIN_GAMMA, errors::future_gamma_is_too_small());
    assert!(MAX_GAMMA >= future_gamma, errors::future_gamma_is_too_big());

    let mut ratio = div_down(future_a, a);
    assert!(MAX_A_CHANGE * PRECISION >= ratio, errors::future_a_change_is_too_big());
    assert!(ratio >= PRECISION / MAX_A_CHANGE, errors::future_a_change_is_too_small());

    ratio = div_down(future_gamma, gamma);
    assert!(MAX_A_CHANGE * PRECISION >= ratio, errors::future_gamma_change_is_too_big());
    assert!(ratio >= PRECISION / MAX_A_CHANGE, errors::future_gamma_change_is_too_small());

    state.a_gamma.a = a;
    state.a_gamma.gamma = gamma;
    state.a_gamma.initial_time = timestamp;

    state.a_gamma.future_a = future_a;
    state.a_gamma.future_gamma = future_gamma;
    state.a_gamma.future_time = future_time;

    increment_version(state);

    events::emit_ramp_a_gamma<LpCoin>(pool_id, a, gamma, timestamp, future_a, future_gamma, future_time);
  }

  public fun stop_ramp<LpCoin>(
    pool: &mut InterestPool<Volatile>,
    pool_admin: &PoolAdmin, 
    clock:&Clock, 
  ) {
    pool.assert_pool_admin(pool_admin);
    let timestamp = clock.timestamp_ms();
    let pool_id = pool.addy();

    let state = load_mut<LpCoin>(pool.state_mut());
    let (a, gamma) = get_a_gamma(state, clock);

    state.a_gamma.a = a;
    state.a_gamma.gamma = gamma;
    state.a_gamma.future_a = a;
    state.a_gamma.future_gamma = gamma;
    state.a_gamma.initial_time = timestamp;
    state.a_gamma.future_time = timestamp;

    increment_version(state);

    events::emit_stop_ramp_a_gamma<LpCoin>(pool_id, a, gamma, timestamp);
  }

  public fun update_parameters<LpCoin>(
    pool: &mut InterestPool<Volatile>,
    pool_admin: &PoolAdmin, 
    clock: &Clock,
    request: BalancesRequest,
    values: vector<Option<u256>>
  ) {
    pool.assert_pool_admin(pool_admin);
    let pool_id = pool.addy();
    let (state, coin_states) = state_and_coin_states_mut<LpCoin>(pool);

    claim_admin_fees_impl(state, clock, request, coin_states);

    let mid_fee = option::destroy_with_default(values.head(), state.fees.mid_fee);
    let out_fee = option::destroy_with_default(*&values[1], state.fees.out_fee);
    let admin_fee = option::destroy_with_default(*&values[2], state.fees.admin_fee); 
    let gamma_fee = option::destroy_with_default(*&values[3], state.fees.gamma_fee);  
    let allowed_extra_profit = option::destroy_with_default(*&values[4], state.rebalancing_params.extra_profit);
    let adjustment_step = option::destroy_with_default(*&values[5], state.rebalancing_params.adjustment_step);
    let ma_half_time = option::destroy_with_default(*&values[6], state.rebalancing_params.ma_half_time); 

    assert!(MAX_FEE >= out_fee && out_fee >= MIN_FEE, errors::out_fee_out_of_range());
    assert!(MAX_FEE >= mid_fee && MIN_FEE >= MIN_FEE, errors::mid_fee_out_of_range());
    assert!(MAX_ADMIN_FEE > admin_fee, errors::admin_fee_is_too_big());
    assert!(gamma_fee != 0 && PRECISION >= gamma_fee, errors::gamma_fee_out_of_range());
    assert!(PRECISION > allowed_extra_profit, errors::extra_profit_is_too_big());
    assert!(PRECISION > adjustment_step, errors::adjustment_step_is_too_big());
    assert!(ma_half_time >= 1000 && ONE_WEEK >= ma_half_time, errors::ma_half_time_out_of_range());

    state.fees.admin_fee = admin_fee;
    state.fees.out_fee = out_fee;
    state.fees.mid_fee= mid_fee;
    state.fees.gamma_fee = gamma_fee;
    state.rebalancing_params.extra_profit = allowed_extra_profit;
    state.rebalancing_params.adjustment_step = adjustment_step;
    state.rebalancing_params.ma_half_time = ma_half_time;

    increment_version(state);

    events::emit_update_parameters<LpCoin>(pool_id, admin_fee, out_fee, mid_fee, gamma_fee, allowed_extra_profit, adjustment_step, ma_half_time);
  }

  // === Public-Package Functions ===

  public(package) fun new_pool_with_hooks<LpCoin>(
    clock: &Clock,
    hooks_builder: HooksBuilder,
    coins: vector<TypeName>,
    coin_decimals: &CoinDecimals,   
    lp_coin_supply: Supply<LpCoin>,
    balances: vector<u256>,
    initial_a_gamma: vector<u256>,
    rebalancing_params: vector<u256>,
    fee_params: vector<u256>, 
    ctx: &mut TxContext
  ): (InterestPool<Volatile>, PoolAdmin) {
    let state_v1 = new_state_v1(
      clock,
      coin_decimals,
      lp_coin_supply,
      balances,
      initial_a_gamma,
      rebalancing_params,
      fee_params,
      ctx
    );

    interest_pool::new_with_hooks<Volatile>(
      make_coins_vec_set_from_vector(coins),
      versioned::create(STATE_V1_VERSION, state_v1, ctx), 
      hooks_builder,
      ctx
    )
  }

  public(package) fun register_2_pool<CoinA, CoinB, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_decimals: &CoinDecimals,
    price: u256,
    ctx: &mut TxContext        
  ): Coin<LpCoin> {
    assert!(
      coin_a.value() != 0 
      && coin_b.value() != 0,
      errors::no_zero_liquidity_amounts()
    );

    let state = load_mut<LpCoin>(pool.state_mut());

    // @dev This is the quote coin in the pool 
    // So we do not need to pass a price
    register_coin<CoinA, LpCoin>(
      state, 
      coin_decimals,
      PRECISION, // * First coin price is always 1. The other coins are priced in this coin. So we put Zero.
      0
    );

    register_coin<CoinB, LpCoin>(
      state, 
      coin_decimals,
      price,
      1
    );

    add_liquidity_2_pool_impl<CoinA, CoinB, LpCoin>(
      pool,
      clock,
      coin_a,
      coin_b,
      0,
      ctx
    )
  }

  public(package) fun register_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,    
    coin_decimals: &CoinDecimals,
    price: vector<u256>,
    ctx: &mut TxContext        
  ): Coin<LpCoin> {
    assert!(
      coin_a.value() != 0 
      && coin_b.value() != 0
      && coin_c.value() != 0, 
      errors::no_zero_liquidity_amounts()
    );

    let state = load_mut<LpCoin>(pool.state_mut());

    // @dev This is the quote coin in the pool 
    // So we do not need to pass a price
    register_coin<CoinA, LpCoin>(
      state, 
      coin_decimals,
      PRECISION, // * First coin does not have a price. The other coins are priced in this coin. So we put Zero.
      0
    );

    register_coin<CoinB, LpCoin>(
      state, 
      coin_decimals,
      *vector::borrow(&price, 0),
      1
    );

    register_coin<CoinC, LpCoin>(
      state, 
      coin_decimals,
      *vector::borrow(&price, 1),
      2
    );

    add_liquidity_3_pool_impl<CoinA, CoinB, CoinC, LpCoin>(
      pool,
      clock,
      coin_a,
      coin_b,
      coin_c,
      0,
      ctx
    )
  }

  public(package) fun swap_impl<CoinIn, CoinOut, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    clock: &Clock,
    coin_in: Coin<CoinIn>,
    mint_amount: u64,
    ctx: &mut TxContext
  ): Coin<CoinOut> {

    assert!(type_name::get<CoinIn>() != type_name::get<CoinOut>(), errors::cannot_swap_same_coin());
    
    let coin_in_value = coin_in.value();
    assert!(coin_in_value != 0, errors::no_zero_coin());

    let pool_id = pool.addy();
    let (state, coin_states) = state_and_coin_states_mut<LpCoin>(pool);
    let coin_in_index = coin_state<CoinIn, LpCoin>(state).index;
    
    let mut initial_coin_in_b = *&state.balances[coin_in_index];

    deposit_coin<CoinIn, LpCoin>(state, coin_in);
    
    let coin_in_state = &coin_states[coin_in_index];
    let coin_out_state = coin_state<CoinOut, LpCoin>(state);

    let (a, gamma) = get_a_gamma(state, clock);
    let mut tweak_price_index = coin_out_state.index;
    let timestamp = clock.timestamp_ms();

    let mut coin_out_b = *&state.balances[coin_out_state.index];
    let mut balances_in_price = balances_in_price_impl(state, coin_states);

    // Block scope
    {
      let t = state.a_gamma.future_time;
      if (t != 0) {
        if (coin_in_state.index != 0) initial_coin_in_b = mul_down(initial_coin_in_b, coin_in_state.price);
        let coin_in_ref = &mut balances_in_price[coin_in_state.index];
        // * Save the value to restore later
        let saved_value = *coin_in_ref;
        *coin_in_ref = initial_coin_in_b;
        state.d = volatile_math::invariant_(a, gamma, balances_in_price);
        let coin_in_ref =  &mut balances_in_price[coin_in_state.index];
        *coin_in_ref = saved_value;
        if (timestamp >= t) state.a_gamma.future_time = 1;
      }; 
    };

    let new_out_balance = volatile_math::y(a, gamma, &balances_in_price, state.d, coin_out_state.index) + 1; // give a small edge to the protocol
    let current_out_balance = *&balances_in_price[coin_out_state.index];

    let mut coin_out_amount = current_out_balance - min(current_out_balance, new_out_balance);

    let ref = &mut balances_in_price[coin_out_state.index];
    *ref = *ref - coin_out_amount;

    // Convert from Price => Coin Balance
    coin_out_amount = if (coin_out_state.index != 0) div_down(coin_out_amount, coin_out_state.price) else coin_out_amount;

    coin_out_amount = coin_out_amount - fee_impl(state, balances_in_price) * coin_out_amount / 10000000000;

    // Scale to the right decimal house
    let amount_out = mul_down(coin_out_amount, coin_out_state.decimals_scalar).to_u64();
    assert!(amount_out >= mint_amount, errors::slippage());

    let ref = &mut state.balances[coin_out_state.index];
    *ref = *ref - coin_out_amount;

    coin_out_b = coin_out_b - coin_out_amount;

    if (coin_out_state.index != 0) coin_out_b = mul_down(coin_out_b, coin_out_state.price);

    let ref = &mut balances_in_price[coin_out_state.index];
    *ref = coin_out_b;

    let coin_in_amount = div_down(coin_in_value.to_u256(), coin_in_state.decimals_scalar);

    let mut p = 0;
    if (coin_in_amount > 100000 && coin_out_amount > 100000) {
      p = if (coin_in_state.index != 0 && coin_out_state.index != 0) {

        coin_in_state.last_price * coin_in_amount / coin_out_amount
      } else if (coin_in_state.index == 0) {
        div_down(coin_in_amount, coin_out_amount)
      } else {
        tweak_price_index = coin_in_state.index; 
        div_down(coin_out_amount, coin_in_amount)
      };
    };

    let lp_supply = state.lp_coin_supply.supply_value().to_u256();

    tweak_price(
      state,
      coin_states,
      timestamp,
      a,
      gamma,
      balances_in_price,
      tweak_price_index,
      p,
      0,
      lp_supply * ROLL
    ); 

    events::emit_swap<Volatile, CoinIn, CoinOut, LpCoin>(pool_id, coin_in_value, amount_out);

    increment_version(state);

    coin_balance_mut(state).take(amount_out, ctx)
  }

  public(package) fun add_liquidity_2_pool_impl<CoinA, CoinB, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext      
  ): Coin<LpCoin> {
    assert!(coin_a.value() != 0 || coin_b.value() != 0, errors::must_supply_one_coin());
    // Make sure the second argument is in right order
    assert!(pool.are_coins_ordered(vector[type_name::get<CoinA>(), type_name::get<CoinB>()]), errors::coins_must_be_in_order());

    let (state, coin_states) = state_and_coin_states_mut<LpCoin>(pool);

    let old_balances = state.balances;

    // Update Balances
    deposit_coin<CoinA, LpCoin>(state, coin_a);
    deposit_coin<CoinB, LpCoin>(state, coin_b);

    add_liquidity(state, clock, coin_states, old_balances, lp_coin_min_amount, ctx)
  }

  public(package) fun add_liquidity_3_pool_impl<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext      
  ): Coin<LpCoin> {
    assert!(coin_a.value() != 0 || coin_b.value() != 0 || coin_c.value() != 0, errors::must_supply_one_coin());
    // Make sure the second argument is in right order
    assert!(pool.are_coins_ordered(vector[type_name::get<CoinA>(), type_name::get<CoinB>(), type_name::get<CoinC>()]), errors::coins_must_be_in_order());

    let (state, coin_states) = state_and_coin_states_mut<LpCoin>(pool);

    let old_balances = state.balances;

    // Update Balances
    deposit_coin<CoinA, LpCoin>(state, coin_a);
    deposit_coin<CoinB, LpCoin>(state, coin_b);
    deposit_coin<CoinC, LpCoin>(state, coin_c);

    add_liquidity(state, clock, coin_states, old_balances, lp_coin_min_amount, ctx)
  }

  public(package) fun remove_liquidity_2_pool_impl<CoinA, CoinB, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>) {
    assert!(lp_coin.value() != 0, errors::no_zero_coin());

    let pool_id = pool.addy();

    // Make sure the second argument is in right order
    assert!(pool.are_coins_ordered(vector[type_name::get<CoinA>(), type_name::get<CoinB>()]), errors::coins_must_be_in_order());

    let state = load_mut<LpCoin>(pool.state_mut());

    let total_supply = state.lp_coin_supply.supply_value();
    let lp_coin_amount = state.lp_coin_supply.decrease_supply(lp_coin.into_balance());

    // Empties the pool
    state.d = state.d - state.d * lp_coin_amount.to_u256() / total_supply.to_u256();

    let (coin_a, coin_b) = (
      withdraw_coin<CoinA, LpCoin>(state, lp_coin_amount, min_amounts.head(), total_supply, ctx),
      withdraw_coin<CoinB, LpCoin>(state, lp_coin_amount, *&min_amounts[1], total_supply, ctx),
    );

    events::emit_remove_liquidity_2_pool<Volatile, CoinA, CoinB, LpCoin>(pool_id, coin_a.value(), coin_b.value(), lp_coin_amount);

    increment_version(state);

    (coin_a, coin_b)
  }

  public(package) fun remove_liquidity_3_pool_impl<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>, Coin<CoinC>) {

    assert!(lp_coin.value() != 0, errors::no_zero_coin());
    // Make sure the second argument is in right order
    assert!(pool.are_coins_ordered(vector[type_name::get<CoinA>(), type_name::get<CoinB>(), type_name::get<CoinC>()]), errors::coins_must_be_in_order());

    let pool_id = pool.addy();

    let state = load_mut<LpCoin>(pool.state_mut());

    let total_supply = state.lp_coin_supply.supply_value();
    let lp_coin_amount = state.lp_coin_supply.decrease_supply(lp_coin.into_balance());

    // Empties the pool
    state.d = state.d - state.d * lp_coin_amount.to_u256() / total_supply.to_u256();

    let (coin_a, coin_b, coin_c) = (
      withdraw_coin<CoinA, LpCoin>(state, lp_coin_amount, min_amounts.head(), total_supply, ctx),
      withdraw_coin<CoinB, LpCoin>(state, lp_coin_amount, *&min_amounts[1], total_supply, ctx),
      withdraw_coin<CoinC, LpCoin>(state, lp_coin_amount, *&min_amounts[2], total_supply, ctx),
    );

    events::emit_remove_liquidity_3_pool<Volatile, CoinA, CoinB, CoinC, LpCoin>(
      pool_id,
      coin_a.value(),
      coin_b.value(),
      coin_c.value(),
      lp_coin_amount
    );

    increment_version(state);

    (coin_a, coin_b, coin_c)
  }

  public(package) fun remove_liquidity_one_coin_impl<CoinOut, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amount: u64,
    ctx: &mut TxContext    
  ): Coin<CoinOut> {
    let lp_coin_amount = lp_coin.value();

    assert!(lp_coin_amount != 0, errors::no_zero_coin());

    let pool_id = pool.addy();

    let (state, coin_states) = state_and_coin_states_mut<LpCoin>(pool);
    let (a, gamma) = get_a_gamma(state, clock);
    let timestamp = clock.timestamp_ms();
    let a_gamma_future_time = state.a_gamma.future_time;

    let (amount_out, p, d, balances_in_price, index_out) = calculate_remove_one_coin_impl<CoinOut, LpCoin>(
      state,
      a,
      gamma,
      coin_states,
      lp_coin_amount.to_u256() * ROLL,
      a_gamma_future_time != 0,
      true
    );

    if (timestamp >= a_gamma_future_time) state.a_gamma.future_time = 1;

    state.lp_coin_supply.decrease_supply(lp_coin.into_balance());

    let current_balance = &mut state.balances[index_out];
    *current_balance = *current_balance - amount_out;

    let lp_supply = state.lp_coin_supply.supply_value().to_u256();

    tweak_price(
      state,
      coin_states,
      timestamp,
      a,
      gamma,
      balances_in_price,
      index_out,
      p,
    d,
    lp_supply * ROLL
    );

    let remove_amount = mul_down(amount_out, *&coin_states[index_out].decimals_scalar).to_u64();
    assert!(remove_amount >= min_amount, errors::slippage());

    events::emit_remove_liquidity<Volatile, CoinOut, LpCoin>(pool_id, remove_amount, lp_coin_amount);

    increment_version(state);

    coin_balance_mut(state).take(remove_amount, ctx)
  }

  // === Private Functions ===

  fun new_state_v1<LpCoin>(
    clock: &Clock,
    coin_decimals: &CoinDecimals,   
    lp_coin_supply: Supply<LpCoin>,
    balances: vector<u256>,
    initial_a_gamma: vector<u256>,
    rebalancing_params: vector<u256>,
    fee_params: vector<u256>, 
    ctx: &mut TxContext
  ): StateV1<LpCoin> {
    assert!(lp_coin_supply.supply_value() == 0, errors::supply_must_have_zero_value());
    assert!(rebalancing_params.length() == 3, errors::must_have_3_values());
    assert!(fee_params.length() == 3, errors::must_have_3_values());

    let lp_coin_decimals = decimals<LpCoin>(coin_decimals);

    assert!(lp_coin_decimals == 9, errors::must_have_9_decimals());

    let timestamp = clock.timestamp_ms();
    let (a, gamma) = vector_2_to_tuple(initial_a_gamma);
    let (extra_profit, adjustment_step, ma_half_time) = vector_3_to_tuple(rebalancing_params);
    let (mid_fee, out_fee, gamma_fee) = vector_3_to_tuple(fee_params);

    let n_coins = balances.length();
 
    StateV1 {
      id: object::new(ctx),
      d: 0,
      lp_coin_supply,
      n_coins: n_coins.to_u256(),
      balances,
      a_gamma: AGamma { 
        a, 
        gamma, 
        initial_time: timestamp,
        future_a: a, 
        future_gamma: gamma, 
        future_time: 0  
      },
      xcp_profit: 0,
      xcp_profit_a: PRECISION,
      virtual_price: 0,
      rebalancing_params: RebalancingParams {
        extra_profit,
        adjustment_step,
        ma_half_time,
      },
      fees: Fees {
        mid_fee,
        out_fee,
        gamma_fee,
        admin_fee: ADMIN_FEE
      },
      last_prices_timestamp: timestamp,
      min_a: volatile_math::min_a(n_coins),
      max_a: volatile_math::max_a(n_coins),
      not_adjusted: false,
      version: 0,
      coin_states: table::new(ctx),
      coin_balances: bag::new(ctx),
      admin_balance: balance::zero()
    }    
  }

  fun new_pool<LpCoin>(
    clock: &Clock,
    coins: vector<TypeName>,
    coin_decimals: &CoinDecimals,   
    lp_coin_supply: Supply<LpCoin>,
    balances: vector<u256>,
    initial_a_gamma: vector<u256>,
    rebalancing_params: vector<u256>,
    fee_params: vector<u256>, 
    ctx: &mut TxContext
  ): (InterestPool<Volatile>, PoolAdmin) {
    let state_v1 = new_state_v1(
      clock,
      coin_decimals,
      lp_coin_supply,
      balances,
      initial_a_gamma,
      rebalancing_params,
      fee_params,
      ctx
    );

    interest_pool::new<Volatile>(
      make_coins_vec_set_from_vector(coins),
      versioned::create(STATE_V1_VERSION, state_v1, ctx), 
      ctx
    )
  }

  fun add_liquidity<LpCoin>(
    state: &mut StateV1<LpCoin>,
    clock: &Clock,
    coin_states: vector<CoinState>,
    mut old_balances_price: vector<u256>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext
  ): Coin<LpCoin> {
    let mut amounts = vector[];
    let mut amounts_p = empty_vector(state.n_coins);
    let timestamp = clock.timestamp_ms();
    let mut ix = INF_COINS;
    let n_coins = state.n_coins.to_u64();
    let mut new_balances_price = state.balances;
    let xx = state.balances;
    let (a, gamma) = get_a_gamma(state, clock);

    // Block Scope
    {
      let mut i: u64 = 0;
      while (n_coins > i) {
        let old_bal = &mut old_balances_price[i];
        let new_bal = &mut new_balances_price[i];
        amounts.push_back(*new_bal - *old_bal);

        let p = *new_bal - *old_bal;

        // If amount was sent
        if (p != 0) 
          ix = if (ix == INF_COINS) i else INF_COINS - 1;
  
        i = i + 1;
      };
    };

    // Block Scope
    {
      let mut i: u64 = 1;
      while (n_coins > i) {
        let old_bal = &mut old_balances_price[i];
        let new_bal = &mut new_balances_price[i];
        let coin_state = &coin_states[i];

        // Divide first to prevent overflow - these values r already scaled to 1e18
        *old_bal = mul_down(*old_bal, coin_state.price);
        *new_bal = mul_down(*new_bal, coin_state.price);
        i = i + 1;
      };
    };

    // Block Scope
    {
      let mut i: u64 = 0;
      while (n_coins > i) {
        let old_bal = &mut old_balances_price[i];
        let new_bal = &mut new_balances_price[i];

        let p = *new_bal - *old_bal;

        // If amount was sent
        if (p != 0) {
          let new_p = &mut amounts_p[i];
          *new_p = p;
        };

        i = i + 1;
      };
    };

    assert!(ix != INF_COINS, errors::must_supply_one_coin());

    // Calculate the previous and new invariant with current prices
    let old_d = if (state.a_gamma.future_time != 0) {
      if (timestamp >= state.a_gamma.future_time) state.a_gamma.future_time = 1;
      volatile_math::invariant_(a, gamma, old_balances_price)
    } else  state.d;

    let new_d = volatile_math::invariant_(a, gamma, new_balances_price);

    let lp_coin_supply = state.lp_coin_supply.supply_value().to_u256() * ROLL;

    // Calculate how many tokens to mint to the user
    let mut d_token = if (old_d != 0)
      lp_coin_supply * new_d / old_d - lp_coin_supply
    else 
      xcp_impl(state, coin_states, new_d);

    // Remove decimals, otherwise, the first initial supply will be inconsistent.
    d_token = (d_token / ROLL) * ROLL; 

    // Insanity check - something is wrong if this occurs as we check that the user deposited coins
    assert!(d_token != 0, errors::expected_a_non_zero_value());

    // Take fee
    if (old_d != 0) {
      // Remove fee
      d_token = d_token - mul_div_up(calculate_fee(state, amounts_p, new_balances_price), d_token, 10000000000);

       // local update
      let lp_supply = lp_coin_supply + d_token;
      let mut p = 0;
      if (d_token > 1000 && n_coins > ix) {
          let mut s = 0;
          let mut i = 0;
          while (n_coins > i) {
            let coin_state = &coin_states[i];

            if (i != ix) {
              if (i == 0)
                s = s + xx.head()
              else 
                s = s + mul_down(*&xx[i], coin_state.last_price);
            };

            i = i + 1;
          };

          s = s * d_token / lp_supply;
          p = div_down(s, *&amounts[ix] - (d_token * *&xx[ix] / lp_supply));
      };

      tweak_price(
        state,
        coin_states,
        timestamp,
        a,
        gamma,
        new_balances_price,
        ix,
        p,
        new_d,
        lp_supply
      );

    } else {
      state.d = new_d;
      state.virtual_price = PRECISION;
      state.xcp_profit = PRECISION;
    };

    // Bring back to 1e9 scalar
    let d_token_scale_down = (d_token / ROLL).to_u64();

    assert!(d_token_scale_down >= lp_coin_min_amount, errors::slippage());

    increment_version(state);

    state.lp_coin_supply.increase_supply(d_token_scale_down).to_coin(ctx)
  }

  fun calculate_remove_one_coin_impl<CoinOut, LpCoin>(
    state: &StateV1<LpCoin>,
    a: u256,
    gamma: u256,
    coin_states: vector<CoinState>,
    lp_coin_amount: u256,
    update_d: bool,
    calc_price: bool
  ): (u256, u256, u256, vector<u256>, u64) {
    
    let mut xp = state.balances;

    let mut index = 1;
    let mut price_scale_i = PRECISION;
    let mut index_out: u64 = 0;
    let n_coins = state.n_coins.to_u64();

    while (n_coins > index) {
      let coin_state = &coin_states[index];
      let v = &mut xp[index];

      if (coin_state.type_name == type_name::get<CoinOut>()) {
        price_scale_i = coin_state.price;
        index_out = coin_state.index;
      };

      // we do not update the first coin price
      *v = mul_down(*v, coin_state.price);
      
      index = index + 1;
    };

    // Invalid coin was provided
    assert!(index_out != 300, errors::invalid_coin_type());

    let d0 = if (update_d) volatile_math::invariant_(a, gamma, xp) else state.d;
    let d = d0;

    let fee = fee_impl(state, xp);
    let d_b = lp_coin_amount * d / (state.lp_coin_supply.supply_value().to_u256() * ROLL);
    let d = d - (d_b - mul_div_up(fee, d_b, 20000000000));
    let y = volatile_math::y(a, gamma, &xp, d, index_out);
    let dy = div_down((*&xp[index_out] - y), price_scale_i);  
    let i_xp = &mut xp[index_out];
    *i_xp = y;

    let mut p = 0;
    if (calc_price && dy > 100000 && lp_coin_amount > 100000) {
      let mut s = 0;

      let mut index = 0;
      while(n_coins > index) {
        if (index != index_out) {
          s = if (index == 0) 
            s + state.balances.head()
          else
             s + mul_down(*&state.balances[index], *&coin_states[index].last_price)  
        };  

        index = index + 1;
      };

      s = s * d_b / d0;
      p = div_down(s, dy - (d_b * *&state.balances[index_out] / d0));
    };

    (dy, p, d, xp, index_out)
  } 

  fun deposit_coin<CoinType, LpCoin>(state: &mut StateV1<LpCoin>, coin_in: Coin<CoinType>) {
    let coin_value = coin_in.value().to_u256();

    if (coin_value == 0) {
      coin_in.destroy_zero();
      return
    };

    let coin_state = coin_state<CoinType, LpCoin>(state);

    // Update the balance for the coin
    let current_balance = &mut state.balances[coin_state.index];
    *current_balance = *current_balance + div_down(coin_value, coin_state.decimals_scalar);

    coin_balance_mut(state).join(coin_in.into_balance());
  }

  fun withdraw_coin<CoinType, LpCoin>(
    state: &mut StateV1<LpCoin>, 
    burn_amount: u64,
    min_amount: u64,
    supply: u64,
    ctx: &mut TxContext
    ): Coin<CoinType> {
      let coin_state = coin_state<CoinType, LpCoin>(state);
      let current_balance = &mut state.balances[coin_state.index];
      
      // give a small edge to the protocol
      let coin_amount = *current_balance * (burn_amount - 1).to_u256() / supply.to_u256();

      *current_balance = *current_balance - coin_amount;

      let remove_amount = mul_down(coin_amount, coin_state.decimals_scalar).to_u64();
      assert!(remove_amount >= min_amount, errors::slippage());

      coin_balance_mut(state).take(remove_amount, ctx)
  }

  fun register_coin<CoinType, LpCoin>(
    state: &mut StateV1<LpCoin>, 
    coin_decimals: &CoinDecimals,
    price: u256,
    index: u64
  ) {
    let coin_name = type_name::get<CoinType>();

    state.coin_states.add(coin_name, CoinState {
      index,
      price,
      price_oracle: price,
      last_price: price,
      decimals_scalar: scalar<CoinType>(coin_decimals).to_u256(),
      type_name: coin_name
    });
    state.coin_balances.add(coin_name, balance::zero<CoinType>());    
  }

  fun get_a_gamma<LpCoin>(state: &StateV1<LpCoin>, clock: &Clock): (u256, u256) {
    let mut t1 = state.a_gamma.future_time;
    let mut gamma1 = state.a_gamma.future_gamma;
    let mut a1 = state.a_gamma.future_a;

    let timestamp = clock.timestamp_ms();

    if (t1 > timestamp) {
      let mut t0 = state.a_gamma.initial_time;
      let a0 = state.a_gamma.a;
      let gamma0 = state.a_gamma.gamma;

      t1 = t1 - t0;
      t0 = timestamp - t0;
      let t2 = t1 - t0;

      a1 = (a0 * t2.to_u256() + a1 * t0.to_u256()) / t1.to_u256();
      gamma1 = (gamma0 * t2.to_u256() + gamma1 * t0.to_u256()) / t1.to_u256();
    };

    (a1, gamma1)
  }

  fun tweak_price<LpCoin>(
    state: &mut StateV1<LpCoin>,
    mut coin_states: vector<CoinState>,
    timestamp: u64,
    a: u256, 
    gamma: u256, 
    balances: vector<u256>, 
    i: u64,
    p_i: u256,
    new_d: u256, 
    lp_supply: u256
  ) {
    // Update Moving Average
    
    let n_coins = state.n_coins.to_u64();

    if (timestamp > state.last_prices_timestamp ) {  
      let alpha = volatile_math::half_pow(
        div_down(((timestamp - state.last_prices_timestamp) / 1000).to_u256(), state.rebalancing_params.ma_half_time), 
      10000000000);

      // update prices (do not update the first one)
      let mut index = 1;

      while (n_coins > index) {
        let coin_state = &mut coin_states[index];

        coin_state.price_oracle = (coin_state.last_price * (PRECISION - alpha) + coin_state.price_oracle * alpha) / PRECISION;

        index = index + 1;
      };

      state.last_prices_timestamp = timestamp;
    };

    let d_unadjusted = if (new_d == 0) volatile_math::invariant_(a, gamma, balances) else new_d;
    
    if (p_i != 0) {
      if (i != 0) {
        let coin_state = &mut coin_states[i];
        coin_state.last_price = p_i;
        } else {
          // We do not change the first coin
          let mut i = 1;
          while ((state.n_coins as u64) > i) {
            let coin_state = &mut coin_states[i];
            coin_state.last_price = div_down(coin_state.last_price, p_i);
            i = i + 1;
          };
        };
     } else {
      let mut xp = balances;
      let dx_price = xp.head() / 1000000;
      let ref = &mut xp[0];
      *ref = *ref + dx_price;

      // We do not change the first coin
      let mut i = 1;
      while (n_coins > i) {
        let coin_state = &mut coin_states[i];
        coin_state.last_price = coin_state.price * dx_price / (*&balances[i] - volatile_math::y(a, gamma, &xp, d_unadjusted, i));
        i = i + 1;
      };
    };

    let old_xcp_profit = state.xcp_profit;
    let mut old_virtual_price = state.virtual_price;
    let mut xp = vector[d_unadjusted / state.n_coins];

    // We do nt change the first coin
    let mut i = 1;
    while (n_coins > i) {
      let coin_state = &coin_states[i];
      xp.push_back(div_down(d_unadjusted, state.n_coins * coin_state.price));
      i = i + 1;
    };

    let mut xcp_profit = PRECISION;
    let mut virtual_price = PRECISION;

    if (old_virtual_price != 0) {
      virtual_price = div_down(volatile_math::geometric_mean(xp, true), lp_supply);
      xcp_profit = old_xcp_profit * virtual_price / old_virtual_price;
      
      if (old_virtual_price > virtual_price && state.a_gamma.future_time == 0) abort errors::incurred_a_loss();
      if (state.a_gamma.future_time == 1) state.a_gamma.future_time = 0;
    };

    state.xcp_profit = xcp_profit;

    let mut needs_adjustment = state.not_adjusted;
    if (!needs_adjustment && (virtual_price * 2 - PRECISION > xcp_profit + 2 * state.rebalancing_params.extra_profit)) {
      needs_adjustment = true;
      state.not_adjusted = true;
    };

    if (needs_adjustment) {
      let adjustment_step = state.rebalancing_params.adjustment_step;
      let mut norm = 0;

      // We do nt change the first coin
      let mut i = 1;
      while (n_coins > i) {
        let coin_state = vector::borrow(&coin_states, i);

        let ratio = diff(PRECISION, div_down(coin_state.price_oracle, coin_state.price));
        norm = norm + math256::pow(ratio, 2);
        i = i + 1;
      };

      if (norm > math256::pow(adjustment_step, 2) && old_virtual_price != 0) {
        norm = volatile_math::sqrt(norm / PRECISION);

        let mut p_new = vector[0];
        let mut xp = balances;

        // We do not change the first coin
        let mut i = 1;
        while (n_coins > i) {
          let coin_state = &coin_states[i];
          
          let value = (coin_state.price * (norm - adjustment_step) + adjustment_step * coin_state.price_oracle) / norm;
          p_new.push_back(value);

          let x = &mut xp[i];
          *x = *x * value / coin_state.price;

          i = i + 1;
        };
   
        let d = volatile_math::invariant_(a, gamma, xp);
        let x = &mut xp[0];
        *x = d / state.n_coins;

        let mut i = 1;
        while (n_coins > i) {
          let x = &mut xp[i];
          *x = div_down(d, state.n_coins * *vector::borrow(&p_new, i));
          i = i + 1;
        };

        old_virtual_price = div_down(volatile_math::geometric_mean(xp, true), lp_supply);
        if (old_virtual_price > PRECISION && (2 * old_virtual_price - PRECISION > xcp_profit)) {
           let mut i = 1;
           while (n_coins > i) {
            let coin_state = &mut coin_states[i];
            coin_state.price = *&p_new[i];

            i = i + 1;
          };
          update_coin_state_prices(state, coin_states);
          state.d = d;
          state.virtual_price = old_virtual_price;
          return
        } else {
          state.not_adjusted = false;
        }
      };
    };

    update_coin_state_prices(state, coin_states);
    state.d = d_unadjusted;
    state.virtual_price = virtual_price;
  }

  fun balances_in_price_impl<LpCoin>(state: &StateV1<LpCoin>, coin_states: vector<CoinState>): vector<u256> {
    let mut balances = state.balances;
    let n_coins = state.n_coins.to_u64();

    let mut i = 1;
    while (n_coins > i) {
      let coin_state = &coin_states[i];
      let ref = &mut balances[i];
      *ref = mul_down(*ref, coin_state.price);
      i = i + 1;
    };

    balances    
  }  

  fun xcp_impl<LpCoin>(state: &StateV1<LpCoin>, coin_states: vector<CoinState>, d: u256): u256 {
    let mut x = vector[d / state.n_coins];
    let n_coins = state.n_coins.to_u64();

    let mut index = 1;

    while (n_coins > index) {
      let coin_state = *&coin_states[index];
      x.push_back(div_down(d, state.n_coins * coin_state.price));

      index = index + 1;
    };

    volatile_math::geometric_mean(x, true)
  }

  fun fee_impl<LpCoin>(state: &StateV1<LpCoin>, balances: vector<u256>): u256 {
    let f = volatile_math::reduction_coefficient(balances, state.fees.gamma_fee);
    (state.fees.mid_fee * f + state.fees.out_fee * (PRECISION - f)) / PRECISION
  }

  fun calculate_fee<LpCoin>(state: &StateV1<LpCoin>, amounts: vector<u256>, balances: vector<u256>): u256 {
    let fee = mul_div_up(fee_impl(state, balances), state.n_coins, 4 * (state.n_coins - 1)); 
    let s = sum(amounts);
    let avg = s / state.n_coins;

    let mut index = 0;
    let mut s_diff = 0;
    let n_coins = state.n_coins.to_u64();
    while (n_coins > index) {
      let x = *vector::borrow(&amounts, index);
      s_diff = s_diff + diff(x, avg);

      index = index + 1;
    };

    fee * s_diff / s + NOISE_FEE
  }

  fun claim_admin_fees_impl<LpCoin>(state: &mut StateV1<LpCoin>, clock: &Clock, request: BalancesRequest, coin_states: vector<CoinState>) {
    let (a, gamma) = get_a_gamma(state, clock);
    let state_id = object::id_address(state);

    let xcp_profit = state.xcp_profit;
    let xcp_profit_a = state.xcp_profit_a;
    let vprice = state.virtual_price;

    let BalancesRequest { coins, version, state_id: request_state_id } = request;
    let n_coins = state.n_coins.to_u64();
    
    assert!(state_id == request_state_id, errors::wrong_pool_id());
    assert!(state.version == version, errors::version_was_updated());
    assert!(n_coins == coins.size(), errors::missing_coin_balance());

    let mut i = 0;
    while (n_coins > i) {
      let ref_mut = &mut state.balances[i];
      let coin_state = &coin_states[i];
      let bal = *coins.get(&coin_state.type_name);
      *ref_mut = bal;

      i = i + 1;
    };

    if (xcp_profit > xcp_profit_a) {
      let fees = (xcp_profit - xcp_profit_a) * state.fees.admin_fee / 20000000000;
      if (fees != 0) {
        let frac = mul_up(state.lp_coin_supply.supply_value().to_u256() * ROLL, div_up (vprice, (vprice - fees)) - PRECISION);
        state.admin_balance.join( state.lp_coin_supply.increase_supply((frac / ROLL).to_u64()));
        state.xcp_profit = xcp_profit - (fees * 2)
      };
    };
    
    let d = volatile_math::invariant_(a, gamma, balances_in_price_impl(state, coin_states));

    state.virtual_price = div_down(
      xcp_impl(state, coin_states, d),
      state.lp_coin_supply.supply_value().to_u256() * ROLL
    );

    if (state.xcp_profit > xcp_profit_a) state.xcp_profit_a = state.xcp_profit;
  }  

  // * Borrow State Functions

  fun state_and_coin_states<LpCoin>(pool: &mut InterestPool<Volatile>): (&StateV1<LpCoin>, vector<CoinState>) {
    let coins = pool.coins();    
    let state = load<LpCoin>(pool.state_mut());
    let coin_states = coin_state_vector_in_order(state, coins);
    (state, coin_states)
  }

  fun state_and_coin_states_mut<LpCoin>(pool: &mut InterestPool<Volatile>): (&mut StateV1<LpCoin>, vector<CoinState>) {
    let coins = pool.coins();   
    let state = load_mut<LpCoin>(pool.state_mut());
    let coin_states = coin_state_vector_in_order(state, coins);
    (state, coin_states)
  }

  fun update_coin_state_prices<LpCoin>(state: &mut StateV1<LpCoin>, new_coin_states: vector<CoinState>) {
    let mut i = 1;
    let n_coins = state.n_coins.to_u64();
    
    while (n_coins > i) {
      let new_state = vector::borrow(&new_coin_states, i);
      let current_state = coin_state_with_key_mut(state, new_state.type_name);
      current_state.last_price = new_state.last_price;
      current_state.price = new_state.price;
      current_state.price_oracle = new_state.price_oracle;
      i = i + 1;
    };
  }

  fun coin_state_vector_in_order<LpCoin>(state: &StateV1<LpCoin>, coins: vector<TypeName>): vector<CoinState> {
    let mut data = vector::empty();
    let mut i = 0;
    let n_coins = state.n_coins.to_u64();
    
    while (n_coins > i) {
        let coin_key = *&coins[i];
        data.push_back(*coin_state_with_key(state, coin_key));
        i = i + 1;
    };
    data
  }

  fun increment_version<LpCoin>(state: &mut StateV1<LpCoin>) {
    state.version = if (state.version == MAX_U256) 0 else state.version + 1;
  }

  fun coin_state<CoinType, LpCoin>(state: &StateV1<LpCoin>): CoinState {
    *coin_state_with_key(state, type_name::get<CoinType>())
  }

  fun coin_balance_impl<CoinType, LpCoin>(state: &StateV1<LpCoin>): &Balance<CoinType>  {
    state.coin_balances.borrow(type_name::get<CoinType>())
  }

  fun coin_balance_mut<CoinType, LpCoin>(state: &mut StateV1<LpCoin>): &mut Balance<CoinType>  {
    state.coin_balances.borrow_mut(type_name::get<CoinType>())
  }

  fun coin_state_with_key<LpCoin>(state: &StateV1<LpCoin>, type_name: TypeName): &CoinState {
    state.coin_states.borrow(type_name)
  }

  fun coin_state_with_key_mut<LpCoin>(state: &mut StateV1<LpCoin>, type_name: TypeName): &mut CoinState {
    state.coin_states.borrow_mut(type_name)
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
}