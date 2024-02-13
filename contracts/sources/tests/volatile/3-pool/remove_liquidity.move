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
  const ETH_DECIMALS_SCALAR: u64 = 1000000000;
  const USDC_DECIMALS_SCALAR: u64 = 1000000; 

  const POW_10_18: u256 = 1_000_000_000_000_000_000;

  #[test]
  fun remove_liquidity() {
    let scenario = scenario();
    let (_, bob) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 150_000, 3, 100);
    let c = clock::create_for_testing(ctx(test));

    next_tx(test, bob);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

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

      let (coin_usdc, coin_eth, coin_btc) = interest_clamm_volatile::remove_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        mint_for_testing(606255835556 / 3, ctx(test)),
        vector[0, 0, 0],
        ctx(test)
      );    

      burn(coin_usdc);
      burn(coin_eth);
      burn(coin_btc);

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&pool), 404170557011);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&pool),
        vector[279999999994226859693737, 1999999999958763284, 116666666664261191540]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        279999999995
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, BTC>(&pool),
        2 * BTC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        116666666665
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&pool),
        137866294158111962778870
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        2379240621198716758801
      );  
     assert_eq(
        interest_clamm_volatile::coin_price<BTC, LP_COIN>(&pool),
        47500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<BTC, LP_COIN>(&pool),
        47500000000000000000000
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500000000000000000000
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&pool),
        1000450051533339894
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&pool),
        1000450051533339894
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&pool),
        502893815471912523707801
      );   

      test::return_shared(pool);
    };

    next_tx(test, bob);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

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

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&pool), 404170557011);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&pool),
        vector[482447205028526486355728, 1519506791357439328, 88637896162517294091]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        482447205030
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, BTC>(&pool),
        1519506792
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        88637896164
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&pool),
        209963397337079221917267
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        3623463203677270681373
      );  
     assert_eq(
        interest_clamm_volatile::coin_price<BTC, LP_COIN>(&pool),
        47500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<BTC, LP_COIN>(&pool),
        47500308280358950919387
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500002999487993090817
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&pool),
        1000927192665861592
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&pool),
        1000927192665861592
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&pool),
        503133658855049259319304
      );   

      test::return_shared(pool);
    };    

    clock::destroy_for_testing(c);
    test::end(scenario);
  }

  #[test]
  fun remove_liquidity_extreme_usdc_swaps() {
    let scenario = scenario();
    let (_, bob) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 150_000, 3, 100);
    let c = clock::create_for_testing(ctx(test));

    next_tx(test, bob);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

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

      let i = 0;

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

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&pool), 404170557011);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&pool),
        vector[613333333320687406948185, 906254713313933422, 116666666664261191540]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        613333333321
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, BTC>(&pool),
        906254716
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        116666666665
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&pool),
        597530835708084332217372
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        2379240621198716758801
      );  
     assert_eq(
        interest_clamm_volatile::coin_price<BTC, LP_COIN>(&pool),
        47500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<BTC, LP_COIN>(&pool),
        47530575536002866827274
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500118531199812384023
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&pool),
        1001579802229274660
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&pool),
        1001579802229274660
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&pool),
        503461704530236245038409
      );   

      test::return_shared(pool);
    };

    clock::destroy_for_testing(c);
    test::end(scenario);
  }  

  #[test]
  fun remove_liquidity_extreme_btc_swaps() {
    let scenario = scenario();
    let (_, bob) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 150_000, 3, 100);
    let c = clock::create_for_testing(ctx(test));

    next_tx(test, bob);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

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

      let i = 0;

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

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&pool), 454691876641);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&pool),
        vector[314999999996016533188679, 5999999999924124442, 49270259568734475754]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        314999999997
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, BTC>(&pool),
        6 * BTC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        49270259571
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&pool),
        137866294158111962778870
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        14607534616082764102093
      );  
     assert_eq(
        interest_clamm_volatile::coin_price<BTC, LP_COIN>(&pool),
        47500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<BTC, LP_COIN>(&pool),
        47512182359425747006491
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500587595794228389742
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&pool),
        1001852539196963431
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&pool),
        1001852539196963431
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&pool),
        566548650639305975240118
      );   

      test::return_shared(pool);
    };

    clock::destroy_for_testing(c);
    test::end(scenario);
  }    
}