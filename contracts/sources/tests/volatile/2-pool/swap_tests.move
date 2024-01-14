// * 2 Pool - USDC - ETH
// All values tested agaisnt Curve pool
#[test_only]
module amm::volatile_2pool_swap_tests {
  use sui::clock;
  use sui::coin::burn_for_testing as burn;

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx}; 

  use amm::interest_amm_volatile;
  use amm::eth::ETH;
  use amm::usdc::USDC;
  use amm::lp_coin::LP_COIN;
  use amm::curves::Volatile;
  use amm::interest_pool::InterestPool;
  use amm::init_interest_amm_volatile::setup_2pool;
  use amm::amm_test_utils ::{people, scenario, mint};

  const USDC_DECIMALS_SCALAR: u64 = 1000000; 
  const TWENTY_MILLISECONDS: u64 = 22000;

  const POW_10_18: u256 = 1_000_000_000_000_000_000;

  #[test]
  fun extreme_usdc_swaps() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let c = clock::create_for_testing(ctx(test));

    clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS / 20);

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      let i = 0;

      while (5 > i) {

        burn(interest_amm_volatile::swap<USDC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(1500, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        i = i + 1;
      };
 
      // Our balancs are stored with 1e18 instead of the real balances
      assert_eq(
        interest_amm_volatile::balances<LP_COIN>(&pool),
        vector[12000 * POW_10_18, 1106310976911120041]
      );
      assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        12000 * USDC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        1106310979
      );
     assert_eq(
        interest_amm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        9375490921061207367077
      );      
     assert_eq(
        interest_amm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );
     assert_eq(
        interest_amm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500285873804165099191
      );      
     assert_eq(
        interest_amm_volatile::xcp_profit<LP_COIN>(&pool),
        1002112077667827315
      );  
     assert_eq(
        interest_amm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_amm_volatile::virtual_price<LP_COIN>(&pool),
        1002112077667827315
      );        
     assert_eq(
        interest_amm_volatile::invariant_<LP_COIN>(&pool),
        9019008698993174159760
      );   

      test::return_shared(pool);
    };   

    clock::destroy_for_testing(c);
    test::end(scenario);     
  }  

  #[test]
  fun extreme_eth_swaps() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let c = clock::create_for_testing(ctx(test));

    clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS / 20);

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      let i = 0;

      while (5 > i) {

        burn(interest_amm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(3, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        i = i + 1;
      };
 
      // Our balancs are stored with 1e18 instead of the real balances
      assert_eq(
        interest_amm_volatile::balances<LP_COIN>(&pool),
        vector[731977559577057813005, 18000000000000000000]
      );
      assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        731977562
      );
     assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        18000000000
      );
     assert_eq(
        interest_amm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        49396381960951867623
      );      
     assert_eq(
        interest_amm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );
     assert_eq(
        interest_amm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1499878531304466355375
      );      
     assert_eq(
        interest_amm_volatile::xcp_profit<LP_COIN>(&pool),
        1004566873717172552
      );  
     assert_eq(
        interest_amm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_amm_volatile::virtual_price<LP_COIN>(&pool),
        1004566873717172552
      );        
     assert_eq(
        interest_amm_volatile::invariant_<LP_COIN>(&pool),
        9041101863437238975828
      );   

      test::return_shared(pool);
    };   

    clock::destroy_for_testing(c);
    test::end(scenario);     
  }    
}