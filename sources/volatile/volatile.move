module amm::volatile {

  use sui::object::{Self, UID};
  use sui::balance::{Self, Supply, Balance};
  use sui::table::{Self, Table};

  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18
  const A_MULTIPLIER: u256 = 10000;
  const ADMIN_FEE: u256 = 5 * 1_000_000_000;
  const MIN_FEE: u256 = 5 * 100_000;
  const MAX_FEE: u256 = 10 * 1_000_000_000;
  const NOISE_FEE: u256 = 100_000;
  const MAX_A_CHANGE: u256 = 10;
  const MIN_GAMMA: u256 = 10_000_000_000;
  const MAX_GAMMA: u256 = 5 * 10_000_000_000_000_000;
  const MIN_RAMP_TIME: u256 = 86400000;

 struct CoinState<phantom CoinType> has store {
    decimals: u256,
    index: u64,
    balance: Balance<CoinType>
  }

  struct State<phantom LpCoin> has key, store {
    balances: vector<u256>,
    lp_coin_supply: Supply<LpCoin>,
    initial_a: u256,
    future_a: u256,
    initial_a_time: u256,
    future_a_time: u256,
    fee_percent: u256,
    n_coins: u64,
    price_scale_packed: u256,
    prince_oracle_packed: u256,
    last_prices_packed: u256,
    last_prices_timestamp: u256,
    initial_gamma: u256,
    future_gamma: u256,
    initial_gamma_time: u256,
    future_gamma_time: u256,
    xcp_profit: u256,
    xcp_profit_a: u256,
    virtual_price: u256,
    packed_rebalancing_params: u256,
    future_packed_rebalancing_params: u256,
    packed_fee_params: u256,
    future_packed_fee_params: u256,
    price_size: u128,
    price_mask: u256,
    min_a: u256,
    max_a: u256
  }


}