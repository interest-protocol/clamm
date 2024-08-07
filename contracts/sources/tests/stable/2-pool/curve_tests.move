// * 2 InterestPool - USDC - USDT
#[test_only]
module clamm::stable_tuple_2pool_curve_tests {

  use sui::clock::Clock;
  use sui::test_utils::assert_eq;
  use sui::coin::{burn_for_testing as burn, mint_for_testing};
  use sui::test_scenario::{Self as test, next_tx, ctx};

  use suitears::math64::diff;
  use suitears::math256::diff as u256_diff;

  use clamm::usdt::USDT;
  use clamm::usdc::USDC;
  use clamm::curves::Stable;
  use clamm::lp_coin::LP_COIN;
  use clamm::interest_clamm_stable;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_stable::setup_2pool;
  use clamm::stable_simulation::{Self as sim, State as SimState};
  use clamm::amm_test_utils::{people, scenario, mint, normalize_amount, add_decimals};

  const USDC_DECIMALS: u8 = 6; 
  const USDT_DECIMALS: u8 = 9;
  const USDT_DECIMALS_SCALAR: u256 = 1_000_000_000; 
  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18

  #[test]
  fun virtual_price_always_up() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test); 

      let virtual_price = interest_clamm_stable::virtual_price<LP_COIN>(&mut pool, &c);

      {
        let mut i = 0;
        while (3 > i) {
          
          burn(interest_clamm_stable::swap<USDC, USDT, LP_COIN>(
            &mut pool,
            &c,
            mint<USDC>(300, USDC_DECIMALS, ctx(test)),
            0,
            ctx(test)
          ));
          i = i + 1;
        }
      };

      let virtual_price_2 = interest_clamm_stable::virtual_price<LP_COIN>(&mut pool, &c);
      assert_eq(virtual_price_2 > virtual_price, true);

      {
        let mut i = 0;
        while (3 > i) {
          
          burn(interest_clamm_stable::add_liquidity_2_pool<USDC, USDT, LP_COIN>(
            &mut pool,
            &c,
            mint<USDC>(300, USDC_DECIMALS, ctx(test)),
            mint<USDT>(400, USDT_DECIMALS, ctx(test)),
            0,
            ctx(test)
          ));
          i = i + 1;
        }        
      };

      let virtual_price_3 = interest_clamm_stable::virtual_price<LP_COIN>(&mut pool, &c);
      assert_eq(virtual_price_3 > virtual_price_2, true);

      {
        let mut i = 0;

        let supply = interest_clamm_stable::lp_coin_supply<LP_COIN>(&mut pool);

        while (3 > i) {
          
          let (a, b) = interest_clamm_stable::remove_liquidity_2_pool<USDC, USDT, LP_COIN>(
            &mut pool,
            &c,
            mint_for_testing<LP_COIN>(supply / 10, ctx(test)),
            vector[0, 0],
            ctx(test)
          );
          burn(a);
          burn(b);
          i = i + 1;
        }        
      }; 

      let virtual_price_4 = interest_clamm_stable::virtual_price<LP_COIN>(&mut pool, &c);
      assert_eq(virtual_price_4 > virtual_price_3, true);     

        {
        let mut i = 0;
        while (3 > i) {
          let supply = interest_clamm_stable::lp_coin_supply<LP_COIN>(&mut pool);
          
          burn(interest_clamm_stable::remove_liquidity_one_coin<USDC, LP_COIN>(
            &mut pool,
            &c,
            mint_for_testing<LP_COIN>(supply / 10, ctx(test)),
            0,
            ctx(test)
          ));
          i = i + 1;
        }        
      }; 

      let virtual_price_5 = interest_clamm_stable::virtual_price<LP_COIN>(&mut pool, &c);
      assert_eq(virtual_price_5 >= virtual_price_4, true); 

      test::return_shared(c);
      test::return_shared(pool);            
    };
    test::end(scenario);      
  }

  // * Compare the balances after swap of the sim and the pool
  #[test]
  fun swaps() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    setup_2pool(test, 1000, 1000);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test); 
      let mut sim_state = test::take_shared<SimState>(test);  

      let virtual_price = interest_clamm_stable::virtual_price<LP_COIN>(&mut pool, &c);

      burn(interest_clamm_stable::swap<USDT, USDC, LP_COIN>(
        &mut pool,
        &c,
        mint<USDT>(300, USDT_DECIMALS, ctx(test)),
        0,
        ctx(test)
      ));

      burn(interest_clamm_stable::swap<USDC, USDT, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(450, USDC_DECIMALS, ctx(test)),
        0,
        ctx(test)
      ));

      sim::swap(&mut sim_state, 1, 0, normalize_amount(300));
      sim::swap(&mut sim_state, 0, 1, normalize_amount(450));


      let new_virtual_price = interest_clamm_stable::virtual_price<LP_COIN>(&mut pool, &c);

      let pool_balances = interest_clamm_stable::balances<LP_COIN>(&mut pool);
      let (sim_balances, _, n_coins, _, _) = sim::view_state(&sim_state);

      {
        let mut i = 0;
        while (n_coins > i) {
          let pool_bal = *vector::borrow(&pool_balances, i);
          let sim_bal = *vector::borrow(&sim_balances, i);

          // Less than 1 USD loss
          // Because in the contract we remove fees on 1e9 scalar
          // In the sim the fees are calculated on a 1e18 scalar
          let limit = PRECISION;
          assert_eq(limit > u256_diff(pool_bal, sim_bal), true);
          i = i + 1;
        };
      };

      assert_eq(new_virtual_price > virtual_price, true);

      test::return_shared(c);
      test::return_shared(pool);
      test::return_shared(sim_state);   
    };
    test::end(scenario);  
  }

  // * We test that the pool does not break in every imbalanced scenarios
  #[test]
  fun imbalanced_swaps() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    // Imbalanced set up
    setup_2pool(test, 10000, 10);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test);

      {
        let mut i = 0;
        while (3 > i) {
          assert_eq(
            burn(interest_clamm_stable::swap<USDT, USDC, LP_COIN>(
              &mut pool,
               &c,
               mint<USDT>(25, USDT_DECIMALS, ctx(test)),
               0,
               ctx(test))) != 0,
               true
          );
          i = i + 1;
        }
      };

      {
        let mut i = 0;
        while (3 > i) {
          assert_eq(
              burn(interest_clamm_stable::swap<USDC, USDT, LP_COIN>(
                &mut pool,
                &c,
                mint<USDC>(30, USDC_DECIMALS, ctx(test)),
                0,
                ctx(test))) != 0,
               true
          );
          i = i + 1;
        }
      };

      test::return_shared(c);
      test::return_shared(pool);
    };
    test::end(scenario);   
  }

  // * We compare the pool curve with our Sim curve
  #[test]
  fun curve() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    setup_2pool(test, 100, 121);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Stable>>(test);
      let c = test::take_shared<Clock>(test);
      let mut sim_state = test::take_shared<SimState>(test);

      burn(interest_clamm_stable::swap<USDT, USDC, LP_COIN>(
        &mut pool,
        &c,
        mint<USDT>(25, USDT_DECIMALS, ctx(test)),
        0,
        ctx(test)
      ));

      burn(interest_clamm_stable::swap<USDC, USDT, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(30, USDC_DECIMALS, ctx(test)),
        0,
        ctx(test)
      ));

      sim::swap(&mut sim_state, 1, 0, normalize_amount(25));
      sim::swap(&mut sim_state, 0, 1, normalize_amount(30));

      let (pool_dy, _) = interest_clamm_stable::quote_swap<USDC, USDT, LP_COIN>(&mut pool, &c, add_decimals(10, USDC_DECIMALS));

      let sim_dy = sim::dy(&sim_state, 0, 1, normalize_amount(10));
      let sim_dy = ((sim_dy * USDT_DECIMALS_SCALAR / PRECISION) as u64);

      // Difference of 1 cent
      // happens because of fees rounding
      assert_eq((USDT_DECIMALS_SCALAR as u64) / 100 > diff(pool_dy, sim_dy), true);

      test::return_shared(c);
      test::return_shared(pool);
      test::return_shared(sim_state);
    };

    test::end(scenario);
  }
}