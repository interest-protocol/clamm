#[test_only]
module clamm::init_interest_amm_stable {
  use sui::clock::Clock;
  use sui::coin::{Self, burn_for_testing as burn, TreasuryCap};
  use sui::test_scenario::{Self as test, Scenario, next_tx, ctx};

  use suitears::coin_decimals::CoinDecimals;

  use clamm::interest_clamm_stable;
  use clamm::dai::DAI;
  use clamm::usdt::USDT;
  use clamm::usdc::USDC;
  use clamm::frax::FRAX;
  use clamm::lp_coin::LP_COIN;
  use clamm::true_usd::TRUE_USD;
  use clamm::stable_simulation::{Self as sim, State as SimState};
  use clamm::amm_test_utils::{people, mint, normalize_amount, setup_dependencies};

  const DAI_DECIMALS: u8 = 9;
  const FRAX_DECIMALS: u8 = 9;
  const USDC_DECIMALS: u8 = 6; 
  const USDT_DECIMALS: u8 = 9;
  const TRUE_USD_DECIMALS: u8 = 9;

  public fun setup_3pool(test: &mut Scenario, dai_amount: u64, usdc_amount: u64, usdt_amount: u64) {
    let (alice, _) = people();

    setup_dependencies(test);

    let initial_a = 360;

    next_tx(test, alice);
    {
      sim::init_for_testing(ctx(test));
    };

    next_tx(test, alice);
    {
      let c = test::take_shared<Clock>(test);
      let coin_decimals = test::take_shared<CoinDecimals>(test);
      let lp_coin_cap = test::take_from_sender<TreasuryCap<LP_COIN>>(test);
      let sim_state = test::take_shared<SimState>(test);

      burn(interest_clamm_stable::new_3_pool(
        &c,
        initial_a,
        mint<DAI>(dai_amount, DAI_DECIMALS, ctx(test)),
        mint<USDC>(usdc_amount, USDC_DECIMALS, ctx(test)),
        mint<USDT>(usdt_amount, USDT_DECIMALS, ctx(test)),
        &coin_decimals,
        coin::treasury_into_supply(lp_coin_cap),
        ctx(test)
      ));

      sim::set_state(
        &mut sim_state, 
        initial_a, 
        3, 
        vector[normalize_amount((dai_amount as u256)), normalize_amount((usdc_amount as u256)), normalize_amount((usdt_amount as u256))],
        1
      );

      test::return_shared(sim_state);
      test::return_shared(coin_decimals);
      test::return_shared(c);
    };
  }

  public fun setup_4pool(
    test: &mut Scenario, 
    dai_amount: u64, 
    usdc_amount: u64, 
    usdt_amount: u64,
    frax_amount: u64
  ) {
    let (alice, _) = people();

    setup_dependencies(test);

    let initial_a = 360;

    next_tx(test, alice);
    {
      sim::init_for_testing(ctx(test));
    };

    next_tx(test, alice);
    {
      let c = test::take_shared<Clock>(test);
      let coin_decimals = test::take_shared<CoinDecimals>(test);
      let lp_coin_cap = test::take_from_sender<TreasuryCap<LP_COIN>>(test);
      let sim_state = test::take_shared<SimState>(test);

      burn(interest_clamm_stable::new_4_pool(
        &c,
        initial_a,
        mint<DAI>(dai_amount, DAI_DECIMALS, ctx(test)),
        mint<USDC>(usdc_amount, USDC_DECIMALS, ctx(test)),
        mint<USDT>(usdt_amount, USDT_DECIMALS, ctx(test)),
        mint<FRAX>(frax_amount, FRAX_DECIMALS, ctx(test)),
        &coin_decimals,
        coin::treasury_into_supply(lp_coin_cap),
        ctx(test)
      ));

      sim::set_state(
        &mut sim_state, 
        initial_a, 
        4, 
        vector[
          normalize_amount((dai_amount as u256)), 
          normalize_amount((usdc_amount as u256)), 
          normalize_amount((usdt_amount as u256)),
          normalize_amount((frax_amount as u256))
        ],
        1
      );

      test::return_shared(sim_state);
      test::return_shared(coin_decimals);
      test::return_shared(c);
    };
  }

  public fun setup_5pool(
    test: &mut Scenario, 
    dai_amount: u64, 
    usdc_amount: u64, 
    usdt_amount: u64,
    frax_amount: u64,
    true_usd_amount: u64
  ) {
    let (alice, _) = people();

    setup_dependencies(test);

    let initial_a = 360;

    next_tx(test, alice);
    {
      sim::init_for_testing(ctx(test));
    };

    next_tx(test, alice);
    {
      let c = test::take_shared<Clock>(test);
      let coin_decimals = test::take_shared<CoinDecimals>(test);
      let lp_coin_cap = test::take_from_sender<TreasuryCap<LP_COIN>>(test);
      let sim_state = test::take_shared<SimState>(test);

      burn(interest_clamm_stable::new_5_pool(
        &c,
        initial_a,
        mint<DAI>(dai_amount, DAI_DECIMALS, ctx(test)),
        mint<USDC>(usdc_amount, USDC_DECIMALS, ctx(test)),
        mint<USDT>(usdt_amount, USDT_DECIMALS, ctx(test)),
        mint<FRAX>(frax_amount, FRAX_DECIMALS, ctx(test)),
        mint<TRUE_USD>(true_usd_amount, TRUE_USD_DECIMALS, ctx(test)),
        &coin_decimals,
        coin::treasury_into_supply(lp_coin_cap),
        ctx(test)
      ));

      sim::set_state(
        &mut sim_state, 
        initial_a, 
        5, 
        vector[
          normalize_amount((dai_amount as u256)), 
          normalize_amount((usdc_amount as u256)), 
          normalize_amount((usdt_amount as u256)),
          normalize_amount((frax_amount as u256)),
          normalize_amount((true_usd_amount as u256))
        ],
        1
      );

      test::return_shared(sim_state);
      test::return_shared(coin_decimals);
      test::return_shared(c);
    };
  }
}