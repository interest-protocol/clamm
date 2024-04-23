#[test_only]
module clamm::stable_hooks_tests {
  use std::string;
  use std::type_name;

  use sui::clock;
  use sui::coin::mint_for_testing as mint;
  use sui::test_utils::{destroy, assert_eq}; 
  use sui::balance::create_supply_for_testing;

  use suitears::coin_decimals::CoinDecimals;

  use clamm::eth::ETH;
  use clamm::dai::DAI;
  use clamm::frax::FRAX;
  use clamm::usdc::USDC;
  use clamm::usdt::USDT;
  use clamm::lp_coin::LP_COIN;
  use clamm::true_usd::TRUE_USD;
  use clamm::interest_clamm_stable;
  use clamm::interest_pool::{Self, HooksBuilder};
  use clamm::amm_test_utils ::{people, scenario, setup_dependencies}; 

  use fun string::utf8 as vector.utf8;

  public struct Witness has drop {}

  const INITIAL_A: u256 = 360;
  const DAI_DECIMALS_SCALAR: u64 = 1000000000; 
  const USDC_DECIMALS_SCALAR: u64 = 1000000; 
  const USDT_DECIMALS_SCALAR: u64 = 1000000000; 
  const FRAX_DECIMALS_SCALAR: u64 = 1000000000; 
  const TRUE_USD_DECIMALS_SCALAR: u64 = 1000000000; 

 #[test]
 fun test_swap_with_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;
   setup_dependencies(test);

