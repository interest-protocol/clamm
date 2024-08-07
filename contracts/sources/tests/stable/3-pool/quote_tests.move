// * 3 InterestPool - DAI - USDC - USDT
#[test_only]
module clamm::stable_3pool_quote_tests {

  use sui::clock::{Self, Clock};
  use sui::test_utils::assert_eq;
  use sui::coin::{burn_for_testing as burn, mint_for_testing};
  use sui::test_scenario::{Self as test, next_tx, ctx};

  use clamm::dai::DAI;
  use clamm::usdt::USDT;
  use clamm::usdc::USDC;
  use clamm::curves::Stable;
  use clamm::interest_clamm_stable;
  use clamm::lp_coin::LP_COIN;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_stable::setup_3pool;
  use clamm::amm_test_utils::{people, scenario, add_decimals, mint};

  const USDC_DECIMALS: u8 = 6; 
  const USDT_DECIMALS: u8 = 9;
  const DAI_DECIMALS: u8 = 9;

  #[test]
  fun test_quote_swap() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test); 

      let (expected_value, _) = interest_clamm_stable::quote_swap<USDT, USDC, LP_COIN>(
        &mut pool,
        &c,
        add_decimals(55, USDT_DECIMALS)       
      );

      let coin_usdc = interest_clamm_stable::swap<USDT, USDC, LP_COIN>(
        &mut pool,
        &c,
        mint<USDT>(55, USDT_DECIMALS, ctx(test)),
        0,
        ctx(test)
      );

      assert_eq(burn(coin_usdc), expected_value);

      test::return_shared(c);
      test::return_shared(pool);
    };
    test::end(scenario); 
  }

  #[test]
  fun test_quote_add_liquidity() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test); 

      let expected_value = interest_clamm_stable::quote_add_liquidity<LP_COIN>(&mut pool, &c, vector[add_decimals(110, DAI_DECIMALS), add_decimals(120, USDC_DECIMALS), add_decimals(140, USDT_DECIMALS)]);

      let lp_coin = interest_clamm_stable::add_liquidity_3_pool<DAI, USDC, USDT, LP_COIN>(
        &mut pool,
        &c,
        mint<DAI>(110, DAI_DECIMALS, ctx(test)),
        mint<USDC>(120, USDC_DECIMALS, ctx(test)),
        mint<USDT>(140, USDT_DECIMALS, ctx(test)),
        0,
        ctx(test)
      );

      assert_eq(burn(lp_coin), expected_value);

      test::return_shared(c);
      test::return_shared(pool);
    };
    test::end(scenario);      
  }

  #[test]
  fun test_quote_remove_liquidity() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);    
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);

      let supply = interest_clamm_stable::lp_coin_supply<LP_COIN>(&mut pool);
      
      let c = clock::create_for_testing(ctx(test));

      let amounts = interest_clamm_stable::quote_remove_liquidity<LP_COIN>(&mut pool, supply / 10);

      let(coin_dai, coin_usdc, coin_usdt) = interest_clamm_stable::remove_liquidity_3_pool<DAI, USDC, USDT, LP_COIN>(
        &mut pool,
        &c,
        mint_for_testing<LP_COIN>(supply / 10, ctx(test)),
        vector[0, 0, 0],
        ctx(test)
      );

      assert_eq(burn(coin_dai), amounts[0]);
      assert_eq(burn(coin_usdc), amounts[1]);
      assert_eq(burn(coin_usdt), amounts[2]);

      clock::destroy_for_testing(c);

      test::return_shared(pool);            
    };
    test::end(scenario); 
  }  

  #[test]
  fun test_quote_remove_liquidity_one_coin() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 700);

    next_tx(test, alice);    
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test);

      let supply = interest_clamm_stable::lp_coin_supply<LP_COIN>(&mut pool);

      let (expected_value, _) = interest_clamm_stable::quote_remove_liquidity_one_coin<DAI, LP_COIN>(&mut pool, &c, supply/ 10);

      let coin_dai = interest_clamm_stable::remove_liquidity_one_coin<DAI, LP_COIN>(
        &mut pool,
        &c,
        mint_for_testing<LP_COIN>(supply / 10, ctx(test)),
        0,
        ctx(test)
      );

      assert_eq(burn(coin_dai), expected_value);

      test::return_shared(c);
      test::return_shared(pool);            
    };
    test::end(scenario); 
  }  
}