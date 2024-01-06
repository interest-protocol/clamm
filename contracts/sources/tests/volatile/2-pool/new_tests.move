// * 2 Pool - USDC - ETH
#[test_only]
module amm::volatile_2pool_new_tests {
  // use std::vector;
  
  // use sui::coin::{Self, burn_for_testing as burn, TreasuryCap};

  // use sui::test_utils::assert_eq;
  // use sui::test_scenario::{Self as test, next_tx}; 

  // use amm::interest_amm_volatile;
  // use amm::eth::ETH;
  // use amm::usdc::USDC;
  // use amm::lp_coin::LP_COIN;
  // use amm::curves::Volatile;
  // use amm::interest_pool::InterestPool;
  // use amm::init_interest_amm_volatile::setup_2pool;
  // use amm::amm_test_utils ::{people, scenario, normalize_amount};


  // const A: u256  = 36450000;
  // const GAMMA: u256 = 70000000000000;
  // const MID_FEE: u256 = 4000000;
  // const OUT_FEE: u256 = 40000000;
  // const ALLOWED_EXTRA_PROFIT: u256 = 2000000000000;
  // const FEE_GAMMA: u256 = 10000000000000000;
  // const ADJUSTMENT_STEP: u256 = 1500000000000000;
  // const MA_TIME: u256 = 600_000; // 10 minutes
  // const PRECISION: u256 = 1_000_000_000_000_000_000;
  // const INITIAL_ETH_PRICE: u256 = 1500 * 1_000_000_000_000_000_000;

  // const ETH_DECIMALS_SCALAR: u64 = 1000000000;
  // const USDC_DECIMALS_SCALAR: u64 = 1000000; 

  // #[test]
  // fun sets_initial_state_correctly() {
  //  let scenario = scenario();
  //   let (alice, _) = people();

  //   let test = &mut scenario;
    
  //   setup_2pool(test, 15000, 10);

  //   next_tx(test, alice);
  //   {
  //     let pool = test::take_shared<InterestPool<Volatile>>(test);

  //     test::return_shared(pool);
  //   };
  //   test::end(scenario);   
  // }
}