// * 3 InterestPool - DAI - USDC - USDT
#[test_only]
module clamm::stable_swap_fees_tests {

  use sui::clock::Clock;
  use sui::test_utils::assert_eq;
  use sui::coin::burn_for_testing as burn;
  use sui::test_scenario::{Self as test, next_tx, ctx};

  use clamm::dai::DAI;
  use clamm::usdt::USDT;
  use clamm::usdc::USDC;
  use clamm::stable_fees;
  use clamm::curves::Stable;
  use clamm::lp_coin::LP_COIN;
  use clamm::interest_clamm_stable;
  use clamm::interest_pool::InterestPool;
  use clamm::pool_admin::{Self, PoolAdmin};
  use clamm::init_interest_amm_stable::setup_3pool;
  use clamm::amm_test_utils::{people, scenario, mint};

  const DAI_DECIMALS: u8 = 9;
  const USDC_DECIMALS: u8 = 6; 
  const USDT_DECIMALS: u8 = 9;

  const MAX_FEE_PERCENT: u256 = 20000000000000000; // 2%
  const MAX_ADMIN_FEE: u256 = 200000000000000000; // 20%

  #[test]
  fun updates_fees_correctly() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let admin_cap = test::take_from_sender<PoolAdmin>(test);

      interest_clamm_stable::update_fee<LP_COIN>(
        &mut pool,
        &admin_cap,
        option::some(MAX_FEE_PERCENT),
          option::some(MAX_FEE_PERCENT),
          option::some(MAX_ADMIN_FEE),
      );

      let fees = interest_clamm_stable::fees<LP_COIN>(&mut pool);

      let fee_in = stable_fees::fee_in_percent(&fees);
      let fee_out = stable_fees::fee_out_percent(&fees);
      let fee_admin = stable_fees::admin_fee_percent(&fees);

      assert_eq(fee_in, MAX_FEE_PERCENT);
      assert_eq(fee_out, MAX_FEE_PERCENT);
      assert_eq(fee_admin, MAX_ADMIN_FEE);

      test::return_to_sender(test, admin_cap);
      test::return_shared(pool);
    };
    test::end(scenario);      
  }

  #[test]
  fun takes_fees_correctly() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let admin_cap = test::take_from_sender<PoolAdmin>(test);
      let c = test::take_shared<Clock>(test);

      interest_clamm_stable::update_fee<LP_COIN>(
        &mut pool,
        &admin_cap,
        option::some(MAX_FEE_PERCENT),
        option::some(MAX_FEE_PERCENT),
        option::some(MAX_ADMIN_FEE),
      );

      // Swap to collect fees
      burn(interest_clamm_stable::swap<DAI, USDC, LP_COIN>(
        &mut pool,
        &c,
        mint<DAI>(300, DAI_DECIMALS, ctx(test)),
        0,
        ctx(test)
      ));

      burn(interest_clamm_stable::swap<USDC, USDT, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(300, USDC_DECIMALS, ctx(test)),
        0,
        ctx(test)
      ));

      burn(interest_clamm_stable::swap<USDT, DAI, LP_COIN>(
        &mut pool,
        &c,
        mint<USDT>(300, USDT_DECIMALS, ctx(test)),
        0,
        ctx(test)
      ));

      let balances = interest_clamm_stable::balances<LP_COIN>(&mut pool);

      let admin_dai_balance = interest_clamm_stable::admin_balance<DAI, LP_COIN>(&mut pool);
      let admin_dai = interest_clamm_stable::take_fees<DAI, LP_COIN>(&mut pool, &admin_cap, ctx(test));

      assert_eq(burn(admin_dai), admin_dai_balance);
      assert_eq(interest_clamm_stable::admin_balance<DAI, LP_COIN>(&mut pool), 0);

      let admin_usdc_balance = interest_clamm_stable::admin_balance<USDC, LP_COIN>(&mut pool);
      let admin_usdc = interest_clamm_stable::take_fees<USDC, LP_COIN>(&mut pool, &admin_cap, ctx(test));

      assert_eq(burn(admin_usdc), admin_usdc_balance);
      assert_eq(interest_clamm_stable::admin_balance<USDC, LP_COIN>(&mut pool), 0);

      let admin_usdt_balance = interest_clamm_stable::admin_balance<USDT, LP_COIN>(&mut pool);
      let admin_usdt = interest_clamm_stable::take_fees<USDT, LP_COIN>(&mut pool,&admin_cap,ctx(test));

      assert_eq(burn(admin_usdt), admin_usdt_balance);
      assert_eq(interest_clamm_stable::admin_balance<USDT, LP_COIN>(&mut pool), 0);

      let balances_2 = interest_clamm_stable::balances<LP_COIN>(&mut pool);

      // Admin Balances does not come from pool reserves
      assert_eq(balances_2, balances);
      
      test::return_shared(c);
      test::return_to_sender(test, admin_cap);
      test::return_shared(pool);
    };
    test::end(scenario);      
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_POOL_ADMIN, location = clamm::interest_pool)]
  fun take_fees_invalid_admin() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let pool_admin_cap = pool_admin::new(test.ctx());

      burn(interest_clamm_stable::take_fees<USDC, LP_COIN>(&mut pool, &pool_admin_cap, ctx(test)));

      pool_admin::destroy(pool_admin_cap);
      
      test::return_shared(pool);
    };
    test::end(scenario);      
  }  
}