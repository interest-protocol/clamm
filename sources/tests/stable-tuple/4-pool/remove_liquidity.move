// * 3 Pool - DAI - USDC - USDT - FRAX
#[test_only]
module amm::stable_tuple_4pool_remove_liquidity_tests { 
  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx};
  use sui::coin::{burn_for_testing as burn, mint_for_testing as mint};

  use amm::dai::DAI;
  use amm::usdt::USDT;
  use amm::usdc::USDC;
  use amm::frax::FRAX;
  use amm::stable_tuple;
  use amm::lp_coin::LP_COIN;
  use amm::curves::StableTuple;
  use amm::interest_pool::Pool;
  use amm::init_stable_tuple::setup_4pool;
  use amm::test_utils::{people, scenario, normalize_amount};

  const DAI_DECIMALS_SCALAR: u256 = 1000000000; 
  const USDC_DECIMALS_SCALAR: u256 = 1000000; 
  const USDT_DECIMALS_SCALAR: u256 = 1000000000; 
  const FRAX_DECIMALS_SCALAR: u256 = 1000000000; 
  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18

  #[test]
  fun remove_liquidity() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_4pool(test, 2100, 800, 900, 1000);

    next_tx(test, alice);    
    {
      let pool = test::take_shared<Pool<StableTuple>>(test);

      let (_, _, _, _, _, supply, _, _, _) = stable_tuple::view_state<LP_COIN>(&pool);

      let(coin_dai, coin_usdc, coin_usdt, coin_frax) = stable_tuple::remove_liquidity_4_pool<DAI, USDC, USDT, FRAX, LP_COIN>(
        &mut pool,
        mint<LP_COIN>(supply / 10, ctx(test)),
        vector[0, 0, 0, 0],
        ctx(test)
      );

      let (balances_2, _, _, _, _, supply_2, _, _, _) = stable_tuple::view_state<LP_COIN>(&pool);

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


      test::return_shared(pool);            
    };
    test::end(scenario); 
  }

  #[test]
  #[expected_failure(abort_code = 11)]  
  fun remove_liquidity_slippage() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_4pool(test, 2100, 800, 900, 1000);

    next_tx(test, alice);    
    {
      let pool = test::take_shared<Pool<StableTuple>>(test);

      let (_, _, _, _, _, supply, _, _, _) = stable_tuple::view_state<LP_COIN>(&pool);

       let expected_dai_amount = ((2100 * DAI_DECIMALS_SCALAR) * ((supply / 10) as u256) / (supply as u256) as u64);
      let expected_usdc_amount = ((800 * USDC_DECIMALS_SCALAR) * ((supply / 10) as u256) / (supply as u256) as u64);
      let expected_usdt_amount = ((900 * USDT_DECIMALS_SCALAR) * ((supply / 10) as u256) / (supply as u256) as u64);
      let expected_frax_amount = ((1000 * FRAX_DECIMALS_SCALAR) * ((supply / 10) as u256) / (supply as u256) as u64);

      let(coin_dai, coin_usdc, coin_usdt, coin_frax) = stable_tuple::remove_liquidity_4_pool<DAI, USDC, USDT, FRAX, LP_COIN>(
        &mut pool,
        mint<LP_COIN>(supply / 10, ctx(test)),
        vector[expected_dai_amount, expected_usdc_amount + 1, expected_usdt_amount, expected_frax_amount],
        ctx(test)
      );

      burn(coin_dai);
      burn(coin_usdc);
      burn(coin_usdt);
      burn(coin_frax);

      test::return_shared(pool);            
    };
    test::end(scenario); 
  }
}
