// * 2 Pool - USDC - ETH
// All values tested agaisnt Curve pool
#[test_only]
module amm::volatile_2pool_add_liquidity_tests {
  use std::vector;
  use std::type_name;
  
  use sui::clock;
  use sui::coin::{Self, burn_for_testing as burn, TreasuryCap};

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx}; 

  use amm::interest_amm_volatile;
  use amm::eth::ETH;
  use amm::usdc::USDC;
  use amm::lp_coin::LP_COIN;
  use amm::curves::Volatile;
  use amm::interest_pool::InterestPool;
  use amm::init_interest_amm_volatile::setup_2pool;
  use amm::amm_test_utils ::{people, scenario, normalize_amount};

  const ETH_DECIMALS_SCALAR: u64 = 1000000000;
  const USDC_DECIMALS_SCALAR: u64 = 1000000; 

  const POW_10_18: u256 = 1_000_000_000_000_000_000;
  const POW_10_9: u256 = 1_000_000_000; 

  #[test]
  fun mints_correct_lp_coin_amount() {
    let scenario = scenario();
    let (alice, _) = people();

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
    clock::destroy_for_testing(c);
    test::end(scenario);     
  }
}