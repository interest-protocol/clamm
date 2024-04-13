// * 3 Pool - USDC - BTC - ETH
// All values tested agaisnt Curve pool
#[test_only]
module clamm::volatile_3pool_add_liquidity_tests {
  use sui::clock;
  use sui::coin::{Self, burn_for_testing as burn};

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
  const POW_10_9: u256 = 1_000_000_000;   

  #[test]
  fun mints_correct_lp_coin_amount() {
    let scenario = scenario();
    let (alice, bob) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 150000, 3, 100);

    let c = clock::create_for_testing(ctx(test));

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&pool), 355781584449);
      assert_eq(355781584449, 355781584449860319361 / POW_10_9);
      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&pool),
        vector[150000 * POW_10_18, 3 * POW_10_18, 100 * POW_10_18]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        150000 * USDC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, BTC>(&pool),
        3 * BTC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        100 * ETH_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&pool),
        47500000000000000000000
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
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
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&pool),
        POW_10_18
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&pool),
        442486144074400445244930
      );  

      test::return_shared(pool);
    };

    next_tx(test, bob);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      clock::increment_for_testing(&mut c, 14000);

      burn(interest_clamm_volatile::add_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(60000, 6, ctx(test)),
        mint<BTC>(2, 9, ctx(test)),
        mint<ETH>(5, 9, ctx(test)),
        0,
        ctx(test)
      ));

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&pool), 480377433096);
      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&pool),
        vector[210000 * POW_10_18, 5 * POW_10_18, 105 * POW_10_18]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        210000 * USDC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, BTC>(&pool),
        5 * BTC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        105 * ETH_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&pool),
        42297153987631797536005
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        1972991592365437383014
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
        1000187682388072132
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&pool),
        1000187682388072132
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&pool),
        597558336908883561483801
      );        

      test::return_shared(pool);
    };

    next_tx(test, bob);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      clock::increment_for_testing(&mut c, 1000);

      burn(interest_clamm_volatile::add_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(300555, 6, ctx(test)),
        coin::zero(ctx(test)),
        coin::zero(ctx(test)),
        0,
        ctx(test)
      ));

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&pool),
        vector[510555000000000000000000, 5 * POW_10_18, 105 * POW_10_18]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        510555000000
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, BTC>(&pool),
        5 * BTC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        105 * ETH_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&pool),
        66264310361808798928720
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        3090962745530641314761
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
        47499994006794493076617
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500000544843304867041
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&pool),
        1000691985365185009
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&pool),
        1000691985365185009
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&pool),
        805384032226452839704013
      );  

      test::return_shared(pool);
    };

    next_tx(test, bob);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      clock::increment_for_testing(&mut c, 1000);

      burn(interest_clamm_volatile::add_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        &c,
        coin::zero(ctx(test)),
        mint<BTC>(1, 9, ctx(test)),
        coin::zero(ctx(test)),
        0,
        ctx(test)
      ));

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&pool),
        vector[510555000000000000000000, 6 * POW_10_18, 105 * POW_10_18]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        510555000000
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, BTC>(&pool),
        6 * BTC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        105 * ETH_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&pool),
        75742558258239927005947
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        3090962745530641314761
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
        47500015621580678404452
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500002377487092478625
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&pool),
        1000806764620574247
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&pool),
        1000806764620574247
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&pool),
        855738310293549946471340
      );  

      test::return_shared(pool);
    };    

    next_tx(test, bob);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      clock::increment_for_testing(&mut c, 1000);

      burn(interest_clamm_volatile::add_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        &c,
        coin::zero(ctx(test)),
        coin::zero(ctx(test)),
        mint<ETH>(27, 9, ctx(test)),
        0,
        ctx(test)
      ));

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&pool),
        vector[510555000000000000000000, 6 * POW_10_18, 132 * POW_10_18]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        510555000000
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, BTC>(&pool),
        6 * BTC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        132 * ETH_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&pool),
        75742558258239927005947
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        4041883988588709601393
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
        47500048154421676806457
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500004210128769051209
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&pool),
        1000947482733339946
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&pool),
        1000947482733339946
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&pool),
        923081926000246540413964
      );  

      test::return_shared(pool);
    };  

    clock::destroy_for_testing(c);
    test::end(scenario);
  }  


  #[test]
  fun mints_correct_lp_after_swap() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 150000, 3, 100);
    let c = clock::create_for_testing(ctx(test));

    clock::increment_for_testing(&mut c, 14000);

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      let i = 0;

      while (7 > i) {

       clock::increment_for_testing(&mut c, 1000);

        burn(interest_clamm_volatile::swap<USDC, BTC, LP_COIN>(
          &mut pool,
          &c,
          mint(20_000, 6, ctx(test)),
          0,
          ctx(test)
          )
        );


        i = i + 1;
      };   

      burn(interest_clamm_volatile::add_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(150_000, 6, ctx(test)),
        mint<BTC>(3, 9, ctx(test)),
        coin::zero(ctx(test)),
        0,
        ctx(test)
      ));            

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&pool), 586029756384);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&pool),
        vector[440_000 * POW_10_18, 4535024703268191759, 100 * POW_10_18]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        440000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, BTC>(&pool),
        4535024708
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        100 * ETH_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&pool),
        95866830069307439719678
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        4332316479302974128020
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
        47500360431049558268970
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500000000000000000000
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&pool),
        1001226700522592789
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&pool),
        1001226700522592789
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&pool),
        729740251698351883505844
      );      

      clock::increment_for_testing(&mut c, 1000);

      burn(interest_clamm_volatile::add_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        &c,
        coin::zero(ctx(test)),
        mint<BTC>(3, 9, ctx(test)),
        coin::zero(ctx(test)),
        0,
        ctx(test)
      )); 

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&pool), 693824797654);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&pool),
        vector[440_000 * POW_10_18, 7535024703268191759, 100 * POW_10_18]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        440000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, BTC>(&pool),
        7535024708
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        100 * ETH_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&pool),
        74162751883116321756555
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        4332316479302974128020
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
        47500416144824576282281
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500003262571039149783
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&pool),
        1001529230816697783
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&pool),
        1001529230816697783
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&pool),
        864230636705116526806970
      );                 

      test::return_shared(pool);
    };

    clock::destroy_for_testing(c);
    test::end(scenario);
  }

  #[test]
  fun mints_correct_lp_after_swap_time_delay() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 150000, 3, 100);

    let c = clock::create_for_testing(ctx(test));

    clock::increment_for_testing(&mut c, 14_000);

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);  

      let i = 0;

      while (7 > i) {

       clock::increment_for_testing(&mut c, 22_000);

        burn(interest_clamm_volatile::swap<USDC, BTC, LP_COIN>(
          &mut pool,
          &c,
          mint(20_000, 6, ctx(test)),
          0,
          ctx(test)
          )
        );


        i = i + 1;
      };  


      burn(interest_clamm_volatile::add_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        &c,
        coin::zero(ctx(test)),
        mint<BTC>(3, 9, ctx(test)),
        coin::zero(ctx(test)),
        0,
        ctx(test)
      ));  

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&pool),
        vector[290_000 * POW_10_18, 4535024703268191759, 100 * POW_10_18]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        290000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, BTC>(&pool),
        4535024708
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        100 * ETH_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&pool),
        81184196198274029942090
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
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
        47507950004918896540470
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500000000000000000000
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&pool),
        1001400556023233209
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&pool),
        1001400556023233209
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&pool),
        634242617991253887928774
      );     

      clock::increment_for_testing(&mut c, 22_000);  

      burn(interest_clamm_volatile::add_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        &c,
        coin::zero(ctx(test)),
        coin::zero(ctx(test)),
        mint<ETH>(55, 9, ctx(test)),
        0,
        ctx(test)
      ));   

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&pool),
        vector[290_000 * POW_10_18, 4535024703268191759, 155 * POW_10_18]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        290000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, BTC>(&pool),
        4535024708
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        155 * ETH_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&pool),
        81184196198274029942090
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        2598919271237524520504
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
        47508805666980580612474
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500000000000000000000
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&pool),
        1001600639447195803
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&pool),
        1001600639447195803
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&pool),
        733139234906431020032474
      );                       

      test::return_shared(pool);
    };
    clock::destroy_for_testing(c);
    test::end(scenario);
  }  
}