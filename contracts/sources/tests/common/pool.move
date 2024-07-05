#[test_only]
module clamm::interest_pool_tests {

  use std::string;
  use std::type_name;

  use sui::versioned;
  use sui::test_utils::{assert_eq, destroy};
  use sui::test_scenario::{Self as test, next_tx, ctx};

  use clamm::eth::ETH;
  use clamm::usdc::USDC;
  use clamm::curves::Stable;
  use clamm::pool_admin::PoolAdmin;
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

  const START_DONATE: vector<u8> = b"START_DONATE";
  const FINISH_DONATE: vector<u8> = b"FINISH_DONATE";  

  public struct StartSwapWitness has drop {}
  public struct FinishSwapWitness has drop {}
  public struct StartAddLiquidityWitness has drop {}
  public struct FinishAddLiquidityWitness has drop {}
  public struct StartRemoveLiquidityWitness has drop {}
  public struct FinishRemoveLiquidityWitness has drop {}
  public struct StartDonateWitness has drop {}
  public struct FinishDonateWitness has drop {}  
  public struct Action has drop {}

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
      assert_eq(interest_pool::start_swap_name(), START_SWAP);
      assert_eq(interest_pool::finish_swap_name(), FINISH_SWAP);
      assert_eq(interest_pool::start_add_liquidity_name(), START_ADD_LIQUIDITY);
      assert_eq(interest_pool::finish_add_liquidity_name(), FINISH_ADD_LIQUIDITY);
      assert_eq(interest_pool::start_remove_liquidity_name(), START_REMOVE_LIQUIDITY);
      assert_eq(interest_pool::finish_remove_liquidity_name(), FINISH_REMOVE_LIQUIDITY);
      assert_eq(interest_pool::start_donate_name(), START_DONATE);
      assert_eq(interest_pool::finish_donate_name(), FINISH_DONATE);
      assert_eq(pool.paused(), false);

      // Will not throw
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
     let pool = interest_pool::new<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

     assert_eq(pool.are_coins_ordered(vector[type_name::get<USDC>(), type_name::get<ETH>()]), true);
     assert_eq(pool.are_coins_ordered(vector[type_name::get<ETH>(), type_name::get<USDC>()]), false);

     destroy(pool);
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
     let pool = interest_pool::new<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

