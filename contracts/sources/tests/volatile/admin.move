// * 2 Pool - USDC - ETH
// All values tested agaisnt Curve pool
#[test_only]
module clamm::volatile_admin_tests {
  use std::option;

  use sui::clock::Clock;
  use sui::test_utils::assert_eq;
  use sui::coin::{Self, burn_for_testing as burn, TreasuryCap};
  use sui::test_scenario::{Self as test, Scenario, next_tx, ctx};

  use suitears::coin_decimals::CoinDecimals;

  use clamm::btc::BTC;
  use clamm::eth::ETH;
  use clamm::usdc::USDC;
  use clamm::lp_coin::LP_COIN;
  use clamm::curves::Volatile;
  use clamm::amm_admin::Admin;
  use clamm::interest_clamm_volatile;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_volatile::setup_2pool;
  use clamm::amm_test_utils ::{people, scenario};

  const MIN_FEE: u256 = 5 * 100_000;
  const MAX_FEE: u256 = 10 * 1_000_000_000;
  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18
  const ONE_WEEK: u256 = 7 * 86400000; // 1 week in milliseconds

  #[test]
  fun test_ramp() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    setup_2pool(test, 15000, 10);

    next_tx(test, alice);
    { 
      let pool = test::take_shared<InterestPool<Volatile>>(test);
      let cap = test::take_from_sender<Admin>(test);

      interest_clamm_volatile::update_parameters<LP_COIN>(
        &mut pool,
        &cap,
        vector[
          option::some(MIN_FEE + 123),
          option::some(MIN_FEE + 1234),
          option::some(MIN_FEE + 12345),
          option::some(MIN_FEE + 123456),
          option::some(MIN_FEE + 1234567),
          option::some(MIN_FEE + 12345678),
          option::some(ONE_WEEK / 2)
        ]
      );

      assert_eq(interest_clamm_volatile::mid_fee<LP_COIN>(&pool), MIN_FEE + 123);
      assert_eq(interest_clamm_volatile::out_fee<LP_COIN>(&pool), MIN_FEE + 1234);
      assert_eq(interest_clamm_volatile::admin_fee<LP_COIN>(&pool), MIN_FEE + 12345);
      assert_eq(interest_clamm_volatile::gamma_fee<LP_COIN>(&pool), MIN_FEE + 123456);
      assert_eq(interest_clamm_volatile::extra_profit<LP_COIN>(&pool), MIN_FEE + 1234567);
      assert_eq(interest_clamm_volatile::adjustment_step<LP_COIN>(&pool), MIN_FEE + 12345678);
      assert_eq(interest_clamm_volatile::ma_half_time<LP_COIN>(&pool),ONE_WEEK / 2);

      test::return_to_sender(test, cap);
      test::return_shared(pool);
    };

    next_tx(test, alice);
    { 
      let pool = test::take_shared<InterestPool<Volatile>>(test);
      let cap = test::take_from_sender<Admin>(test);

      interest_clamm_volatile::update_parameters<LP_COIN>(
        &mut pool,
        &cap,
        vector[
          option::none(),
          option::none(),
          option::none(),
          option::none(),
          option::none(),
          option::none(),
          option::none(),
        ]
      );

      assert_eq(interest_clamm_volatile::mid_fee<LP_COIN>(&pool), MIN_FEE + 123);
      assert_eq(interest_clamm_volatile::out_fee<LP_COIN>(&pool), MIN_FEE + 1234);
      assert_eq(interest_clamm_volatile::admin_fee<LP_COIN>(&pool), MIN_FEE + 12345);
      assert_eq(interest_clamm_volatile::gamma_fee<LP_COIN>(&pool), MIN_FEE + 123456);
      assert_eq(interest_clamm_volatile::extra_profit<LP_COIN>(&pool), MIN_FEE + 1234567);
      assert_eq(interest_clamm_volatile::adjustment_step<LP_COIN>(&pool), MIN_FEE + 12345678);
      assert_eq(interest_clamm_volatile::ma_half_time<LP_COIN>(&pool),ONE_WEEK / 2);

      test::return_to_sender(test, cap);
      test::return_shared(pool);
    };
    test::end(scenario);
  }
}