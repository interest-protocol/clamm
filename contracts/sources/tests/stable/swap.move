// * 3 InterestPool - DAI - USDC - USDT
#[test_only]
module amm::stable_tuple_swap_tests {
 use std::option;

  use sui::clock::Clock;
  use sui::test_utils::assert_eq;
  use sui::coin::burn_for_testing as burn;
  use sui::test_scenario::{Self as test, next_tx, ctx};

  use suitears::comparator::{Self, eq};

  use amm::dai::DAI;
  use amm::usdt::USDT;
  use amm::usdc::USDC;
  use amm::stable_fees;
  use amm::stable_math;
  use amm::curves::Stable;
  use amm::interest_stable;
  use amm::amm_admin::Admin;
  use amm::lp_coin::LP_COIN;
  use amm::interest_pool::InterestPool;
  use amm::init_interest_stable::setup_3pool;
  use amm::stable_simulation::{Self as sim, State as SimState};
  use amm::amm_test_utils::{people, scenario, normalize_amount, mint};

  const DAI_DECIMALS: u8 = 9;
  const DAI_DECIMALS_SCALAR: u256 = 1000000000; 
  const USDC_DECIMALS_SCALAR: u256 = 1000000; 
  const USDT_DECIMALS_SCALAR: u256 = 1000000000; 
  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18
  const MAX_ADMIN_FEE: u256 = 200000000000000000; // 20%

  #[test]
  fun swap_no_admin_fee() {
   let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test);
      let sim_state = test::take_shared<SimState>(test); 

      let coin_usdc = interest_stable::swap<DAI, USDC, LP_COIN>(
        &mut pool,
        &c,
        mint<DAI>(344, DAI_DECIMALS, ctx(test)),
        0,
        ctx(test)
      );

      let balances_2 = interest_stable::balances<LP_COIN>(&pool);

      let expected_amount = sim::swap(&mut sim_state, 0, 1, normalize_amount(344));

      let coin_usdc_amount = burn(coin_usdc);

      assert_eq(coin_usdc_amount, ((expected_amount * USDC_DECIMALS_SCALAR / PRECISION) as u64));

      let expected_balances = vector[
        normalize_amount(1344),
        ((1000 * (USDC_DECIMALS_SCALAR as u64) - coin_usdc_amount) as u256) * PRECISION / USDC_DECIMALS_SCALAR,
        normalize_amount(1000)
      ];

      assert_eq(eq(&comparator::compare(&balances_2, &expected_balances)), true);

      let dai_balance = interest_stable::coin_balance<DAI, LP_COIN>(&pool);
      let usdc_balance = interest_stable::coin_balance<USDC, LP_COIN>(&pool);
      let usdt_balance = interest_stable::coin_balance<USDT, LP_COIN>(&pool);

      let coin_balances = vector[dai_balance, usdc_balance, usdt_balance];
      let expected_balances = vector[
        1344 * (DAI_DECIMALS_SCALAR as u64),
        1000 * (USDC_DECIMALS_SCALAR as u64) - coin_usdc_amount,
        1000 * (USDT_DECIMALS_SCALAR as u64)
      ];

      assert_eq(eq(&comparator::compare(&expected_balances, &coin_balances)), true);
      assert_eq(interest_stable::admin_balance<DAI, LP_COIN>(&pool), 0);
      assert_eq(interest_stable::admin_balance<USDC, LP_COIN>(&pool), 0);

      test::return_shared(sim_state);
      test::return_shared(c);
      test::return_shared(pool);
    };
    test::end(scenario); 
  }

  #[test]
  fun swap_admin_fee() {
   let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test);
      let sim_state = test::take_shared<SimState>(test); 
      let admin_cap = test::take_from_sender<Admin>(test);

      interest_stable::update_fee<LP_COIN>(
           &mut pool,
        &admin_cap,
        option::none(),
        option::none(),
        option::some(MAX_ADMIN_FEE)
      );

      let coin_usdc = interest_stable::swap<DAI, USDC, LP_COIN>(
        &mut pool,
        &c,
        mint<DAI>(344, DAI_DECIMALS, ctx(test)),
        0,
        ctx(test)
      );

      burn(coin_usdc);

      let fees = interest_stable::fees<LP_COIN>(&pool);

      let amp = interest_stable::a<LP_COIN>(&pool, &c);

      let fee_in = stable_fees::calculate_fee_in_amount(&fees, ((344 * DAI_DECIMALS_SCALAR) as u64));
      let admin_fee_in = stable_fees::calculate_admin_amount(&fees, fee_in);

      let y = stable_math::y(
        amp, 
        0, 
        1,
        normalize_amount(1000) + ((344 * DAI_DECIMALS_SCALAR - ((fee_in + admin_fee_in) as u256)) * PRECISION / DAI_DECIMALS_SCALAR),
        vector[normalize_amount(1000), normalize_amount(1000), normalize_amount(1000)]
      );

      let dy = normalize_amount(1000) - y;

      let dy = ((dy * USDC_DECIMALS_SCALAR / PRECISION) as u64);

      let fee_out = stable_fees::calculate_fee_out_amount(&fees, dy);
      let admin_fee_out = stable_fees::calculate_admin_amount(&fees, fee_out);

      assert_eq(interest_stable::admin_balance<DAI, LP_COIN>(&pool), (admin_fee_in as u64));
      assert_eq(interest_stable::admin_balance<USDC, LP_COIN>(&pool), admin_fee_out);

      test::return_to_sender(test, admin_cap);
      test::return_shared(sim_state);
      test::return_shared(c);
      test::return_shared(pool);
    };
    test::end(scenario); 
  }

  #[test]
  #[expected_failure(abort_code = amm::errors::SLIPPAGE, location = amm::interest_stable)]  
  fun swap_slippage() {
   let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test);
      let sim_state = test::take_shared<SimState>(test); 


      let fees = interest_stable::fees<LP_COIN>(&pool);

      let amp = interest_stable::a<LP_COIN>(&pool, &c);

      let fee_in = stable_fees::calculate_fee_in_amount(&fees, ((344 * DAI_DECIMALS_SCALAR) as u64));
      let admin_fee_in = stable_fees::calculate_admin_amount(&fees, fee_in);

      let y = stable_math::y(
        amp, 
        0, 
        1,
        normalize_amount(1000) + ((344 * DAI_DECIMALS_SCALAR - ((fee_in + admin_fee_in) as u256)) * PRECISION / DAI_DECIMALS_SCALAR),
        vector[normalize_amount(1000), normalize_amount(1000), normalize_amount(1000)]
      );

      let dy = normalize_amount(1000) - y;

      let dy = ((dy * USDC_DECIMALS_SCALAR / PRECISION) as u64);


      burn(interest_stable::swap<DAI, USDC, LP_COIN>(
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
}
