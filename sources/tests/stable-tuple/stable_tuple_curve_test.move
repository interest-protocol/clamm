// * 3 Pool - DAI - USDC - USDT
#[test_only]
module amm::stable_tuple_curve_test {
  use sui::clock::Clock;
  use sui::test_utils::{assert_eq};
  use sui::coin::{burn_for_testing as burn};
  use sui::test_scenario::{Self as test, next_tx, ctx};

  use amm::dai::DAI;
  use amm::usdt::USDT;
  use amm::usdc::USDC;
  use amm::stable_tuple;
  use amm::lp_coin::LP_COIN;
  use amm::curves::StableTuple;
  use amm::interest_pool::Pool;
  use amm::init_stable_tuple::setup_3pool;
  use amm::stable_tuple_simulation::{Self as sim, State as SimState};
  use amm::test_utils::{people, scenario, mint, normalize_amount, add_decimals};

  const DAI_DECIMALS: u8 = 9;
  const USDC_DECIMALS: u8 = 6; 
  const USDT_DECIMALS: u8 = 9;
  const DAI_DECIMALS_SCALAR: u256 = 1000000000;
  const USDC_DECIMALS_SCALAR: u256 = 1000000; 
  const USDT_DECIMALS_SCALAR: u256 = 1000000000;
  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18

  #[test]
  public fun curve() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    setup_3pool(test);

    next_tx(test, alice);
    {
      let pool = test::take_shared<Pool<StableTuple>>(test);
      let c = test::take_shared<Clock>(test);
      let sim_state = test::take_shared<SimState>(test);

      burn(stable_tuple::swap<DAI, USDC, LP_COIN>(
        &mut pool,
        &c,
        mint<DAI>(25, DAI_DECIMALS, ctx(test)),
        0,
        ctx(test)
      ));

      burn(stable_tuple::swap<USDC, USDT, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(30, USDC_DECIMALS, ctx(test)),
        0,
        ctx(test)
      ));

      burn(stable_tuple::swap<USDT, DAI, LP_COIN>(
        &mut pool,
        &c,
        mint<USDT>(30, USDT_DECIMALS, ctx(test)),
        0,
        ctx(test)
      ));

      sim::swap(&mut sim_state, 0, 1, normalize_amount(25));
      sim::swap(&mut sim_state, 1, 2, normalize_amount(30));
      sim::swap(&mut sim_state, 2, 0, normalize_amount(30));

      let (pool_dy, _, _) = stable_tuple::quote_swap<DAI, USDC, LP_COIN>(&pool, &c, add_decimals(10, DAI_DECIMALS));
      let sim_dy = sim::dy(&sim_state, 0, 1, normalize_amount(10));
      let sim_dy = ((sim_dy * USDC_DECIMALS_SCALAR / PRECISION) as u64);


      // assert_eq(sim_dy, pool_dy);

      test::return_shared(c);
      test::return_shared(pool);
      test::return_shared(sim_state);
    };

    test::end(scenario);
  }
}