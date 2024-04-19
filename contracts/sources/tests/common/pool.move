module clamm::interest_pool_tests {

  use std::string;
  use std::type_name;

  use sui::versioned;
  use sui::test_utils::{assert_eq, destroy};
  use sui::test_scenario::{Self as test, next_tx, ctx};

  use clamm::eth::ETH;
  use clamm::usdc::USDC;
  use clamm::curves::Stable;
  use clamm::pool_admin::{Self, PoolAdmin};
  use clamm::amm_test_utils::{people, scenario};
  use clamm::interest_pool::{Self, InterestPool};
  use clamm::init_interest_amm_stable::setup_3pool;
  use clamm::utils::make_coins_vec_set_from_vector;

  use fun string::utf8 as vector.utf8;

  const START_SWAP: vector<u8> = b"START_SWAP";
  const FINISH_SWAP: vector<u8> = b"FINISH_SWAP";
  
  const START_ADD_LIQUIDITY: vector<u8> = b"START_ADD_LIQUIDITY";
  const FINISH_ADD_LIQUIDITY: vector<u8> = b"FINISH_ADD_LIQUIDITY";

  const START_REMOVE_LIQUIDITY: vector<u8> = b"START_REMOVE_LIQUIDITY";
  const FINISH_REMOVE_LIQUIDITY: vector<u8> = b"FINISH_REMOVE_LIQUIDITY";

  public struct StartSwapWitness has drop {}
  public struct FinishSwapWitness has drop {}
  public struct StartAddLiquidityWitness has drop {}
  public struct FinishAddLiquidityWitness has drop {}
  public struct StartRemoveLiquidityWitness has drop {}
  public struct FinishRemoveLiquidityWitness has drop {}

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
      assert_eq(interest_pool::start_swap(), START_SWAP);
      assert_eq(interest_pool::finish_swap(), FINISH_SWAP);
      assert_eq(interest_pool::start_add_liquidity(), START_ADD_LIQUIDITY);
      assert_eq(interest_pool::finish_add_liquidity(), FINISH_ADD_LIQUIDITY);
      assert_eq(interest_pool::start_remove_liquidity(), START_REMOVE_LIQUIDITY);
      assert_eq(interest_pool::finish_remove_liquidity(), FINISH_REMOVE_LIQUIDITY);

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
  fun test_are_coins_ordered() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    next_tx(test, alice);
    {
     let (pool, pool_admin) = interest_pool::new<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

     assert_eq(pool.are_coins_ordered(vector[type_name::get<USDC>(), type_name::get<ETH>()]), true);
     assert_eq(pool.are_coins_ordered(vector[type_name::get<ETH>(), type_name::get<USDC>()]), false);

     destroy(pool);
     destroy(pool_admin);
    };
    test::end(scenario);      
  }

  #[test]
  fun test_has_hooks() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    next_tx(test, alice);
    {
     let (pool, pool_admin) = interest_pool::new<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

     assert_eq(pool.has_hooks(), false);

     destroy(pool);
     destroy(pool_admin);
    };

    next_tx(test, alice);
    {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    hooks_builder.add_rule(interest_pool::start_swap().utf8(), StartSwapWitness {});

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

     assert_eq(pool.has_hooks(), true);

     destroy(pool);
     destroy(pool_admin);
    };

    test::end(scenario);       
  }

  #[test]
  fun test_has_swap_hooks() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    next_tx(test, alice);
    {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    hooks_builder.add_rule(interest_pool::start_add_liquidity().utf8(), StartAddLiquidityWitness {});

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

     assert_eq(pool.has_swap_hooks(), false);

     destroy(pool);
     destroy(pool_admin);
    };

    next_tx(test, alice);
    {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    hooks_builder.add_rule(interest_pool::start_swap().utf8(), StartSwapWitness {});

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

     assert_eq(pool.has_swap_hooks(), true);

     destroy(pool);
     destroy(pool_admin);
    };

    next_tx(test, alice);
    {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    hooks_builder.add_rule(interest_pool::finish_swap().utf8(), FinishSwapWitness {});

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

     assert_eq(pool.has_swap_hooks(), true);

     destroy(pool);
     destroy(pool_admin);
    };

    test::end(scenario);      
  }

  #[test]
  fun test_has_add_liquidity_hooks() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    next_tx(test, alice);
    {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    hooks_builder.add_rule(interest_pool::start_add_liquidity().utf8(), StartAddLiquidityWitness {});

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

     assert_eq(pool.has_add_liquidity_hooks(), true);

     destroy(pool);
     destroy(pool_admin);
    };

    next_tx(test, alice);
    {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    hooks_builder.add_rule(interest_pool::finish_add_liquidity().utf8(), FinishAddLiquidityWitness {});

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

     assert_eq(pool.has_add_liquidity_hooks(), true);

     destroy(pool);
     destroy(pool_admin);
    };

    next_tx(test, alice);
    {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    hooks_builder.add_rule(interest_pool::start_swap().utf8(), StartSwapWitness {});

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

     assert_eq(pool.has_add_liquidity_hooks(), false);

     destroy(pool);
     destroy(pool_admin);
    };

    test::end(scenario);      
  }

  #[test]
  fun test_has_remove_liquidity_hooks() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    next_tx(test, alice);
    {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    hooks_builder.add_rule(interest_pool::start_remove_liquidity().utf8(), StartRemoveLiquidityWitness {});

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

     assert_eq(pool.has_remove_liquidity_hooks(), true);

     destroy(pool);
     destroy(pool_admin);
    };

    next_tx(test, alice);
    {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    hooks_builder.add_rule(interest_pool::finish_remove_liquidity().utf8(), FinishRemoveLiquidityWitness {});

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

     assert_eq(pool.has_remove_liquidity_hooks(), true);

     destroy(pool);
     destroy(pool_admin);
    };

    next_tx(test, alice);
    {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    hooks_builder.add_rule(interest_pool::start_swap().utf8(), StartSwapWitness {});

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

     assert_eq(pool.has_remove_liquidity_hooks(), false);

     destroy(pool);
     destroy(pool_admin);
    };

    test::end(scenario);      
  }

  #[test]
  fun test_read_hooks_data() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    next_tx(test, alice);
    {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    hooks_builder.add_rule(interest_pool::start_swap().utf8(), StartSwapWitness {});
    hooks_builder.add_rule(interest_pool::finish_swap().utf8(), FinishSwapWitness {});
    hooks_builder.add_rule(interest_pool::start_add_liquidity().utf8(), StartAddLiquidityWitness {});
    hooks_builder.add_rule(interest_pool::finish_add_liquidity().utf8(), FinishAddLiquidityWitness {});
    hooks_builder.add_rule(interest_pool::start_remove_liquidity().utf8(), StartRemoveLiquidityWitness {});
    hooks_builder.add_rule(interest_pool::finish_remove_liquidity().utf8(), FinishRemoveLiquidityWitness {});

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

     let (start_swap, finish_swap) = pool.swap_hooks();
     assert_eq(start_swap, vector[type_name::get<StartSwapWitness>()]);
     assert_eq(finish_swap, vector[type_name::get<FinishSwapWitness>()]);

     let (start_add_liquidity, finish_add_liquidity) = pool.add_liquidity_hooks();
     assert_eq(start_add_liquidity, vector[type_name::get<StartAddLiquidityWitness>()]);
     assert_eq(finish_add_liquidity, vector[type_name::get<FinishAddLiquidityWitness>()]);

     let (start_remove_liquidity, finish_remove_liquidity) = pool.remove_liquidity_hooks();
     assert_eq(start_remove_liquidity, vector[type_name::get<StartRemoveLiquidityWitness>()]);
     assert_eq(finish_remove_liquidity, vector[type_name::get<FinishRemoveLiquidityWitness>()]);

     destroy(pool);
     destroy(pool_admin);
    };

    test::end(scenario);  
  }

  #[test]
  fun test_rule_config() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    next_tx(test, alice);
    {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    hooks_builder.add_rule(interest_pool::start_swap().utf8(), StartSwapWitness {});
    hooks_builder.add_rule_config<StartSwapWitness, u64>(StartSwapWitness {}, 0);

    let (mut pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

     assert_eq(pool.has_rule_config<Stable, StartSwapWitness>(), true);
     assert_eq(pool.has_rule_config<Stable, StartAddLiquidityWitness>(), false);

     assert_eq(*pool.config<Stable, StartSwapWitness, u64>(), 0); 

     let ref = pool.config_mut<Stable, StartSwapWitness, u64>(StartSwapWitness {});
     *ref = 1;

     assert_eq(*pool.config<Stable, StartSwapWitness, u64>(), 1); 


     destroy(pool);
     destroy(pool_admin);
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