// * 3 InterestPool - DAI - USDC - USDT
#[test_only]
module clamm::stable_swap_tests {

  use sui::clock::Clock;
  use sui::coin::burn_for_testing as burn;
  use sui::test_utils::{assert_eq, destroy};
  use sui::test_scenario::{Self as test, next_tx, ctx};

  use suitears::comparator::{Self, eq};
  use suitears::math256::mul_div_up;
  
  use clamm::dai::DAI;
  use clamm::usdt::USDT;
  use clamm::usdc::USDC;
  use clamm::stable_math;
  use clamm::curves::Stable;
  use clamm::lp_coin::LP_COIN;
  use clamm::pool_admin::PoolAdmin;
  use clamm::interest_clamm_stable;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_stable::setup_3pool;
  use clamm::stable_simulation::{Self as sim, State as SimState};
  use clamm::amm_test_utils::{people, scenario, normalize_amount, mint};

  const DAI_DECIMALS: u8 = 9;
  const DAI_DECIMALS_SCALAR: u256 = 1_000_000_000; 
  const USDC_DECIMALS_SCALAR: u256 = 1000000; 
  const USDT_DECIMALS_SCALAR: u256 = 1000000000; 
  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18
  const MAX_ADMIN_FEE: u256 = 200000000000000000; // 20%

