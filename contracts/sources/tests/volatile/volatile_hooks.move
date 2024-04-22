#[test_only]
module clamm::volatile_hooks_tests {
  use std::string;
  use std::type_name;

  use sui::clock;
  use sui::coin::mint_for_testing as mint;
  use sui::test_utils::{destroy, assert_eq}; 
  use sui::balance::create_supply_for_testing;

  use suitears::coin_decimals::CoinDecimals;

  use clamm::eth::ETH;
  use clamm::usdc::USDC;
  use clamm::frax::FRAX;
  use clamm::lp_coin::LP_COIN;
  use clamm::interest_clamm_volatile;
  use clamm::interest_pool::{Self, HooksBuilder};
  use clamm::amm_test_utils ::{people, scenario, setup_dependencies}; 

  use fun string::utf8 as vector.utf8;

  public struct Witness has drop {}

  const ETH_DECIMALS_SCALAR: u64 = 1_000_000_000; 
  const USDC_DECIMALS_SCALAR: u64 = 1_000_000; 
  const FRAX_DECIMALS_SCALAR: u64 = 1000000000; 
  const A: u256  = 36450000;
  const GAMMA: u256 = 70000000000000;
  const MID_FEE: u256 = 4000000;
  const OUT_FEE: u256 = 40000000;
  const ALLOWED_EXTRA_PROFIT: u256 = 2000000000000;
  const GAMMA_FEE: u256 = 10000000000000000;
  const ADJUSTMENT_STEP: u256 = 1500000000000000;
  const MA_TIME: u256 = 600_000; // 10 minutes
  const ETH_INITIAL_PRICE: u256 = 1500 * 1_000_000_000_000_000_000;
  const FRAX_INITIAL_PRICE: u256 = 1_000_000_000_000_000_000;

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

    let (mut pool, pool_admin, lp_coin) = interest_clamm_volatile::new_2_pool_with_hooks<USDC, ETH, LP_COIN>(
      &c,
      &coin_decimals,
      hooks_builder,
      mint(30_000 * USDC_DECIMALS_SCALAR, test.ctx()),
      mint(20 * ETH_DECIMALS_SCALAR, test.ctx()),
      create_supply_for_testing<LP_COIN>(),
      vector[A, GAMMA],
      vector[ALLOWED_EXTRA_PROFIT, ADJUSTMENT_STEP, MA_TIME],
      ETH_INITIAL_PRICE,
      vector[MID_FEE, OUT_FEE, GAMMA_FEE],
      test.ctx()
    ); 

    let mut start_request = pool.start_swap();

    start_request.approve(Witness {});

