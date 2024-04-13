// * 3 InterestPool - DAI - USDC - USDT
#[test_only]
module clamm::stable_tuple_3pool_add_liquidity_tests {
  use std::vector;

  use sui::clock::Clock;
  use sui::test_utils::assert_eq;
  use sui::coin::burn_for_testing as burn;
  use sui::test_scenario::{Self as test, next_tx, ctx};

  use clamm::dai::DAI;
  use clamm::usdt::USDT;
  use clamm::usdc::USDC;
  use clamm::stable_math;
  use clamm::curves::Stable;
  use clamm::interest_clamm_stable;
  use clamm::lp_coin::LP_COIN;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_stable::setup_3pool;
  use clamm::amm_test_utils::{people, scenario, normalize_amount, mint};

  const INITIAL_A: u256 = 360;
  const DAI_DECIMALS: u8 = 9;
  const USDC_DECIMALS: u8 = 6; 
  const USDT_DECIMALS: u8 = 9;

  #[test]
  fun add_liquidity() {
   let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test); 

      let balances = interest_clamm_stable::balances<LP_COIN>(&pool);
      let supply = interest_clamm_stable::lp_coin_supply<LP_COIN>(&pool);

      let k0 = stable_math::invariant_(INITIAL_A, balances);

      let lp_coin = interest_clamm_stable::add_liquidity_3_pool<DAI, USDC, USDT, LP_COIN>(
        &mut pool,
        &c,
        mint<DAI>(100, DAI_DECIMALS, ctx(test)),
        mint<USDC>(110, USDC_DECIMALS, ctx(test)),
        mint<USDT>(120, USDT_DECIMALS, ctx(test)),
        0,
        ctx(test)
      );

      let new_balances = interest_clamm_stable::balances<LP_COIN>(&pool);
      let new_supply = interest_clamm_stable::lp_coin_supply<LP_COIN>(&pool);
      let n_coins = interest_clamm_stable::n_coins<LP_COIN>(&pool);

      let k1 = stable_math::invariant_(INITIAL_A, new_balances);

      let lp_value = burn(lp_coin);

      assert_eq(lp_value, (((supply as u256) * (k1 - k0) / k0) as u64));
      assert_eq(lp_value, new_supply - supply);

      let diff_vector = vector[
        normalize_amount(100),
        normalize_amount(110),
        normalize_amount(120)
      ];
      
      {
        let i = 0;
        while (n_coins > i) {
          let prev_bal = *vector::borrow(&balances, i);
          let new_bal = *vector::borrow(&new_balances, i);
          let diff = *vector::borrow(&diff_vector, i);

          assert_eq(new_bal - prev_bal, diff);

          i = i + 1;
        };
      };

      test::return_shared(c);
      test::return_shared(pool);
    };
    test::end(scenario);      
  }


  #[test]
  #[expected_failure(abort_code = clamm::errors::COINS_MUST_BE_IN_ORDER, location = clamm::interest_clamm_stable)]  
  fun add_liquidity_coins_wrong_order() {
   let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test);
    

      burn(interest_clamm_stable::add_liquidity_3_pool<USDC, DAI, USDT, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(110, USDC_DECIMALS, ctx(test)),
        mint<DAI>(100, DAI_DECIMALS, ctx(test)),
        mint<USDT>(120, USDT_DECIMALS, ctx(test)),
        0,
        ctx(test)
      ));

      test::return_shared(c);
      test::return_shared(pool);
    };
    test::end(scenario);      
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::SLIPPAGE, location = clamm::interest_clamm_stable)]  
  fun add_liquidity_coins_slippage() {
   let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test); 

      let balances = interest_clamm_stable::balances<LP_COIN>(&pool);
      let supply = interest_clamm_stable::lp_coin_supply<LP_COIN>(&pool);

      let k0 = stable_math::invariant_(INITIAL_A, balances);

      let new_balances = vector[
        normalize_amount(1100),
        normalize_amount(1110),
        normalize_amount(1120)        
      ];

      let k1 = stable_math::invariant_(INITIAL_A, new_balances);

      let mint_amount = (((supply as u256) * (k1 - k0) / k0) as u64);

      burn(interest_clamm_stable::add_liquidity_3_pool<DAI, USDC, USDT, LP_COIN>(
        &mut pool,
        &c,
        mint<DAI>(100, DAI_DECIMALS, ctx(test)),
        mint<USDC>(110, USDC_DECIMALS, ctx(test)),
        mint<USDT>(120, USDT_DECIMALS, ctx(test)),
        mint_amount + 1, // slippage
        ctx(test)
      ));

      test::return_shared(c);
      test::return_shared(pool);
    };
    test::end(scenario);      
  }
}