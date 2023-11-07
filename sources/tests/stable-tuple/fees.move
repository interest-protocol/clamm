// * 3 Pool - DAI - USDC - USDT
#[test_only]
module amm::stable_tuple_fees_tests {
  use std::vector;

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx};

  use amm::stable_tuple;
  use amm::lp_coin::LP_COIN;
  use amm::curves::StableTuple;
  use amm::interest_pool::Pool;
  use amm::init_stable_tuple::setup_3pool;
  use amm::test_utils::{people, scenario, normalize_amount};

  const INITIAL_A: u256 = 360;

  #[test]
  fun sets_initial_state_correctly() {
   let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let pool = test::take_shared<Pool<StableTuple>>(test);

      let (balances, initial_a, future_a, initial_a_time, future_a_time, supply, lp_coin_decimals, n_coins, _) = stable_tuple::view_state<LP_COIN>(&pool);

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

      assert_eq(initial_a, INITIAL_A);
      assert_eq(future_a, INITIAL_A);
      assert_eq(initial_a_time, 0);
      assert_eq(future_a_time, 0);
      assert_eq(supply, 3000000000000); // 3000 Stable coin USD were intially deposited
      assert_eq(lp_coin_decimals, 1_000_000_000);


      test::return_shared(pool);
    };
    test::end(scenario);      
  }
}