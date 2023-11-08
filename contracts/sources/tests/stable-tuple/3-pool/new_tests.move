// * 3 Pool - DAI - USDC - USDT
#[test_only]
module amm::stable_tuple_3pool_new_tests {
  use std::vector;

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx};

  use amm::stable_tuple;
  use amm::dai::DAI;
  use amm::usdt::USDT;
  use amm::usdc::USDC;
  use amm::lp_coin::LP_COIN;
  use amm::curves::StableTuple;
  use amm::interest_pool::Pool;
  use amm::init_stable_tuple::setup_3pool;
  use amm::test_utils::{people, scenario, normalize_amount};

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

      let (_, index, balance) = stable_tuple::view_coin_state<DAI, LP_COIN>(&pool);

      assert_eq(index, 0);
      assert_eq(balance, 1000 * DAI_DECIMALS_SCALAR);

      let (_, index, balance) = stable_tuple::view_coin_state<USDC, LP_COIN>(&pool);

      assert_eq(index, 1);
      assert_eq(balance, 1000 * USDC_DECIMALS_SCALAR);

      let (_, index, balance) = stable_tuple::view_coin_state<USDT, LP_COIN>(&pool);

      assert_eq(index, 2);
      assert_eq(balance, 1000 * USDT_DECIMALS_SCALAR); 

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