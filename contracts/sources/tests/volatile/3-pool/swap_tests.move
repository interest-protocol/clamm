// * 3 Pool - USDC - BTC - ETH
// All values tested agaisnt Curve pool
#[test_only]
module clamm::volatile_3pool_swap_tests {
  use sui::clock;
  use sui::coin::burn_for_testing as burn;

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx}; 

  use clamm::interest_clamm_volatile;
  use clamm::btc::BTC;
  use clamm::eth::ETH;
  use clamm::usdc::USDC;
  use clamm::lp_coin::LP_COIN;
  use clamm::curves::Volatile;
  use clamm::pool_admin::PoolAdmin;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_volatile::setup_3pool;
  use clamm::amm_test_utils ::{people, scenario, mint};

  const BTC_DECIMALS_SCALAR: u64 = 1000000000;
  const ETH_DECIMALS_SCALAR: u64 = 1000000000;
  const USDC_DECIMALS_SCALAR: u64 = 1000000; 
  const POW_10_18: u256 = 1_000_000_000_000_000_000;

  #[test]
  fun extreme_usdc_swaps() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 150000, 3, 100);

    let mut c = clock::create_for_testing(ctx(test));

    next_tx(test, alice); 
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);  

      clock::increment_for_testing(&mut c, 14_000);

      let mut i = 0;

      while (5 > i) {

        clock::increment_for_testing(&mut c, 22_000);

        burn(interest_clamm_volatile::swap<USDC, BTC, LP_COIN>(
          &mut pool,
          &c,
          mint(40_000, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        i = i + 1;
      };

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[350_000 * POW_10_18, 1269800855063115831, 100 * POW_10_18]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        350_000 * USDC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, BTC>(&mut pool),
        1269800857
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
        100 * ETH_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&mut pool),
        241613396579540753549299
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
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
        47507425267449372140237
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1001184991177003540
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1001184991177003540
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        443010486250003678766705
      ); 

      test::return_shared(pool);
    };
    
    clock::destroy_for_testing(c);
    test::end(scenario);
  }

  #[test]
  fun extreme_btc_swaps() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 150000, 3, 100);

    let mut c = clock::create_for_testing(ctx(test));

    next_tx(test, alice); 
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);  

      clock::increment_for_testing(&mut c, 14_000);

      let mut i = 0;

      while (5 > i) {

        clock::increment_for_testing(&mut c, 22_000);

        burn(interest_clamm_volatile::swap<BTC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(5, 8, ctx(test)),
          0,
          ctx(test)
          )
        );

        i = i + 1;
      };

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[150_000 * POW_10_18, 5500000000000000000, 54027773845506102414]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        150_000 * USDC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, BTC>(&mut pool),
        5500000000
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
        54027773847
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&mut pool),
        47500000000000000000000
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        4343512371979121649547
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
        1500106516255014532491
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1000751898361443297
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1000751898361443297
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        442818848680020564855580
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
    
    setup_3pool(test, 150000, 3, 100);

    let mut c = clock::create_for_testing(ctx(test));

    next_tx(test, alice); 
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);  

      clock::increment_for_testing(&mut c, 14_000);

      let mut i = 0;

      while (5 > i) {

        clock::increment_for_testing(&mut c, 23_000);

        burn(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(40, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        i = i + 1;
      };

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[49285237353557890973886, 3 * POW_10_18, 300 * POW_10_18]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        49285237357
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, BTC>(&mut pool),
        3 * ETH_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
        300 * BTC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&mut pool),
        47500000000000000000000
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        191456323292332621417
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
        1499902420003103420696
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1001616388232902130
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1001616388232902130
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        443201373469832832623384
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
    
    setup_3pool(test, 150_000, 3, 100);
    
    let mut c = clock::create_for_testing(ctx(test));

    clock::increment_for_testing(&mut c, 14_000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);  

      let mut i = 0;

      while (200 > i) {
        burn(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(75, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, 1_000);

        burn(interest_clamm_volatile::swap<BTC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(2, 9, ctx(test)),
          0,
          ctx(test)
          )
        );        

        clock::increment_for_testing(&mut c, 1_000);

        burn(interest_clamm_volatile::swap<USDC, BTC, LP_COIN>(
          &mut pool,
          &c,
          mint(100_000, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, 1_000);

        burn(interest_clamm_volatile::swap<BTC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(15, 8, ctx(test)),
          0,
          ctx(test)
          )
        );        

        clock::increment_for_testing(&mut c, 22_000);
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
          mint(75, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, 1_000);

        burn(interest_clamm_volatile::swap<BTC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(2, 9, ctx(test)),
          0,
          ctx(test)
          )
        );        

        clock::increment_for_testing(&mut c, 1_000);

        burn(interest_clamm_volatile::swap<USDC, BTC, LP_COIN>(
          &mut pool,
          &c,
          mint(100_000, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, 1_000);

        burn(interest_clamm_volatile::swap<BTC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(15, 8, ctx(test)),
          0,
          ctx(test)
          )
        );        

        clock::increment_for_testing(&mut c, 22_000);
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
          mint(75, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, 1_000);

        burn(interest_clamm_volatile::swap<BTC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(2, 9, ctx(test)),
          0,
          ctx(test)
          )
        );        

        clock::increment_for_testing(&mut c, 1_000);

        burn(interest_clamm_volatile::swap<USDC, BTC, LP_COIN>(
          &mut pool,
          &c,
          mint(100_000, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, 1_000);

        burn(interest_clamm_volatile::swap<BTC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(15, 8, ctx(test)),
          0,
          ctx(test)
          )
        );        

        clock::increment_for_testing(&mut c, 22_000);
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
          mint(75, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, 1_000);

        burn(interest_clamm_volatile::swap<BTC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(2, 9, ctx(test)),
          0,
          ctx(test)
          )
        );        

        clock::increment_for_testing(&mut c, 1_000);

        burn(interest_clamm_volatile::swap<USDC, BTC, LP_COIN>(
          &mut pool,
          &c,
          mint(100_000, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, 1_000);

        burn(interest_clamm_volatile::swap<BTC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(15, 8, ctx(test)),
          0,
          ctx(test)
          )
        );        

        clock::increment_for_testing(&mut c, 22_000);
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
          mint(75, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, 1_000);

        burn(interest_clamm_volatile::swap<BTC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(2, 9, ctx(test)),
          0,
          ctx(test)
          )
        );        

        clock::increment_for_testing(&mut c, 1_000);

        burn(interest_clamm_volatile::swap<USDC, BTC, LP_COIN>(
          &mut pool,
          &c,
          mint(100_000, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, 1_000);

        burn(interest_clamm_volatile::swap<BTC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(15, 8, ctx(test)),
          0,
          ctx(test)
          )
        );        

        clock::increment_for_testing(&mut c, 22_000);
        i = i + 1;
      };        

      let mut request = interest_clamm_volatile::balances_request<LP_COIN>(&mut pool);

      interest_clamm_volatile::read_balance<LP_COIN, USDC>(&mut pool, &mut request);
      interest_clamm_volatile::read_balance<LP_COIN, ETH>(&mut pool, &mut request);
      interest_clamm_volatile::read_balance<LP_COIN, BTC>(&mut pool, &mut request);      

      burn(interest_clamm_volatile::claim_admin_fees<LP_COIN>(&mut pool, &admin_cap, &c, request, ctx(test)));

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 385241469605);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[557682685576000000000000, 17854975450000000000, 344591888209000000000]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        557682685576
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, BTC>(&mut pool),
        17854975450
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
        344591888209
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&mut pool),
        28680336310339966984094
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        1339192935924829907260
      );  
     assert_eq(
        interest_clamm_volatile::coin_price<BTC, LP_COIN>(&mut pool),
        47020670825017524079194
      );
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1495888697711251494483
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<BTC, LP_COIN>(&mut pool),
        46965479070309852771552
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1495417295563758752858
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        3599777285522989457
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        3599777285522989457
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        3924628722381078480
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        1872329268027884263995350
      );             

      test::return_to_sender(test, admin_cap);
      test::return_shared(pool);
    };        

    clock::destroy_for_testing(c);
    test::end(scenario);      
  } 
}