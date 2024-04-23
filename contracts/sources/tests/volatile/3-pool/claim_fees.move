// * 3 Pool - USDC - BTC - ETH
// All values tested agaisnt Curve pool
#[test_only]
module clamm::volatile_3pool_claim_fees_tests {
  use sui::clock;
  use sui::coin::burn_for_testing as burn;

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx}; 

  use clamm::btc::BTC;
  use clamm::eth::ETH;
  use clamm::usdc::USDC;
  use clamm::lp_coin::LP_COIN;
  use clamm::curves::Volatile;
  use clamm::interest_clamm_volatile;
  use clamm::interest_pool::InterestPool;
  use clamm::pool_admin::{Self, PoolAdmin};
  use clamm::init_interest_amm_volatile::setup_3pool;
  use clamm::amm_test_utils ::{people, scenario, mint};

  #[test]
  fun mints_correct_fees() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 150000, 3, 100);

    let mut c = clock::create_for_testing(ctx(test));

    next_tx(test, alice); 
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);  
      let admin_cap = test::take_from_sender<PoolAdmin>(test);

      let mut i = 0;

      while (200 > i) {

        burn(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(75, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        burn(interest_clamm_volatile::swap<BTC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(2, 9, ctx(test)),
          0,
          ctx(test)
          )
        );    

        burn(interest_clamm_volatile::swap<USDC, BTC, LP_COIN>(
          &mut pool,
          &c,
          mint(100_000, 6, ctx(test)),
          0,
          ctx(test)
          )
        );   

        burn(interest_clamm_volatile::swap<BTC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(15, 8, ctx(test)),
          0,
          ctx(test)
          )
        );    

        clock::increment_for_testing(&mut c, 20_000);

        i = i + 1;
      };

      let mut request = interest_clamm_volatile::balances_request<LP_COIN>(&mut pool);

      interest_clamm_volatile::read_balance<USDC, LP_COIN>(&mut pool, &mut request);
      interest_clamm_volatile::read_balance<ETH, LP_COIN>(&mut pool, &mut request);
      interest_clamm_volatile::read_balance<BTC, LP_COIN>(&mut pool, &mut request);         

      assert_eq(burn(interest_clamm_volatile::claim_admin_fees<LP_COIN>(&mut pool, &admin_cap, &c, request, ctx(test))), 15279144167);

      test::return_to_sender(test, admin_cap);
      test::return_shared(pool);
    };
    
    clock::destroy_for_testing(c);
    test::end(scenario);    
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_POOL_ADMIN, location = clamm::interest_pool)]
  fun teest_claim_fees_invalid_pool_admin() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 150000, 3, 100);

    let c = clock::create_for_testing(ctx(test));

    next_tx(test, alice); 
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);  
      let admin_cap = pool_admin::new(test.ctx());

      let mut request = interest_clamm_volatile::balances_request<LP_COIN>(&mut pool);

      interest_clamm_volatile::read_balance<USDC, LP_COIN>(&mut pool, &mut request);
      interest_clamm_volatile::read_balance<ETH, LP_COIN>(&mut pool, &mut request);
      interest_clamm_volatile::read_balance<BTC, LP_COIN>(&mut pool, &mut request);         

      assert_eq(burn(interest_clamm_volatile::claim_admin_fees<LP_COIN>(&mut pool, &admin_cap, &c, request, ctx(test))), 15279144167);

      pool_admin::destroy(admin_cap);

      test::return_shared(pool);
    };
    
    clock::destroy_for_testing(c);
    test::end(scenario);    
  }
}