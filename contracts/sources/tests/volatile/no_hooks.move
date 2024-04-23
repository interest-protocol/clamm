#[test_only]
module clamm::volatile_no_hooks_tests {

  use std::string;
  use std::type_name;

  use sui::clock;
  use sui::versioned;
  use sui::test_utils::destroy;
  use sui::test_scenario::{Self as test, next_tx, ctx};

  use clamm::utils;
  use clamm::eth::ETH;
  use clamm::usdt::USDT;
  use clamm::usdc::USDC;
  use clamm::curves::Volatile;
  use clamm::lp_coin::LP_COIN;
  use clamm::interest_clamm_volatile;
  use clamm::interest_pool::{Self, HooksBuilder};
  use clamm::init_interest_amm_stable::setup_2pool;
  use clamm::amm_test_utils::{people, scenario, mint};

  use fun string::utf8 as vector.utf8;

  const ETH_DECIMALS: u8 = 9;
  const USDC_DECIMALS: u8 = 6; 
  const USDT_DECIMALS: u8 = 9;
  const LP_COIN_DECIMALS: u8 = 9;

  public struct Witness has drop {}

 #[test]
 #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_SWAP_HOOKS, location = clamm::interest_clamm_volatile)]
 fun test_swap_has_hook_error() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
     let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

     add_rule(&mut hooks_builder, interest_pool::start_swap_name());

     let (mut pool, pool_admin) = interest_pool::new_with_hooks<Volatile>(
      utils::make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      hooks_builder,
      ctx(test)
     );

     let c = clock::create_for_testing(test.ctx());

     destroy(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
      &mut pool,
       &c,
       mint<ETH>(344, ETH_DECIMALS, ctx(test)),
       0,
       ctx(test)
      ));

      destroy(c);
      destroy(pool);
      destroy(pool_admin);
    };
    test::end(scenario); 
 }

 #[test]
 #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_ADD_LIQUIDITY_HOOKS, location = clamm::interest_clamm_volatile)]
 fun test_add_liquidity_2_pool_has_hook_error() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
     let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

     add_rule(&mut hooks_builder, interest_pool::start_add_liquidity_name());

     let (mut pool, pool_admin) = interest_pool::new_with_hooks<Volatile>(
      utils::make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      hooks_builder,
      ctx(test)
     );

     let c = clock::create_for_testing(test.ctx());

     destroy(interest_clamm_volatile::add_liquidity_2_pool<USDC, ETH, LP_COIN>(
      &mut pool,
       &c,
       mint<USDC>(344, USDC_DECIMALS, ctx(test)),
       mint<ETH>(344, ETH_DECIMALS, ctx(test)),
       0,
       ctx(test)
      ));

      destroy(c);
      destroy(pool);
      destroy(pool_admin);
    };
    test::end(scenario); 
 }

 #[test]
 #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_ADD_LIQUIDITY_HOOKS, location = clamm::interest_clamm_volatile)]
 fun test_add_liquidity_3_pool_has_hook_error() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
     let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

     add_rule(&mut hooks_builder, interest_pool::start_add_liquidity_name());

     let (mut pool, pool_admin) = interest_pool::new_with_hooks<Volatile>(
      utils::make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      hooks_builder,
      ctx(test)
     );

     let c = clock::create_for_testing(test.ctx());

     destroy(interest_clamm_volatile::add_liquidity_3_pool<USDC, ETH, USDT, LP_COIN>(
      &mut pool,
       &c,
       mint<USDC>(344, USDC_DECIMALS, ctx(test)),
       mint<ETH>(344, ETH_DECIMALS, ctx(test)),
       mint<USDT>(344, USDT_DECIMALS, ctx(test)),
       0,
       ctx(test)
      ));

      destroy(c);
      destroy(pool);
      destroy(pool_admin);
    };
    test::end(scenario); 
 }

 #[test]
 #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_DONATE_HOOKS, location = clamm::interest_clamm_volatile)]
 fun test_donate_has_hook_error() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
     let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

     add_rule(&mut hooks_builder, interest_pool::start_donate_name());

     let c = clock::create_for_testing(test.ctx());

     let (mut pool, pool_admin) = interest_pool::new_with_hooks<Volatile>(
      utils::make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      hooks_builder,
      ctx(test)
     );

     interest_clamm_volatile::donate<ETH, LP_COIN>(&mut pool, &c, mint<ETH>(344, ETH_DECIMALS, ctx(test)));

     destroy(pool);
     destroy(c);
     destroy(pool_admin);
    };
    test::end(scenario); 
 }

 #[test]
 #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_REMOVE_LIQUIDITY_HOOKS, location = clamm::interest_clamm_volatile)]
 fun test_remove_liquidity_2_pool_has_hook_error() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
     let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

     add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());

     let (mut pool, pool_admin) = interest_pool::new_with_hooks<Volatile>(
      utils::make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      hooks_builder,
      ctx(test)
     );

     let (coin_a, coin_b) = interest_clamm_volatile::remove_liquidity_2_pool<USDC, ETH, LP_COIN>(
       &mut pool,
       mint<LP_COIN>(344, LP_COIN_DECIMALS, ctx(test)),
       vector[0, 0],
       ctx(test)
      );

      destroy(coin_a);
      destroy(coin_b);
      destroy(pool);
      destroy(pool_admin);
    };
    test::end(scenario); 
 }

 #[test]
 #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_REMOVE_LIQUIDITY_HOOKS, location = clamm::interest_clamm_volatile)]
 fun test_remove_liquidity_3_pool_has_hook_error() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
     let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

     add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());

     let (mut pool, pool_admin) = interest_pool::new_with_hooks<Volatile>(
      utils::make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      hooks_builder,
      ctx(test)
     );

     let (coin_a, coin_b, coin_c) = interest_clamm_volatile::remove_liquidity_3_pool<USDC, ETH, USDT, LP_COIN>(
       &mut pool,
       mint<LP_COIN>(344, LP_COIN_DECIMALS, ctx(test)),
       vector[0, 0, 0],
       ctx(test)
      );

      destroy(coin_a);
      destroy(coin_b);
      destroy(coin_c);
      destroy(pool);
      destroy(pool_admin);
    };
    test::end(scenario); 
 }

 #[test]
 #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_REMOVE_LIQUIDITY_HOOKS, location = clamm::interest_clamm_volatile)]
 fun test_remove_liquidity_one_coin_has_hook_error() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
     let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

     add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());

     let (mut pool, pool_admin) = interest_pool::new_with_hooks<Volatile>(
      utils::make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<ETH>()]),
      versioned::create(0, 0, ctx(test)),
      hooks_builder,
      ctx(test)
     );

     let c = clock::create_for_testing(test.ctx());
     destroy(interest_clamm_volatile::remove_liquidity_one_coin<USDC, LP_COIN>(
       &mut pool,
       &c,
       mint<LP_COIN>(344, LP_COIN_DECIMALS, ctx(test)),
       0,
       ctx(test)
     ));

      destroy(c);
      destroy(pool);
      destroy(pool_admin);
    };
    test::end(scenario); 
 }

 fun add_rule(hooks_builder: &mut HooksBuilder, name: vector<u8>) {
  interest_pool::add_rule(hooks_builder, name.utf8(), Witness {});
 } 
}