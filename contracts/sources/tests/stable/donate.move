// * 2 InterestPool -USDC - USDT
#[test_only]
module clamm::stable_donate_tests {

  use sui::clock::Clock;
  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx};

  use clamm::usdc::USDC;
  use clamm::curves::Stable;
  use clamm::interest_clamm_stable;
  use clamm::lp_coin::LP_COIN;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_stable::setup_2pool;
  use clamm::amm_test_utils::{people, scenario, mint};

  const USDC_DECIMALS: u8 = 6; 
  const PRECISION: u256 = 1_000_000_000_000_000_000; 
  
  #[test]
  fun donate() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test); 

      interest_clamm_stable::donate<USDC, LP_COIN>(
        &mut pool,
        mint<USDC>(110, USDC_DECIMALS, ctx(test)),
      );

      assert_eq(interest_clamm_stable::balances<LP_COIN>(&mut pool), vector[1110 * PRECISION, 1000 * PRECISION]);


      test::return_shared(c);
      test::return_shared(pool);
    };
    test::end(scenario);      
  }
}