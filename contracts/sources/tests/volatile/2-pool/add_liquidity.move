// * 2 Pool - USDC - ETH
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

  #[test]
  fun mints_correct_lp_coin_amount() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 15000, 10);
    let c = clock::create_for_testing(ctx(test));

    next_tx(test, alice);
    {};
    clock::destroy_for_testing(c);
    test::end(scenario);     
  }
}