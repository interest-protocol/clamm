// * 2 InterestPool - USDC - USDT
#[test_only]
module clamm::stable_tuple_2pool_remove_liquidity_tests { 
  use sui::clock;
  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx};
  use sui::coin::{burn_for_testing as burn, mint_for_testing as mint};

  use clamm::usdt::USDT;
  use clamm::usdc::USDC;
  use clamm::curves::Stable;
  use clamm::interest_clamm_stable;
  use clamm::lp_coin::LP_COIN;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_stable::setup_2pool;
  use clamm::amm_test_utils::{people, scenario, normalize_amount};

  const USDC_DECIMALS_SCALAR: u256 = 1000000; 
  const USDT_DECIMALS_SCALAR: u256 = 1000000000; 
  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18

  #[test]
  fun remove_liquidity() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 900, 1000);

    next_tx(test, alice);    
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);

      let supply = interest_clamm_stable::lp_coin_supply<LP_COIN>(&mut pool);
      
      let c = clock::create_for_testing(ctx(test));

      let(coin_usdc, coin_usdt) = interest_clamm_stable::remove_liquidity_2_pool<USDC, USDT, LP_COIN>(
        &mut pool,
        &c,
        mint<LP_COIN>(supply / 10, ctx(test)),
        vector[0, 0, 0],
        ctx(test)
      );

      let balances_2 = interest_clamm_stable::balances<LP_COIN>(&mut pool);
      let supply_2 = interest_clamm_stable::lp_coin_supply<LP_COIN>(&mut pool);

      let expected_usdc_amount = (900 * USDC_DECIMALS_SCALAR) * ((supply / 10) as u256) / (supply as u256);
      let expected_usdt_amount = (1000 * USDT_DECIMALS_SCALAR) * ((supply / 10) as u256) / (supply as u256);

      let expected_balances = vector[
        normalize_amount(900) - (expected_usdc_amount * PRECISION / USDC_DECIMALS_SCALAR),
        normalize_amount(1000) - (expected_usdt_amount * PRECISION / USDT_DECIMALS_SCALAR)
      ];

      assert_eq(burn(coin_usdc), (expected_usdc_amount as u64));
      assert_eq(burn(coin_usdt), (expected_usdt_amount as u64));
      assert_eq(supply, supply_2 + (supply / 10));
      assert_eq(expected_balances, balances_2);

      clock::destroy_for_testing(c);

      test::return_shared(pool);            
    };
    test::end(scenario); 
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::SLIPPAGE, location = clamm::interest_clamm_stable)]  
  fun remove_liquidity_slippage() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 900, 1000);

    next_tx(test, alice);    
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);

      let supply = interest_clamm_stable::lp_coin_supply<LP_COIN>(&mut pool);

      let expected_usdc_amount = ((900 * USDC_DECIMALS_SCALAR) * ((supply / 10) as u256) / (supply as u256) as u64);
      let expected_usdt_amount = ((1000 * USDT_DECIMALS_SCALAR) * ((supply / 10) as u256) / (supply as u256) as u64);

      let c = clock::create_for_testing(ctx(test));

      let(coin_usdc, coin_usdt) = interest_clamm_stable::remove_liquidity_2_pool<USDC, USDT, LP_COIN>(
        &mut pool,
        &c,
        mint<LP_COIN>(supply / 10, ctx(test)),
        vector[expected_usdc_amount, expected_usdt_amount + 1],
        ctx(test)
      );

      burn(coin_usdc);
      burn(coin_usdt);

      clock::destroy_for_testing(c);

      test::return_shared(pool);            
    };
    test::end(scenario); 
  }
}