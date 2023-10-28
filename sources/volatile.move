module amm::volatile {
  use std::vector;
  use std::type_name::{get, TypeName};

  use sui::math::pow;
  use sui::object::{Self, UID};
  use sui::coin::{Self, Coin};
  use sui::dynamic_field as df;
  use sui::clock::{Self, Clock};
  use sui::dynamic_object_field as dof;
  use sui::tx_context::{Self, TxContext};
  use sui::transfer::public_share_object;
  use sui::balance::{Self, Supply, Balance};

  use suitears::coin_decimals::{get_decimals_scalar, CoinDecimals};

  use amm::errors;
  use amm::asserts;
  use amm::volatile_math;
  use amm::curves::Volatile;
  use amm::utils::make_coins_from_vector;
  use amm::interest_pool::{
    Self as core,
    Pool,
    new_pool
  };

  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18
  const A_MULTIPLIER: u256 = 10000;
  const ADMIN_FEE: u256 = 5 * 1_000_000_000;
  const MIN_FEE: u256 = 5 * 100_000;
  const MAX_FEE: u256 = 10 * 1_000_000_000;
  const NOISE_FEE: u256 = 100_000;
  const MAX_A_CHANGE: u256 = 10;
  const MIN_GAMMA: u256 = 10_000_000_000;
  const MAX_GAMMA: u256 = 5 * 10_000_000_000_000_000;
  const MIN_RAMP_TIME: u256 = 86400000; // 1 day in milliseconds

  // * Structs ---- START ----

  struct AdminCoinBalanceKey has drop, copy, store { type: TypeName }

  struct StateKey has drop, copy, store {}

  struct CoinStateKey has drop, copy, store { type: TypeName }

  struct CoinBalanceKey has drop, copy, store { type: TypeName }

  struct CoinState has store {
    index: u64,
    price: u256,
    price_oracle: u256,
    last_price: u256,
    decimals: u256
  }

  struct AGamma has store, copy {
    a: u256,
    gamma: u256,
    future_a: u256,
    future_gamma: u256,
    initial_time: u64,
    future_time: u64
  }

  struct RebalancingParams has store, copy {
    extra_profit: u256,
    adjustment_step: u256,
    ma_exp_time: u256,
    future_extra_profit: u256,
    future_adjustment_step: u256,
    future_ma_exp_time: u256
  }

  struct Fees has store, copy {
    mid_fee: u256,
    out_fee: u256,
    gamma_fee: u256,
    future_mid_fee: u256,
    future_out_fee: u256,
    future_gamma_fee: u256
  }

  struct State<phantom LpCoin> has key, store {
    id: UID,
    d: u256, // invariant
    lp_coin_supply: Supply<LpCoin>,
    lp_coin_decimals: u256,
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
  }

    // * Structs ---- END ----

  public fun new_2_pool<CoinA, CoinB, LpCoin>(
    c: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_decimals: &CoinDecimals,     
    lp_coin_supply: Supply<LpCoin>,
    initial_a_gamma: vector<u256>,
    rebalancing_params: vector<u256>,
    prices: vector<u256>,
    fee_params: vector<u256>, 
    ctx: &mut TxContext
  ) {
    assert!(
      coin::value(&coin_a) != 0 
      && coin::value(&coin_b) != 0, 
      errors::no_zero_liquidity_amounts()
    );

    let pool = new_pool<Volatile>(
      make_coins_from_vector(vector[get<CoinA>(), get<CoinB>()]), 
      ctx
    );

    add_state<LpCoin>(
      core::borrow_mut_uid(&mut pool),
      c,
      coin_decimals,
      lp_coin_supply,
      vector[0, 0],
      initial_a_gamma,
      rebalancing_params,
      prices,
      fee_params,
      ctx
    );

    register_coin<CoinA>(
      core::borrow_mut_uid(&mut pool), 
      coin_decimals,
      *vector::borrow(&prices, 0),
      0
    );

    register_coin<CoinB>(
      core::borrow_mut_uid(&mut pool), 
      coin_decimals,
      *vector::borrow(&prices, 1),
      1
    );

    public_share_object(pool);
  }

  public fun add_liquidity_2_pool<CoinA, CoinB, LpCoin>(
    pool: &mut Pool<Volatile>,
    c: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext      
  ): Coin<LpCoin> {
    let coin_a_value = coin::value(&coin_a);
    let coin_b_value = coin::value(&coin_b);

    assert!(coin_a_value != 0 || coin_b_value != 0, errors::no_zero_coin());
    // Price coins based on the first one
    assert!(first_coin(pool) == get<CoinA>(), errors::incorrect_first_coin());
    
    let state = load_mut_state<LpCoin>(core::borrow_mut_uid(pool));

    let (a, gamma) = get_a_gamma(state, c);
    let amounts_p = vector::empty<u256>();
    let xx = vector::empty<u256>();
    let d_token = 0;
    let d_token_fee = 0;
    let old_d = 0;

    // Coin is the first in the pool. Price is tight to it.
    let coin_a_state = load_coin_state<CoinA>(&state.id);
    let coin_b_state = load_coin_state<CoinB>(&state.id);


    let old_balances = state.balances;

    // CoinA Balances
    deposit_coin<CoinA, LpCoin>(state, coin_a);
    deposit_coin<CoinB, LpCoin>(state, coin_b);

    let new_balances = state.balances;

    // Update the scale for CoinB
    {
      let old_balB = vector::borrow_mut(&mut old_balances, coin_b_index);
      let new_balB = vector::borrow_mut(&mut new_balances, coin_b_index);

      // Divide first to prevent overflow - these values r already scaled to 1e18
      *old_balB = (*old_balB / PRECISION) * *vector::borrow(&price_scale, 0);
      *new_balB = (*new_balB / PRECISION) * *vector::borrow(&price_scale, 0);
    };

    {
      vector::push_back(&mut amounts_p, *vector::borrow(&new_balances, 0) - *vector::borrow(&old_balances, 0));
      vector::push_back(&mut amounts_p, *vector::borrow(&new_balances, 1) - *vector::borrow(&old_balances, 1));
    };

    if (state.future_a_gamma_time != 0) {
      old_d = volatile_math::invariant_(a, gamma, &old_balances);
      if (clock::timestamp_ms(c) >= state.future_a_gamma_time) state.future_a_gamma_time = 1;
    } else {
      old_d = state.d;
    };

    let new_d = volatile_math::invariant_(a, gamma, &new_balances);

    let lp_coin_supply = (balance::supply_value(&state.lp_coin_supply) as u256);

    // d_token = if (old_d != 0)
    //   lp_coin_supply * new_d / old_d - lp_coin_supply
    // else 
      
  }

  fun deposit_coin<CoinType, LpCoin>(state: &mut State<LpCoin>, coin_in: Coin<CoinType>) {
    let coin_value = (coin::value(&coin_in) as u256);

    if (coin_value == 0) {
      coin::destroy_zero(coin_in);
      return
    };

    let (coin_balance, coin_decimals, coin_index) = load_mut_coin_state<CoinType>(&mut state.id);

    // Update the balance for the coin
    let current_balance = vector::borrow_mut(&mut state.balances, coin_index);
    *current_balance = *current_balance + (coin_value * PRECISION / coin_decimals);

    balance::join(coin_balance, coin::into_balance(coin_in));
  }

  fun add_state<LpCoin>(
    id: &mut UID,
    c: &Clock,
    coin_decimals: &CoinDecimals,   
    lp_coin_supply: Supply<LpCoin>,
    balances: vector<u256>,
    initial_a_gamma: vector<u256>,
    rebalancing_params: vector<u256>,
    prices: vector<u256>,
    fee_params: vector<u256>, 
    ctx: &mut TxContext
  ) {
    let n_coins = (vector::length(&balances) as u256);

    asserts::assert_supply_has_zero_value(&lp_coin_supply);
    assert!((vector::length(&prices) as u256) == n_coins - 1, errors::wrong_configuration());
    assert!(vector::length(&rebalancing_params) == 3, errors::must_have_3_values());
    assert!(vector::length(&fee_params) == 3, errors::must_have_3_values());

    let pow_n_coins = (pow((n_coins as u64), (n_coins as u8)) as u256);
    let timestamp = clock::timestamp_ms(c);

    let (a, gamma) = vector_2_to_tuple(initial_a_gamma);
    let (extra_profit, adjustment_step, ma_exp_time) = vector_3_to_tuple(rebalancing_params);
    let (mid_fee, out_fee, gamma_fee) = vector_3_to_tuple(fee_params);

    dof::add(id, StateKey {}, 
      State {
        id: object::new(ctx),
        d: 0,
        lp_coin_supply,
        lp_coin_decimals: (get_decimals_scalar<LpCoin>(coin_decimals) as u256),
        n_coins,
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
          ma_exp_time,
          future_extra_profit: extra_profit,
          future_adjustment_step: adjustment_step,
          future_ma_exp_time: ma_exp_time
        },
        fees: Fees {
          mid_fee,
          out_fee,
          gamma_fee,
          future_out_fee: 0,
          future_mid_fee: 0,
          future_gamma_fee: 0
        },
        last_prices_timestamp: timestamp,
        min_a: pow_n_coins  * A_MULTIPLIER / 100,
        max_a: 1000 * A_MULTIPLIER * pow_n_coins 
      }
    );
  }

  fun register_coin<CoinType>(
    id: &mut UID, 
    coin_decimals: &CoinDecimals,
    price: u256,
    index: u64
  ) {
    let coin_name = get<CoinType>();

    df::add(id, AdminCoinBalanceKey { type: coin_name }, balance::zero<CoinType>());
    df::add(id, CoinStateKey { type: coin_name }, CoinState {
      index,
      price,
      price_oracle: price,
      last_price: price,
      decimals: (get_decimals_scalar<CoinType>(coin_decimals) as u256),
    });
    df::add(id, CoinBalanceKey { type: coin_name }, balance::zero<CoinType>());
  }

  // * Private functions

  fun get_a_gamma<LpCoin>(state: &State<LpCoin>, c: &Clock): (u256, u256) {
    let t1 = state.a_gamma.future_time;
    let gamma1 = state.a_gamma.future_gamma;
    let a1 = state.a_gamma.future_a;

    let timestamp = clock::timestamp_ms(c);

    if (t1 > timestamp) {
      let t0 = state.a_gamma.initial_time;
      let a0 = state.a_gamma.a;
      let gamma0 = state.a_gamma.gamma;

      t1 = t1 - t0;
      t0 = timestamp - t0;
      let t2 = t1 - t0;

      a1 = (a0 * (t2 as u256) + a1 * (t0 as u256)) / (t1 as u256);
      gamma1 = (gamma0 * (t2 as u256) + gamma1 * (t0 as u256)) / (t1 as u256);
    };

    (a1, gamma1)
  }

  fun first_coin(pool: &Pool<Volatile>): TypeName {
    *vector::borrow(&core::view_coins(pool), 0)
  }

  fun vector_3_to_tuple(x: vector<u256>): (u256, u256, u256) {
    (
      *vector::borrow(&x, 0),
      *vector::borrow(&x, 1),
      *vector::borrow(&x, 2)
    )
  }

  fun vector_2_to_tuple(x: vector<u256>): (u256, u256) {
    (
      *vector::borrow(&x, 0),
      *vector::borrow(&x, 1),
    )
  }

  fun get_xcp<LpCoin>(state: &State<LpCoin>, d: u256) {
    // let x = vector::singleton(d / state.n_coins);

    // let index = 1;
    // let packed_prices_value = state.price_scale_packed;

    // while (state.n_coins > index) {
    //   vector::push_back(&mut x, d * PRECISION / (state.n_coins * ));

    //   index = index + 1;
    // };
  }

  fun load_coin_state<CoinType>(id: &UID): &CoinState {
    load_coin_state_with_key(id, get<CoinType>())
  }

  fun load_mut_coin_state<CoinType>(id: &mut UID): &mut CoinState  {
    load_mut_coin_state_with_key(id, get<CoinType>())
  }

  fun load_coin_balance<CoinType>(id: &UID): &Balance<CoinType> {
    df::borrow(id, CoinBalanceKey { type: get<CoinType>() })
  }

  fun load_mut_coin_balance<CoinType>(id: &mut UID): &mut Balance<CoinType>  {
    df::borrow_mut(id, CoinBalanceKey { type: get<CoinType>() })
  }

  fun load_coin_state_with_key(id: &UID, type: TypeName): &CoinState {
    df::borrow<CoinStateKey, CoinState>(id, CoinStateKey { type })
  }

  fun load_mut_coin_state_with_key(id: &mut UID, type: TypeName): &mut CoinState {
    df::borrow_mut(id, CoinStateKey { type })
  }

  fun load_state<LpCoin>(id: &UID): &State<LpCoin> {
    dof::borrow(id, StateKey {})
  }

  fun load_mut_state<LpCoin>(id: &mut UID): &mut State<LpCoin> {
    dof::borrow_mut(id, StateKey {})
  }
}