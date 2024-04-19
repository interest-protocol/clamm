#[test_only]
module clamm::hooks_tests {
  use std::string;
  use std::type_name;

  use sui::versioned;
  use sui::test_utils::destroy;
  use sui::test_scenario::{Self as test, next_tx, ctx}; 

  use clamm::hooks;
  use clamm::eth::ETH;
  use clamm::usdc::USDC;
  use clamm::curves::Stable;
  use clamm::amm_test_utils ::{people, scenario}; 
  use clamm::interest_pool::{Self, HooksBuilder};
  use clamm::utils::make_coins_vec_set_from_vector;

  use fun string::utf8 as vector.utf8;

  public struct Witness has drop {}

  #[test]
  #[expected_failure(abort_code = clamm::errors::THIS_POOL_HAS_NO_HOOKS, location = clamm::hooks)]
  fun test_start_swap_has_no_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity());    
    add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity());
    add_rule(&mut hooks_builder, interest_pool::finish_remove_liquidity());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    destroy(hooks::start_swap(&pool));

    pool.share();
    transfer::public_transfer(pool_admin, alice);
   };
  
   test::end(scenario);         
 }

 #[test]
 #[expected_failure(abort_code = clamm::errors::THIS_POOL_HAS_NO_HOOKS, location = clamm::hooks)] 
 fun test_finish_swap_has_no_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );    

    let request = hooks::start_add_liquidity(&pool);

    destroy(hooks::finish_swap(&pool, request));

    pool.share();
    transfer::public_transfer(pool_admin, alice);    
   };
   test::end(scenario); 
 }

 #[test]
 #[expected_failure(abort_code = clamm::errors::MUST_BE_START_SWAP_REQUEST, location = clamm::hooks)] 
 fun test_finish_swap_wrong_name() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_swap());
    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity());    
    add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity());
    add_rule(&mut hooks_builder, interest_pool::finish_remove_liquidity());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );    

    let request = hooks::start_add_liquidity(&pool);

    destroy(hooks::finish_swap(&pool, request));

    pool.share();
    transfer::public_transfer(pool_admin, alice);    
   };
   test::end(scenario); 
 }

  #[test]
  #[expected_failure(abort_code = clamm::errors::THIS_POOL_HAS_NO_HOOKS, location = clamm::hooks)]
  fun test_start_add_liquidity_has_no_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_swap());
    add_rule(&mut hooks_builder, interest_pool::finish_swap());
    add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity());
    add_rule(&mut hooks_builder, interest_pool::finish_remove_liquidity());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    destroy(hooks::start_add_liquidity(&pool));

    pool.share();
    transfer::public_transfer(pool_admin, alice);
   };
  
   test::end(scenario);         
 }

  #[test]
  #[expected_failure(abort_code = clamm::errors::THIS_POOL_HAS_NO_HOOKS, location = clamm::hooks)]
  fun test_finish_add_liquidity_has_no_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_swap());
    add_rule(&mut hooks_builder, interest_pool::finish_swap());
    add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity());
    add_rule(&mut hooks_builder, interest_pool::finish_remove_liquidity());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    let request = hooks::start_swap(&pool);

    destroy(hooks::finish_add_liquidity(&pool, request));

    pool.share();
    transfer::public_transfer(pool_admin, alice);
   };
  
   test::end(scenario);         
 } 

  #[test]
  #[expected_failure(abort_code = clamm::errors::MUST_BE_START_ADD_LIQUIDITY_REQUEST, location = clamm::hooks)]
  fun test_finish_add_liquidity_wrong_name() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_swap());
    add_rule(&mut hooks_builder, interest_pool::finish_swap());
    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity());    
    add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity());
    add_rule(&mut hooks_builder, interest_pool::finish_remove_liquidity());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    let request = hooks::start_remove_liquidity(&pool);

    destroy(hooks::finish_add_liquidity(&pool, request));

    pool.share();
    transfer::public_transfer(pool_admin, alice);
   };
  
   test::end(scenario);         
 }  

  #[test]
  #[expected_failure(abort_code = clamm::errors::THIS_POOL_HAS_NO_HOOKS, location = clamm::hooks)]
  fun test_start_remove_liquidity_has_no_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_swap());
    add_rule(&mut hooks_builder, interest_pool::finish_swap());
    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    destroy(hooks::start_remove_liquidity(&pool));

    pool.share();
    transfer::public_transfer(pool_admin, alice);
   };
  
   test::end(scenario);         
 } 

  #[test]
  #[expected_failure(abort_code = clamm::errors::THIS_POOL_HAS_NO_HOOKS, location = clamm::hooks)]
  fun test_finish_remove_liquidity_has_no_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

    add_rule(&mut hooks_builder, interest_pool::start_swap());
    add_rule(&mut hooks_builder, interest_pool::finish_swap());
    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    let request = hooks::start_swap(&pool);

    destroy(hooks::finish_remove_liquidity(&pool, request));

    pool.share();
    transfer::public_transfer(pool_admin, alice);
   };
  
   test::end(scenario);         
 } 

   #[test]
  #[expected_failure(abort_code = clamm::errors::MUST_BE_START_REMOVE_LIQUIDITY_REQUEST, location = clamm::hooks)]
  fun test_finish_remove_liquidity_wrong_name() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;

   next_tx(test, alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));
    
    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity());
    add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity());
    add_rule(&mut hooks_builder, interest_pool::finish_remove_liquidity());

    let (pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
     make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
     versioned::create(0, 0, ctx(test)),
     hooks_builder,
     ctx(test)
    );

    let request = hooks::start_add_liquidity(&pool);

    destroy(hooks::finish_remove_liquidity(&pool, request));

    pool.share();
    transfer::public_transfer(pool_admin, alice);
   };
  
   test::end(scenario);         
 } 

 fun add_rule(hooks_builder: &mut HooksBuilder, name: vector<u8>) {
  interest_pool::add_rule(hooks_builder, name.utf8(), Witness {});
 }
}