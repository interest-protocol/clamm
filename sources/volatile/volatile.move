module amm::volatile {
  use std::vector;
  use std::type_name::get;

  use sui::math::pow;
  use sui::object::{Self, UID};
  use sui::coin::{Self, Coin};
  use sui::dynamic_field as df;
  use sui::clock::{Self, Clock};
  use sui::table::{Self, Table};
  use sui::dynamic_object_field as dof;
  use sui::tx_context::{Self, TxContext};
  use sui::transfer::public_share_object;
  use sui::balance::{Self, Supply, Balance};

  use suitears::coin_decimals::{get_decimals_scalar, CoinDecimals};

  use amm::errors;
  use amm::asserts;
  use amm::curves::Volatile;
  use amm::utils::make_coins_from_vector;
  use amm::volatile_pack::{
    Self as pack, 
    PackedValues, 
    PackedPrices
  };
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

 struct StateKey has copy, store, drop {}

 struct CoinState<phantom CoinType> has store {
    decimals: u256,
    index: u64,
    balance: Balance<CoinType>
  }

  struct State<phantom LpCoin> has key, store {
    id: UID,
    lp_coin_supply: Supply<LpCoin>,
    lp_coin_decimals: u256,
    n_coins: u256,
    balances: vector<u256>,
    price_scale_packed: PackedPrices,
    prince_oracle_packed: PackedPrices,
    last_prices_packed: PackedPrices,
    last_prices_timestamp: u64,
    initial_a_gamma: u256,
    future_a_gamma: u256,
    initial_a_gamma_time: u64,
    future_a_gamma_time: u64,
    xcp_profit: u256,
    xcp_profit_a: u256,
    virtual_price: u256,
    packed_rebalancing_params: PackedValues,
    future_packed_rebalancing_params: PackedValues,
    packed_fee_params: PackedValues,
    future_packed_fee_params: PackedValues,
    min_a: u256,
    max_a: u256,
  }

  public fun new_2_pool<CoinA, CoinB, LpCoin>(
    c: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_decimals: &CoinDecimals,     
    lp_coin_supply: Supply<LpCoin>,
    initial_a_gamma: u256,
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
      2,
      initial_a_gamma,
      rebalancing_params,
      prices,
      fee_params,
      ctx
    );

    public_share_object(pool);
  }

  fun add_state<LpCoin>(
    id: &mut UID,
    c: &Clock,
    coin_decimals: &CoinDecimals,   
    lp_coin_supply: Supply<LpCoin>,
    n_coins: u256,
    initial_a_gamma: u256,
    rebalancing_params: vector<u256>,
    prices: vector<u256>,
    fee_params: vector<u256>, 
    ctx: &mut TxContext
  ) {
    asserts::assert_supply_has_zero_value(&lp_coin_supply);
    assert!((vector::length(&prices) as u256) == n_coins - 1, errors::wrong_configuration());
    assert!(vector::length(&rebalancing_params) == 3, errors::must_have_3_values());
    assert!(vector::length(&fee_params) == 3, errors::must_have_3_values());

    let packed_prices = pack::pack_prices(prices);
    let packed_rebalancing_params = pack::pack(rebalancing_params);
    let packed_fee_params = pack::pack(fee_params);

    let pow_n_coins = (pow((n_coins as u64), (n_coins as u8)) as u256);

    dof::add(id, StateKey {}, 
      State {
        id: object::new(ctx),
        lp_coin_supply,
        lp_coin_decimals: (get_decimals_scalar<LpCoin>(coin_decimals) as u256),
        n_coins,
        balances: vector[],
        price_scale_packed: packed_prices,
        prince_oracle_packed: packed_prices,
        last_prices_packed: packed_prices,
        last_prices_timestamp: clock::timestamp_ms(c),
        initial_a_gamma,
        future_a_gamma: initial_a_gamma,
        initial_a_gamma_time: 0,
        future_a_gamma_time: 0,
        xcp_profit: 0,
        xcp_profit_a: PRECISION,
        virtual_price: 0,
        packed_rebalancing_params: packed_rebalancing_params,
        future_packed_rebalancing_params: pack::make_empty_packed_values(),
        packed_fee_params: packed_fee_params,
        future_packed_fee_params: pack::make_empty_packed_values(),
        min_a: pow_n_coins  * A_MULTIPLIER / 100,
        max_a: 1000 * A_MULTIPLIER * pow_n_coins 
      }
    );
  }
}