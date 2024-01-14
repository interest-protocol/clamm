// * 2 Pool - USDC - ETH
// All values tested agaisnt Curve pool
#[test_only]
module amm::volatile_2pool_add_liquidity_tests {
  use sui::clock;
  use sui::coin::{Self, burn_for_testing as burn};

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

  const ETH_DECIMALS_SCALAR: u64 = 1000000000;
  const USDC_DECIMALS_SCALAR: u64 = 1000000; 
  const TWENTY_MILLISECONDS: u64 = 22000;

  const POW_10_18: u256 = 1_000_000_000_000_000_000;
  const POW_10_9: u256 = 1_000_000_000; 

  #[test]
  fun mints_correct_lp_coin_amount() {
    let scenario = scenario();
    let (alice, bob) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let c = clock::create_for_testing(ctx(test));

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      assert_eq(interest_amm_volatile::lp_coin_supply<LP_COIN>(&pool), 116189500386);
      // Tested via hardhat
      assert_eq(116189500386, 116189500386222506555 / POW_10_9);
      // Our balancs are stored with 1e18 instead of the real balances
      assert_eq(
        interest_amm_volatile::balances<LP_COIN>(&pool),
        vector[4500 * POW_10_18, 3 * POW_10_18]
      );
      assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        4500 * USDC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        3 * ETH_DECIMALS_SCALAR
      );
     assert_eq(
        interest_amm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );      
     assert_eq(
        interest_amm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );
     assert_eq(
        interest_amm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );      
     assert_eq(
        interest_amm_volatile::xcp_profit<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_amm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_amm_volatile::virtual_price<LP_COIN>(&pool),
        POW_10_18
      );        
     assert_eq(
        interest_amm_volatile::invariant_<LP_COIN>(&pool),
        9000000000000000000000
      );   

