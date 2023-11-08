// * 3 Pool - DAI - USDC - USDT
#[test_only]
module amm::stable_tuple_fees_tests {
  use std::option;

  use sui::clock::Clock;
  use sui::test_utils::assert_eq;
  use sui::coin::burn_for_testing as burn;
  use sui::test_scenario::{Self as test, next_tx, ctx};

  use amm::dai::DAI;
  use amm::usdt::USDT;
  use amm::usdc::USDC;
  use amm::stable_fees;
  use amm::stable_tuple;
  use amm::amm_admin::Admin;
  use amm::lp_coin::LP_COIN;
  use amm::curves::StableTuple;
  use amm::interest_pool::Pool;
  use amm::init_stable_tuple::setup_3pool;
  use amm::test_utils::{people, scenario, mint};

  const DAI_DECIMALS: u8 = 9;
  const USDC_DECIMALS: u8 = 6; 
  const USDT_DECIMALS: u8 = 9;

  const MAX_FEE_PERCENT: u256 = 20000000000000000; // 2%
  const MAX_ADMIN_FEE: u256 = 200000000000000000; // 20%

  #[test]
  fun updates_fees_correctly() {
   let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let pool = test::take_shared<Pool<StableTuple>>(test);
      let admin_cap = test::take_from_sender<Admin>(test);

      stable_tuple::update_fee<LP_COIN>(
        &admin_cap,
        &mut pool,
        option::some(MAX_FEE_PERCENT),
          option::some(MAX_FEE_PERCENT),
          option::some(MAX_ADMIN_FEE),
      );

      let (_, _, _, _, _, _, _, _, fees) = stable_tuple::view_state<LP_COIN>(&pool);

      let (fee_in, fee_out, fee_admin) = stable_fees::view(fees);

      assert_eq(fee_in, MAX_FEE_PERCENT);
      assert_eq(fee_out, MAX_FEE_PERCENT);
      assert_eq(fee_admin, MAX_ADMIN_FEE);

      test::return_to_sender(test, admin_cap);
      test::return_shared(pool);
    };
    test::end(scenario);      
  }


  #[test]
  fun takes_fees_correctly() {
   let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 1000, 1000, 1000);

    next_tx(test, alice);
    {
      let pool = test::take_shared<Pool<StableTuple>>(test);
      let admin_cap = test::take_from_sender<Admin>(test);
      let c = test::take_shared<Clock>(test);

      stable_tuple::update_fee<LP_COIN>(
        &admin_cap,
        &mut pool,
        option::some(MAX_FEE_PERCENT),
          option::some(MAX_FEE_PERCENT),
          option::some(MAX_ADMIN_FEE),
      );

      // Swap to collect fees
      burn(stable_tuple::swap<DAI, USDC, LP_COIN>(
        &mut pool,
        &c,
        mint<DAI>(300, DAI_DECIMALS, ctx(test)),
        0,
        ctx(test)
      ));

      burn(stable_tuple::swap<USDC, USDT, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(300, USDC_DECIMALS, ctx(test)),
        0,
        ctx(test)
      ));

      burn(stable_tuple::swap<USDT, DAI, LP_COIN>(
        &mut pool,
        &c,
        mint<USDT>(300, USDT_DECIMALS, ctx(test)),
        0,
        ctx(test)
      ));

      let (balances, _, _, _, _, _, _, _, _) = stable_tuple::view_state<LP_COIN>(&pool);

      let admin_dai_balance = stable_tuple::view_admin_balance<DAI, LP_COIN>(&pool);
      let admin_dai = stable_tuple::take_fees<DAI, LP_COIN>(&admin_cap, &mut pool, ctx(test));

      assert_eq(burn(admin_dai), admin_dai_balance);
      assert_eq(stable_tuple::view_admin_balance<DAI, LP_COIN>(&pool), 0);

      let admin_usdc_balance = stable_tuple::view_admin_balance<USDC, LP_COIN>(&pool);
      let admin_usdc = stable_tuple::take_fees<USDC, LP_COIN>(&admin_cap, &mut pool, ctx(test));

      assert_eq(burn(admin_usdc), admin_usdc_balance);
      assert_eq(stable_tuple::view_admin_balance<USDC, LP_COIN>(&pool), 0);

      let admin_usdt_balance = stable_tuple::view_admin_balance<USDT, LP_COIN>(&pool);
      let admin_usdt = stable_tuple::take_fees<USDT, LP_COIN>(&admin_cap, &mut pool, ctx(test));

      assert_eq(burn(admin_usdt), admin_usdt_balance);
      assert_eq(stable_tuple::view_admin_balance<USDT, LP_COIN>(&pool), 0);

      let (balances_2, _, _, _, _, _, _, _, _) = stable_tuple::view_state<LP_COIN>(&pool);

      // Admin Balances does not come from pool reserves
      assert_eq(balances_2, balances);
      
      test::return_shared(c);
      test::return_to_sender(test, admin_cap);
      test::return_shared(pool);
    };
    test::end(scenario);      
  }
}