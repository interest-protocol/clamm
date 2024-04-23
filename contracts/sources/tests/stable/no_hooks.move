#[test_only]
module clamm::stable_no_hooks_tests {

  use std::string;
  use std::type_name;

  use sui::clock;
  use sui::versioned;
  use sui::test_utils::destroy;
  use sui::test_scenario::{Self as test, next_tx, ctx};

  use clamm::utils;
  use clamm::dai::DAI;
  use clamm::frax::FRAX;
  use clamm::usdt::USDT;
  use clamm::usdc::USDC;
  use clamm::curves::Stable;
  use clamm::lp_coin::LP_COIN;
  use clamm::true_usd::TRUE_USD;
  use clamm::interest_clamm_stable;
  use clamm::interest_pool::{Self, HooksBuilder};
  use clamm::init_interest_amm_stable::setup_2pool;
  use clamm::amm_test_utils::{people, scenario, mint};

  use fun string::utf8 as vector.utf8;

  const DAI_DECIMALS: u8 = 9;
  const USDC_DECIMALS: u8 = 6; 
  const USDT_DECIMALS: u8 = 9;
  const FRAX_DECIMALS: u8 = 9;
  const TRUE_USD_DECIMALS: u8 = 9;
  const LP_COIN_DECIMALS: u8 = 9;

  public struct Witness has drop {}

 #[test]
 #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_SWAP_HOOKS, location = clamm::interest_clamm_stable)]
 fun test_swap_has_hook_error() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
     let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

     add_rule(&mut hooks_builder, interest_pool::start_swap_name());

