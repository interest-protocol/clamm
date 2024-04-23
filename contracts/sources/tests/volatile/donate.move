// * 2 Pool - USDC - ETH
// All values tested agaisnt Curve pool
#[test_only]
module clamm::volatile_donate_tests {
  use sui::clock;

  use sui::test_utils::{assert_eq, destroy};
  use sui::test_scenario::{Self as test, next_tx, ctx}; 

  use clamm::interest_clamm_volatile;
  use clamm::usdc::USDC;
  use clamm::lp_coin::LP_COIN;
  use clamm::curves::Volatile;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_volatile::setup_2pool;
  use clamm::amm_test_utils ::{people, scenario, mint};

  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18

// mint<USDC>(4500, 6, ctx(test))

  #[test]
  fun donate() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let c = clock::create_for_testing(ctx(test));

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let c = clock::create_for_testing(test.ctx());
      let balances = interest_clamm_volatile::balances<LP_COIN>(&mut pool);

      assert_eq(balances, vector[4500 * PRECISION, 3 * PRECISION]);

      let prev_d = interest_clamm_volatile::invariant_<LP_COIN>(&mut pool);

      interest_clamm_volatile::donate<USDC, LP_COIN>(&mut pool, &c, mint<USDC>(1000, 6, ctx(test)));

      let balances = interest_clamm_volatile::balances<LP_COIN>(&mut pool);
      let d = interest_clamm_volatile::invariant_<LP_COIN>(&mut pool);

      assert_eq(balances, vector[5500 * PRECISION, 3 * PRECISION]);   
      assert_eq(d > prev_d, true);   

      destroy(c);
      test::return_shared(pool);
    };  

    clock::destroy_for_testing(c);
    test::end(scenario);
  }
}