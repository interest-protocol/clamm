// * 3 InterestPool - DAI - USDC - USDT
#[test_only]
module clamm::stable_remove_one_coin_liquidity_tests { 
  use sui::clock::Clock;
  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx};
  use sui::coin::{burn_for_testing as burn, mint_for_testing as mint};
  
  use clamm::dai::DAI;
  use clamm::lp_coin::LP_COIN;
  use clamm::curves::Stable;
  use clamm::pool_admin::PoolAdmin;
  use clamm::interest_clamm_stable;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_stable::setup_3pool;
  use clamm::stable_simulation::{Self as sim, State as SimState};
  use clamm::amm_test_utils::{people, scenario, normalize_amount};
  
  const LP_COIN_DECIMALS_SCALAR: u256 = 1000000000; 
  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18

  #[test]
  fun remove_liquidity_one_coin() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);    
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test);
      let mut sim_state = test::take_shared<SimState>(test); 

      let amp = interest_clamm_stable::a<LP_COIN>(&mut pool, &c);

      let balances = interest_clamm_stable::balances<LP_COIN>(&mut pool);
      let supply = interest_clamm_stable::lp_coin_supply<LP_COIN>(&mut pool);

      sim::set_state(&mut sim_state, amp, 3, balances, (supply as u256));

      let coin_dai = interest_clamm_stable::remove_liquidity_one_coin<DAI, LP_COIN>(
        &mut pool,
        &c,
        mint<LP_COIN>(supply / 10, ctx(test)),
        0,
        ctx(test)
      );

      let balances_2 = interest_clamm_stable::balances<LP_COIN>(&mut pool);
      let supply_2 = interest_clamm_stable::lp_coin_supply<LP_COIN>(&mut pool);

      let (expected_amount, admin_fee) = sim::calc_withdraw_one_coin(
        &sim_state, 
        amp,
        ((supply / 10) as u256), 
        0
      );

      let coin_dai_amount = burn(coin_dai);

      let expected_balances = vector[
        normalize_amount(1000) - expected_amount - admin_fee,
        normalize_amount(1000),
        normalize_amount(1000)
      ];

      assert_eq(coin_dai_amount, ((expected_amount * LP_COIN_DECIMALS_SCALAR / PRECISION) as u64));
      assert_eq(supply, supply_2 + (supply / 10));
      assert_eq(expected_balances, balances_2);

      test::return_shared(sim_state);
      test::return_shared(c);
      test::return_shared(pool);            
    };
    test::end(scenario); 
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::SLIPPAGE, location = clamm::interest_clamm_stable)]  
  fun remove_liquidity_one_coin_slippage() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);    
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test);
      let mut sim_state = test::take_shared<SimState>(test); 

      let amp = interest_clamm_stable::a<LP_COIN>(&mut pool, &c);

      let balances = interest_clamm_stable::balances<LP_COIN>(&mut pool);
      let supply = interest_clamm_stable::lp_coin_supply<LP_COIN>(&mut pool);

      sim::set_state(&mut sim_state, amp, 3, balances, (supply as u256) * PRECISION / LP_COIN_DECIMALS_SCALAR);

      let (expected_amount, _) = sim::calc_withdraw_one_coin(&sim_state, amp, normalize_amount(((supply / 10) as u256) / LP_COIN_DECIMALS_SCALAR ), 0);

      burn(interest_clamm_stable::remove_liquidity_one_coin<DAI, LP_COIN>(
        &mut pool,
        &c,
        mint<LP_COIN>(supply / 10, ctx(test)),
        ((expected_amount * LP_COIN_DECIMALS_SCALAR / PRECISION) as u64) + 1, // inc by one to throw
        ctx(test)
      ));

      test::return_shared(sim_state);
      test::return_shared(c);
      test::return_shared(pool);            
    };
    test::end(scenario); 
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::POOL_IS_PAUSED, location = clamm::interest_pool)]
  fun remove_liquidity_one_coin_is_paused() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);    
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test);
      let cap = test.take_from_sender<PoolAdmin>();

      let supply = interest_clamm_stable::lp_coin_supply<LP_COIN>(&mut pool);

      pool.pause(&cap);

      burn(interest_clamm_stable::remove_liquidity_one_coin<DAI, LP_COIN>(
        &mut pool,
        &c,
        mint<LP_COIN>(supply / 10, ctx(test)),
        0,
        ctx(test)
      ));

      test.return_to_sender(cap);
      test::return_shared(c);
      test::return_shared(pool);            
    };
    test::end(scenario); 
  }
}