     let (mut pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
      utils::make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<DAI>()]),
      versioned::create(0, 0, ctx(test)),
      hooks_builder,
      ctx(test)
     );

     let c = clock::create_for_testing(test.ctx());

     destroy(interest_clamm_stable::swap<DAI, USDC, LP_COIN>(
      &mut pool,
       &c,
       mint<DAI>(344, DAI_DECIMALS, ctx(test)),
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
 #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_ADD_LIQUIDITY_HOOKS, location = clamm::interest_clamm_stable)]
 fun test_add_liquidity_2_pool_has_hook_error() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
     let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

     add_rule(&mut hooks_builder, interest_pool::start_add_liquidity_name());

     let (mut pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
      utils::make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<DAI>()]),
      versioned::create(0, 0, ctx(test)),
      hooks_builder,
      ctx(test)
     );

     let c = clock::create_for_testing(test.ctx());

     destroy(interest_clamm_stable::add_liquidity_2_pool<USDC, DAI, LP_COIN>(
      &mut pool,
       &c,
       mint<USDC>(344, USDC_DECIMALS, ctx(test)),
       mint<DAI>(344, DAI_DECIMALS, ctx(test)),
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
 #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_ADD_LIQUIDITY_HOOKS, location = clamm::interest_clamm_stable)]
 fun test_add_liquidity_3_pool_has_hook_error() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
     let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

     add_rule(&mut hooks_builder, interest_pool::start_add_liquidity_name());

     let (mut pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
      utils::make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<DAI>()]),
      versioned::create(0, 0, ctx(test)),
      hooks_builder,
      ctx(test)
     );

     let c = clock::create_for_testing(test.ctx());

     destroy(interest_clamm_stable::add_liquidity_3_pool<USDC, DAI, USDT, LP_COIN>(
      &mut pool,
       &c,
       mint<USDC>(344, USDC_DECIMALS, ctx(test)),
       mint<DAI>(344, DAI_DECIMALS, ctx(test)),
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
 #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_ADD_LIQUIDITY_HOOKS, location = clamm::interest_clamm_stable)]
 fun test_add_liquidity_4_pool_has_hook_error() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
     let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

     add_rule(&mut hooks_builder, interest_pool::start_add_liquidity_name());

     let (mut pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
      utils::make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<DAI>()]),
      versioned::create(0, 0, ctx(test)),
      hooks_builder,
      ctx(test)
     );

     let c = clock::create_for_testing(test.ctx());

     destroy(interest_clamm_stable::add_liquidity_4_pool<USDC, DAI, USDT, FRAX, LP_COIN>(
      &mut pool,
       &c,
       mint<USDC>(344, USDC_DECIMALS, ctx(test)),
       mint<DAI>(344, DAI_DECIMALS, ctx(test)),
       mint<USDT>(344, USDT_DECIMALS, ctx(test)),
       mint<FRAX>(344, FRAX_DECIMALS, ctx(test)),
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
 #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_ADD_LIQUIDITY_HOOKS, location = clamm::interest_clamm_stable)]
 fun test_add_liquidity_5_pool_has_hook_error() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
     let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

     add_rule(&mut hooks_builder, interest_pool::start_add_liquidity_name());

     let (mut pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
      utils::make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<DAI>()]),
      versioned::create(0, 0, ctx(test)),
      hooks_builder,
      ctx(test)
     );

     let c = clock::create_for_testing(test.ctx());

     destroy(interest_clamm_stable::add_liquidity_5_pool<USDC, DAI, USDT, FRAX, TRUE_USD, LP_COIN>(
      &mut pool,
       &c,
       mint<USDC>(344, USDC_DECIMALS, ctx(test)),
       mint<DAI>(344, DAI_DECIMALS, ctx(test)),
       mint<USDT>(344, USDT_DECIMALS, ctx(test)),
       mint<FRAX>(344, FRAX_DECIMALS, ctx(test)),
       mint<TRUE_USD>(344, TRUE_USD_DECIMALS, ctx(test)),
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
 #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_DONATE_HOOKS, location = clamm::interest_clamm_stable)]
 fun test_donate_has_hook_error() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
     let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

     add_rule(&mut hooks_builder, interest_pool::start_donate_name());

     let (mut pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
      utils::make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<DAI>()]),
      versioned::create(0, 0, ctx(test)),
      hooks_builder,
      ctx(test)
     );

     let c = clock::create_for_testing(test.ctx());

     interest_clamm_stable::donate<USDC, LP_COIN>(
       &mut pool,
       mint<USDC>(344, USDC_DECIMALS, ctx(test)),
      );

      destroy(c);
      destroy(pool);
      destroy(pool_admin);
    };
    test::end(scenario); 
 }

 #[test]
 #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_REMOVE_LIQUIDITY_HOOKS, location = clamm::interest_clamm_stable)]
 fun test_remove_liquidity_2_pool_has_hook_error() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
     let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

     add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());

     let (mut pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
      utils::make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<DAI>()]),
      versioned::create(0, 0, ctx(test)),
      hooks_builder,
      ctx(test)
     );

     let c = clock::create_for_testing(test.ctx());
     let (coin_a, coin_b) = interest_clamm_stable::remove_liquidity_2_pool<USDC, DAI, LP_COIN>(
       &mut pool,
       &c,
       mint<LP_COIN>(344, LP_COIN_DECIMALS, ctx(test)),
       vector[0, 0],
       ctx(test)
      );

      destroy(c);
      destroy(coin_a);
      destroy(coin_b);
      destroy(pool);
      destroy(pool_admin);
    };
    test::end(scenario); 
 }

 #[test]
 #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_REMOVE_LIQUIDITY_HOOKS, location = clamm::interest_clamm_stable)]
 fun test_remove_liquidity_3_pool_has_hook_error() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
     let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

     add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());

     let (mut pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
      utils::make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<DAI>()]),
      versioned::create(0, 0, ctx(test)),
      hooks_builder,
      ctx(test)
     );

     let c = clock::create_for_testing(test.ctx());
     let (coin_a, coin_b, coin_c) = interest_clamm_stable::remove_liquidity_3_pool<USDC, DAI, USDT, LP_COIN>(
       &mut pool,
       &c,
       mint<LP_COIN>(344, LP_COIN_DECIMALS, ctx(test)),
       vector[0, 0, 0],
       ctx(test)
      );

      destroy(c);
      destroy(coin_a);
      destroy(coin_b);
      destroy(coin_c);
      destroy(pool);
      destroy(pool_admin);
    };
    test::end(scenario); 
 }

 #[test]
 #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_REMOVE_LIQUIDITY_HOOKS, location = clamm::interest_clamm_stable)]
 fun test_remove_liquidity_4_pool_has_hook_error() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
     let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

     add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());

     let (mut pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
      utils::make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<DAI>()]),
      versioned::create(0, 0, ctx(test)),
      hooks_builder,
      ctx(test)
     );

     let c = clock::create_for_testing(test.ctx());
     let (coin_a, coin_b, coin_c, coin_d) = interest_clamm_stable::remove_liquidity_4_pool<USDC, DAI, USDT, FRAX, LP_COIN>(
       &mut pool,
       &c,
       mint<LP_COIN>(344, LP_COIN_DECIMALS, ctx(test)),
       vector[0, 0, 0, 0],
       ctx(test)
      );

      destroy(c);
      destroy(coin_a);
      destroy(coin_b);
      destroy(coin_c);
      destroy(coin_d);
      destroy(pool);
      destroy(pool_admin);
    };
    test::end(scenario); 
 }

 #[test]
 #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_REMOVE_LIQUIDITY_HOOKS, location = clamm::interest_clamm_stable)]
 fun test_remove_liquidity_5_pool_has_hook_error() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
     let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

     add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());

     let (mut pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
      utils::make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<DAI>()]),
      versioned::create(0, 0, ctx(test)),
      hooks_builder,
      ctx(test)
     );

     let c = clock::create_for_testing(test.ctx());
     let (coin_a, coin_b, coin_c, coin_d, coin_e) = interest_clamm_stable::remove_liquidity_5_pool<USDC, DAI, USDT, FRAX, TRUE_USD, LP_COIN>(
       &mut pool,
       &c,
       mint<LP_COIN>(344, LP_COIN_DECIMALS, ctx(test)),
       vector[0, 0, 0, 0, 0],
       ctx(test)
      );

      destroy(c);
      destroy(coin_a);
      destroy(coin_b);
      destroy(coin_c);
      destroy(coin_d);
      destroy(coin_e);
      destroy(pool);
      destroy(pool_admin);
    };
    test::end(scenario); 
 }

 #[test]
 #[expected_failure(abort_code = clamm::errors::POOL_HAS_NO_REMOVE_LIQUIDITY_HOOKS, location = clamm::interest_clamm_stable)]
 fun test_remove_one_coin_liquidity_has_hook_error() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
     let mut hooks_builder = interest_pool::new_hooks_builder(ctx(test));

     add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());

     let (mut pool, pool_admin) = interest_pool::new_with_hooks<Stable>(
      utils::make_coins_vec_set_from_vector(vector[type_name::get<USDC>(), type_name::get<DAI>()]),
      versioned::create(0, 0, ctx(test)),
      hooks_builder,
      ctx(test)
     );

     let c = clock::create_for_testing(test.ctx());
     destroy(interest_clamm_stable::remove_liquidity_one_coin<USDC, LP_COIN>(
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