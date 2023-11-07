// * 3 Pool - DAI - USDC - USDT
#[test_only]
module amm::stable_tuple_ramp_tests {
  use sui::clock::{Self, Clock};
  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx};

  use amm::stable_tuple;
  use amm::amm_admin::Admin;
  use amm::lp_coin::LP_COIN;
  use amm::curves::StableTuple;
  use amm::interest_pool::Pool;
  use amm::test_utils::{people, scenario};
  use amm::init_stable_tuple::setup_3pool;

  const MAX_A: u256 = 1000000; // 1 million
  const MAX_A_CHANGE: u256 = 10;
  const MIN_RAMP_TIME: u64 = 86400000; // 1 day in milliseconds

  #[test]
  fun ramp_logic() {
   let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let pool = test::take_shared<Pool<StableTuple>>(test);
      let admin_cap = test::take_from_sender<Admin>(test);
      let c = test::take_shared<Clock>(test);

      let (_, initial_a, _, initial_a_time, _, _, _, _, _) = stable_tuple::view_state<LP_COIN>(&pool);

      let future_a_time = ((MIN_RAMP_TIME * 8) as u256);
      let future_a = 500;

      clock::set_for_testing(&mut c, MIN_RAMP_TIME + 1);
      
      stable_tuple::ramp<LP_COIN>(&admin_cap, &mut pool, &c, 500, future_a_time);


      let (_, after_update_initial_a, after_update_future_a, after_update_initial_a_time, after_update_future_a_time, _, _, _, _) = stable_tuple::view_state<LP_COIN>(&pool);

      // Initial state
      assert_eq(initial_a, 360);
      assert_eq(initial_a_time, 0);

      // After updating
      assert_eq(after_update_initial_a, 360);
      // We updated the clock time
      assert_eq(after_update_initial_a_time, (MIN_RAMP_TIME as u256) + 1);
      assert_eq(after_update_future_a, future_a);
      assert_eq(after_update_future_a_time, future_a_time);

      test::return_shared(c);
      test::return_to_sender(test, admin_cap);
      test::return_shared(pool);
    };

    next_tx(test, alice);
    {
      let pool = test::take_shared<Pool<StableTuple>>(test);
      let c = test::take_shared<Clock>(test);
      
      clock::increment_for_testing(&mut c, MIN_RAMP_TIME * 2);

      let (_, initial_a, future_a, initial_a_time, future_a_time, _, _, _, _) = stable_tuple::view_state<LP_COIN>(&pool);

      let current_timestamp = MIN_RAMP_TIME + 1 + MIN_RAMP_TIME * 2;

      let amp = stable_tuple::a<LP_COIN>(&pool, &c);

      // It is ramping up
      assert_eq(amp, initial_a + (future_a - initial_a) * ((current_timestamp as u256) - initial_a_time) / (future_a_time - initial_a_time));

      test::return_shared(c);
      test::return_shared(pool);
    };

    // Now we will ramp down
    next_tx(test, alice);
    {
      let pool = test::take_shared<Pool<StableTuple>>(test);
      let admin_cap = test::take_from_sender<Admin>(test);
      let c = test::take_shared<Clock>(test);     

      clock::increment_for_testing(&mut c, MIN_RAMP_TIME);

      let future_a_time = MIN_RAMP_TIME * 10;

      stable_tuple::ramp<LP_COIN>(&admin_cap, &mut pool, &c, 250, (future_a_time as u256));

      let current_timestamp = MIN_RAMP_TIME + 1 + MIN_RAMP_TIME * 3;

      let (_, initial_a, future_a, initial_a_time, future_a_time, _, _, _, _) = stable_tuple::view_state<LP_COIN>(&pool);

      let amp = stable_tuple::a<LP_COIN>(&pool, &c);

      assert_eq(amp, initial_a - (initial_a - future_a) * ((current_timestamp as u256) - initial_a_time) / (future_a_time - initial_a_time));

      test::return_shared(c);
      test::return_to_sender(test, admin_cap);
      test::return_shared(pool);
    };

    // Now we will stop ramping
    next_tx(test, alice);
    {
      let pool = test::take_shared<Pool<StableTuple>>(test);
      let admin_cap = test::take_from_sender<Admin>(test);
      let c = test::take_shared<Clock>(test);

      let amp = stable_tuple::a<LP_COIN>(&pool, &c);

      let old_timestamp = ((MIN_RAMP_TIME + 1 + MIN_RAMP_TIME * 3) as u256);

      stable_tuple::stop_ramp<LP_COIN>(&admin_cap, &mut pool, &c);

      // Does not matter if we increment
      clock::increment_for_testing(&mut c, MIN_RAMP_TIME);

      let (_, initial_a, future_a, initial_a_time, future_a_time, _, _, _, _) = stable_tuple::view_state<LP_COIN>(&pool);

      assert_eq(amp, stable_tuple::a<LP_COIN>(&pool, &c));
      assert_eq(initial_a, amp);
      assert_eq(future_a, amp);
      assert_eq(initial_a_time, old_timestamp);
      assert_eq(future_a_time, old_timestamp);

      test::return_shared(c);
      test::return_to_sender(test, admin_cap);
      test::return_shared(pool);
    };
    

    test::end(scenario);      
  }
}