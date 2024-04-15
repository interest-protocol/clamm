// * 2 Pool - USDC - ETH
// All values tested agaisnt Curve pool
#[test_only]
module clamm::volatile_2pool_add_liquidity_tests {
  use sui::clock;
  use sui::coin::{Self, burn_for_testing as burn};

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx}; 

  use clamm::interest_clamm_volatile;
  use clamm::eth::ETH;
  use clamm::usdc::USDC;
  use clamm::lp_coin::LP_COIN;
  use clamm::curves::Volatile;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_volatile::setup_2pool;
  use clamm::amm_test_utils ::{people, scenario, mint};

  const ETH_DECIMALS_SCALAR: u64 = 1000000000;
  const USDC_DECIMALS_SCALAR: u64 = 1000000; 
  const TWENTY_MILLISECONDS: u64 = 22000;

  const POW_10_18: u256 = 1_000_000_000_000_000_000;
  const POW_10_9: u256 = 1_000_000_000; 

  #[test]
  fun mints_correct_lp_coin_amount() {
    let mut scenario = scenario();
    let (alice, bob) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let c = clock::create_for_testing(ctx(test));

    next_tx(test, alice);
    {
      let mut pool= test::take_shared<InterestPool<Volatile>>(test);

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 116189500386);
      // Tested via hardhat
      assert_eq(116189500386, 116189500386222506555 / POW_10_9);
      // Our balancs are stored with 1e18 instead of the real balances
      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[4500 * POW_10_18, 3 * POW_10_18]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        4500 * USDC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
        3 * ETH_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );      
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );      
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        POW_10_18
      );        
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        9000000000000000000000
      );   

      test::return_shared(pool);
    };

    next_tx(test, bob);
    {
      let mut pool= test::take_shared<InterestPool<Volatile>>(test);

      burn(interest_clamm_volatile::add_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(6000, 6, ctx(test)),
        mint<ETH>(5, 9, ctx(test)),
        0,
        ctx(test)
      ));

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 290178641322);
      // Tested via hardhat
      assert_eq(290178641323, 290178641323480024837 / POW_10_9);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[10500 * POW_10_18, 8 * POW_10_18]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        10500 * USDC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
        8 * ETH_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        1367804588351518548120
      );      
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );      
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1000056223494887386
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1000056223494887386
      );        
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        22478404648725576993643
      );   

      test::return_shared(pool);
    };   

    next_tx(test, bob);
    {
      let mut pool= test::take_shared<InterestPool<Volatile>>(test);

      burn(interest_clamm_volatile::add_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(3555, 6, ctx(test)),
        coin::zero(ctx(test)),
        0,
        ctx(test)
      ));

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 335767435231);
      // Tested via hardhat
      assert_eq(335767435234, 335767435234073784787 / POW_10_9);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[14055 * POW_10_18, 8 * POW_10_18]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        14055 * USDC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
        8 * ETH_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        1516005048677938417096
      );      
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );      
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1000178579902674702
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1000178579902674702
      );        
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        26013078280601615786050
      );   

      test::return_shared(pool);
    };   

    clock::destroy_for_testing(c);
    test::end(scenario);     
  }

  #[test]
  fun mints_correct_lp_after_swap() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let c = clock::create_for_testing(ctx(test));

    next_tx(test, alice);
    {
      let mut pool= test::take_shared<InterestPool<Volatile>>(test);

      let mut i = 0;

      while (8 > i) {
        burn(interest_clamm_volatile::swap<USDC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(500, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        i = i + 1;
      };

      burn(interest_clamm_volatile::add_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(4500, 6, ctx(test)),
        mint<ETH>(3, 9, ctx(test)),
        0,
        ctx(test)
      ));      

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 244539028188);
      // Tested via hardhat
      assert_eq(244539028189 + 1, 244539028190137475954 / POW_10_9);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[13000 * POW_10_18, 4567622127595462229]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        13000 * USDC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
        4567622131
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        2786752167066841674560
      );      
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );      
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1001168132266667655
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1001168132266667655
      );        
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        18964038331684244301432
      );

      burn(interest_clamm_volatile::add_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        &c,
        coin::zero(ctx(test)),
        mint<ETH>(7, 9, ctx(test)),
        0,
        ctx(test)
      ));      

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 388129423442);
      // Tested via hardhat
      assert_eq(388129423446, 388129423446248101851 / POW_10_9);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[13000 * POW_10_18, 11567622127595462229]
      );

      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        13000 * USDC_DECIMALS_SCALAR
      );

     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
        11567622131
      );

     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        1767841266383700717695
      );

     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );

     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );    

     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1001695159726921902
      );  

     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  

     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1001695159726921902
      );        
     
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        30115339782508672007053
      );

      test::return_shared(pool);
    };

    clock::destroy_for_testing(c);
    test::end(scenario);     
  }  

  #[test]
  fun mints_correct_lp_after_swap_time_delay() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let mut c = clock::create_for_testing(ctx(test));

    next_tx(test, alice);
    {
      let mut pool= test::take_shared<InterestPool<Volatile>>(test);

      let mut i = 0;

           assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );   

     clock::increment_for_testing(&mut c, 31000);

      while (8 > i) {

        burn(interest_clamm_volatile::swap<USDC, ETH, LP_COIN>(
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

      burn(interest_clamm_volatile::add_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(4500, 6, ctx(test)),
        mint<ETH>(3, 9, ctx(test)),
        0,
        ctx(test)
      ));      

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 244539028188);
      // Tested via hardhat
      assert_eq(244539028189 + 1, 244539028190137475954 / POW_10_9);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[13000 * POW_10_18, 4567622127595462229]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        13000 * USDC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
        4567622131
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        2786752167066841674560
      );      
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1500345157438641016991
      );      
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1001168132266667655
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1001168132266667655
      );        
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        18964038331684244301432
      );

      clock::increment_for_testing(&mut c, 1000);

      burn(interest_clamm_volatile::add_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        &c,
        coin::zero(ctx(test)),
        mint<ETH>(7, 9, ctx(test)),
        0,
        ctx(test)
      ));      

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 388129423442);
      // Tested via hardhat
      assert_eq(388129423446, 388129423446248101851 / POW_10_9);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[13000 * POW_10_18, 11567622127595462229]
      );

      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        13000 * USDC_DECIMALS_SCALAR
      );

     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
        11567622131
      );

     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        1767841266383700717695
      );

     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );

     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1500346639262541997545
      );    

     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1001695159726921902
      );  

     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  

     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1001695159726921902
      );        
     
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        30115339782508672007053
      );

      test::return_shared(pool);
    };

    clock::destroy_for_testing(c);
    test::end(scenario);     
  }    
}