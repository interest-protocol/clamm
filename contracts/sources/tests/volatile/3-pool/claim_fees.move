// * 3 Pool - USDC - BTC - ETH
// All values tested agaisnt Curve pool
#[test_only]
module clamm::volatile_3pool_claim_fees_tests {
  use sui::clock;
  use sui::coin::{Self, burn_for_testing as burn};

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx}; 

  use clamm::interest_clamm_volatile;
  use clamm::btc::BTC;
  use clamm::eth::ETH;
  use clamm::usdc::USDC;
  use clamm::lp_coin::LP_COIN;
  use clamm::curves::Volatile;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_volatile::setup_3pool;
  use clamm::amm_test_utils ::{people, scenario, mint};

  const BTC_DECIMALS_SCALAR: u64 = 1000000000;
  const ETH_DECIMALS_SCALAR: u64 = 1000000000;
  const USDC_DECIMALS_SCALAR: u64 = 1000000; 

  const POW_10_18: u256 = 1_000_000_000_000_000_000;
  const POW_10_9: u256 = 1_000_000_000;   

  #[test]
  fun mints_correct_fees() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 150000, 3, 100);

    let c = clock::create_for_testing(ctx(test));

    next_tx(test, alice); 
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);  

      clock::increment_for_testing(&mut c, 14_000);

      let i = 0;

      while (5 > i) {

        clock::increment_for_testing(&mut c, 23_000);

        burn(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(40, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        i = i + 1;
      };

      test::return_shared(pool);
    };
    
    clock::destroy_for_testing(c);
    test::end(scenario);    
  }

}