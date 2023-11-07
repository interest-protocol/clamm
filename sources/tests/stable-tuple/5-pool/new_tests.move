// * 4 Pool - DAI - USDC - USDT - FRAX - TRUE USD
#[test_only]
module amm::stable_tuple_5pool_new_tests {
  use std::vector;

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx};

  use amm::stable_tuple;
  use amm::lp_coin::LP_COIN;
  use amm::curves::StableTuple;
  use amm::interest_pool::Pool;
  use amm::init_stable_tuple::setup_5pool;
  use amm::test_utils::{people, scenario, normalize_amount};

  const INITIAL_A: u256 = 360;

  #[test]
  fun sets_initial_state_correctly() {
   let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_5pool(test, 100, 2000, 30000, 45000, 45000);

    next_tx(test, alice);
    {
      let pool = test::take_shared<Pool<StableTuple>>(test);

      let (balances, initial_a, future_a, initial_a_time, future_a_time, supply, lp_coin_decimals, n_coins, _) = stable_tuple::view_state<LP_COIN>(&pool);

      assert_eq(n_coins, 5);
      assert_eq(vector::length(&balances), 5);
      
      let bals = vector[
        normalize_amount(100),
        normalize_amount(2000),
        normalize_amount(30000),
        normalize_amount(45000),
        normalize_amount(45000)
      ];

      {
        let i = 0;
        while (n_coins > i) {
          // We initiated all balances with 1000
          assert_eq(*vector::borrow(&balances, i), *vector::borrow(&bals, i));
          i = i + 1;
        };
      };

      assert_eq(initial_a, INITIAL_A);
      assert_eq(future_a, INITIAL_A);
      assert_eq(initial_a_time, 0);
      assert_eq(future_a_time, 0);
      assert_eq(supply, 103827319551970);
      assert_eq(lp_coin_decimals, 1_000_000_000);


      test::return_shared(pool);
    };
    test::end(scenario);      
  }
}