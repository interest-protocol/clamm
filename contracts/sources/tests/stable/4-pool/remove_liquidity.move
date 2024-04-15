// * 4 InterestPool - DAI - USDC - USDT - FRAX
#[test_only]
module clamm::stable_tuple_4pool_remove_liquidity_tests {
  use sui::clock; 
  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx};
  use sui::coin::{burn_for_testing as burn, mint_for_testing as mint};

  use clamm::dai::DAI;
  use clamm::frax::FRAX;
  use clamm::usdt::USDT;
  use clamm::usdc::USDC;
  use clamm::curves::Stable;
  use clamm::interest_clamm_stable;
  use clamm::lp_coin::LP_COIN;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_stable::setup_4pool;
  use clamm::amm_test_utils::{people, scenario, normalize_amount};

  const DAI_DECIMALS_SCALAR: u256 = 1000000000; 
  const USDC_DECIMALS_SCALAR: u256 = 1000000; 
  const USDT_DECIMALS_SCALAR: u256 = 1000000000; 
  const FRAX_DECIMALS_SCALAR: u256 = 1000000000; 
  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18

  #[test]
  fun remove_liquidity() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_4pool(test, 2100, 800, 900, 1000);

    next_tx(test, alice);    
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);

      let supply = interest_clamm_stable::lp_coin_supply<LP_COIN>(&mut pool);

      let c = clock::create_for_testing(ctx(test));

      let(coin_dai, coin_usdc, coin_usdt, coin_frax) = interest_clamm_stable::remove_liquidity_4_pool<DAI, USDC, USDT, FRAX, LP_COIN>(
        &mut pool,
        mint<LP_COIN>(supply / 10, ctx(test)),
        &c,
        vector[0, 0, 0, 0],
        ctx(test)
      );

      let balances_2 = interest_clamm_stable::balances<LP_COIN>(&mut pool);
      let supply_2 = interest_clamm_stable::lp_coin_supply<LP_COIN>(&mut pool);

      let expected_dai_amount = (2100 * DAI_DECIMALS_SCALAR) * ((supply / 10) as u256) / (supply as u256);
      let expected_usdc_amount = (800 * USDC_DECIMALS_SCALAR) * ((supply / 10) as u256) / (supply as u256);
      let expected_usdt_amount = (900 * USDT_DECIMALS_SCALAR) * ((supply / 10) as u256) / (supply as u256);
      let expected_frax_amount = (1000 * FRAX_DECIMALS_SCALAR) * ((supply / 10) as u256) / (supply as u256);

      let expected_balances = vector[
        normalize_amount(2100) - (expected_dai_amount * PRECISION / DAI_DECIMALS_SCALAR),
        normalize_amount(800) - (expected_usdc_amount * PRECISION / USDC_DECIMALS_SCALAR),
        normalize_amount(900) - (expected_usdt_amount * PRECISION / USDT_DECIMALS_SCALAR),
        normalize_amount(1000) - (expected_frax_amount * PRECISION / FRAX_DECIMALS_SCALAR)
      ];

      assert_eq(burn(coin_dai), (expected_dai_amount as u64));
      assert_eq(burn(coin_usdc), (expected_usdc_amount as u64));
      assert_eq(burn(coin_usdt), (expected_usdt_amount as u64));
      assert_eq(burn(coin_frax), (expected_frax_amount as u64));
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
    
    setup_4pool(test, 2100, 800, 900, 1000);

    next_tx(test, alice);    
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);

      let supply = interest_clamm_stable::lp_coin_supply<LP_COIN>(&mut pool);

      let expected_dai_amount = ((2100 * DAI_DECIMALS_SCALAR) * ((supply / 10) as u256) / (supply as u256) as u64);
      let expected_usdc_amount = ((800 * USDC_DECIMALS_SCALAR) * ((supply / 10) as u256) / (supply as u256) as u64);
      let expected_usdt_amount = ((900 * USDT_DECIMALS_SCALAR) * ((supply / 10) as u256) / (supply as u256) as u64);
      let expected_frax_amount = ((1000 * FRAX_DECIMALS_SCALAR) * ((supply / 10) as u256) / (supply as u256) as u64);

      let c = clock::create_for_testing(ctx(test));

      let(coin_dai, coin_usdc, coin_usdt, coin_frax) = interest_clamm_stable::remove_liquidity_4_pool<DAI, USDC, USDT, FRAX, LP_COIN>(
        &mut pool,
        mint<LP_COIN>(supply / 10, ctx(test)),
        &c,
        vector[expected_dai_amount, expected_usdc_amount + 1, expected_usdt_amount, expected_frax_amount],
        ctx(test)
      );

      burn(coin_dai);
      burn(coin_usdc);
      burn(coin_usdt);
      burn(coin_frax);

      clock::destroy_for_testing(c);

      test::return_shared(pool);            
    };
    test::end(scenario); 
  }
}
