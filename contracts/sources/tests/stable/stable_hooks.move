#[test_only]
module clamm::stable_hooks_tests {
  use std::string;
  use std::type_name;

  use sui::clock;
  use sui::coin::mint_for_testing as mint;
  use sui::test_utils::{destroy, assert_eq}; 
  use sui::balance::create_supply_for_testing;

  use suitears::coin_decimals::CoinDecimals;

  use clamm::hooks;
  use clamm::eth::ETH;
  use clamm::dai::DAI;
  use clamm::frax::FRAX;
  use clamm::usdc::USDC;
  use clamm::usdt::USDT;
  use clamm::lp_coin::LP_COIN;
  use clamm::interest_clamm_stable_hooks;
  use clamm::interest_pool::{Self, HooksBuilder};
  use clamm::amm_test_utils ::{people, scenario, setup_dependencies}; 

  use fun string::utf8 as vector.utf8;

  public struct Witness has drop {}

  const INITIAL_A: u256 = 360;

 #[test]
 fun test_swap() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;
   setup_dependencies(test);

   test.next_tx(alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(test.ctx());
    let c = clock::create_for_testing(test.ctx());
    let coin_decimals = test.take_shared<CoinDecimals>();

    add_rule(&mut hooks_builder, interest_pool::start_swap());
    add_rule(&mut hooks_builder, interest_pool::finish_swap()); 

    let (mut pool, pool_admin, lp_coin) = interest_clamm_stable_hooks::new_2_pool<USDC, ETH, LP_COIN>(
      &c,
      hooks_builder,
      INITIAL_A,
      mint(2, test.ctx()),
      mint(3, test.ctx()),
      &coin_decimals,
      create_supply_for_testing<LP_COIN>(),
      test.ctx()
    ); 

    let mut start_request = hooks::start_swap(&pool);

    start_request.approve(Witness {});

    let (mut finish_request, coin_out) = interest_clamm_stable_hooks::swap<USDC, ETH, LP_COIN>(
      &mut pool,
      start_request,
      &c,
      mint(1, test.ctx()),
      0,
      test.ctx()
    );

    finish_request.approve(Witness {});

    hooks::finish(&pool, finish_request);

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
 fun test_add_liquidity_2_pool() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;
   setup_dependencies(test);

   test.next_tx(alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(test.ctx());
    let c = clock::create_for_testing(test.ctx());
    let coin_decimals = test.take_shared<CoinDecimals>();

    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity()); 

    let (mut pool, pool_admin, lp_coin) = interest_clamm_stable_hooks::new_2_pool<USDC, ETH, LP_COIN>(
      &c,
      hooks_builder,
      INITIAL_A,
      mint(2, test.ctx()),
      mint(3, test.ctx()),
      &coin_decimals,
      create_supply_for_testing<LP_COIN>(),
      test.ctx()
    ); 

    let mut start_request = hooks::start_add_liquidity(&pool);

    start_request.approve(Witness {});

    let (mut finish_request, coin_out) = interest_clamm_stable_hooks::add_liquidity_2_pool<USDC, ETH, LP_COIN>(
      &mut pool,
      start_request,
      &c,
      mint(1, test.ctx()),
      mint(2, test.ctx()),
      0,
      test.ctx()
    );

    finish_request.approve(Witness {});

    hooks::finish(&pool, finish_request);

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
 fun test_add_liquidity_3_pool() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;
   setup_dependencies(test);

   test.next_tx(alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(test.ctx());
    let c = clock::create_for_testing(test.ctx());
    let coin_decimals = test.take_shared<CoinDecimals>();

    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity()); 

    let (mut pool, pool_admin, lp_coin) = interest_clamm_stable_hooks::new_3_pool<USDC, ETH, USDT, LP_COIN>(
      &c,
      hooks_builder,
      INITIAL_A,
      mint(2, test.ctx()),
      mint(3, test.ctx()),
      mint(3, test.ctx()),
      &coin_decimals,
      create_supply_for_testing<LP_COIN>(),
      test.ctx()
    ); 

    let mut start_request = hooks::start_add_liquidity(&pool);

    start_request.approve(Witness {});

    let (mut finish_request, coin_out) = interest_clamm_stable_hooks::add_liquidity_3_pool<USDC, ETH, USDT, LP_COIN>(
      &mut pool,
      start_request,
      &c,
      mint(1, test.ctx()),
      mint(2, test.ctx()),
      mint(3, test.ctx()),
      0,
      test.ctx()
    );

    finish_request.approve(Witness {});

    hooks::finish(&pool, finish_request);

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
 fun test_add_liquidity_4_pool() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;
   setup_dependencies(test);

   test.next_tx(alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(test.ctx());
    let c = clock::create_for_testing(test.ctx());
    let coin_decimals = test.take_shared<CoinDecimals>();

    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity()); 

    let (mut pool, pool_admin, lp_coin) = interest_clamm_stable_hooks::new_4_pool<USDC, ETH, USDT, DAI, LP_COIN>(
      &c,
      hooks_builder,
      INITIAL_A,
      mint(2, test.ctx()),
      mint(3, test.ctx()),
      mint(3, test.ctx()),
      mint(3, test.ctx()),
      &coin_decimals,
      create_supply_for_testing<LP_COIN>(),
      test.ctx()
    ); 

    let mut start_request = hooks::start_add_liquidity(&pool);

    start_request.approve(Witness {});

    let (mut finish_request, coin_out) = interest_clamm_stable_hooks::add_liquidity_4_pool<USDC, ETH, USDT, DAI, LP_COIN>(
      &mut pool,
      start_request,
      &c,
      mint(1, test.ctx()),
      mint(2, test.ctx()),
      mint(3, test.ctx()),
      mint(4, test.ctx()),
      0,
      test.ctx()
    );

    finish_request.approve(Witness {});

    hooks::finish(&pool, finish_request);

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
 fun test_add_liquidity_5_pool() {
   let mut scenario = scenario();
   let (alice, _) = people();

   let test = &mut scenario;
   setup_dependencies(test);

   test.next_tx(alice);
   {
    let mut hooks_builder = interest_pool::new_hooks_builder(test.ctx());
    let c = clock::create_for_testing(test.ctx());
    let coin_decimals = test.take_shared<CoinDecimals>();

    add_rule(&mut hooks_builder, interest_pool::start_add_liquidity());
    add_rule(&mut hooks_builder, interest_pool::finish_add_liquidity()); 

    let (mut pool, pool_admin, lp_coin) = interest_clamm_stable_hooks::new_5_pool<USDC, ETH, USDT, DAI, FRAX, LP_COIN>(
      &c,
      hooks_builder,
      INITIAL_A,
      mint(2, test.ctx()),
      mint(3, test.ctx()),
      mint(3, test.ctx()),
      mint(3, test.ctx()),
      mint(3, test.ctx()),
      &coin_decimals,
      create_supply_for_testing<LP_COIN>(),
      test.ctx()
    ); 

    let mut start_request = hooks::start_add_liquidity(&pool);

    start_request.approve(Witness {});

    let (mut finish_request, coin_out) = interest_clamm_stable_hooks::add_liquidity_5_pool<USDC, ETH, USDT, DAI, FRAX, LP_COIN>(
      &mut pool,
      start_request,
      &c,
      mint(1, test.ctx()),
      mint(2, test.ctx()),
      mint(3, test.ctx()),
      mint(4, test.ctx()),
      mint(5, test.ctx()),
      0,
      test.ctx()
    );

    finish_request.approve(Witness {});

    hooks::finish(&pool, finish_request);

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

 fun add_rule(hooks_builder: &mut HooksBuilder, name: vector<u8>) {
  interest_pool::add_rule(hooks_builder, name.utf8(), Witness {});
 }
}