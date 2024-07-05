// * 2 InterestPool USDC - USDT
#[test_only]
module clamm::stable_tuple_2pool_new_tests {

  use sui::clock::Clock;
  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx};
  use sui::coin::{Self, burn_for_testing as burn, TreasuryCap};
  
  use suitears::coin_decimals::CoinDecimals;

  use clamm::usdt::USDT;
  use clamm::usdc::USDC;
  use clamm::curves::Stable;
  use clamm::interest_pool;
  use clamm::lp_coin::LP_COIN;
  use clamm::interest_clamm_stable;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_stable::setup_2pool;
  use clamm::amm_test_utils::{people, scenario, normalize_amount, setup_dependencies, mint};


  const INITIAL_A: u256 = 360;
  const MAX_A: u256 = 1_000_000;
  const USDC_DECIMALS_SCALAR: u64 = 1000000; 
  const USDT_DECIMALS_SCALAR: u64 = 1000000000;
  const USDC_DECIMALS: u8 = 6; 
  const USDT_DECIMALS: u8 = 9;

  #[test]
  fun sets_initial_state_correctly() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);

      let balances = interest_clamm_stable::balances<LP_COIN>(&mut pool);
      let initial_a = interest_clamm_stable::initial_a<LP_COIN>(&mut pool);
      let future_a = interest_clamm_stable::future_a<LP_COIN>(&mut pool);
      let initial_a_time = interest_clamm_stable::initial_a_time<LP_COIN>(&mut pool);
      let future_a_time = interest_clamm_stable::future_a_time<LP_COIN>(&mut pool);
      let supply = interest_clamm_stable::lp_coin_supply<LP_COIN>(&mut pool);   
      let lp_coin_decimals_scalar = interest_clamm_stable::lp_coin_decimals_scalar<LP_COIN>(&mut pool);  
      let n_coins = interest_clamm_stable::n_coins<LP_COIN>(&mut pool);  

      assert_eq(n_coins, 2);
      assert_eq(vector::length(&balances), 2);

      {
        let mut i = 0;
        while (n_coins > i) {
          // We initiated all balances with 1000
          assert_eq(*vector::borrow(&balances, i), normalize_amount(1000));
          i = i + 1;
        };
      };

      let index = interest_clamm_stable::coin_index<USDC, LP_COIN>(&mut pool);
      let balance = interest_clamm_stable::coin_balance<USDC, LP_COIN>(&mut pool);

      assert_eq(index, 0);
      assert_eq(balance, 1000 * USDC_DECIMALS_SCALAR);

      let index = interest_clamm_stable::coin_index<USDT, LP_COIN>(&mut pool);
      let balance = interest_clamm_stable::coin_balance<USDT, LP_COIN>(&mut pool);

      assert_eq(index, 1);
      assert_eq(balance, 1000 * USDT_DECIMALS_SCALAR);

      assert_eq(initial_a, INITIAL_A);
      assert_eq(future_a, INITIAL_A);
      assert_eq(initial_a_time, 0);
      assert_eq(future_a_time, 0);
      assert_eq(supply, 2000000000000); // 2000 Stable coin USD were intially deposited
      assert_eq(lp_coin_decimals_scalar, 1_000_000_000);


      test::return_shared(pool);
    };
    test::end(scenario);      
  }  

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_AMPLIFIER, location = clamm::interest_clamm_stable)] 
  public fun test_new_pool_a_error() {
    let (alice, _) = people();

    let mut scenario = scenario();
    let test = &mut scenario;

    setup_dependencies(test);

    next_tx(test, alice);
    {
      let c = test::take_shared<Clock>(test);
      let coin_decimals = test::take_shared<CoinDecimals>(test);
      let lp_coin_cap = test::take_from_sender<TreasuryCap<LP_COIN>>(test);

      let (pool, pool_admin, lp_coin) = interest_clamm_stable::new_2_pool(
        &c,
        &coin_decimals,
        mint<USDC>(1000, USDC_DECIMALS, test.ctx()),
        mint<USDT>(1000, USDT_DECIMALS, test.ctx()),
        coin::treasury_into_supply(lp_coin_cap),
        MAX_A,
        test.ctx()
      );

      burn(lp_coin);    
      interest_pool::share(pool);
      transfer::public_transfer(pool_admin, alice);

      test::return_shared(coin_decimals);
      test::return_shared(c);
    };
    test::end(scenario); 
  }  
}