    let (mut finish_request, coin_out) = interest_clamm_volatile::swap_with_hooks<USDC, ETH, LP_COIN>(
      &mut pool,
      &c,
      start_request,
      mint(3 * USDC_DECIMALS_SCALAR, test.ctx()),
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

    let (mut pool, pool_admin, lp_coin) = interest_clamm_volatile::new_2_pool_with_hooks<USDC, ETH, LP_COIN>(
      &c,
      &coin_decimals,
      hooks_builder,
      mint(30_000 * USDC_DECIMALS_SCALAR, test.ctx()),
      mint(20 * ETH_DECIMALS_SCALAR, test.ctx()),
      create_supply_for_testing<LP_COIN>(),
      vector[A, GAMMA],
      vector[ALLOWED_EXTRA_PROFIT, ADJUSTMENT_STEP, MA_TIME],
      ETH_INITIAL_PRICE,
      vector[MID_FEE, OUT_FEE, GAMMA_FEE],
      test.ctx()
    ); 

    let mut start_request = pool.start_add_liquidity();

    start_request.approve(Witness {});

    let (mut finish_request, coin_out) = interest_clamm_volatile::add_liquidity_2_pool_with_hooks<USDC, ETH, LP_COIN>(
      &mut pool,
      &c,
      start_request,
      mint(2000, test.ctx()),
      mint(1, test.ctx()),
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

    let (mut pool, pool_admin, lp_coin) = interest_clamm_volatile::new_3_pool_with_hooks<USDC, FRAX, ETH, LP_COIN>(
      &c,
      &coin_decimals,
      hooks_builder,
      mint(30_000 * USDC_DECIMALS_SCALAR, test.ctx()),
      mint(30_000 * FRAX_DECIMALS_SCALAR, test.ctx()),
      mint(20 * ETH_DECIMALS_SCALAR, test.ctx()),
      create_supply_for_testing<LP_COIN>(),
      vector[A, GAMMA],
      vector[ALLOWED_EXTRA_PROFIT, ADJUSTMENT_STEP, MA_TIME],
      vector[FRAX_INITIAL_PRICE, ETH_INITIAL_PRICE],
      vector[MID_FEE, OUT_FEE, GAMMA_FEE],
      test.ctx()
    ); 

    let mut start_request = pool.start_add_liquidity();

    start_request.approve(Witness {});

    let (mut finish_request, coin_out) = interest_clamm_volatile::add_liquidity_3_pool_with_hooks<USDC, FRAX, ETH, LP_COIN>(
      &mut pool,
      &c,
      start_request,
      mint(2000, test.ctx()),
      mint(2000, test.ctx()),
      mint(1, test.ctx()),
      0,
      test.ctx()
    );

    finish_request.approve(Witness {});

    pool.finish(finish_request);

    assert_eq(pool.coins(), vector[type_name::get<USDC>(), type_name::get<FRAX>(), type_name::get<ETH>()]);

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

    let (mut pool, pool_admin, mut lp_coin) = interest_clamm_volatile::new_2_pool_with_hooks<USDC, ETH, LP_COIN>(
      &c,
      &coin_decimals,
      hooks_builder,
      mint(30_000 * USDC_DECIMALS_SCALAR, test.ctx()),
      mint(20 * ETH_DECIMALS_SCALAR, test.ctx()),
      create_supply_for_testing<LP_COIN>(),
      vector[A, GAMMA],
      vector[ALLOWED_EXTRA_PROFIT, ADJUSTMENT_STEP, MA_TIME],
      ETH_INITIAL_PRICE,
      vector[MID_FEE, OUT_FEE, GAMMA_FEE],
      test.ctx()
    ); 

    let mut start_request = pool.start_remove_liquidity();

    start_request.approve(Witness {});

    let value = lp_coin.value();

    let (mut finish_request, coin_a, coin_b) = interest_clamm_volatile::remove_liquidity_2_pool_with_hooks<USDC, ETH, LP_COIN>(
      &mut pool,
      start_request,
      lp_coin.split(value / 10, test.ctx()),
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

    let (mut pool, pool_admin, mut lp_coin) = interest_clamm_volatile::new_3_pool_with_hooks<USDC, FRAX, ETH, LP_COIN>(
      &c,
      &coin_decimals,
      hooks_builder,
      mint(30_000 * USDC_DECIMALS_SCALAR, test.ctx()),
      mint(30_000 * FRAX_DECIMALS_SCALAR, test.ctx()),
      mint(20 * ETH_DECIMALS_SCALAR, test.ctx()),
      create_supply_for_testing<LP_COIN>(),
      vector[A, GAMMA],
      vector[ALLOWED_EXTRA_PROFIT, ADJUSTMENT_STEP, MA_TIME],
      vector[FRAX_INITIAL_PRICE, ETH_INITIAL_PRICE],
      vector[MID_FEE, OUT_FEE, GAMMA_FEE],
      test.ctx()
    );

    let mut start_request = pool.start_remove_liquidity();

    start_request.approve(Witness {});

    let value = lp_coin.value();

    let (mut finish_request, coin_a, coin_b, coin_c) = interest_clamm_volatile::remove_liquidity_3_pool_with_hooks<USDC, FRAX, ETH, LP_COIN>(
      &mut pool,
      start_request,
      lp_coin.split(value / 10, test.ctx()),
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

    let (mut pool, pool_admin, mut lp_coin) = interest_clamm_volatile::new_2_pool_with_hooks<USDC, ETH, LP_COIN>(
      &c,
      &coin_decimals,
      hooks_builder,
      mint(30_000 * USDC_DECIMALS_SCALAR, test.ctx()),
      mint(20 * ETH_DECIMALS_SCALAR, test.ctx()),
      create_supply_for_testing<LP_COIN>(),
      vector[A, GAMMA],
      vector[ALLOWED_EXTRA_PROFIT, ADJUSTMENT_STEP, MA_TIME],
      ETH_INITIAL_PRICE,
      vector[MID_FEE, OUT_FEE, GAMMA_FEE],
      test.ctx()
    ); 

    let mut start_request = pool.start_remove_liquidity();

    start_request.approve(Witness {});

    let value = lp_coin.value();

    let (mut finish_request, coin_out) = interest_clamm_volatile::remove_liquidity_one_coin_with_hooks<ETH, LP_COIN>(
      &mut pool,
      &c,
      start_request,
      lp_coin.split(value / 10, test.ctx()),
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