// * 3 InterestPool - DAI - USDC - USDT
#[test_only]
module clamm::stable_ramp_tests {
  use sui::clock::{Self, Clock};
  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx};

  use clamm::curves::Stable;
  use clamm::lp_coin::LP_COIN;
  use clamm::interest_clamm_stable;
  use clamm::interest_pool::InterestPool;
  use clamm::pool_admin::{Self, PoolAdmin};
  use clamm::amm_test_utils::{people, scenario};
  use clamm::init_interest_amm_stable::setup_3pool;

  const MAX_A: u256 = 1000000; // 1 million
  const MAX_A_CHANGE: u256 = 10;
  const MIN_RAMP_TIME: u64 = 86400000; // 1 day in milliseconds

  #[test]
  fun ramp_logic() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let admin_cap = test::take_from_sender<PoolAdmin>(test);
      let mut c = test::take_shared<Clock>(test);

      let initial_a = interest_clamm_stable::initial_a<LP_COIN>(&mut pool);
      let initial_a_time = interest_clamm_stable::initial_a_time<LP_COIN>(&mut pool);

      let future_a_time = ((MIN_RAMP_TIME * 8) as u256);
      let future_a = 500;

      clock::set_for_testing(&mut c, MIN_RAMP_TIME + 1);
      
      interest_clamm_stable::ramp<LP_COIN>(&mut pool, &admin_cap, &c, 500, future_a_time);

      let after_update_initial_a = interest_clamm_stable::initial_a<LP_COIN>(&mut pool);
      let after_update_initial_a_time = interest_clamm_stable::initial_a_time<LP_COIN>(&mut pool);

      let after_update_future_a = interest_clamm_stable::future_a<LP_COIN>(&mut pool);
      let after_update_future_a_time = interest_clamm_stable::future_a_time<LP_COIN>(&mut pool);

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
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let mut c = test::take_shared<Clock>(test);
      
      clock::increment_for_testing(&mut c, MIN_RAMP_TIME * 2);

      let initial_a = interest_clamm_stable::initial_a<LP_COIN>(&mut pool);
      let initial_a_time = interest_clamm_stable::initial_a_time<LP_COIN>(&mut pool);

      let future_a = interest_clamm_stable::future_a<LP_COIN>(&mut pool);
      let future_a_time = interest_clamm_stable::future_a_time<LP_COIN>(&mut pool);

      let current_timestamp = MIN_RAMP_TIME + 1 + MIN_RAMP_TIME * 2;

      let amp = interest_clamm_stable::a<LP_COIN>(&mut pool, &c);

      // It is ramping up
      assert_eq(amp, initial_a + (future_a - initial_a) * ((current_timestamp as u256) - initial_a_time) / (future_a_time - initial_a_time));

      test::return_shared(c);
      test::return_shared(pool);
    };

    // Now we will ramp down
    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let admin_cap = test::take_from_sender<PoolAdmin>(test);
      let mut c = test::take_shared<Clock>(test);     

      clock::increment_for_testing(&mut c, MIN_RAMP_TIME);

      let future_a_time = MIN_RAMP_TIME * 10;

      interest_clamm_stable::ramp<LP_COIN>(&mut pool,&admin_cap, &c, 250, (future_a_time as u256));

      let current_timestamp = MIN_RAMP_TIME + 1 + MIN_RAMP_TIME * 3;

      let initial_a = interest_clamm_stable::initial_a<LP_COIN>(&mut pool);
      let initial_a_time = interest_clamm_stable::initial_a_time<LP_COIN>(&mut pool);

      let future_a = interest_clamm_stable::future_a<LP_COIN>(&mut pool);
      let future_a_time = interest_clamm_stable::future_a_time<LP_COIN>(&mut pool);

      let amp = interest_clamm_stable::a<LP_COIN>(&mut pool, &c);

      assert_eq(amp, initial_a - (initial_a - future_a) * ((current_timestamp as u256) - initial_a_time) / (future_a_time - initial_a_time));

      test::return_shared(c);
      test::return_to_sender(test, admin_cap);
      test::return_shared(pool);
    };

    // Now we will stop ramping
    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let admin_cap = test::take_from_sender<PoolAdmin>(test);
      let mut c = test::take_shared<Clock>(test);

      let amp = interest_clamm_stable::a<LP_COIN>(&mut pool, &c);

      let old_timestamp = ((MIN_RAMP_TIME + 1 + MIN_RAMP_TIME * 3) as u256);

      interest_clamm_stable::stop_ramp<LP_COIN>(&mut pool, &admin_cap, &c);

      // Does not matter if we increment
      clock::increment_for_testing(&mut c, MIN_RAMP_TIME);

      let initial_a = interest_clamm_stable::initial_a<LP_COIN>(&mut pool);
      let initial_a_time = interest_clamm_stable::initial_a_time<LP_COIN>(&mut pool);

      let future_a = interest_clamm_stable::future_a<LP_COIN>(&mut pool);
      let future_a_time = interest_clamm_stable::future_a_time<LP_COIN>(&mut pool);

      assert_eq(amp, interest_clamm_stable::a<LP_COIN>(&mut pool, &c));
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

  #[test]
  #[expected_failure(abort_code = clamm::errors::WAIT_ONE_DAY, location = clamm::interest_clamm_stable)]
  fun ramp_abort_too_early() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let admin_cap = test::take_from_sender<PoolAdmin>(test);
      let mut c = test::take_shared<Clock>(test);      

      // initial_a_time is at Zero - We need to wait more than 1 day

      // We only wait one day - so will throw
      clock::set_for_testing(&mut c, MIN_RAMP_TIME);

      interest_clamm_stable::ramp<LP_COIN>(&mut pool,&admin_cap, &c, 1, 1);

      test::return_shared(c);
      test::return_to_sender(test, admin_cap);
      test::return_shared(pool); 
    };    

    test::end(scenario); 
  }  


  #[test]
  #[expected_failure(abort_code = clamm::errors::FUTURE_TAMP_TIME_IS_TOO_SHORT, location = clamm::interest_clamm_stable)]
  fun ramp_future_time_too_short() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let admin_cap = test::take_from_sender<PoolAdmin>(test);
      let mut c = test::take_shared<Clock>(test);      

      clock::set_for_testing(&mut c, MIN_RAMP_TIME + 1);

      // Ramp time is too short
      interest_clamm_stable::ramp<LP_COIN>(&mut pool, &admin_cap, &c, 1, ((MIN_RAMP_TIME * 2) as u256) );

      test::return_shared(c);
      test::return_to_sender(test, admin_cap);
      test::return_shared(pool); 
    };    

    test::end(scenario); 
  } 

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_AMPLIFIER, location = clamm::interest_clamm_stable)]
  fun ramp_abort_zero_a() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let admin_cap = test::take_from_sender<PoolAdmin>(test);
      let mut c = test::take_shared<Clock>(test);      

      clock::set_for_testing(&mut c, MIN_RAMP_TIME + 1);

      // Ramp time is too short
      interest_clamm_stable::ramp<LP_COIN>(&mut pool, &admin_cap, &c, 0, ((MIN_RAMP_TIME * 2 + 1) as u256) );

      test::return_shared(c);
      test::return_to_sender(test, admin_cap);
      test::return_shared(pool); 
    };    

    test::end(scenario); 
  } 

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_AMPLIFIER, location = clamm::interest_clamm_stable)]
  fun ramp_abort_a_too_high() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let admin_cap = test::take_from_sender<PoolAdmin>(test);
      let mut c = test::take_shared<Clock>(test);      

      clock::set_for_testing(&mut c, MIN_RAMP_TIME + 1);

      // Ramp time is too short
      interest_clamm_stable::ramp<LP_COIN>(&mut pool, &admin_cap, &c, MAX_A, ((MIN_RAMP_TIME * 2 + 1) as u256) );

      test::return_shared(c);
      test::return_to_sender(test, admin_cap);
      test::return_shared(pool); 
    };    

    test::end(scenario); 
  } 

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_AMPLIFIER, location = clamm::interest_clamm_stable)]
  fun ramp_up_too_high() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let admin_cap = test::take_from_sender<PoolAdmin>(test);
      let mut c = test::take_shared<Clock>(test);      

      clock::set_for_testing(&mut c, MIN_RAMP_TIME + 1);

      // Ramp Up is too high
      interest_clamm_stable::ramp<LP_COIN>(&mut pool,&admin_cap,&c, 360 * MAX_A_CHANGE + 1, ((MIN_RAMP_TIME * 2 + 1) as u256) );

      test::return_shared(c);
      test::return_to_sender(test, admin_cap);
      test::return_shared(pool); 
    };    

    test::end(scenario); 
  } 

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_AMPLIFIER, location = clamm::interest_clamm_stable)]
  fun ramp_down_too_low() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let admin_cap = test::take_from_sender<PoolAdmin>(test);
      let mut c = test::take_shared<Clock>(test);      

      clock::set_for_testing(&mut c, MIN_RAMP_TIME + 1);

      // Ramp down is too low
      interest_clamm_stable::ramp<LP_COIN>(&mut pool,&admin_cap, &c, 360 / (MAX_A_CHANGE + 1), ((MIN_RAMP_TIME * 2 + 1) as u256) );

      test::return_shared(c);
      test::return_to_sender(test, admin_cap);
      test::return_shared(pool); 
    };    

    test::end(scenario); 
  } 

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_POOL_ADMIN, location = clamm::interest_pool)]
  fun ramp_invalid_admin() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let pool_admin_cap = pool_admin::new(test.ctx());
      let c = test::take_shared<Clock>(test);      

      // Ramp down is too low
      interest_clamm_stable::ramp<LP_COIN>(&mut pool,&pool_admin_cap, &c, 360 / (MAX_A_CHANGE + 1), ((MIN_RAMP_TIME * 2 + 1) as u256));

      pool_admin::destroy(pool_admin_cap);

      test::return_shared(c);
      test::return_shared(pool); 
    };    

    test::end(scenario); 
  }   

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_POOL_ADMIN, location = clamm::interest_pool)]
  fun stop_ramp_invalid_admin() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let pool_admin_cap = pool_admin::new(test.ctx());
      let c = test::take_shared<Clock>(test);      

      // Ramp down is too low
      interest_clamm_stable::stop_ramp<LP_COIN>(&mut pool, &pool_admin_cap, &c);

      pool_admin::destroy(pool_admin_cap);

      test::return_shared(c);
      test::return_shared(pool); 
    };    

    test::end(scenario); 
  }     
}