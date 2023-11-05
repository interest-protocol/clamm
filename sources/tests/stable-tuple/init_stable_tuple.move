#[test_only]
module amm::init_stable_tuple {
  use sui::clock::Clock;
  use sui::test_scenario::{Self as test, Scenario, next_tx, ctx};
  use sui::coin::{Self, burn_for_testing as burn, TreasuryCap};

  use suitears::coin_decimals::CoinDecimals;

  use amm::stable_tuple;
  use amm::dai::DAI;
  use amm::usdt::USDT;
  use amm::usdc::USDC;
  use amm::lp_coin::LP_COIN;
  use amm::stable_tuple_simulation::{Self as sim, State as SimState};
  use amm::test_utils::{people, mint, add_decimals, setup_dependencies};

  const DAI_DECIMALS: u8 = 9;
  const USDC_DECIMALS: u8 = 6; 
  const USDT_DECIMALS: u8 = 9;

  public fun setup_3pool(test: &mut Scenario) {
    let (alice, _) = people();

    setup_dependencies(test);

    let initial_a = 2 * 360;

    next_tx(test, alice);
    {
      sim::init_for_testing(ctx(test));
    };

    next_tx(test, alice);
    {
      let c = test::take_shared<Clock>(test);
      let coin_decimals = test::take_shared<CoinDecimals>(test);
      let lp_coin_cap = test::take_from_sender<TreasuryCap<LP_COIN>>(test);
      let sim_state = test::take_from_sender<SimState>(test);

      burn(stable_tuple::new_3_pool(
        &c,
        initial_a,
        mint<DAI>(100, DAI_DECIMALS, ctx(test)),
        mint<USDC>(110, USDC_DECIMALS, ctx(test)),
        mint<USDT>(121, USDT_DECIMALS, ctx(test)),
        &coin_decimals,
        coin::treasury_into_supply(lp_coin_cap),
        ctx(test)
      ));

      sim::set_state(
        &mut sim_state, 
        initial_a, 
        3, 
        vector[make_amount(100, DAI_DECIMALS), make_amount(110, USDC_DECIMALS), make_amount(121, USDT_DECIMALS)],
        vector[make_amount(1, DAI_DECIMALS), make_amount(1, USDC_DECIMALS), make_amount(1, USDT_DECIMALS)],
        1
      );

      test::return_shared(sim_state);
      test::return_shared(coin_decimals);
      test::return_shared(c);
    };
  }

  fun make_amount(x: u64, e: u8): u256 {
    (add_decimals(x, e) as u256)
  }
}