  #[test]
  fun swap_admin_fee() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test);
      let mut sim_state = test::take_shared<SimState>(test); 

      let coin_usdc = interest_clamm_stable::swap<DAI, USDC, LP_COIN>(
        &mut pool,
        &c,
        mint<DAI>(344, DAI_DECIMALS, ctx(test)),
        0,
        ctx(test)
      );

      let balances_2 = interest_clamm_stable::balances<LP_COIN>(&mut pool);

      let (expected_amount, fee) = sim::swap(&mut sim_state, 0, 1, normalize_amount(344));

      let admin_fee = mul_div_up(fee, MAX_ADMIN_FEE, PRECISION);

      let coin_usdc_amount = burn(coin_usdc);

      assert_eq(
        coin_usdc_amount, 
        ((expected_amount * USDC_DECIMALS_SCALAR / PRECISION) as u64) - ((fee * USDC_DECIMALS_SCALAR / PRECISION) as u64)
      );

      assert_eq(eq(&comparator::compare(&balances_2, &sim_state.xp())), true);

      let dai_balance = interest_clamm_stable::coin_balance<DAI, LP_COIN>(&mut pool);
      let usdc_balance = interest_clamm_stable::coin_balance<USDC, LP_COIN>(&mut pool);
      let usdt_balance = interest_clamm_stable::coin_balance<USDT, LP_COIN>(&mut pool);

      let admin_fee = ((admin_fee  * USDC_DECIMALS_SCALAR / PRECISION) as u64); 

      let coin_balances = vector[dai_balance, usdc_balance, usdt_balance];
      let expected_balances = vector[
        1344 * (DAI_DECIMALS_SCALAR as u64),
        (1000 * (USDC_DECIMALS_SCALAR) as u64) - admin_fee - coin_usdc_amount,
        1000 * (USDT_DECIMALS_SCALAR as u64)
      ];

      assert_eq(eq(&comparator::compare(&expected_balances, &coin_balances)), true);
      assert_eq(interest_clamm_stable::admin_balance<DAI, LP_COIN>(&mut pool), 0);
      assert_eq(interest_clamm_stable::admin_balance<USDC, LP_COIN>(&mut pool), admin_fee);

      test::return_shared(sim_state);
      test::return_shared(c);
      test::return_shared(pool);
    };
    test::end(scenario); 
  }

  #[test]
  fun swap_no_admin_fee() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test);
      let sim_state = test::take_shared<SimState>(test); 
      let admin_cap = test::take_from_sender<PoolAdmin>(test);

      interest_clamm_stable::commit_fee<LP_COIN>(&mut pool, &admin_cap, option::some(0), option::some(0), test.ctx());

      test.next_epoch(@0x0);
      test.next_epoch(@0x0);
      test.next_epoch(@0x0);
      test.next_epoch(@0x0);

      interest_clamm_stable::update_fee<LP_COIN>(
        &mut pool,
        &admin_cap,
        test.ctx()
      );

      let coin_usdc = interest_clamm_stable::swap<DAI, USDC, LP_COIN>(
        &mut pool,
        &c,
        mint<DAI>(344, DAI_DECIMALS, ctx(test)),
        0,
        ctx(test)
      );

      burn(coin_usdc);

      assert_eq(interest_clamm_stable::admin_balance<DAI, LP_COIN>(&mut pool), 0);
      assert_eq(interest_clamm_stable::admin_balance<USDC, LP_COIN>(&mut pool), 0);

      destroy(admin_cap);
      test::return_shared(sim_state);
      test::return_shared(c);
      test::return_shared(pool);
    };
    test::end(scenario); 
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::SLIPPAGE, location = clamm::interest_clamm_stable)]  
  fun swap_slippage() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test);
      let sim_state = test::take_shared<SimState>(test); 

      let amp = interest_clamm_stable::a<LP_COIN>(&mut pool, &c);

      let y = stable_math::y(
        amp, 
        0, 
        1,
        normalize_amount(1000) + ((344 * DAI_DECIMALS_SCALAR) * PRECISION / DAI_DECIMALS_SCALAR),
        vector[normalize_amount(1000), normalize_amount(1000), normalize_amount(1000)]
      );

      let dy = normalize_amount(1000) - y;

      let dy = ((dy * USDC_DECIMALS_SCALAR / PRECISION) as u64);

      burn(interest_clamm_stable::swap<DAI, USDC, LP_COIN>(
        &mut pool,
        &c,
        mint<DAI>(344, DAI_DECIMALS, ctx(test)),
        dy, // does not have fee_out
        ctx(test)
      ));

      test::return_shared(sim_state);
      test::return_shared(c);
      test::return_shared(pool);
    };
    test::end(scenario); 
  }

  #[test]
  fun swap_value_is_too_low_no_fees() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test);
      let cap = test.take_from_sender<PoolAdmin>();

      interest_clamm_stable::commit_fee<LP_COIN>(
        &mut pool,
        &cap,
        option::some(0),
        option::some(MAX_ADMIN_FEE),
        test.ctx()
      );

      test.next_epoch(alice);
      test.next_epoch(alice);
      test.next_epoch(alice);
      test.next_epoch(alice);

      interest_clamm_stable::update_fee<LP_COIN>(&mut pool, &cap, test.ctx());

      burn(interest_clamm_stable::swap<DAI, USDC, LP_COIN>(
        &mut pool,
        &c,
        mint<DAI>(10_000_000, 0, ctx(test)),
        0,
        ctx(test)
      ));

      test.return_to_sender(cap);
      test::return_shared(c);
      test::return_shared(pool);
    };
    test::end(scenario); 
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::POOL_IS_PAUSED, location = clamm::interest_pool)]
  fun swap_is_paused() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test);
      let cap = test.take_from_sender<PoolAdmin>();

      pool.pause(&cap);

      burn(interest_clamm_stable::swap<DAI, USDC, LP_COIN>(
        &mut pool,
        &c,
        mint<DAI>(344, DAI_DECIMALS, ctx(test)),
        0,
        ctx(test)
      ));

      test.return_to_sender(cap);
      test::return_shared(c);
      test::return_shared(pool);
    };
    test::end(scenario); 
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_STABLE_FEE_AMOUNT, location = clamm::interest_clamm_stable)]
  fun swap_value_is_too_low() {
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test);

      burn(interest_clamm_stable::swap<DAI, USDC, LP_COIN>(
        &mut pool,
        &c,
        mint<DAI>(1_000_000, 0, ctx(test)),
        0,
        ctx(test)
      ));

      test::return_shared(c);
      test::return_shared(pool);
    };
    test::end(scenario); 
  }
}