      test::return_shared(pool);
    };

    next_tx(test, bob);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      burn(interest_amm_volatile::add_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(6000, 6, ctx(test)),
        mint<ETH>(5, 9, ctx(test)),
        0,
        ctx(test)
      ));

      assert_eq(interest_amm_volatile::lp_coin_supply<LP_COIN>(&pool), 290178641322);
      // Tested via hardhat
      assert_eq(290178641323, 290178641323480024837 / POW_10_9);

      assert_eq(
        interest_amm_volatile::balances<LP_COIN>(&pool),
        vector[10500 * POW_10_18, 8 * POW_10_18]
      );
      assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        10500 * USDC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        8 * ETH_DECIMALS_SCALAR
      );
     assert_eq(
        interest_amm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        1367804588351518548120
      );      
     assert_eq(
        interest_amm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );
     assert_eq(
        interest_amm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );      
     assert_eq(
        interest_amm_volatile::xcp_profit<LP_COIN>(&pool),
        1000056223491914378
      );  
     assert_eq(
        interest_amm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_amm_volatile::virtual_price<LP_COIN>(&pool),
        1000056223491914378
      );        
     assert_eq(
        interest_amm_volatile::invariant_<LP_COIN>(&pool),
        22478404648725576993643
      );   

      test::return_shared(pool);
    };   

    next_tx(test, bob);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      burn(interest_amm_volatile::add_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(3555, 6, ctx(test)),
        coin::zero(ctx(test)),
        0,
        ctx(test)
      ));

      assert_eq(interest_amm_volatile::lp_coin_supply<LP_COIN>(&pool), 335767435232);
      // Tested via hardhat
      assert_eq(335767435234, 335767435234073784787 / POW_10_9);

      assert_eq(
        interest_amm_volatile::balances<LP_COIN>(&pool),
        vector[14055 * POW_10_18, 8 * POW_10_18]
      );
      assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        14055 * USDC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        8 * ETH_DECIMALS_SCALAR
      );
     assert_eq(
        interest_amm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        1516005048653128167559
      );      
     assert_eq(
        interest_amm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );
     assert_eq(
        interest_amm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );      
     assert_eq(
        interest_amm_volatile::xcp_profit<LP_COIN>(&pool),
        1000178579901483538
      );  
     assert_eq(
        interest_amm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_amm_volatile::virtual_price<LP_COIN>(&pool),
        1000178579901483538
      );        
     assert_eq(
        interest_amm_volatile::invariant_<LP_COIN>(&pool),
        26013078280601615786050
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
    
    setup_2pool(test, 4500, 3);
    let c = clock::create_for_testing(ctx(test));

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      let i = 0;

      while (8 > i) {
        burn(interest_amm_volatile::swap<USDC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(500, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        i = i + 1;
      };

      burn(interest_amm_volatile::add_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(4500, 6, ctx(test)),
        mint<ETH>(3, 9, ctx(test)),
        0,
        ctx(test)
      ));      

      assert_eq(interest_amm_volatile::lp_coin_supply<LP_COIN>(&pool), 244539028189);
      // Tested via hardhat
      assert_eq(244539028189 + 1, 244539028190137475954 / POW_10_9);

      assert_eq(
        interest_amm_volatile::balances<LP_COIN>(&pool),
        vector[13000 * POW_10_18, 4567622127595462229]
      );
      assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        13000 * USDC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        4567622131
      );
     assert_eq(
        interest_amm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        2786752167066841674560
      );      
     assert_eq(
        interest_amm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );
     assert_eq(
        interest_amm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );      
     assert_eq(
        interest_amm_volatile::xcp_profit<LP_COIN>(&pool),
        1001168132263464894
      );  
     assert_eq(
        interest_amm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_amm_volatile::virtual_price<LP_COIN>(&pool),
        1001168132263464894
      );        
     assert_eq(
        interest_amm_volatile::invariant_<LP_COIN>(&pool),
        18964038331684244301432
      );

      burn(interest_amm_volatile::add_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        &c,
        coin::zero(ctx(test)),
        mint<ETH>(7, 9, ctx(test)),
        0,
        ctx(test)
      ));      

      assert_eq(interest_amm_volatile::lp_coin_supply<LP_COIN>(&pool), 388129423444);
      // Tested via hardhat
      assert_eq(388129423446, 388129423446248101851 / POW_10_9);

      assert_eq(
        interest_amm_volatile::balances<LP_COIN>(&pool),
        vector[13000 * POW_10_18, 11567622127595462229]
      );

      assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        13000 * USDC_DECIMALS_SCALAR
      );

     assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        11567622131
      );

     assert_eq(
        interest_amm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        1767841266387619531190
      );

     assert_eq(
        interest_amm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );

     assert_eq(
        interest_amm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );    

     assert_eq(
        interest_amm_volatile::xcp_profit<LP_COIN>(&pool),
        1001695159722318915
      );  

     assert_eq(
        interest_amm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  

     assert_eq(
        interest_amm_volatile::virtual_price<LP_COIN>(&pool),
        1001695159722318915
      );        
     
     assert_eq(
        interest_amm_volatile::invariant_<LP_COIN>(&pool),
        30115339782508672007053
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
    
    setup_2pool(test, 4500, 3);
    let c = clock::create_for_testing(ctx(test));

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      let i = 0;

           assert_eq(
        interest_amm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );   

     clock::increment_for_testing(&mut c, 31000);

      while (8 > i) {

        burn(interest_amm_volatile::swap<USDC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(500, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS + 1);

        i = i + 1;
      };

      burn(interest_amm_volatile::add_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(4500, 6, ctx(test)),
        mint<ETH>(3, 9, ctx(test)),
        0,
        ctx(test)
      ));      

      assert_eq(interest_amm_volatile::lp_coin_supply<LP_COIN>(&pool), 244539028189);
      // Tested via hardhat
      assert_eq(244539028189 + 1, 244539028190137475954 / POW_10_9);

      assert_eq(
        interest_amm_volatile::balances<LP_COIN>(&pool),
        vector[13000 * POW_10_18, 4567622127595462229]
      );
      assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        13000 * USDC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        4567622131
      );
     assert_eq(
        interest_amm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        2786752167066841674560
      );      
     assert_eq(
        interest_amm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );
     assert_eq(
        interest_amm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500344250359062078083
      );      
     assert_eq(
        interest_amm_volatile::xcp_profit<LP_COIN>(&pool),
        1001168132263464894
      );  
     assert_eq(
        interest_amm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_amm_volatile::virtual_price<LP_COIN>(&pool),
        1001168132263464894
      );        
     assert_eq(
        interest_amm_volatile::invariant_<LP_COIN>(&pool),
        18964038331684244301432
      );

      clock::increment_for_testing(&mut c, 1000);

      burn(interest_amm_volatile::add_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        &c,
        coin::zero(ctx(test)),
        mint<ETH>(7, 9, ctx(test)),
        0,
        ctx(test)
      ));      

      assert_eq(interest_amm_volatile::lp_coin_supply<LP_COIN>(&pool), 388129423444);
      // Tested via hardhat
      assert_eq(388129423446, 388129423446248101851 / POW_10_9);

      assert_eq(
        interest_amm_volatile::balances<LP_COIN>(&pool),
        vector[13000 * POW_10_18, 11567622127595462229]
      );

      assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        13000 * USDC_DECIMALS_SCALAR
      );

     assert_eq(
        interest_amm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        11567622131
      );

     assert_eq(
        interest_amm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        1767841266387619531190
      );

     assert_eq(
        interest_amm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );

     assert_eq(
        interest_amm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500345679700521748269
      );    

     assert_eq(
        interest_amm_volatile::xcp_profit<LP_COIN>(&pool),
        1001695159722318915
      );  

     assert_eq(
        interest_amm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  

     assert_eq(
        interest_amm_volatile::virtual_price<LP_COIN>(&pool),
        1001695159722318915
      );        
     
     assert_eq(
        interest_amm_volatile::invariant_<LP_COIN>(&pool),
        30115339782508672007053
      );

      test::return_shared(pool);
    };

    clock::destroy_for_testing(c);
    test::end(scenario);     
  }    
}