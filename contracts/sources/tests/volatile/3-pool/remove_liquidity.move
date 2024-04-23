// * 3 Pool - USDC - BTC - ETH
// All values tested agaisnt Curve pool
#[test_only]
module clamm::volatile_3pool_remove_liquidity_tests {
  use sui::clock;
  use sui::coin::{Self, mint_for_testing, burn_for_testing as burn};

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx}; 

  use clamm::interest_clamm_volatile;
  use clamm::btc::BTC;
  use clamm::eth::ETH;
  use clamm::usdc::USDC;
  use clamm::lp_coin::LP_COIN;
  use clamm::curves::Volatile;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_volatile::setup_3pool;
  use clamm::amm_test_utils ::{people, scenario, mint};

  const BTC_DECIMALS_SCALAR: u64 = 1000000000;

  const POW_10_18: u256 = 1_000_000_000_000_000_000;

  #[test]
  fun remove_liquidity() {
    let mut scenario = scenario();
    let (_, bob) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 150_000, 3, 100);
    let mut c = clock::create_for_testing(ctx(test));

    next_tx(test, bob);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      clock::increment_for_testing(&mut c, 14_000);

      burn(interest_clamm_volatile::add_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(270_000, 6, ctx(test)),
        coin::zero(ctx(test)),
        mint<ETH>(75, 9, ctx(test)),
        0,
        ctx(test)
      )); 

      let supply_value = interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool);     

      let (coin_usdc, coin_eth, coin_btc) = interest_clamm_volatile::remove_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        mint_for_testing(supply_value / 3, ctx(test)),
        vector[0, 0, 0],
        ctx(test)
      );    

      burn(coin_usdc);
      burn(coin_eth);
      burn(coin_btc);

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 404170557020);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[280000000001154628061253, 2000000000008247344, 116666666667147761693]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<USDC, LP_COIN>(&mut pool),
        280000000002
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<BTC, LP_COIN>(&mut pool),
        (2 * BTC_DECIMALS_SCALAR) + 1
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<ETH, LP_COIN>(&mut pool),
        116666666668
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&mut pool),
        137866294158111962778870
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        2379240621198716758801
      );  
     assert_eq(
        interest_clamm_volatile::coin_price<BTC, LP_COIN>(&mut pool),
        47500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<BTC, LP_COIN>(&mut pool),
        47500000000000000000000
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1000450051533876402
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1000450051533876402
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        502893815483110876137822
      );   

      test::return_shared(pool);
    };

    next_tx(test, bob);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      clock::increment_for_testing(&mut c, 3_000);

      let lp_coin = interest_clamm_volatile::add_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(355_005, 6, ctx(test)),
        coin::zero(ctx(test)),
        coin::zero(ctx(test)),
        0,
        ctx(test)
      );

      let (coin_usdc, coin_eth, coin_btc) = interest_clamm_volatile::remove_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        lp_coin,
        vector[0, 0, 0],
        ctx(test)
      );    

      burn(coin_usdc);
      burn(coin_eth);
      burn(coin_btc);

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 404170557020);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[482447205035750742508553, 1519506791401210901, 88637896165070635835]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<USDC, LP_COIN>(&mut pool),
        482447205037
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<BTC, LP_COIN>(&mut pool),
        1519506793
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<ETH, LP_COIN>(&mut pool),
        88637896166
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&mut pool),
        209963397333543933646304
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        3623463203616260109404
      );  
     assert_eq(
        interest_clamm_volatile::coin_price<BTC, LP_COIN>(&mut pool),
        47500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<BTC, LP_COIN>(&mut pool),
        47500312785177266637905
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1500003043318707752741
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1000927192666594209
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1000927192666594209
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        503133658865958237205300
      );   

      test::return_shared(pool);
    };    

    clock::destroy_for_testing(c);
    test::end(scenario);
  }

  #[test]
  fun remove_liquidity_extreme_usdc_swaps() {
    let mut scenario = scenario();
    let (_, bob) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 150_000, 3, 100);
    let mut c = clock::create_for_testing(ctx(test));

    next_tx(test, bob);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      clock::increment_for_testing(&mut c, 14_000);

      burn(interest_clamm_volatile::add_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(270_000, 6, ctx(test)),
        coin::zero(ctx(test)),
        mint<ETH>(75, 9, ctx(test)),
        0,
        ctx(test)
      ));

      clock::increment_for_testing(&mut c, 2_000);

      let mut i = 0;

      while (5 > i) {

        clock::increment_for_testing(&mut c, 23_000);

        burn(interest_clamm_volatile::swap<USDC, BTC, LP_COIN>(
          &mut pool,
          &c,
          mint(100_000, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        i = i + 1;
      };      


      let (coin_usdc, coin_eth, coin_btc) = interest_clamm_volatile::remove_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        mint_for_testing(606255835555 / 3, ctx(test)),
        vector[0, 0, 0],
        ctx(test)
      );    

      burn(coin_usdc);
      burn(coin_eth);
      burn(coin_btc);

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 404170557011);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[613333333322204918114403, 906254713316175680, 116666666664549848555]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<USDC, LP_COIN>(&mut pool),
        613333333323
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<BTC, LP_COIN>(&mut pool),
        906254716
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<ETH, LP_COIN>(&mut pool),
        116666666665
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&mut pool),
        597530835708084332217372
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        2379240621198716758801
      );  
     assert_eq(
        interest_clamm_volatile::coin_price<BTC, LP_COIN>(&mut pool),
        47500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<BTC, LP_COIN>(&mut pool),
        47530651889234516300919
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1500118802533383375452
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1001579802229274660
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1001579802229274660
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        503461704530236245038409
      );   

      test::return_shared(pool);
    };

    clock::destroy_for_testing(c);
    test::end(scenario);
  }  

  #[test]
  fun remove_liquidity_extreme_btc_swaps() {
    let mut scenario = scenario();
    let (_, bob) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 150_000, 3, 100);
    let mut c = clock::create_for_testing(ctx(test));

    next_tx(test, bob);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      clock::increment_for_testing(&mut c, 14_000);

      burn(interest_clamm_volatile::add_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(270_000, 6, ctx(test)),
        coin::zero(ctx(test)),
        mint<ETH>(75, 9, ctx(test)),
        0,
        ctx(test)
      ));

      clock::increment_for_testing(&mut c, 2_000);

      let mut i = 0;

      while (5 > i) {

        clock::increment_for_testing(&mut c, 23_000);

        burn(interest_clamm_volatile::swap<BTC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(1, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        i = i + 1;
      };      


      let (coin_usdc, coin_eth, coin_btc) = interest_clamm_volatile::remove_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        mint_for_testing(606255835555 / 4, ctx(test)),
        vector[0, 0, 0],
        ctx(test)
      );    

      burn(coin_usdc);
      burn(coin_eth);
      burn(coin_btc);

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 454691876641);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[314999999996709310025430, 5999999999937320191, 49270259568842835419]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<USDC, LP_COIN>(&mut pool),
        314999999997
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<BTC, LP_COIN>(&mut pool),
        6 * BTC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<ETH, LP_COIN>(&mut pool),
        49270259572
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&mut pool),
        137866294158111962778870
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        14607534616082764102093
      );  
     assert_eq(
        interest_clamm_volatile::coin_price<BTC, LP_COIN>(&mut pool),
        47500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<BTC, LP_COIN>(&mut pool),
        47512210246455417853287
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1500589103118418628864
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1001852539196963431
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1001852539196963431
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        566548650639305975240118
      );   

      test::return_shared(pool);
    };

    clock::destroy_for_testing(c);
    test::end(scenario);
  }   

  #[test]
  fun remove_liquidity_extreme_eth_swaps() {
    let mut scenario = scenario();
    let (_, bob) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 150_000, 3, 100);
    let mut c = clock::create_for_testing(ctx(test));

    next_tx(test, bob);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      clock::increment_for_testing(&mut c, 14_000);

      burn(interest_clamm_volatile::add_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(270_000, 6, ctx(test)),
        coin::zero(ctx(test)),
        mint<ETH>(75, 9, ctx(test)),
        0,
        ctx(test)
      ));

      clock::increment_for_testing(&mut c, 2_000);

      let mut i = 0;

      while (5 > i) {

        burn(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(30, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, 23_000);

        i = i + 1;
      };      

      let supply_value = interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool);

      let (coin_usdc, coin_eth, coin_btc) = interest_clamm_volatile::remove_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        mint_for_testing(supply_value / 4, ctx(test)),
        vector[0, 0, 0],
        ctx(test)
      );    

      burn(coin_usdc);
      burn(coin_eth);
      burn(coin_btc);

      // assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 454691876641);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[169789951763685635623065, 2250000000006185508, 243750000000670096643]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<USDC, LP_COIN>(&mut pool),
        169789951767
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<BTC, LP_COIN>(&mut pool),
        2250000001
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<ETH, LP_COIN>(&mut pool),
        243750000001
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&mut pool),
        137866294158111962778870
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        772718757652294274659
      );  
     assert_eq(
        interest_clamm_volatile::coin_price<BTC, LP_COIN>(&mut pool),
        47500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<BTC, LP_COIN>(&mut pool),
        47509809523310118920343
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1499993552369428764870
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1001300900141929550
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1001300900141929550
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        566236698188664749448299
      );   

      test::return_shared(pool);
    };

    clock::destroy_for_testing(c);
    test::end(scenario);
  }    

  #[test]
  fun remove_liquidity_one_coin() {
    let mut scenario = scenario();
    let (_, bob) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 150_000, 3, 100);
    let mut c = clock::create_for_testing(ctx(test));

    next_tx(test, bob);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      clock::increment_for_testing(&mut c, 14_000);

      burn(interest_clamm_volatile::add_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(270_000, 6, ctx(test)),
        coin::zero(ctx(test)),
        mint<ETH>(75, 9, ctx(test)),
        0,
        ctx(test)
      ));

      clock::increment_for_testing(&mut c, 3_000);

      let lp_coin_supply = interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool);

      burn(interest_clamm_volatile::remove_liquidity_one_coin<USDC, LP_COIN>(
        &mut pool, 
        &c,
        mint_for_testing(lp_coin_supply / 3, ctx(test)),
        0,
        ctx(test)
      ));

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 404170557020);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[125062211597987906391863, 3 * POW_10_18, 175 * POW_10_18]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<USDC, LP_COIN>(&mut pool),
        125062211598
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<BTC, LP_COIN>(&mut pool),
        3 * BTC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<ETH, LP_COIN>(&mut pool),
        175000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&mut pool),
        77210508402993608039251
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        1332467657142710861694
      );  
     assert_eq(
        interest_clamm_volatile::coin_price<BTC, LP_COIN>(&mut pool),
        47500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<BTC, LP_COIN>(&mut pool),
        47500312785177266637905
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1500003043318707752741
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1001415131649422200
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1001415131649422200
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        503378929978066651181501
      );
      
      let lp_coin = interest_clamm_volatile::add_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(355_000, 6, ctx(test)),
        coin::zero(ctx(test)),
        coin::zero(ctx(test)),
        0,
        ctx(test)
      );

      burn(interest_clamm_volatile::remove_liquidity_one_coin<BTC, LP_COIN>(
        &mut pool, 
        &c,
        lp_coin,
        0,
        ctx(test)
      ));

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 404170557020);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[480062211597987906391863, 776720781346506998, 175 * POW_10_18]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<USDC, LP_COIN>(&mut pool),
        480062211598
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<BTC, LP_COIN>(&mut pool),
        776720782
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<ETH, LP_COIN>(&mut pool),
        175000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&mut pool),
        232371584058617670550462
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        1438563592051637010540
      );  
     assert_eq(
        interest_clamm_volatile::coin_price<BTC, LP_COIN>(&mut pool),
        47500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<BTC, LP_COIN>(&mut pool),
        47500312785177266637905
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1500003043318707752741
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1003225385620269081
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1003225385620269081
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        504288885977365910280904
      );

      let lp_coin = interest_clamm_volatile::add_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        &c,
        coin::zero(ctx(test)),
        mint(2, 9, ctx(test)),
        mint(35, 9, ctx(test)),
        0,
        ctx(test)
      );

      burn(interest_clamm_volatile::remove_liquidity_one_coin<ETH, LP_COIN>(
        &mut pool, 
        &c,
        lp_coin,
        0,
        ctx(test)
      ));  

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 404170557020);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[480062211597987906391863, 2776720781346506998, 49323684945134632985]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<USDC, LP_COIN>(&mut pool),
        480062211598
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<BTC, LP_COIN>(&mut pool),
        2776720782
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<ETH, LP_COIN>(&mut pool),
        49323684946
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&mut pool),
        170477432582809189662301
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        4542997979090313454126
      );  
     assert_eq(
        interest_clamm_volatile::coin_price<BTC, LP_COIN>(&mut pool),
        47500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<BTC, LP_COIN>(&mut pool),
        47500312785177266637905
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1500003043318707752741
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1004813917275696236
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1004813917275696236
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        505087389354909386381160
      );

      test::return_shared(pool);
    };

    clock::destroy_for_testing(c);
    test::end(scenario);
  }    
}