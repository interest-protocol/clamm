// * 2 Pool - USDC - ETH
// All values tested agaisnt Curve pool
#[test_only]
module amm::volatile_2pool_swap_tests {
  use sui::clock;
  use sui::coin::burn_for_testing as burn;

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx}; 

  use amm::eth::ETH;
  use amm::amm_admin;
  use amm::usdc::USDC;
  use amm::lp_coin::LP_COIN;
  use amm::curves::Volatile;
  use amm::interest_amm_volatile;
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

  #[test]
  fun extreme_swaps() {
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

      let i = 0;

      while (5 > i) {

        burn(interest_amm_volatile::swap<USDC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(3000, 6, ctx(test)),
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
        vector[15731977559577057813005, 861434413817268225]
      );
      assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        15731977562
      );
     assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        861434417
      );
     assert_eq(
        interest_amm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        14603002594390712364427
      );      
     assert_eq(
        interest_amm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );
     assert_eq(
        interest_amm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500089631965365939472
      );      
     assert_eq(
        interest_amm_volatile::xcp_profit<LP_COIN>(&pool),
        1014507555149379367
      );  
     assert_eq(
        interest_amm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_amm_volatile::virtual_price<LP_COIN>(&pool),
        1014507555149379367
      );        
     assert_eq(
        interest_amm_volatile::invariant_<LP_COIN>(&pool),
        9130567996326928986922
      );   

      test::return_shared(pool);
    };   

    clock::destroy_for_testing(c);
    test::end(scenario);     
  } 

  #[test]
  fun do_1000_swaps() {
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

      while (200 > i) {

        burn(interest_amm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(5, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        burn(interest_amm_volatile::swap<USDC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(6700, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);
        i = i + 1;
      };  

      test::return_shared(pool);
    };

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      let i = 0;

      while (200 > i) {

        burn(interest_amm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(5, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        burn(interest_amm_volatile::swap<USDC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(6700, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);
        i = i + 1;
      };        

      test::return_shared(pool);
    };   

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      let i = 0;

      while (200 > i) {

        burn(interest_amm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(5, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        burn(interest_amm_volatile::swap<USDC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(6700, 6, ctx(test)),
          0,
          ctx(test)
          )
        );
        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        i = i + 1;
    };  

    test::return_shared(pool);
  };

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      let i = 0;

      while (200 > i) {

        burn(interest_amm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(5, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        burn(interest_amm_volatile::swap<USDC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(6700, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);
        i = i + 1;
      };

      test::return_shared(pool);
    };  

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);
      let admin_cap = test::take_from_sender<amm_admin::Admin>(test);
      let i = 0;

      while (200 > i) {

        burn(interest_amm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(5, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        burn(interest_amm_volatile::swap<USDC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(6700, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);
        i = i + 1;
      };

      burn(interest_amm_volatile::claim_admin_fees<LP_COIN>(&mut pool, &admin_cap, ctx(test)));


      assert_eq(
        interest_amm_volatile::balances<LP_COIN>(&pool),
        vector[32418888758081696393064, 19568068883753941489]
      );
      assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        32418889269
      );
     assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        19568069382
      );
     assert_eq(
        interest_amm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        1343258164074646161579
      );      
     assert_eq(
        interest_amm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1493260119937499079177
      );
     assert_eq(
        interest_amm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1492071306578867767373
      );      
     assert_eq(
        interest_amm_volatile::xcp_profit<LP_COIN>(&pool),
        5689309510204642587
      );  
     assert_eq(
        interest_amm_volatile::xcp_profit_a<LP_COIN>(&pool),
        5689309510204642587
      );  
     assert_eq(
        interest_amm_volatile::virtual_price<LP_COIN>(&pool),
        6275288361292987208
      );        
     assert_eq(
        interest_amm_volatile::invariant_<LP_COIN>(&pool),
        61614176163583333170910
      );   

      test::return_to_sender(test, admin_cap);
      test::return_shared(pool);
    };        

    clock::destroy_for_testing(c);
    test::end(scenario);     
  }   
}