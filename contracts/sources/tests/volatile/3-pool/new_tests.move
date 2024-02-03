// * 2 Pool - USDC - ETH - btc
#[test_only]
module clamm::volatile_3pool_new_tests {
  use std::type_name;
  
  use sui::clock;

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx}; 

  use clamm::interest_clamm_volatile;
  use clamm::eth::ETH;
  use clamm::btc::BTC;
  use clamm::usdc::USDC;
  use clamm::lp_coin::LP_COIN;
  use clamm::curves::Volatile;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_volatile::setup_3pool;
  use clamm::amm_test_utils ::{people, scenario, normalize_amount};

  const A: u256  = 36450000;
  const GAMMA: u256 = 70000000000000;
  const MID_FEE: u256 = 4000000;
  const OUT_FEE: u256 = 40000000;
  const ALLOWED_EXTRA_PROFIT: u256 = 2000000000000;
  const FEE_GAMMA: u256 = 10000000000000000;
  const ADJUSTMENT_STEP: u256 = 1500000000000000;
  const MA_TIME: u256 = 600_000; // 10 minutes
  const PRECISION: u256 = 1_000_000_000_000_000_000;
  const INITIAL_ETH_PRICE: u256 = 1500 * 1_000_000_000_000_000_000;
  const BTC_INITIAL_PRICE: u256 = 47500 * 1_000_000_000_000_000_000;
  const INITIAL_ADMIN_FEE: u256 = 2000000000;

  const BTC_DECIMALS_SCALAR: u64 = 1_000_000_000;
  const ETH_DECIMALS_SCALAR: u64 = 1_000_000_000;
  const USDC_DECIMALS_SCALAR: u64 = 1_000_000;   

  #[test]
  fun sets_3pool_state_correctly() {
    let scenario = scenario();
    let (alice, _) = people();    

    let test = &mut scenario;

    setup_3pool(test, 150_000, 3, 100);

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      let c = clock::create_for_testing(ctx(test));

      clock::destroy_for_testing(c);

      test::return_shared(pool);
    };

    test::end(scenario);
  }  
} 