   test.next_tx(alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(test.ctx());
    let c = clock::create_for_testing(test.ctx());
    let coin_decimals = test.take_shared<CoinDecimals>();

    add_rule(&mut hooks_builder, interest_pool::start_swap_name());
    add_rule(&mut hooks_builder, interest_pool::finish_swap_name()); 

    let (mut pool, pool_admin, lp_coin) = interest_clamm_stable::new_2_pool_with_hooks<USDC, ETH, LP_COIN>(
      &c,
      &coin_decimals,
      hooks_builder,
      mint(2, test.ctx()),
      mint(3, test.ctx()),
      create_supply_for_testing<LP_COIN>(),
      INITIAL_A,
      test.ctx()
    ); 

    let mut start_request = pool.start_swap();

    start_request.approve(Witness {});

    let (mut finish_request, coin_out) = interest_clamm_stable::swap_with_hooks<USDC, ETH, LP_COIN>(
      &mut pool,
      &c,
      start_request,
      mint(1, test.ctx()),
      0,
      test.ctx()
    );

    finish_request.approve(Witness {});

    pool.finish(finish_request);

    destroy(c);     
    destroy(pool);
    destroy(lp_coin); 
    destroy(coin_out);
    destroy(pool_admin);
    destroy(coin_decimals);
   };
   scenario.end();    
 }

 #[test]
 fun test_add_liquidity_2_pool_with_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;
   setup_dependencies(test);

   test.next_tx(alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(test.ctx());
    let c = clock::create_for_testing(test.ctx());
    let coin_decimals = test.take_shared<CoinDecimals>();

    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity_name()); 

    let (mut pool, pool_admin, lp_coin) = interest_clamm_stable::new_2_pool_with_hooks<USDC, ETH, LP_COIN>(
      &c,
      &coin_decimals,
      hooks_builder,
      mint(2, test.ctx()),
      mint(3, test.ctx()),
      create_supply_for_testing<LP_COIN>(),
      INITIAL_A,
      test.ctx()
    ); 

    let mut start_request = pool.start_add_liquidity();

    start_request.approve(Witness {});

    let (mut finish_request, coin_out) = interest_clamm_stable::add_liquidity_2_pool_with_hooks<USDC, ETH, LP_COIN>(
      &mut pool,
      &c,
      start_request,
      mint(1, test.ctx()),
      mint(2, test.ctx()),
      0,
      test.ctx()
    );

    finish_request.approve(Witness {});

    pool.finish(finish_request);

    assert_eq(pool.coins(), vector[type_name::get<USDC>(), type_name::get<ETH>()]);

    destroy(c);     
    destroy(pool);
    destroy(lp_coin); 
    destroy(coin_out);
    destroy(pool_admin);
    destroy(coin_decimals);
   };
   scenario.end();    
 }

 #[test]
 fun test_add_liquidity_3_pool_with_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;
   setup_dependencies(test);

   test.next_tx(alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(test.ctx());
    let c = clock::create_for_testing(test.ctx());
    let coin_decimals = test.take_shared<CoinDecimals>();

    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity_name()); 

    let (mut pool, pool_admin, lp_coin) = interest_clamm_stable::new_3_pool_with_hooks<USDC, ETH, USDT, LP_COIN>(
      &c,
      &coin_decimals,
      hooks_builder,
      mint(2, test.ctx()),
      mint(3, test.ctx()),
      mint(3, test.ctx()),
      create_supply_for_testing<LP_COIN>(),
      INITIAL_A,
      test.ctx()
    ); 

    let mut start_request = pool.start_add_liquidity();

    start_request.approve(Witness {});

    let (mut finish_request, coin_out) = interest_clamm_stable::add_liquidity_3_pool_with_hooks<USDC, ETH, USDT, LP_COIN>(
      &mut pool,
      &c,
      start_request,
      mint(1, test.ctx()),
      mint(2, test.ctx()),
      mint(3, test.ctx()),
      0,
      test.ctx()
    );

    finish_request.approve(Witness {});

    pool.finish(finish_request);

    assert_eq(pool.coins(), vector[type_name::get<USDC>(), type_name::get<ETH>(), type_name::get<USDT>()]);

    destroy(c);     
    destroy(pool);
    destroy(lp_coin); 
    destroy(coin_out);
    destroy(pool_admin);
    destroy(coin_decimals);
   };
   scenario.end();    
 }

 #[test]
 fun test_add_liquidity_4_pool_with_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;
   setup_dependencies(test);

   test.next_tx(alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(test.ctx());
    let c = clock::create_for_testing(test.ctx());
    let coin_decimals = test.take_shared<CoinDecimals>();

    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity_name()); 

    let (mut pool, pool_admin, lp_coin) = interest_clamm_stable::new_4_pool_with_hooks<USDC, ETH, USDT, DAI, LP_COIN>(
      &c,
      &coin_decimals,
      hooks_builder,
      mint(2, test.ctx()),
      mint(3, test.ctx()),
      mint(3, test.ctx()),
      mint(3, test.ctx()),
      create_supply_for_testing<LP_COIN>(),
      INITIAL_A,
      test.ctx()
    ); 

    let mut start_request = pool.start_add_liquidity();

    start_request.approve(Witness {});

    let (mut finish_request, coin_out) = interest_clamm_stable::add_liquidity_4_pool_with_hooks<USDC, ETH, USDT, DAI, LP_COIN>(
      &mut pool,
      &c,
      start_request,
      mint(1, test.ctx()),
      mint(2, test.ctx()),
      mint(3, test.ctx()),
      mint(4, test.ctx()),
      0,
      test.ctx()
    );

    finish_request.approve(Witness {});

    pool.finish(finish_request);

    assert_eq(pool.coins(), vector[type_name::get<USDC>(), type_name::get<ETH>(), type_name::get<USDT>(), type_name::get<DAI>()]);

    destroy(c);     
    destroy(pool);
    destroy(lp_coin); 
    destroy(coin_out);
    destroy(pool_admin);
    destroy(coin_decimals);
   };
   scenario.end();    
 }

 #[test]
 fun test_add_liquidity_5_pool_with_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;
   setup_dependencies(test);

   test.next_tx(alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(test.ctx());
    let c = clock::create_for_testing(test.ctx());
    let coin_decimals = test.take_shared<CoinDecimals>();

    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity_name()); 

    let (mut pool, pool_admin, lp_coin) = interest_clamm_stable::new_5_pool_with_hooks<USDC, ETH, USDT, DAI, FRAX, LP_COIN>(
      &c,
      &coin_decimals,
      hooks_builder,
      mint(2, test.ctx()),
      mint(3, test.ctx()),
      mint(3, test.ctx()),
      mint(3, test.ctx()),
      mint(3, test.ctx()),
      create_supply_for_testing<LP_COIN>(),
      INITIAL_A,
      test.ctx()
    ); 

    let mut start_request = pool.start_add_liquidity();

    start_request.approve(Witness {});

    let (mut finish_request, coin_out) = interest_clamm_stable::add_liquidity_5_pool_with_hooks<USDC, ETH, USDT, DAI, FRAX, LP_COIN>(
      &mut pool,
      &c,
      start_request,
      mint(1, test.ctx()),
      mint(2, test.ctx()),
      mint(3, test.ctx()),
      mint(4, test.ctx()),
      mint(5, test.ctx()),
      0,
      test.ctx()
    );

    finish_request.approve(Witness {});

    pool.finish(finish_request);

    assert_eq(pool.coins(), vector[type_name::get<USDC>(), type_name::get<ETH>(), type_name::get<USDT>(), type_name::get<DAI>(), type_name::get<FRAX>()]);

    destroy(c);     
    destroy(pool);
    destroy(lp_coin); 
    destroy(coin_out);
    destroy(pool_admin);
    destroy(coin_decimals);
   };
   scenario.end();    
 }

 #[test]
 fun test_donate_with_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;
   setup_dependencies(test);

   test.next_tx(alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(test.ctx());
    let c = clock::create_for_testing(test.ctx());
    let coin_decimals = test.take_shared<CoinDecimals>();

    add_rule(&mut hooks_builder, interest_pool::start_donate_name());
    add_rule(&mut hooks_builder, interest_pool::finish_donate_name()); 

    let (mut pool, pool_admin, lp_coin) = interest_clamm_stable::new_2_pool_with_hooks<USDC, ETH, LP_COIN>(
      &c,
      &coin_decimals,
      hooks_builder,
      mint(2, test.ctx()),
      mint(3, test.ctx()),
      create_supply_for_testing<LP_COIN>(),
      INITIAL_A,
      test.ctx()
    ); 

    let mut start_request = pool.start_donate();

    start_request.approve(Witness {});

    let mut finish_request = interest_clamm_stable::donate_with_hooks<USDC, LP_COIN>(
      &mut pool,
      start_request,
      mint(1, test.ctx()),
    );

    finish_request.approve(Witness {});

    pool.finish(finish_request);

    destroy(c);     
    destroy(pool);
    destroy(lp_coin); 
    destroy(pool_admin);
    destroy(coin_decimals);
   };
   scenario.end();    
 }

 #[test]
 fun test_remove_liquidity_2_pool_with_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;
   setup_dependencies(test);

   test.next_tx(alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(test.ctx());
    let c = clock::create_for_testing(test.ctx());
    let coin_decimals = test.take_shared<CoinDecimals>();

    add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_remove_liquidity_name()); 

    let (mut pool, pool_admin, lp_coin) = interest_clamm_stable::new_2_pool_with_hooks<USDC, ETH, LP_COIN>(
      &c,
      &coin_decimals,
      hooks_builder,
      mint(1000, test.ctx()),
      mint(1000, test.ctx()),
      create_supply_for_testing<LP_COIN>(),
      INITIAL_A,
      test.ctx()
    ); 

    let mut start_request = pool.start_remove_liquidity();

    start_request.approve(Witness {});

    let (mut finish_request, coin_a, coin_b) = interest_clamm_stable::remove_liquidity_2_pool_with_hooks<USDC, ETH, LP_COIN>(
      &mut pool,
      &c,
      start_request,
      mint<LP_COIN>(lp_coin.value() / 10, test.ctx()),
      vector[0, 0],
      test.ctx()
    );

    finish_request.approve(Witness {});

    pool.finish(finish_request);

    destroy(c);     
    destroy(pool);
    destroy(coin_a);
    destroy(coin_b);
    destroy(lp_coin); 
    destroy(pool_admin);
    destroy(coin_decimals);
   };
   scenario.end();    
 }

 #[test]
 fun test_remove_liquidity_3_pool_with_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;
   setup_dependencies(test);

   test.next_tx(alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(test.ctx());
    let c = clock::create_for_testing(test.ctx());
    let coin_decimals = test.take_shared<CoinDecimals>();

    add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_remove_liquidity_name()); 

    let (mut pool, pool_admin, lp_coin) = interest_clamm_stable::new_3_pool_with_hooks<USDC, ETH, USDT, LP_COIN>(
      &c,
      &coin_decimals,
      hooks_builder,
      mint(1000, test.ctx()),
      mint(1000, test.ctx()),
      mint(1000, test.ctx()),
      create_supply_for_testing<LP_COIN>(),
      INITIAL_A,
      test.ctx()
    ); 

    let mut start_request = pool.start_remove_liquidity();

    start_request.approve(Witness {});

    let (mut finish_request, coin_a, coin_b, coin_c) = interest_clamm_stable::remove_liquidity_3_pool_with_hooks<USDC, ETH, USDT, LP_COIN>(
      &mut pool,
      &c,
      start_request,
      mint<LP_COIN>(lp_coin.value() / 10, test.ctx()),
      vector[0, 0, 0],
      test.ctx()
    );

    finish_request.approve(Witness {});

    pool.finish(finish_request);

    destroy(c);     
    destroy(pool);
    destroy(coin_a);
    destroy(coin_b);
    destroy(coin_c);
    destroy(lp_coin); 
    destroy(pool_admin);
    destroy(coin_decimals);
   };
   scenario.end();    
 }

 #[test]
 fun test_remove_liquidity_4_pool_with_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;
   setup_dependencies(test);

   test.next_tx(alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(test.ctx());
    let c = clock::create_for_testing(test.ctx());
    let coin_decimals = test.take_shared<CoinDecimals>();

    add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_remove_liquidity_name()); 

    let (mut pool, pool_admin, lp_coin) = interest_clamm_stable::new_4_pool_with_hooks<USDC, ETH, USDT, FRAX, LP_COIN>(
      &c,
      &coin_decimals,
      hooks_builder,
      mint(1000, test.ctx()),
      mint(1000, test.ctx()),
      mint(1000, test.ctx()),
      mint(1000, test.ctx()),
      create_supply_for_testing<LP_COIN>(),
      INITIAL_A,
      test.ctx()
    ); 

    let mut start_request = pool.start_remove_liquidity();

    start_request.approve(Witness {});

    let (mut finish_request, coin_a, coin_b, coin_c, coin_d) = interest_clamm_stable::remove_liquidity_4_pool_with_hooks<USDC, ETH, USDT, FRAX, LP_COIN>(
      &mut pool,
      &c,
      start_request,
      mint<LP_COIN>(lp_coin.value() / 10, test.ctx()),
      vector[0, 0, 0, 0],
      test.ctx()
    );

    finish_request.approve(Witness {});

    pool.finish(finish_request);

    destroy(c);     
    destroy(pool);
    destroy(coin_a);
    destroy(coin_b);
    destroy(coin_c);
    destroy(coin_d);
    destroy(lp_coin); 
    destroy(pool_admin);
    destroy(coin_decimals);
   };
   scenario.end();    
 }

 #[test]
 fun test_remove_liquidity_5_pool_with_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;
   setup_dependencies(test);

   test.next_tx(alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(test.ctx());
    let c = clock::create_for_testing(test.ctx());
    let coin_decimals = test.take_shared<CoinDecimals>();

    add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_remove_liquidity_name()); 

    let (mut pool, pool_admin, lp_coin) = interest_clamm_stable::new_5_pool_with_hooks<USDC, TRUE_USD, USDT, FRAX, DAI, LP_COIN>(
      &c,
      &coin_decimals,
      hooks_builder,
      mint(1000 * USDC_DECIMALS_SCALAR, test.ctx()),
      mint(1000 * TRUE_USD_DECIMALS_SCALAR, test.ctx()),
      mint(1000 * USDT_DECIMALS_SCALAR, test.ctx()),
      mint(1000 * FRAX_DECIMALS_SCALAR, test.ctx()),
      mint(1000 * DAI_DECIMALS_SCALAR, test.ctx()),
      create_supply_for_testing<LP_COIN>(),
      INITIAL_A,
      test.ctx()
    ); 

    let mut start_request = pool.start_remove_liquidity();

    start_request.approve(Witness {});

    let (mut finish_request, coin_a, coin_b, coin_c, coin_d, coin_e) = interest_clamm_stable::remove_liquidity_5_pool_with_hooks<USDC, TRUE_USD, USDT, FRAX, DAI, LP_COIN>(
      &mut pool,
      &c,
      start_request,
      mint<LP_COIN>(lp_coin.value() / 10, test.ctx()),
      vector[0, 0, 0, 0, 0],
      test.ctx()
    );

    finish_request.approve(Witness {});

    pool.finish(finish_request);

    destroy(c);     
    destroy(pool);
    destroy(coin_a);
    destroy(coin_b);
    destroy(coin_c);
    destroy(coin_d);
    destroy(coin_e);
    destroy(lp_coin); 
    destroy(pool_admin);
    destroy(coin_decimals);
   };
   scenario.end();    
 }  

 #[test]
 fun test_remove_liquidity_one_coin_with_hooks() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;
   setup_dependencies(test);

   test.next_tx(alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(test.ctx());
    let c = clock::create_for_testing(test.ctx());
    let coin_decimals = test.take_shared<CoinDecimals>();

    add_rule(&mut hooks_builder, interest_pool::start_remove_liquidity_name());
    add_rule(&mut hooks_builder, interest_pool::finish_remove_liquidity_name()); 

    let (mut pool, pool_admin, lp_coin) = interest_clamm_stable::new_2_pool_with_hooks<USDC, ETH, LP_COIN>(
      &c,
      &coin_decimals,
      hooks_builder,
      mint(2, test.ctx()),
      mint(3, test.ctx()),
      create_supply_for_testing<LP_COIN>(),
      INITIAL_A,
      test.ctx()
    ); 

    let mut start_request = pool.start_remove_liquidity();

    start_request.approve(Witness {});

    let (mut finish_request, coin_out) = interest_clamm_stable::remove_liquidity_one_coin_with_hooks<USDC, LP_COIN>(
      &mut pool,
      &c,
      start_request,
      mint<LP_COIN>(lp_coin.value() / 10, test.ctx()),
      0, 
      test.ctx()
    ); 

    finish_request.approve(Witness {});

    pool.finish(finish_request);

    destroy(c);     
    destroy(pool);
    destroy(lp_coin); 
    destroy(coin_out);
    destroy(pool_admin);
    destroy(coin_decimals);
   };
   scenario.end();    
 }

 fun add_rule(hooks_builder: &mut HooksBuilder, name: vector<u8>) {
  hooks_builder.add_rule(name.utf8(), Witness {});
 }
}