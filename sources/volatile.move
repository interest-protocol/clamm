// CurveV2 in Move - All logic from Curve
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
  
  use suitears::math256::{Self, sum, diff, mul_div_up};
  use suitears::comparator::{compare, is_equal};
  use suitears::coin_decimals::{get_decimals_scalar, CoinDecimals};
  use suitears::fixed_point_ray::{ray_mul_down as fmul, ray_div_down as fdiv};

  use amm::errors;
  use amm::asserts;
  use amm::volatile_math;
  use amm::curves::Volatile;
  use amm::interest_pool::{
    Self as core,
    Pool,
    new_pool
  };
  use amm::utils::{
    empty_vector,
    vector_2_to_tuple,
    vector_3_to_tuple,
    make_coins_from_vector
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
  const INF_COINS: u64 = 15;

  // * Structs ---- START ----

  struct AdminCoinBalanceKey has drop, copy, store { type: TypeName }

  struct StateKey has drop, copy, store {}

  struct CoinStateKey has drop, copy, store { type: TypeName }

  struct CoinBalanceKey has drop, copy, store { type: TypeName }

  struct CoinState has store, copy, drop {
    index: u64,
    price: u256, // 1e18
    price_oracle: u256, // 1e18
    last_price: u256, // 1e18
    decimals: u256,
    type: TypeName
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
    ma_half_time: u256,
    future_extra_profit: u256,
    future_adjustment_step: u256,
    future_ma_half_time: u256
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
    not_adjusted: bool
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
    price: u256, // @ on a pool with 2 coins, we only need 1 price
    fee_params: vector<u256>, 
    ctx: &mut TxContext
  ): Coin<LpCoin> {
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
      fee_params,
      ctx
    );

    // @dev This is the quote coin in the pool 
    // So we do not need to pass a price
    register_coin<CoinA>(
      core::borrow_mut_uid(&mut pool), 
      coin_decimals,
      0,
      0
    );

    register_coin<CoinB>(
      core::borrow_mut_uid(&mut pool), 
      coin_decimals,
      price,
      1
    );

    let lp_coin =    add_liquidity_2_pool<CoinA, CoinB, LpCoin>(
      &mut pool,
      c,
      coin_a,
      coin_b,
      0,
      ctx
    );

    public_share_object(pool);

    lp_coin
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
    // Make sure the second argument is in right order
    assert!(are_coins_ordered(pool, vector[get<CoinA>(), get<CoinB>()]), errors::coins_must_be_in_order());

    let (state, coin_states, coins) = load<LpCoin>(pool);
    let (a, gamma) = get_a_gamma(state, c);


    let n_coins_u64 = (state.n_coins as u64);
    let amounts = vector[];
    let amounts_p = empty_vector(state.n_coins);
    let timestamp = clock::timestamp_ms(c);
    let ix = INF_COINS;

    let old_balances = state.balances;

    // Update Balances
    deposit_coin<CoinA, LpCoin>(state, coin_a);
    deposit_coin<CoinB, LpCoin>(state, coin_b);

    let new_balances = state.balances;
    let xx = new_balances;

    // Convert balances to first coin price (usually Stable Coin USD)
    {
      let i: u64 = 1;
      while (n_coins_u64 > i) {
        let old_bal = vector::borrow_mut(&mut old_balances, i);
        let new_bal = vector::borrow_mut(&mut new_balances, i);
        vector::push_back(&mut amounts, *new_bal - *old_bal);
        let coin_state = vector::borrow(&coin_states, i);

        // Divide first to prevent overflow - these values r already scaled to 1e18
        *old_bal = fmul(*old_bal, coin_state.price);
        *new_bal = fmul(*new_bal, coin_state.price);

        let p = *new_bal - *old_bal;

        // If amount was sent
        if (p != 0) {
          let new_p = vector::borrow_mut(&mut amounts, i);
          *new_p = p;

          ix = if (ix == INF_COINS) i else INF_COINS - 1;
        };

        i = i + 1;
      };
    };

    // Calculate the previous and new invariant with current prices
    let old_d = if (state.a_gamma.future_time != 0) {
      if (timestamp >= state.a_gamma.future_time) state.a_gamma.future_time = 1;
      volatile_math::invariant_(a, gamma, &old_balances)
    } else  state.d;
    let new_d = volatile_math::invariant_(a, gamma, &new_balances);


    let lp_coin_supply = (balance::supply_value(&state.lp_coin_supply) as u256);

    // Calculate how many tokens to mint to the user
    let d_token = if (old_d != 0)
      lp_coin_supply * new_d / old_d - lp_coin_supply
    else 
      get_xcp(state, coins, new_d);

    // Insanity check - something is wrong if this occurs as we check that the user deposited coins
    assert!(d_token != 0, errors::expected_a_non_zero_value());

    // Take fee
    if (old_d != 0) {
      // Remove fee
      d_token = d_token - mul_div_up(calculate_fee(state, amounts_p, new_balances), d_token, 10000000000);
       // local update
      let lp_supply = lp_coin_supply + d_token;
      let p = 0;
      if (d_token > 100000 && n_coins_u64 > ix) {
          let s = 0;

          let i = 0;
          while (n_coins_u64 > i) {
            let coin_state = vector::borrow(&coin_states, i);

            if (i != ix)
              s = s + *vector::borrow(&xx, 0)
            else 
              s = s + fmul(*vector::borrow(&xx, i), coin_state.last_price);

            i = i + 1;
          };

          s = s * d_token / lp_supply;
          p = fdiv(s, (*vector::borrow(&amounts, ix) - d_token * *vector::borrow(&xx, ix) / lp_supply));
      };

      tweak_prices(
        state,
        coin_states,
        timestamp,
        a,
        gamma,
        new_balances,
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

    assert!((d_token as u64) >= lp_coin_min_amount, errors::slippage());

    coin::from_balance(
      balance::increase_supply(
        &mut state.lp_coin_supply, 
        (d_token as u64)
      ), 
      ctx
    )
  }

  fun deposit_coin<CoinType, LpCoin>(state: &mut State<LpCoin>, coin_in: Coin<CoinType>) {
    let coin_value = (coin::value(&coin_in) as u256);

    if (coin_value == 0) {
      coin::destroy_zero(coin_in);
      return
    };

    let coin_state = load_mut_coin_state<CoinType>(&mut state.id);

    // Update the balance for the coin
    let current_balance = vector::borrow_mut(&mut state.balances, coin_state.index);
    *current_balance = *current_balance + fdiv(coin_value, coin_state.decimals);

    balance::join(load_mut_coin_balance(&mut state.id), coin::into_balance(coin_in));
  }

  fun add_state<LpCoin>(
    id: &mut UID,
    c: &Clock,
    coin_decimals: &CoinDecimals,   
    lp_coin_supply: Supply<LpCoin>,
    balances: vector<u256>,
    initial_a_gamma: vector<u256>,
    rebalancing_params: vector<u256>,
    fee_params: vector<u256>, 
    ctx: &mut TxContext
  ) {
    asserts::assert_supply_has_zero_value(&lp_coin_supply);
    assert!(vector::length(&rebalancing_params) == 3, errors::must_have_3_values());
    assert!(vector::length(&fee_params) == 3, errors::must_have_3_values());

    let n_coins = (vector::length(&balances) as u256);

    let pow_n_coins = (pow((n_coins as u64), (n_coins as u8)) as u256);
    let timestamp = clock::timestamp_ms(c);
    let (a, gamma) = vector_2_to_tuple(initial_a_gamma);
    let (extra_profit, adjustment_step, ma_half_time) = vector_3_to_tuple(rebalancing_params);
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
          ma_half_time,
          future_extra_profit: extra_profit,
          future_adjustment_step: adjustment_step,
          future_ma_half_time: ma_half_time
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
        max_a: 1000 * A_MULTIPLIER * pow_n_coins,
        not_adjusted: false
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

    df::add(id, CoinStateKey { type: coin_name }, CoinState {
      index,
      price,
      price_oracle: price,
      last_price: price,
      decimals: (get_decimals_scalar<CoinType>(coin_decimals) as u256),
      type: coin_name
    });
    df::add(id, CoinBalanceKey { type: coin_name }, balance::zero<CoinType>());    
    df::add(id, AdminCoinBalanceKey { type: coin_name }, balance::zero<CoinType>());
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

  fun tweak_prices<LpCoin>(
    state: &mut State<LpCoin>,
    coin_states: vector<CoinState>,
    timestamp: u64,
    a: u256, 
    gamma: u256, 
    balances: vector<u256>, 
    i: u64,
    p_i: u256,
    new_d: u256, 
    lp_supply: u256
  ) {

    let new_coin_states = coin_states;

    // Update Moving Average
    
    if (timestamp > state.last_prices_timestamp) {  
      let alpha = volatile_math::half_pow(fdiv(((timestamp - state.last_prices_timestamp) as u256), state.rebalancing_params.ma_half_time), 10000000000);

      // update prices (do not update the first one)
      let index = 1;

      while ((state.n_coins as u64) > index) {
        let coin_state = vector::borrow_mut(&mut new_coin_states, index);
        coin_state.price_oracle = (coin_state.last_price * (PRECISION - alpha) + coin_state.price_oracle * alpha) / PRECISION;

        index = index + 1;
      };
      state.last_prices_timestamp = timestamp;
    };

    let d_unadjusted = if (new_d == 0) volatile_math::invariant_(a, gamma, &balances) else new_d;
    
    if (p_i != 0) {
      if (i != 0) {
        let coin_state = vector::borrow_mut(&mut new_coin_states, i);
        coin_state.last_price = p_i;
        } else {
          // We do not change the first coin
          let i = 1;
          while ((state.n_coins as u64) > i) {
            let coin_state = vector::borrow_mut(&mut new_coin_states, i);
            coin_state.last_price = fdiv(coin_state.last_price, p_i);
            i = i + 1;
          };
        };
     } else {
      let xp = balances;
      let dx_price = *vector::borrow(&xp, 0) / 1000000;
      let ref = vector::borrow_mut(&mut xp, 0);
      *ref = *ref + dx_price;

      // We do nt change the first coin
      let i = 1;
      while ((state.n_coins as u64) > i) {
        let coin_state = vector::borrow_mut(&mut new_coin_states, i);
        coin_state.last_price = coin_state.price * dx_price / (*vector::borrow(&balances, i) - volatile_math::calculate_balance(a, gamma, &xp, d_unadjusted, (i as u256)));
        i = i + 1;
      };
     };

    let old_xcp_profit = state.xcp_profit;
    let old_virtual_price = state.virtual_price;
    let xp = vector[];
    vector::push_back(&mut xp, d_unadjusted / state.n_coins);

    // We do nt change the first coin
    let i = 1;
    while ((state.n_coins as u64) > i) {
      let coin_state = vector::borrow(&new_coin_states, i);
      vector::push_back(&mut xp, fdiv(d_unadjusted, state.n_coins * coin_state.price));
      i = i + 1;
    };

    let xcp_profit = PRECISION;
    let virtual_price = PRECISION;

    if (old_virtual_price != 0) {
      virtual_price = fdiv(volatile_math::geometric_mean(&xp, true), lp_supply);
      xcp_profit = old_xcp_profit * virtual_price / old_virtual_price;
      
      if (old_virtual_price > virtual_price && state.a_gamma.future_time == 0) abort errors::incurred_a_loss();
      if (state.a_gamma.future_time == 1) state.a_gamma.future_time = 0;
    };

    state.xcp_profit = xcp_profit;

    let needs_adjustment = state.not_adjusted;

    if (!needs_adjustment && (virtual_price * 2 - PRECISION > xcp_profit + 2 * state.rebalancing_params.extra_profit)) {
      needs_adjustment = true;
      state.not_adjusted = true;
    };

    if (needs_adjustment) {
      let adjustment_step = state.rebalancing_params.adjustment_step;
      let norm = 0;

      // We do nt change the first coin
      let i = 1;
      while ((state.n_coins as u64) > i) {
        let coin_state = vector::borrow(&new_coin_states, i);

        let ratio = diff(PRECISION, fdiv(coin_state.price_oracle, coin_state.price));
        norm = norm + math256::pow(ratio, 2);
        i = i + 1;
      };

      if (norm > math256::pow(adjustment_step, 2) && old_virtual_price != 0) {
        norm = volatile_math::sqrt(norm / PRECISION);

        let p_new = empty_vector(state.n_coins);
        let xp = balances;

        // We do nt change the first coin
        let i = 1;
        while ((state.n_coins as u64) > i) {
          let coin_state = vector::borrow(&new_coin_states, i);

          let value = vector::borrow_mut(&mut p_new, i);
          *value = (coin_state.price * (norm - adjustment_step) + adjustment_step * coin_state.price_oracle) / norm;

          let x = vector::borrow_mut(&mut xp, i);
          *x = *x + *value / coin_state.price;

          i = i + 1;
        };
        let d = volatile_math::invariant_(a, gamma, &xp);
        let x = vector::borrow_mut(&mut xp, 0);
        *x = d / state.n_coins;

        let i = 1;
        while ((state.n_coins as u64) > i) {
          let x = vector::borrow_mut(&mut xp, 0);
          *x = fmul(d, state.n_coins * *vector::borrow(&p_new, i));
          i = i + 1;
        };

        old_virtual_price = PRECISION * volatile_math::geometric_mean(&xp, true) / lp_supply;

        if (old_virtual_price > PRECISION && (2 * (old_virtual_price - PRECISION) > xcp_profit - PRECISION)) {
          state.d = d;
          state.virtual_price = old_virtual_price;
           let i = 1;
           while ((state.n_coins as u64) > i) {
            let coin_state = vector::borrow_mut(&mut new_coin_states, i);
            coin_state.price = *vector::borrow(&p_new, i);
           };
           update_coin_state_prices(state, new_coin_states);
          return
        } else {
          state.not_adjusted = false;
        };
      };
    };

    update_coin_state_prices(state, new_coin_states);
    state.d = d_unadjusted;
    state.virtual_price = virtual_price;
  }

  // * Utilities

  fun are_coins_ordered(pool: &Pool<Volatile>, coins: vector<TypeName>): bool {
    is_equal(&compare(&core::view_coins(pool), &coins))
  }

  fun get_xcp<LpCoin>(state: &State<LpCoin>, coins: vector<TypeName>, d: u256): u256 {
    let x = vector::singleton(d / state.n_coins);

    let index = 1;
    let len = vector::length(&coins);

    while (len > index) {
      let coin_state = load_coin_state_with_key(&state.id, *vector::borrow(&coins, index));
      vector::push_back(&mut x, fdiv(d, state.n_coins * coin_state.price));

      index = index + 1;
    };

    volatile_math::geometric_mean(&x, true)
  }

  fun fee<LpCoin>(state: &State<LpCoin>, balances: vector<u256>): u256 {
    let f = volatile_math::reduction_coefficient(&balances, state.fees.gamma_fee);
    (state.fees.mid_fee * f + state.fees.out_fee * (PRECISION - f)) / PRECISION
  }

  fun calculate_fee<LpCoin>(state: &State<LpCoin>, amounts: vector<u256>, balances: vector<u256>): u256 {
    let fee = mul_div_up(fee(state, balances), state.n_coins, 4 * (state.n_coins - 1)); 
    let s = sum(&amounts);
    let avg = s / state.n_coins;

    let index = 0;
    let s_diff = 0;
    while (state.n_coins > index) {
      let x = *vector::borrow(&amounts, (index as u64));
      s_diff = s_diff + diff(x, avg);

      index = index + 1;
    };

    fee * s_diff / s + NOISE_FEE
  }

  // * Load State Functions

  fun load<LpCoin>(pool: &mut Pool<Volatile>): (&mut State<LpCoin>, vector<CoinState>, vector<TypeName>) {

    let coins = core::view_coins(pool);    
    let state = load_mut_state<LpCoin>(core::borrow_mut_uid(pool));
    let coin_states = load_coin_state_vector_in_order(state, coins);
    (state, coin_states, coins)
  }

  fun update_coin_state_prices<LpCoin>(state: &mut State<LpCoin>, new_coin_states: vector<CoinState>) {
    let i = 0;
    while ((state.n_coins as u64) > i) {
      let new_state = vector::borrow(&new_coin_states, i);
      let current_state = load_mut_coin_state_with_key(&mut state.id, new_state.type);
      current_state.last_price = new_state.last_price;
      current_state.price = new_state.price;
      current_state.price_oracle = new_state.price_oracle;
      i = i + 1;
    };
  }

  fun load_coin_state_vector_in_order<LpCoin>(state: &State<LpCoin>, coins: vector<TypeName>): vector<CoinState> {
    let data = vector::empty();
    let i = 0;
    while ((state.n_coins as u64) > i) {
        let coin_key = *vector::borrow(&coins, i);
        vector::push_back(&mut data, *load_coin_state_with_key(&state.id, coin_key));
        i = i + 1;
    };
    data
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