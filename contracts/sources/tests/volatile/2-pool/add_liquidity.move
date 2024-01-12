// * 2 Pool - USDC - ETH
// All values tested agaisnt Curve pool
#[test_only]
module amm::volatile_2pool_add_liquidity_tests {
  use sui::clock;
  use sui::coin::{burn_for_testing as burn};

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

      assert_eq(interest_amm_volatile::lp_coin_supply<LP_COIN>(&pool), 290062042772);
      // Tested via hardhat

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
        1000458224059486969
      );  
     assert_eq(
        interest_amm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_amm_volatile::virtual_price<LP_COIN>(&pool),
        1000458224059486969
      );        
     assert_eq(
        interest_amm_volatile::invariant_<LP_COIN>(&pool),
        22478404648725576993643
      );   

      test::return_shared(pool);
    };   
    clock::destroy_for_testing(c);
    test::end(scenario);     
  }
}