#[test_only]
module clamm::hooks_tests {
  use std::string;
  use std::type_name;

  use sui::versioned;
  use sui::test_utils::destroy;
  use sui::test_scenario::{Self as test, next_tx, ctx}; 

  use clamm::eth::ETH;
  use clamm::usdc::USDC;
  use clamm::curves::Stable;
  use clamm::amm_test_utils ::{people, scenario}; 
  use clamm::interest_pool::{Self, HooksBuilder};
  use clamm::utils::make_coins_vec_set_from_vector;

  use fun string::utf8 as vector.utf8;

  public struct Witness has drop {}

  #[test]
  fun test_swap_hooks_flow() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_swap_name());
    add_rule(&mut hooks_builder, interest_pool::finish_swap_name()); 

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    let mut start_request = pool.start_swap();

    start_request.approve(Witness {});

    let mut finish_request = pool.finish_swap(start_request);

    finish_request.approve(Witness {});

    pool.finish(finish_request);

    destroy(pool);
    destroy(pool_admin);    
   };
   test::end(scenario);   
  }

  #[test]
  fun test_add_liquidity_hooks_flow() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity_name()); 

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    let mut start_request = pool.start_add_liquidity();

    start_request.approve(Witness {});

    let mut finish_request = pool.finish_add_liquidity(start_request);

    finish_request.approve(Witness {});

    pool.finish(finish_request);

    destroy(pool);
    destroy(pool_admin);    
   };
   test::end(scenario);   
  }

  #[test]
  fun test_donate_hooks_flow() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_donate_name());
    add_rule(&mut hooks_builder, interest_pool::finish_donate_name()); 

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    let mut start_request = pool.start_donate();

    start_request.approve(Witness {});

    let mut finish_request = pool.finish_donate(start_request);

    finish_request.approve(Witness {});

    pool.finish(finish_request);

    destroy(pool);
    destroy(pool_admin);    
   };
   test::end(scenario);   
  }

  #[test]
  fun test_remove_liquidity_hooks_flow() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_remove_liquidity_name()); 

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    let mut start_request = pool.start_remove_liquidity();

    start_request.approve(Witness {});

    let mut finish_request = pool.finish_remove_liquidity(start_request);

    finish_request.approve(Witness {});

    pool.finish(finish_request);

    destroy(pool);
    destroy(pool_admin);    
   };
   test::end(scenario);   
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_SWAP_HOOKS, location = clamm::interest_pool)]
  fun test_start_swap_has_no_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity_name());    
    add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_remove_liquidity_name());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    destroy(pool.start_swap());

    pool.share();
    transfer::public_transfer(pool_admin, alice);
   };
  
   test::end(scenario);         
 }

 #[test]
 #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_SWAP_HOOKS, location = clamm::interest_pool)] 
 fun test_finish_swap_has_no_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity_name());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );    

    let request = pool.start_add_liquidity();

    destroy(pool.finish_swap(request));

    pool.share();
    transfer::public_transfer(pool_admin, alice);    
   };
   test::end(scenario); 
 }

 #[test]
 #[expected_failure(abort_code = clamm::errors::MUST_BE_START_SWAP_REQUEST, location = clamm::interest_pool)] 
 fun test_finish_swap_wrong_name() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_swap_name());
    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity_name());    
    add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_remove_liquidity_name());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );    

    let request = pool.start_add_liquidity();

    destroy(pool.finish_swap(request));

    pool.share();
    transfer::public_transfer(pool_admin, alice);    
   };
   test::end(scenario); 
 }

  #[test]
  #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_ADD_LIQUIDITY_HOOKS, location = clamm::interest_pool)]
  fun test_start_add_liquidity_has_no_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_swap_name());
    add_rule(&mut hooks_builder, interest_pool::finish_swap_name());
    add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_remove_liquidity_name());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    destroy(pool.start_add_liquidity());

    pool.share();
    transfer::public_transfer(pool_admin, alice);
   };
  
   test::end(scenario);         
 }

  #[test]
  #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_ADD_LIQUIDITY_HOOKS, location = clamm::interest_pool)]
  fun test_finish_add_liquidity_has_no_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_swap_name());
    add_rule(&mut hooks_builder, interest_pool::finish_swap_name());
    add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_remove_liquidity_name());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    let request = pool.start_swap();

    destroy(pool.finish_add_liquidity(request));

    pool.share();
    transfer::public_transfer(pool_admin, alice);
   };
  
   test::end(scenario);         
 } 

  #[test]
  #[expected_failure(abort_code = clamm::errors::MUST_BE_START_ADD_LIQUIDITY_REQUEST, location = clamm::interest_pool)]
  fun test_finish_add_liquidity_wrong_name() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_swap_name());
    add_rule(&mut hooks_builder, interest_pool::finish_swap_name());
    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity_name());    
    add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_remove_liquidity_name());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    let request = pool.start_remove_liquidity();

    destroy(pool.finish_add_liquidity(request));

    pool.share();
    transfer::public_transfer(pool_admin, alice);
   };
  
   test::end(scenario);         
 }  

  #[test]
  #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_REMOVE_LIQUIDITY_HOOKS, location = clamm::interest_pool)]
  fun test_start_remove_liquidity_has_no_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_swap_name());
    add_rule(&mut hooks_builder, interest_pool::finish_swap_name());
    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity_name());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    destroy(pool.start_remove_liquidity());

    pool.share();
    transfer::public_transfer(pool_admin, alice);
   };
  
   test::end(scenario);         
 } 

  #[test]
  #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_REMOVE_LIQUIDITY_HOOKS, location = clamm::interest_pool)]
  fun test_finish_remove_liquidity_has_no_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_swap_name());
    add_rule(&mut hooks_builder, interest_pool::finish_swap_name());
    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity_name());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    let request = pool.start_swap();

    destroy(pool.finish_remove_liquidity(request));

    pool.share();
    transfer::public_transfer(pool_admin, alice);
   };
  
   test::end(scenario);         
 } 

  #[test]
  #[expected_failure(abort_code = clamm::errors::MUST_BE_START_REMOVE_LIQUIDITY_REQUEST, location = clamm::interest_pool)]
  fun test_finish_remove_liquidity_wrong_name() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));
    
    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_remove_liquidity_name());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    let request = pool.start_add_liquidity();

    destroy(pool.finish_remove_liquidity(request));

    pool.share();
    transfer::public_transfer(pool_admin, alice);
   };
  
   test::end(scenario);         
 } 

  #[test]
  #[expected_failure(abort_code = clamm::errors::MUST_BE_FINISH_REQUEST, location = clamm::interest_pool)]
  fun test_finish_start_swap_error() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_swap_name());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    let start_request = pool.start_swap();

    pool.finish(start_request);

    destroy(pool);
    destroy(pool_admin);    
   };
   test::end(scenario);   
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::MUST_BE_FINISH_REQUEST, location = clamm::interest_pool)]
  fun test_finish_start_add_liquidity_error() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity_name());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    let start_request = pool.start_add_liquidity();

    pool.finish(start_request);

    destroy(pool);
    destroy(pool_admin);    
   };
   test::end(scenario);   
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::MUST_BE_FINISH_REQUEST, location = clamm::interest_pool)]
  fun test_finish_start_donate_error() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_donate_name());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    let start_request = pool.start_donate();

    pool.finish(start_request);

    destroy(pool);
    destroy(pool_admin);    
   };
   test::end(scenario);   
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::MUST_BE_FINISH_REQUEST, location = clamm::interest_pool)]
  fun test_finish_start_remove_liquidity_error() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    let start_request = pool.start_remove_liquidity();

    pool.finish(start_request);

    destroy(pool);
    destroy(pool_admin);    
   };
   test::end(scenario);   
  }

 fun add_rule(hooks_builder: &mut HooksBuilder, name: vector<u8>) {
  interest_pool::add_rule(hooks_builder, name.utf8(), Witness {});
 }
}