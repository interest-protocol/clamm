// * 3 InterestPool - DAI - USDC - USDT
#[test_only]
module clamm::stable_tuple_3pool_add_liquidity_tests {

  use sui::clock::Clock;
  use sui::test_utils::assert_eq;
  use sui::coin::burn_for_testing as burn;
  use sui::test_scenario::{Self as test, next_tx, ctx};

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
  use clamm::amm_test_utils::{people, scenario, normalize_amount, mint, add_decimals, get_stable_add_liquidity_added_balances};

  const INITIAL_A: u256 = 360;
  const DAI_DECIMALS: u8 = 9;
  const USDC_DECIMALS: u8 = 6; 
  const USDT_DECIMALS: u8 = 9;

  #[test]
  fun add_liquidity() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test); 

      let balances = interest_clamm_stable::balances<LP_COIN>(&mut pool);
      let supply = interest_clamm_stable::lp_coin_supply<LP_COIN>(&mut pool);

      let expected_value = interest_clamm_stable::quote_add_liquidity<LP_COIN>(
        &mut pool, &c, vector[add_decimals(100, DAI_DECIMALS), add_decimals(110, USDC_DECIMALS), add_decimals(120, USDT_DECIMALS)]
      );

      let lp_coin = interest_clamm_stable::add_liquidity_3_pool<DAI, USDC, USDT, LP_COIN>(
        &mut pool,
        &c,
        mint<DAI>(100, DAI_DECIMALS, ctx(test)),
        mint<USDC>(110, USDC_DECIMALS, ctx(test)),
        mint<USDT>(120, USDT_DECIMALS, ctx(test)),
        0,
        ctx(test)
      );

      let new_balances = vector[
        balances[0] + normalize_amount(100),
        balances[1] + normalize_amount(110),
        balances[2] + normalize_amount(120),
      ];
      let actual_balances = interest_clamm_stable::balances<LP_COIN>(&mut pool);
      let new_supply = interest_clamm_stable::lp_coin_supply<LP_COIN>(&mut pool);
      let n_coins = interest_clamm_stable::n_coins<LP_COIN>(&mut pool);

      let lp_value = burn(lp_coin);

      assert_eq(lp_value, expected_value);
      assert_eq(lp_value, new_supply - supply);

      let diff_vector = get_stable_add_liquidity_added_balances<LP_COIN>(&mut pool, &c, balances, new_balances);
      
      {
        let mut i = 0;
        while (n_coins > i) {
          let prev_bal = *vector::borrow(&balances, i);
          let new_bal = *vector::borrow(&actual_balances, i);
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
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
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
   let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test); 

      let balances = interest_clamm_stable::balances<LP_COIN>(&mut pool);
      let supply = interest_clamm_stable::lp_coin_supply<LP_COIN>(&mut pool);

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

  #[test]
  #[expected_failure(abort_code = clamm::errors::POOL_IS_PAUSED, location = clamm::interest_pool)]  
  fun add_liquidity_is_paused() {
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

      let lp_coin = interest_clamm_stable::add_liquidity_3_pool<DAI, USDC, USDT, LP_COIN>(
        &mut pool,
        &c,
        mint<DAI>(100, DAI_DECIMALS, ctx(test)),
        mint<USDC>(110, USDC_DECIMALS, ctx(test)),
        mint<USDT>(120, USDT_DECIMALS, ctx(test)),
        0,
        ctx(test)
      );

      burn(lp_coin);

      test.return_to_sender(cap);
      test::return_shared(c);
      test::return_shared(pool);
    };
    test::end(scenario);      
  }
}