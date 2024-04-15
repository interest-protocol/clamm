// * 2 Pool - USDC - ETH
// All values tested agaisnt Curve pool
#[test_only]
module clamm::volatile_2pool_quote_tests {

  use sui::clock;
  use sui::coin::burn_for_testing as burn;

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx}; 

  use clamm::eth::ETH;
  use clamm::usdc::USDC;
  use clamm::lp_coin::LP_COIN;
  use clamm::curves::Volatile;
  use clamm::interest_clamm_volatile;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_volatile::setup_2pool;
  use clamm::amm_test_utils ::{people, scenario, mint, add_decimals};

  #[test]
  fun test_quote_swap() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let c = clock::create_for_testing(ctx(test));

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let expected_amount = interest_clamm_volatile::quote_swap<USDC, ETH, LP_COIN>(
        &mut pool,
        &c,
        add_decimals(1499, 6)
      );

      let coin_out = interest_clamm_volatile::swap<USDC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint(1499, 6, ctx(test)),
        expected_amount,
        ctx(test)  
      );

      assert_eq(burn(coin_out), expected_amount);

      let expected_amount = interest_clamm_volatile::quote_swap<ETH, USDC, LP_COIN>(
        &mut pool,
        &c,
        add_decimals(25, 8)
      );

      let coin_out = interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
        &mut pool,
        &c,
        mint(25, 8, ctx(test)),
        expected_amount,
        ctx(test)  
      );

      assert_eq(burn(coin_out), expected_amount);      

      test::return_shared(pool);
    };

    clock::destroy_for_testing(c);
    test::end(scenario);    
  }

  #[test]
  fun test_quote_add_liquidity() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    setup_2pool(test, 4500, 3);
    let c = clock::create_for_testing(ctx(test));

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let expected_amount = interest_clamm_volatile::quote_add_liquidity<LP_COIN>(
        &mut pool,
        &c,
        vector[add_decimals(6000, 6), add_decimals(5, 9)]
      );

      let amount = burn(interest_clamm_volatile::add_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(6000, 6, ctx(test)),
        mint<ETH>(5, 9, ctx(test)),
        0,
        ctx(test)
      ));

      assert_eq(expected_amount, amount);

      test::return_shared(pool);
    };

    clock::destroy_for_testing(c);
    test::end(scenario);      
  }

  #[test] 
  fun test_quote_remove_liquidity() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    setup_2pool(test, 4500, 3);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let expected_amounts = interest_clamm_volatile::quote_remove_liquidity<LP_COIN>(
        &mut pool,
          add_decimals(123, 8)
      );

      let (coin_usdc, coin_eth) = interest_clamm_volatile::remove_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        mint<LP_COIN>(123, 8, ctx(test)),
        vector[0, 0],
        ctx(test)  
      );

      assert_eq(burn(coin_usdc), * vector::borrow(&expected_amounts, 0));
      assert_eq(burn(coin_eth), * vector::borrow(&expected_amounts, 1));

      test::return_shared(pool);
    };    

    test::end(scenario);     
  }

  #[test]
  fun test_remove_liquidity_one_coin() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    setup_2pool(test, 4500, 3);
    let c = clock::create_for_testing(ctx(test));

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let expected_eth_amount = interest_clamm_volatile::quote_remove_liquidity_one_coin<ETH, LP_COIN>(
        &mut pool,
        &c,
          add_decimals(123, 8)
      );

      let coin_eth = interest_clamm_volatile::remove_liquidity_one_coin<ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<LP_COIN>(123, 8, ctx(test)),
        expected_eth_amount,
        ctx(test)
      );

      assert_eq(burn(coin_eth), expected_eth_amount);

      test::return_shared(pool);
    };

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let expected_usdc_amount = interest_clamm_volatile::quote_remove_liquidity_one_coin<USDC, LP_COIN>(
        &mut pool,
        &c,
          add_decimals(123, 8)
      );

      let coin_usdc = interest_clamm_volatile::remove_liquidity_one_coin<USDC, LP_COIN>(
        &mut pool,
        &c,
        mint<LP_COIN>(123, 8, ctx(test)),
        expected_usdc_amount,
        ctx(test)
      );

      assert_eq(burn(coin_usdc), expected_usdc_amount);

      test::return_shared(pool);
    };    

    clock::destroy_for_testing(c);
    test::end(scenario); 
  }
}