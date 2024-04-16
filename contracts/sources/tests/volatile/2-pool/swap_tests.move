// * 2 Pool - USDC - ETH
// All values tested agaisnt Curve pool
#[test_only]
module clamm::volatile_2pool_swap_tests {
  use sui::clock;
  use sui::coin::burn_for_testing as burn;

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx}; 

  use clamm::eth::ETH;
  use clamm::usdc::USDC;
  use clamm::lp_coin::LP_COIN;
  use clamm::curves::Volatile;
  use clamm::pool_admin::PoolAdmin;
  use clamm::interest_clamm_volatile;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_volatile::setup_2pool;
  use clamm::amm_test_utils ::{people, scenario, mint};

  const USDC_DECIMALS_SCALAR: u64 = 1000000; 
  const TWENTY_MILLISECONDS: u64 = 22000;

  const POW_10_18: u256 = 1_000_000_000_000_000_000;

  #[test]
  fun extreme_usdc_swaps() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let mut c = clock::create_for_testing(ctx(test));

    clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS / 20);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let mut i = 0;

      while (5 > i) {

        burn(interest_clamm_volatile::swap<USDC, ETH, LP_COIN>(
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
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[12000 * POW_10_18, 1106310976911120041]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        12000 * USDC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
        1106310979
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        9375490921061207367077
      );      
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1500286627088623267965
      );      
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1002112077667827315
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1002112077667827315
      );        
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        9019008698993174159760
      );   

      test::return_shared(pool);
    };   

    clock::destroy_for_testing(c);
    test::end(scenario);     
  }  

  #[test]
  fun extreme_eth_swaps() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let mut c = clock::create_for_testing(ctx(test));

    clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS / 20);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let mut i = 0;

      while (5 > i) {

        burn(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
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
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[731977559577057813005, 18000000000000000000]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        731977562
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
        18000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        49396381960951867623
      );      
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1499878211235715324043
      );      
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1004566873717172552
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1004566873717172552
      );        
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        9041101863437238975828
      );   

      test::return_shared(pool);
    };   

    clock::destroy_for_testing(c);
    test::end(scenario);     
  }    

  #[test]
  fun extreme_swaps() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let mut c = clock::create_for_testing(ctx(test));

    clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS / 20);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let mut i = 0;

      while (5 > i) {

        burn(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
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

      let mut i = 0;

      while (5 > i) {

        burn(interest_clamm_volatile::swap<USDC, ETH, LP_COIN>(
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
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[15731977559577057813005, 861434413817268225]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        15731977562
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
        861434417
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        14603002594390712364427
      );      
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1500089868213114519950
      );      
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1014507555149379367
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1014507555149379367
      );        
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        9130567996326928986922
      );   

      test::return_shared(pool);
    };   

    clock::destroy_for_testing(c);
    test::end(scenario);     
  } 

  #[test]
  fun do_1000_swaps() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let mut c = clock::create_for_testing(ctx(test));

    clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS / 20);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let mut i = 0;

      while (200 > i) {

        burn(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(5, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        burn(interest_clamm_volatile::swap<USDC, ETH, LP_COIN>(
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
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let mut i = 0;

      while (200 > i) {

        burn(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(5, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        burn(interest_clamm_volatile::swap<USDC, ETH, LP_COIN>(
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
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let mut i = 0;

      while (200 > i) {

        burn(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(5, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        burn(interest_clamm_volatile::swap<USDC, ETH, LP_COIN>(
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
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let mut i = 0;

      while (200 > i) {

        burn(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(5, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        burn(interest_clamm_volatile::swap<USDC, ETH, LP_COIN>(
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
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);
      let admin_cap = test::take_from_sender<PoolAdmin>(test);
      let mut i = 0;

      while (200 > i) {

        burn(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(5, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        burn(interest_clamm_volatile::swap<USDC, ETH, LP_COIN>(
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

      let mut request = interest_clamm_volatile::balances_request<LP_COIN>(&mut pool);

      interest_clamm_volatile::read_balance<LP_COIN, USDC>(&mut pool, &mut request);
      interest_clamm_volatile::read_balance<LP_COIN, ETH>(&mut pool, &mut request);

      burn(interest_clamm_volatile::claim_admin_fees<LP_COIN>(&mut pool, &admin_cap, &c, request, ctx(test)));


      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[32419468392000000000000, 19568523115000000000]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        32419468392
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
        19568523115
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        1343258103294868861995
      );      
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1493260119937499166452
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1492050941790739771521
      );      
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        5689202091945346487
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        5689202091945346487
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        6275442332237540972
      );        
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        61615437066806353959147
      );   

      test::return_to_sender(test, admin_cap);
      test::return_shared(pool);
    };        

    clock::destroy_for_testing(c);
    test::end(scenario);     
  }   
}