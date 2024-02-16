// * 2 Pool - USDC - ETH
// All values tested agaisnt Curve pool
#[test_only]
module clamm::volatile_admin_tests {
  use std::option;

  use sui::clock::{Self, Clock};
  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx};

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
  const ONE_WEEK: u256 = 7 * 86400000; // 1 week in milliseconds
  const MIN_RAMP_TIME: u64 = 86400000; // 1 day in milliseconds

  #[test]
  fun test_update_parameters() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    setup_2pool(test, 15000, 10);

    let c = clock::create_for_testing(ctx(test));

    next_tx(test, alice);
    { 
      let pool = test::take_shared<InterestPool<Volatile>>(test);
      let cap = test::take_from_sender<Admin>(test);

      let request = interest_clamm_volatile::balances_request<LP_COIN>(&pool);

      interest_clamm_volatile::read_balance<LP_COIN, USDC>(&pool, &mut request);
      interest_clamm_volatile::read_balance<LP_COIN, ETH>(&pool, &mut request);

      interest_clamm_volatile::update_parameters<LP_COIN>(
        &mut pool,
        &cap,
        &c,
        request,
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

      let request = interest_clamm_volatile::balances_request<LP_COIN>(&pool);

      interest_clamm_volatile::read_balance<LP_COIN, USDC>(&pool, &mut request);
      interest_clamm_volatile::read_balance<LP_COIN, ETH>(&pool, &mut request);      

      interest_clamm_volatile::update_parameters<LP_COIN>(
        &mut pool,
        &cap,
        &c,
        request,
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

    clock::destroy_for_testing(c);
    test::end(scenario);
  }

  #[test]
  fun test_ramp() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    setup_2pool(test, 15000, 10);

    let c = clock::create_for_testing(ctx(test));

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);
      let cap = test::take_from_sender<Admin>(test);

      let current_a = interest_clamm_volatile::a<LP_COIN>(&pool, &c);
      let current_gamma = interest_clamm_volatile::gamma<LP_COIN>(&pool, &c);

      clock::increment_for_testing(&mut c, MIN_RAMP_TIME);

      interest_clamm_volatile::ramp<LP_COIN>(
        &mut pool,
        &cap,
        &c,
        current_a + 300,
            current_gamma * 2,
            ((ONE_WEEK * 2) as u64)
      );

      assert_eq(interest_clamm_volatile::a<LP_COIN>(&pool, &c), current_a);
      assert_eq(interest_clamm_volatile::gamma<LP_COIN>(&pool, &c), current_gamma);
      assert_eq(interest_clamm_volatile::initial_time<LP_COIN>(&pool), MIN_RAMP_TIME);
      assert_eq(interest_clamm_volatile::future_a<LP_COIN>(&pool), current_a + 300);
      assert_eq(interest_clamm_volatile::future_gamma<LP_COIN>(&pool), current_gamma * 2);
      assert_eq(interest_clamm_volatile::future_time<LP_COIN>(&pool), ((ONE_WEEK * 2) as u64));

      clock::increment_for_testing(&mut c, (ONE_WEEK as u64));

      let (expected_a, expected_gamma) = calculate_a_gamma(
        &c, 
        current_a, 
        current_a + 300, 
        current_gamma, 
        current_gamma * 2, 
        86400000, 
        (ONE_WEEK * 2)
      );

      assert_eq(interest_clamm_volatile::a<LP_COIN>(&pool, &c), expected_a);
      assert_eq(interest_clamm_volatile::gamma<LP_COIN>(&pool, &c), expected_gamma);
      assert_eq(interest_clamm_volatile::initial_time<LP_COIN>(&pool), MIN_RAMP_TIME);
      assert_eq(interest_clamm_volatile::future_a<LP_COIN>(&pool), current_a + 300);
      assert_eq(interest_clamm_volatile::future_gamma<LP_COIN>(&pool), current_gamma * 2);
      assert_eq(interest_clamm_volatile::future_time<LP_COIN>(&pool), ((ONE_WEEK * 2) as u64));

      interest_clamm_volatile::stop_ramp<LP_COIN>(
        &mut pool,
        &cap,
        &c
      );      

      assert_eq(interest_clamm_volatile::a<LP_COIN>(&pool, &c), expected_a);
      assert_eq(interest_clamm_volatile::gamma<LP_COIN>(&pool, &c), expected_gamma);
      assert_eq(interest_clamm_volatile::initial_time<LP_COIN>(&pool), (ONE_WEEK as u64) + 86400000);
      assert_eq(interest_clamm_volatile::future_a<LP_COIN>(&pool), expected_a);
      assert_eq(interest_clamm_volatile::future_gamma<LP_COIN>(&pool), expected_gamma);
      assert_eq(interest_clamm_volatile::future_time<LP_COIN>(&pool), (ONE_WEEK as u64) + 86400000);      

      test::return_to_sender(test, cap);
      test::return_shared(pool);            
    };    

    clock::destroy_for_testing(c);
    test::end(scenario);
  }

  fun calculate_a_gamma(c: &Clock, a: u256, future_a: u256, gamma: u256, future_gamma: u256, t0: u256, t1: u256): (u256, u256) {
    let current_time = (clock::timestamp_ms(c) as u256);

    let gamma1 = future_gamma;
    let a1 = future_a;

    if (t1 > current_time) {

      t1 = t1 - t0;
      t0 = current_time - t0;
      let t2 = t1 - t0;

      a1 = (a * t2 + a1 * t0) / t1;
      gamma1 = (gamma * t2 + gamma1 * t0) / t1;
    };

    (a1, gamma1)
  }
}