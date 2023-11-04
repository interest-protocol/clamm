#[test_only]
module amm::stable_pair_tests {
  use std::vector;
  use std::type_name::get;

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, Scenario, next_tx, ctx};
  use sui::coin::{Self, burn_for_testing as burn, CoinMetadata, TreasuryCap};

  use suitears::math256::sqrt_down;
  use suitears::coin_decimals::{Self, CoinDecimals};

  use amm::stable_pair;
  use amm::stable_fees;
  use amm::stable_pair_math;
  use amm::amm_admin as admin;
  use amm::curves::StablePair;
  use amm::usdt::{Self, USDT};
  use amm::usdc::{Self, USDC};
  use amm::lp_coin::{Self, LP_COIN};
  use amm::interest_pool::{Self, Pool};
  use amm::test_utils::{people, scenario, mint, add_decimals};

  const USDC_DECIMALS: u8 = 6;
  const USDT_DECIMALS: u8 = 9;
  const MINIMUM_LIQUIDITY: u64 = 100;
  const INITIAL_FEE_PERCENT: u256 = 250000000000000; // 0.025%

  #[test]
  fun initial_state() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    create_pool_(test);

    next_tx(test, alice);
    {
      let pool = test::take_shared<Pool<StablePair>>(test);

      let coins = interest_pool::view_coins(&pool);

      assert_eq(*vector::borrow(&coins, 0),get<USDC>());
      assert_eq(*vector::borrow(&coins, 1),get<USDT>());

      let (supply, balance_x, balance_y, admin_fee_balance_x, admin_fee_balance_y, decimals_x, decimals_y, seed_liquidity, fees) = stable_pair::view_state<USDC, USDT, LP_COIN>(&pool);

      let lp_coin_initial_user_balance = (sqrt_down(((add_decimals(100, 6) * add_decimals(100, 9)) as u256)) as u64);

      assert_eq(supply, lp_coin_initial_user_balance + seed_liquidity);
      assert_eq(balance_x, add_decimals(100, 6));
      assert_eq(balance_y, add_decimals(100, 9));
      assert_eq(admin_fee_balance_x, 0);
      assert_eq(admin_fee_balance_y, 0);
      assert_eq(decimals_x, add_decimals(1, 6));
      assert_eq(decimals_y, add_decimals(1, 9));
      assert_eq(seed_liquidity, MINIMUM_LIQUIDITY);

      let (fee_in, fee_out, fee_admin) = stable_fees::view(&fees);

      assert_eq(fee_in, INITIAL_FEE_PERCENT);
      assert_eq(fee_out, INITIAL_FEE_PERCENT);
      assert_eq(fee_admin, 0);


      test::return_shared(pool);
    };

    test::end(scenario);
  }

  #[test]
  fun swap_usdc() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    create_pool_(test);

    next_tx(test, alice);
    {
      let pool = test::take_shared<Pool<StablePair>>(test);

      let usdc_amount = 10000000; // 10

      let (_, balance_x, balance_y, _, _, decimals_x, decimals_y, _, fees) = stable_pair::view_state<USDC, USDT, LP_COIN>(&pool);

      let k = stable_pair_math::invariant_(balance_x, balance_y, decimals_x, decimals_y);

      let fee_in = stable_fees::calculate_fee_in_amount(&fees, usdc_amount);

      let amount_out = stable_pair_math::calculate_amount_out(k, usdc_amount - fee_in, balance_x, balance_y, decimals_x, decimals_y, true);

      let fee_out = stable_fees::calculate_fee_out_amount(&fees, amount_out);

      let coin_usdt = stable_pair::swap<USDC, USDT, LP_COIN>(
        &mut pool,
        mint<USDC>(10, 6, ctx(test)),
        0,
        ctx(test)
      );

      assert_eq(burn(coin_usdt), amount_out - fee_out);

      test::return_shared(pool);
    };
    test::end(scenario);  
  }

  #[test]
  fun swap_usdt() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    create_pool_(test);

    next_tx(test, alice);
    {
      let pool = test::take_shared<Pool<StablePair>>(test);

      let usdt_amount = 25000000000; // 25

      let (_, balance_x, balance_y, _, _, decimals_x, decimals_y, _, fees) = stable_pair::view_state<USDC, USDT, LP_COIN>(&pool);

      let k = stable_pair_math::invariant_(balance_x, balance_y, decimals_x, decimals_y);

      let fee_in = stable_fees::calculate_fee_in_amount(&fees, usdt_amount);

      let amount_out = stable_pair_math::calculate_amount_out(k, usdt_amount - fee_in, balance_x, balance_y, decimals_x, decimals_y, false);

      let fee_out = stable_fees::calculate_fee_out_amount(&fees, amount_out);

      let coin_usdt = stable_pair::swap<USDT, USDC, LP_COIN>(
        &mut pool,
        mint<USDT>(25, 9, ctx(test)),
        0,
        ctx(test)
      );

      assert_eq(burn(coin_usdt), amount_out - fee_out);

      test::return_shared(pool);
    };
    test::end(scenario);  
  }

  #[test]
  #[expected_failure(abort_code = 11)]  
  fun swap_usdc_high_min_amount() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    create_pool_(test);

    next_tx(test, alice);
    {

      let pool = test::take_shared<Pool<StablePair>>(test);

      let usdt_amount = 25000000000; // 25

      let (_, balance_x, balance_y, _, _, decimals_x, decimals_y, _, fees) = stable_pair::view_state<USDC, USDT, LP_COIN>(&pool);

      let k = stable_pair_math::invariant_(balance_x, balance_y, decimals_x, decimals_y);

      let fee_in = stable_fees::calculate_fee_in_amount(&fees, usdt_amount);

      let amount_out = stable_pair_math::calculate_amount_out(k, usdt_amount - fee_in, balance_x, balance_y, decimals_x, decimals_y, false);

      burn(stable_pair::swap<USDT, USDC, LP_COIN>(
        &mut pool,
        mint<USDT>(25, 9, ctx(test)),
        amount_out, // too high because we did not remove the fee_out
        ctx(test)
      ));

      test::return_shared(pool);
    };
    test::end(scenario); 
  }

  // Set up

  fun create_pool_(test: &mut Scenario) {
    let (alice, _) = people();

    next_tx(test, alice);
    {
      usdc::init_for_testing(ctx(test));
      usdt::init_for_testing(ctx(test));
      lp_coin::init_for_testing(ctx(test));
      admin::init_for_testing(ctx(test));
      coin_decimals::init_for_testing(ctx(test));
    };

    next_tx(test, alice);
    {
      let coin_decimals_storage = test::take_shared<CoinDecimals>(test);
      let usdt_metadata = test::take_shared<CoinMetadata<USDT>>(test);
      let usdc_metadata = test::take_shared<CoinMetadata<USDC>>(test);

      coin_decimals::register_coin<USDT>(&mut coin_decimals_storage, &usdt_metadata);
      coin_decimals::register_coin<USDC>(&mut coin_decimals_storage, &usdc_metadata);

      test::return_shared(coin_decimals_storage);
      test::return_shared(usdc_metadata);
      test::return_shared(usdt_metadata);
    };

    next_tx(test, alice);
    {
      let coin_decimals = test::take_shared<CoinDecimals>(test);
      let lp_coin_cap = test::take_from_sender<TreasuryCap<LP_COIN>>(test);

      let lp_coin = stable_pair::new(
        mint<USDC>(100, USDC_DECIMALS, ctx(test)),
        mint<USDT>(100, USDT_DECIMALS, ctx(test)),
        coin::treasury_into_supply(lp_coin_cap),
        &coin_decimals,
        ctx(test)
      );

       let lp_coin_initial_user_balance = (sqrt_down(((add_decimals(100, 6) * add_decimals(100, 9)) as u256)) as u64);

      assert_eq(burn(lp_coin), lp_coin_initial_user_balance);

      test::return_shared(coin_decimals);
    };
  }
}