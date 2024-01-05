// * 3 InterestPool - DAI - USDC - USDT
#[test_only]
module amm::stable_tuple_3pool_new_tests {
  use std::vector;

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx};

  use amm::dai::DAI;
  use amm::usdt::USDT;
  use amm::usdc::USDC;
  use amm::curves::Stable;
  use amm::interest_stable;
  use amm::lp_coin::LP_COIN;
  use amm::interest_pool::InterestPool;
  use amm::init_interest_stable::setup_3pool;
  use amm::amm_test_utils::{people, scenario, normalize_amount};

  const INITIAL_A: u256 = 360;
  const DAI_DECIMALS_SCALAR: u64 = 1000000000;
  const USDC_DECIMALS_SCALAR: u64 = 1000000; 
  const USDT_DECIMALS_SCALAR: u64 = 1000000000;

  #[test]
  fun sets_initial_state_correctly() {
   let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Stable>>(test);

      let balances = interest_stable::balances<LP_COIN>(&pool);
      let initial_a = interest_stable::initial_a<LP_COIN>(&pool);
      let future_a = interest_stable::future_a<LP_COIN>(&pool);
      let initial_a_time = interest_stable::initial_a_time<LP_COIN>(&pool);
      let future_a_time = interest_stable::future_a_time<LP_COIN>(&pool);
      let supply = interest_stable::lp_coin_supply<LP_COIN>(&pool);   
      let lp_coin_decimals_scalar = interest_stable::lp_coin_decimals_scalar<LP_COIN>(&pool);  
      let n_coins = interest_stable::n_coins<LP_COIN>(&pool);  

      assert_eq(n_coins, 3);
      assert_eq(vector::length(&balances), 3);

      {
        let i = 0;
        while (n_coins > i) {
          // We initiated all balances with 1000
          assert_eq(*vector::borrow(&balances, i), normalize_amount(1000));
          i = i + 1;
        };
      };

      let index = interest_stable::coin_index<DAI, LP_COIN>(&pool);
      let balance = interest_stable::coin_balance<DAI, LP_COIN>(&pool);

      assert_eq(index, 0);
      assert_eq(balance, 1000 * DAI_DECIMALS_SCALAR);

      let index = interest_stable::coin_index<USDC, LP_COIN>(&pool);
      let balance = interest_stable::coin_balance<USDC, LP_COIN>(&pool);

      assert_eq(index, 1);
      assert_eq(balance, 1000 * USDC_DECIMALS_SCALAR);

      let index = interest_stable::coin_index<USDT, LP_COIN>(&pool);
      let balance = interest_stable::coin_balance<USDT, LP_COIN>(&pool);

      assert_eq(index, 2);
      assert_eq(balance, 1000 * USDT_DECIMALS_SCALAR); 

      assert_eq(initial_a, INITIAL_A);
      assert_eq(future_a, INITIAL_A);
      assert_eq(initial_a_time, 0);
      assert_eq(future_a_time, 0);
      assert_eq(supply, 3000000000000); // 3000 Stable coin USD were intially deposited
      assert_eq(lp_coin_decimals_scalar, 1_000_000_000);


      test::return_shared(pool);
    };
    test::end(scenario);      
  }
}