module clamm::interest_pool_tests {

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx};

  use clamm::curves::Stable;
  use clamm::interest_pool::InterestPool;
  use clamm::pool_admin::{Self, PoolAdmin};
  use clamm::amm_test_utils::{people, scenario};
  use clamm::init_interest_amm_stable::setup_3pool;

  #[test]
  fun view_functions() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let pool_admin_cap = test::take_from_sender<PoolAdmin>(test);

      assert_eq(object::id(&pool).id_to_address(), pool.addy());
      assert_eq(pool_admin_cap.addy(), pool.pool_admin_address());
      // Will not throw
      pool.assert_pool_admin(&pool_admin_cap);
      // Will not throw
      pool.uid_mut(&pool_admin_cap);


      test::return_to_sender(test, pool_admin_cap);
      test::return_shared(pool);
    };
    test::end(scenario);      
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_POOL_ADMIN, location = clamm::interest_pool)]
  fun test_assert_pool_admin_error() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Stable>>(test);
      let wrong_admin_cap = pool_admin::new(test.ctx());

      pool.assert_pool_admin(&wrong_admin_cap);
      
      pool_admin::destroy(wrong_admin_cap);

      test::return_shared(pool);
    };
    test::end(scenario);      
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_POOL_ADMIN, location = clamm::interest_pool)]
  fun test_uid_mut_error() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let wrong_admin_cap = pool_admin::new(test.ctx());

      pool.uid_mut(&wrong_admin_cap);
      
      pool_admin::destroy(wrong_admin_cap);

      test::return_shared(pool);
    };
    test::end(scenario);      
  }

}