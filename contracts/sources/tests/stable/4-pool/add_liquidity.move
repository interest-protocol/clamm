// * 4 Pool - DAI - USDC - USDT - FRAX
#[test_only]
module amm::stable_tuple_4pool_add_liquidity_tests {
  // use std::vector;

  // use sui::clock::Clock;
  // use sui::test_utils::assert_eq;
  // use sui::coin::burn_for_testing as burn;
  // use sui::test_scenario::{Self as test, next_tx, ctx};

  // use amm::dai::DAI;
  // use amm::usdt::USDT;
  // use amm::usdc::USDC;
  // use amm::frax::FRAX;
  // use amm::stable_tuple;
  // use amm::lp_coin::LP_COIN;
  // use amm::stable_tuple_math;
  // use amm::curves::StableTuple;
  // use amm::interest_pool::Pool;
  // use amm::init_stable_tuple::setup_4pool;
  // use amm::test_utils::{people, scenario, normalize_amount, mint};

  // const INITIAL_A: u256 = 360;
  // const DAI_DECIMALS: u8 = 9;
  // const USDC_DECIMALS: u8 = 6; 
  // const USDT_DECIMALS: u8 = 9;
  // const FRAX_DECIMALS: u8 = 9;

  // #[test]
  // fun add_liquidity() {
  //  let scenario = scenario();
  //   let (alice, _) = people();

  //   let test = &mut scenario;
    
  //   setup_4pool(test, 1000, 1000, 1000, 1000);

  //   next_tx(test, alice);
  //   {
  //     let pool = test::take_shared<Pool<StableTuple>>(test);
  //     let c = test::take_shared<Clock>(test); 

  //     let (balances, _, _, _, _, supply, _, _, _) = stable_tuple::view_state<LP_COIN>(&pool);

  //     let k0 = stable_tuple_math::invariant_(INITIAL_A, &balances);

  //     let lp_coin = stable_tuple::add_liquidity_4_pool<DAI, USDC, USDT, FRAX, LP_COIN>(
  //       &mut pool,
  //       &c,
  //       mint<DAI>(100, DAI_DECIMALS, ctx(test)),
  //       mint<USDC>(110, USDC_DECIMALS, ctx(test)),
  //       mint<USDT>(120, USDT_DECIMALS, ctx(test)),
  //       mint<FRAX>(130, FRAX_DECIMALS, ctx(test)),
  //       0,
  //       ctx(test)
  //     );

  //     let (new_balances, _, _, _, _, new_supply, _, n_coins, _) = stable_tuple::view_state<LP_COIN>(&pool);

  //     let k1 = stable_tuple_math::invariant_(INITIAL_A, &new_balances);

  //     let lp_value = burn(lp_coin);

  //     assert_eq(lp_value, (((supply as u256) * (k1 - k0) / k0) as u64));
  //     assert_eq(lp_value, new_supply - supply);

  //     let diff_vector = vector[
  //       normalize_amount(100),
  //       normalize_amount(110),
  //       normalize_amount(120),
  //       normalize_amount(130)
  //     ];
      
  //     {
  //       let i = 0;
  //       while (n_coins > i) {
  //         let prev_bal = *vector::borrow(&balances, i);
  //         let new_bal = *vector::borrow(&new_balances, i);
  //         let diff = *vector::borrow(&diff_vector, i);

  //         assert_eq(new_bal - prev_bal, diff);

  //         i = i + 1;
  //       };
  //     };

  //     test::return_shared(c);
  //     test::return_shared(pool);
  //   };
  //   test::end(scenario);      
  // }


  // #[test]
  // #[expected_failure(abort_code = 22)]  
  // fun add_liquidity_coins_wrong_order() {
  //  let scenario = scenario();
  //   let (alice, _) = people();

  //   let test = &mut scenario;
    
  //   setup_4pool(test, 1000, 1000, 1000, 1000);

  //   next_tx(test, alice);
  //   {
  //     let pool = test::take_shared<Pool<StableTuple>>(test);
  //     let c = test::take_shared<Clock>(test);
    

  //     burn(stable_tuple::add_liquidity_4_pool<FRAX, USDC, DAI, USDT, LP_COIN>(
  //       &mut pool,
  //       &c,
  //       mint<FRAX>(130, FRAX_DECIMALS, ctx(test)),
  //       mint<USDC>(110, USDC_DECIMALS, ctx(test)),
  //       mint<DAI>(100, DAI_DECIMALS, ctx(test)),
  //       mint<USDT>(120, USDT_DECIMALS, ctx(test)),
  //       0,
  //       ctx(test)
  //     ));

  //     test::return_shared(c);
  //     test::return_shared(pool);
  //   };
  //   test::end(scenario);      
  // }

  // #[test]
  // #[expected_failure(abort_code = 11)]  
  // fun add_liquidity_coins_slippage() {
  //  let scenario = scenario();
  //   let (alice, _) = people();

  //   let test = &mut scenario;
    
  //   setup_4pool(test, 1000, 1000, 1000, 1000);

  //   next_tx(test, alice);
  //   {
  //     let pool = test::take_shared<Pool<StableTuple>>(test);
  //     let c = test::take_shared<Clock>(test); 

  //     let (balances, _, _, _, _, supply, _, _, _) = stable_tuple::view_state<LP_COIN>(&pool);

  //     let k0 = stable_tuple_math::invariant_(INITIAL_A, &balances);

  //     let new_balances = vector[
  //       normalize_amount(1100),
  //       normalize_amount(1110),
  //       normalize_amount(1120),
  //       normalize_amount(1130)         
  //     ];

  //     let k1 = stable_tuple_math::invariant_(INITIAL_A, &new_balances);

  //     let mint_amount = (((supply as u256) * (k1 - k0) / k0) as u64);

  //     burn(stable_tuple::add_liquidity_4_pool<DAI, USDC, USDT, FRAX, LP_COIN>(
  //       &mut pool,
  //       &c,
  //       mint<DAI>(100, DAI_DECIMALS, ctx(test)),
  //       mint<USDC>(110, USDC_DECIMALS, ctx(test)),
  //       mint<USDT>(120, USDT_DECIMALS, ctx(test)),
  //       mint<FRAX>(130, FRAX_DECIMALS, ctx(test)),
  //       mint_amount + 1, // slippage
  //       ctx(test)
  //     ));

  //     test::return_shared(c);
  //     test::return_shared(pool);
  //   };
  //   test::end(scenario);      
  // }
}