     assert_eq(pool.has_hooks(), false);
     destroy(pool);
    };

    next_tx(test, alice);
    {
    let (mut pool, mut hooks_builder) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     ctx(test)
    );

    hooks_builder.add_rule(interest_pool::start_swap_name().utf8(), StartSwapWitness {});

    pool.add_hooks(hooks_builder);

     assert_eq(pool.has_hooks(), true);

     destroy(pool);
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
     let (mut pool, mut hooks_builder) = interest_pool::new_with_hooks<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

     hooks_builder.add_rule(interest_pool::start_add_liquidity_name().utf8(), StartAddLiquidityWitness {});
     
     pool.add_hooks(hooks_builder);
    

     assert_eq(pool.has_swap_hooks(), false);

     destroy(pool);
    };

    next_tx(test, alice);
    {
     let (mut pool, mut hooks_builder) = interest_pool::new_with_hooks<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

     hooks_builder.add_rule(interest_pool::start_swap_name().utf8(), StartSwapWitness {});
     
     pool.add_hooks(hooks_builder);

     assert_eq(pool.has_swap_hooks(), true);

     destroy(pool);
    };

    next_tx(test, alice);
    {
     let (mut pool, mut hooks_builder) = interest_pool::new_with_hooks<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

     hooks_builder.add_rule(interest_pool::finish_swap_name().utf8(), FinishSwapWitness {});

     pool.add_hooks(hooks_builder);

     assert_eq(pool.has_swap_hooks(), true);

     destroy(pool);
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
     let (mut pool, mut hooks_builder) = interest_pool::new_with_hooks<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

     hooks_builder.add_rule(interest_pool::start_add_liquidity_name().utf8(), StartAddLiquidityWitness {});

     pool.add_hooks(hooks_builder);

     assert_eq(pool.has_add_liquidity_hooks(), true);

     destroy(pool);
    };

    next_tx(test, alice);
    {
     let (mut pool, mut hooks_builder) = interest_pool::new_with_hooks<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

     hooks_builder.add_rule(interest_pool::finish_add_liquidity_name().utf8(), FinishAddLiquidityWitness {});

     pool.add_hooks(hooks_builder);

     assert_eq(pool.has_add_liquidity_hooks(), true);

     destroy(pool);
    };

    next_tx(test, alice);
    {
     let (mut pool, mut hooks_builder) = interest_pool::new_with_hooks<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );
     
     hooks_builder.add_rule(interest_pool::start_swap_name().utf8(), StartSwapWitness {});
    
     pool.add_hooks(hooks_builder);

     assert_eq(pool.has_add_liquidity_hooks(), false);

     destroy(pool);
    };

    test::end(scenario);      
  }

  #[test]
  fun test_has_donate_hooks() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    next_tx(test, alice);
    {
     let (mut pool, mut hooks_builder) = interest_pool::new_with_hooks<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

     hooks_builder.add_rule(interest_pool::start_donate_name().utf8(), StartDonateWitness {});
     
     pool.add_hooks(hooks_builder);

     assert_eq(pool.has_donate_hooks(), true);

     destroy(pool);
    };

    next_tx(test, alice);
    {
     let (mut pool, mut hooks_builder) = interest_pool::new_with_hooks<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

     hooks_builder.add_rule(interest_pool::finish_donate_name().utf8(), FinishDonateWitness {});

     pool.add_hooks(hooks_builder);

     assert_eq(pool.has_donate_hooks(), true);

     destroy(pool);
    };

    next_tx(test, alice);
    {
     let (mut pool, mut hooks_builder) = interest_pool::new_with_hooks<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

     hooks_builder.add_rule(interest_pool::start_swap_name().utf8(), StartSwapWitness {});

     pool.add_hooks(hooks_builder);

     assert_eq(pool.has_donate_hooks(), false);

     destroy(pool);
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
     let (mut pool, mut hooks_builder) = interest_pool::new_with_hooks<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

     hooks_builder.add_rule(interest_pool::start_remove_liquidity_name().utf8(), StartRemoveLiquidityWitness {});

     pool.add_hooks(hooks_builder);

     assert_eq(pool.has_remove_liquidity_hooks(), true);

     destroy(pool);
    };

    next_tx(test, alice);
    {
     let (mut pool, mut hooks_builder) = interest_pool::new_with_hooks<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

     hooks_builder.add_rule(interest_pool::finish_remove_liquidity_name().utf8(), FinishRemoveLiquidityWitness {});

     pool.add_hooks(hooks_builder);

     assert_eq(pool.has_remove_liquidity_hooks(), true);

     destroy(pool);
    };

    next_tx(test, alice);
    {
     let (mut pool, mut hooks_builder) = interest_pool::new_with_hooks<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

     hooks_builder.add_rule(interest_pool::start_swap_name().utf8(), StartSwapWitness {});

     pool.add_hooks(hooks_builder);

     assert_eq(pool.has_remove_liquidity_hooks(), false);

     destroy(pool);
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
     let (mut pool, mut hooks_builder) = interest_pool::new_with_hooks<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

    hooks_builder.add_rule(interest_pool::start_swap_name().utf8(), StartSwapWitness {});
    hooks_builder.add_rule(interest_pool::finish_swap_name().utf8(), FinishSwapWitness {});
    hooks_builder.add_rule(interest_pool::start_add_liquidity_name().utf8(), StartAddLiquidityWitness {});
    hooks_builder.add_rule(interest_pool::finish_add_liquidity_name().utf8(), FinishAddLiquidityWitness {});
    hooks_builder.add_rule(interest_pool::start_remove_liquidity_name().utf8(), StartRemoveLiquidityWitness {});
    hooks_builder.add_rule(interest_pool::finish_remove_liquidity_name().utf8(), FinishRemoveLiquidityWitness {});
    hooks_builder.add_rule(interest_pool::start_donate_name().utf8(), StartDonateWitness {});
    hooks_builder.add_rule(interest_pool::finish_donate_name().utf8(), FinishDonateWitness {});

    pool.add_hooks(hooks_builder);

     let (start_swap, finish_swap) = pool.swap_hooks();
     assert_eq(start_swap, vector[type_name::get<StartSwapWitness>()]);
     assert_eq(finish_swap, vector[type_name::get<FinishSwapWitness>()]);

     let (start_add_liquidity, finish_add_liquidity) = pool.add_liquidity_hooks();
     assert_eq(start_add_liquidity, vector[type_name::get<StartAddLiquidityWitness>()]);
     assert_eq(finish_add_liquidity, vector[type_name::get<FinishAddLiquidityWitness>()]);

     let (start_remove_liquidity, finish_remove_liquidity) = pool.remove_liquidity_hooks();
     assert_eq(start_remove_liquidity, vector[type_name::get<StartRemoveLiquidityWitness>()]);
     assert_eq(finish_remove_liquidity, vector[type_name::get<FinishRemoveLiquidityWitness>()]);

     let (start_donate, finish_donate) = pool.donate_hooks();
     assert_eq(start_donate, vector[type_name::get<StartDonateWitness>()]);
     assert_eq(finish_donate, vector[type_name::get<FinishDonateWitness>()]);

     destroy(pool);
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
     let (mut pool, mut hooks_builder) = interest_pool::new_with_hooks<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

     hooks_builder.add_rule(interest_pool::start_swap_name().utf8(), StartSwapWitness {});
     hooks_builder.add_rule_config<StartSwapWitness, u64>(StartSwapWitness {}, 0);

     pool.add_hooks(hooks_builder);

     assert_eq(pool.has_rule_config<Stable, StartSwapWitness>(), true);
     assert_eq(pool.has_rule_config<Stable, StartAddLiquidityWitness>(), false);

     assert_eq(*pool.config<Stable, StartSwapWitness, u64>(), 0); 

     let ref = pool.config_mut<Stable, StartSwapWitness, u64>(StartSwapWitness {});
     *ref = 1;

     assert_eq(*pool.config<Stable, StartSwapWitness, u64>(), 1); 


     destroy(pool);
    };

    test::end(scenario);  
  }

  #[test]
  fun test_request() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    next_tx(test, alice);
    {
     let (mut pool, mut hooks_builder) = interest_pool::new_with_hooks<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

     hooks_builder.add_rule(interest_pool::start_swap_name().utf8(), StartSwapWitness {});
     hooks_builder.add_rule(interest_pool::start_swap_name().utf8(), Action {});

     pool.add_hooks(hooks_builder);
     let mut request = pool.new_request(interest_pool::start_swap_name().utf8());

     request.approve(StartSwapWitness {});
     request.approve(Action {});

     pool.confirm_for_testing(request);

     destroy(pool);
    };

    test::end(scenario);      
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::RULE_NOT_APPROVED, location = clamm::interest_pool)]
  fun test_request_missing_approval() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    next_tx(test, alice);
    {
     let (mut pool, mut hooks_builder) = interest_pool::new_with_hooks<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

     hooks_builder.add_rule(interest_pool::start_swap_name().utf8(), StartSwapWitness {});
     hooks_builder.add_rule(interest_pool::start_swap_name().utf8(), Action {});

     pool.add_hooks(hooks_builder);

     let mut request = pool.new_request(interest_pool::start_swap_name().utf8());

     request.approve(StartSwapWitness {});

     pool.confirm_for_testing(request);

     destroy(pool);
    };

    test::end(scenario);      
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::WRONG_REQUEST_POOL_ADDRESS, location = clamm::interest_pool)]
  fun test_request_wrong_pool() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    next_tx(test, alice);
    {
    let (mut pool, mut hooks_builder) = interest_pool::new_with_hooks<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

     hooks_builder.add_rule(interest_pool::start_swap_name().utf8(), StartSwapWitness {});
     hooks_builder.add_rule(interest_pool::start_swap_name().utf8(), Action {});

     pool.add_hooks(hooks_builder);

    let (mut pool2, mut hooks_builder2) = interest_pool::new_with_hooks<Stable>(
      make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      ctx(test)
     );

     hooks_builder2.add_rule(interest_pool::start_swap_name().utf8(), StartSwapWitness {});
     hooks_builder2.add_rule(interest_pool::start_swap_name().utf8(), Action {});

     pool2.add_hooks(hooks_builder2);

     let mut request = pool.new_request(interest_pool::start_swap_name().utf8());

     request.approve(StartSwapWitness {});
     request.approve(Action {});

     pool2.confirm_for_testing(request);

     destroy(pool);
     destroy(pool2);    
    };

    test::end(scenario);      
  }

  #[test]
  fun test_pause_logic() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let pool_admin_cap = test::take_from_sender<PoolAdmin>(test);

      assert_eq(pool.paused(), false);
      
      pool.pause(&pool_admin_cap);

      assert_eq(pool.paused(), true);


      test::return_to_sender(test, pool_admin_cap);
      test::return_shared(pool);
    };
    test::end(scenario);   
  }
}