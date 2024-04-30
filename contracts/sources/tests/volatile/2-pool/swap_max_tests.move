// * 2 Pool - USDC - ETH
// All values tested agaisnt Curve pool
#[test_only]
module clamm::volatile_2pool_swap_max_tests {
  use sui::clock::{Self, Clock};
  use sui::coin::{Self, burn_for_testing as burn, TreasuryCap};
  use sui::test_scenario::{Self as test, Scenario, next_tx, ctx};

  use suitears::coin_decimals::CoinDecimals;

  use clamm::eth::ETH;
  use clamm::usdc::USDC;
  use clamm::interest_pool;
  use clamm::lp_coin::LP_COIN;
  use clamm::curves::Volatile;
  use clamm::pool_admin::PoolAdmin;
  use clamm::interest_clamm_volatile;
  use clamm::interest_pool::InterestPool;
  use clamm::amm_test_utils ::{people, scenario, mint, setup_dependencies};

  const A: u256  = 36450000;
  const GAMMA: u256 = 70000000000000;
  const TWENTY_MILLISECONDS: u64 = 22000;
  const MAX_FEE: u256 = 10 * 1_000_000_000;
  const ONE_WEEK: u256 = 7 * 86400000; // 1 week in milliseconds
  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18 
  const ETH_INITIAL_PRICE: u256 = 1500 * 1_000_000_000_000_000_000;

  const ETH_DECIMALS: u8 = 9;
  const USDC_DECIMALS: u8 = 6; 

  #[test]
  fun extreme_usdc_swaps() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let mut c = clock::create_for_testing(ctx(test));

    clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS / 20);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let mut i = 0;

      while (5 > i) {

        burn(interest_clamm_volatile::swap<USDC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(1500, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        i = i + 1;
      };

      test::return_shared(pool);
    };   

    clock::destroy_for_testing(c);
    test::end(scenario);     
  }  

  #[test]
  fun extreme_eth_swaps() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let mut c = clock::create_for_testing(ctx(test));

    clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS / 20);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let mut i = 0;

      while (5 > i) {

        burn(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(3, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        i = i + 1;
      };  

      test::return_shared(pool);
    };   

    clock::destroy_for_testing(c);
    test::end(scenario);     
  }    

  #[test]
  fun extreme_swaps() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let mut c = clock::create_for_testing(ctx(test));

    clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS / 20);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let mut i = 0;

      while (5 > i) {

        burn(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(3, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        i = i + 1;
      };

      let mut i = 0;

      while (5 > i) {

        burn(interest_clamm_volatile::swap<USDC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(3000, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        i = i + 1;
      };

      test::return_shared(pool);
    };   

    clock::destroy_for_testing(c);
    test::end(scenario);     
  } 

  #[test]
  fun do_1000_swaps() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let mut c = clock::create_for_testing(ctx(test));

    clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS / 20);

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let mut i = 0;

      while (200 > i) {

        burn(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(5, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        burn(interest_clamm_volatile::swap<USDC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(6700, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);
        i = i + 1;
      };  

      test::return_shared(pool);
    };

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let mut i = 0;

      while (200 > i) {

        burn(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(5, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        burn(interest_clamm_volatile::swap<USDC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(6700, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);
        i = i + 1;
      };        

      test::return_shared(pool);
    };   

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let mut i = 0;

      while (200 > i) {

        burn(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(5, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        burn(interest_clamm_volatile::swap<USDC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(6700, 6, ctx(test)),
          0,
          ctx(test)
          )
        );
        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        i = i + 1;
    };  

    test::return_shared(pool);
  };

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let mut i = 0;

      while (200 > i) {

        burn(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(5, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        burn(interest_clamm_volatile::swap<USDC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(6700, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);
        i = i + 1;
      };

      test::return_shared(pool);
    };  

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);
      let admin_cap = test::take_from_sender<PoolAdmin>(test);
      let mut i = 0;

      while (200 > i) {

        burn(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(5, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        burn(interest_clamm_volatile::swap<USDC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(6700, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);
        i = i + 1;
      };

      let mut request = interest_clamm_volatile::balances_request<LP_COIN>(&mut pool);

      interest_clamm_volatile::read_balance<USDC, LP_COIN>(&mut pool, &mut request);
      interest_clamm_volatile::read_balance<ETH, LP_COIN>(&mut pool, &mut request);

      burn(interest_clamm_volatile::claim_admin_fees<LP_COIN>(&mut pool, &admin_cap, &c, request, ctx(test)));

      test::return_to_sender(test, admin_cap);
      test::return_shared(pool);
    };        

    clock::destroy_for_testing(c);
    test::end(scenario);     
  }  

  public fun setup_2pool(test: &mut Scenario, usdc_amount: u64, eth_amount: u64) {
    let (alice, _) = people();
    
    setup_dependencies(test);

    next_tx(test, alice);
    {
      let c = test::take_shared<Clock>(test);
      let coin_decimals = test::take_shared<CoinDecimals>(test);
      let lp_coin_cap = test::take_from_sender<TreasuryCap<LP_COIN>>(test);

      let (pool, pool_admin, lp_coin) = interest_clamm_volatile::new_2_pool<USDC, ETH, LP_COIN>(
        &c,
        &coin_decimals,
        mint<USDC>(usdc_amount, USDC_DECIMALS, ctx(test)),
        mint<ETH>(eth_amount, ETH_DECIMALS, ctx(test)),
        coin::treasury_into_supply(lp_coin_cap),
        vector[A, GAMMA],
        vector[PRECISION - 1, PRECISION - 1, ONE_WEEK],
        ETH_INITIAL_PRICE,
        vector[MAX_FEE, MAX_FEE, PRECISION],
        ctx(test)
      );

      burn(lp_coin);    
      interest_pool::share(pool);
      transfer::public_transfer(pool_admin, alice);
      
      test::return_shared(coin_decimals);
      test::return_shared(c);
    };
  }   
}