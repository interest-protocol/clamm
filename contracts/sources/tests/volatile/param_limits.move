#[test_only]
module clamm::assert_parameters_values_tests {
  use sui::clock::Clock;
  use sui::coin::{Self, burn_for_testing as burn, TreasuryCap};
  use sui::test_scenario::{Self as test, next_tx, ctx};

  use suitears::coin_decimals::CoinDecimals;

  use clamm::eth::ETH;
  use clamm::usdc::USDC;
  use clamm::interest_pool;
  use clamm::lp_coin::LP_COIN;
  use clamm::interest_clamm_volatile;
  use clamm::amm_test_utils::{people, mint, scenario, setup_dependencies};

  const A: u256  = 36450000;
  const GAMMA: u256 = 70000000000000;
  const MID_FEE: u256 = 4000000;
  const OUT_FEE: u256 = 40000000;
  const ALLOWED_EXTRA_PROFIT: u256 = 2000000000000;
  const GAMMA_FEE: u256 = 10000000000000000;
  const ADJUSTMENT_STEP: u256 = 1500000000000000;
  const MA_TIME: u256 = 600_000; // 10 minutes
  const ETH_INITIAL_PRICE: u256 = 1500 * 1_000_000_000_000_000_000;

  const MIN_FEE: u256 = 5 * 100_000;
  const MAX_FEE: u256 = 10 * 1_000_000_000;
  const ONE_WEEK: u256 = 7 * 86400000; // 1 week in milliseconds
  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18 

  const ETH_DECIMALS: u8 = 9;
  const USDC_DECIMALS: u8 = 6; 

  #[test]
  #[expected_failure(abort_code = clamm::errors::OUT_FEE_OUT_OF_RANGE, location = clamm::interest_clamm_volatile)]  
  public fun test_parameters_out_fee_too_high() {
    let (alice, _) = people();
    let mut scenario = scenario();

    let test = &mut scenario;
        
    setup_dependencies(test);

    next_tx(test, alice);
    {
      let c = test::take_shared<Clock>(test);
      let coin_decimals = test::take_shared<CoinDecimals>(test);
      let lp_coin_cap = test::take_from_sender<TreasuryCap<LP_COIN>>(test);

      let (pool, pool_admin, lp_coin) = interest_clamm_volatile::new_2_pool<USDC, ETH, LP_COIN>(
        &c,
        &coin_decimals,
        mint<USDC>(4500, USDC_DECIMALS, ctx(test)),
        mint<ETH>(1, ETH_DECIMALS, ctx(test)),
        coin::treasury_into_supply(lp_coin_cap),
        vector[A, GAMMA],
        vector[ALLOWED_EXTRA_PROFIT, ADJUSTMENT_STEP, MA_TIME],
        ETH_INITIAL_PRICE,
        vector[MID_FEE, MAX_FEE + 1, GAMMA_FEE],
        ctx(test)
      );

      burn(lp_coin);    
      interest_pool::share(pool);
      transfer::public_transfer(pool_admin, alice);
      
      test::return_shared(coin_decimals);
      test::return_shared(c);
    };
    test::end(scenario); 
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::OUT_FEE_OUT_OF_RANGE, location = clamm::interest_clamm_volatile)]  
  public fun test_parameters_out_fee_too_low() {
    let (alice, _) = people();
    let mut scenario = scenario();

    let test = &mut scenario;
        
    setup_dependencies(test);

    next_tx(test, alice);
    {
      let c = test::take_shared<Clock>(test);
      let coin_decimals = test::take_shared<CoinDecimals>(test);
      let lp_coin_cap = test::take_from_sender<TreasuryCap<LP_COIN>>(test);

      let (pool, pool_admin, lp_coin) = interest_clamm_volatile::new_2_pool<USDC, ETH, LP_COIN>(
        &c,
        &coin_decimals,
        mint<USDC>(4500, USDC_DECIMALS, ctx(test)),
        mint<ETH>(1, ETH_DECIMALS, ctx(test)),
        coin::treasury_into_supply(lp_coin_cap),
        vector[A, GAMMA],
        vector[ALLOWED_EXTRA_PROFIT, ADJUSTMENT_STEP, MA_TIME],
        ETH_INITIAL_PRICE,
        vector[MID_FEE, MIN_FEE - 1, GAMMA_FEE],
        ctx(test)
      );

      burn(lp_coin);    
      interest_pool::share(pool);
      transfer::public_transfer(pool_admin, alice);
      
      test::return_shared(coin_decimals);
      test::return_shared(c);
    };
    test::end(scenario); 
  }  

  #[test]
  #[expected_failure(abort_code = clamm::errors::MID_FEE_OUT_OF_RANGE, location = clamm::interest_clamm_volatile)]  
  public fun test_parameters_mid_fee_too_high() {
    let (alice, _) = people();
    let mut scenario = scenario();

    let test = &mut scenario;
        
    setup_dependencies(test);

    next_tx(test, alice);
    {
      let c = test::take_shared<Clock>(test);
      let coin_decimals = test::take_shared<CoinDecimals>(test);
      let lp_coin_cap = test::take_from_sender<TreasuryCap<LP_COIN>>(test);

      let (pool, pool_admin, lp_coin) = interest_clamm_volatile::new_2_pool<USDC, ETH, LP_COIN>(
        &c,
        &coin_decimals,
        mint<USDC>(4500, USDC_DECIMALS, ctx(test)),
        mint<ETH>(1, ETH_DECIMALS, ctx(test)),
        coin::treasury_into_supply(lp_coin_cap),
        vector[A, GAMMA],
        vector[ALLOWED_EXTRA_PROFIT, ADJUSTMENT_STEP, MA_TIME],
        ETH_INITIAL_PRICE,
        vector[MAX_FEE + 1, OUT_FEE, GAMMA_FEE],
        ctx(test)
      );

      burn(lp_coin);    
      interest_pool::share(pool);
      transfer::public_transfer(pool_admin, alice);
      
      test::return_shared(coin_decimals);
      test::return_shared(c);
    };
    test::end(scenario); 
  }   

  #[test]
  #[expected_failure(abort_code = clamm::errors::MID_FEE_OUT_OF_RANGE, location = clamm::interest_clamm_volatile)]  
  public fun test_parameters_mid_fee_too_low() {
    let (alice, _) = people();
    let mut scenario = scenario();

    let test = &mut scenario;
        
    setup_dependencies(test);

    next_tx(test, alice);
    {
      let c = test::take_shared<Clock>(test);
      let coin_decimals = test::take_shared<CoinDecimals>(test);
      let lp_coin_cap = test::take_from_sender<TreasuryCap<LP_COIN>>(test);

      let (pool, pool_admin, lp_coin) = interest_clamm_volatile::new_2_pool<USDC, ETH, LP_COIN>(
        &c,
        &coin_decimals,
        mint<USDC>(4500, USDC_DECIMALS, ctx(test)),
        mint<ETH>(1, ETH_DECIMALS, ctx(test)),
        coin::treasury_into_supply(lp_coin_cap),
        vector[A, GAMMA],
        vector[ALLOWED_EXTRA_PROFIT, ADJUSTMENT_STEP, MA_TIME],
        ETH_INITIAL_PRICE,
        vector[MIN_FEE - 1, OUT_FEE, GAMMA_FEE],
        ctx(test)
      );

      burn(lp_coin);    
      interest_pool::share(pool);
      transfer::public_transfer(pool_admin, alice);
      
      test::return_shared(coin_decimals);
      test::return_shared(c);
    };
    test::end(scenario); 
  }   

  #[test]
  #[expected_failure(abort_code = clamm::errors::GAMMA_FEE_OUT_OF_RANGE, location = clamm::interest_clamm_volatile)]  
  public fun test_parameters_gamma_fee_too_low() {
    let (alice, _) = people();
    let mut scenario = scenario();

    let test = &mut scenario;
        
    setup_dependencies(test);

    next_tx(test, alice);
    {
      let c = test::take_shared<Clock>(test);
      let coin_decimals = test::take_shared<CoinDecimals>(test);
      let lp_coin_cap = test::take_from_sender<TreasuryCap<LP_COIN>>(test);

      let (pool, pool_admin, lp_coin) = interest_clamm_volatile::new_2_pool<USDC, ETH, LP_COIN>(
        &c,
        &coin_decimals,
        mint<USDC>(4500, USDC_DECIMALS, ctx(test)),
        mint<ETH>(1, ETH_DECIMALS, ctx(test)),
        coin::treasury_into_supply(lp_coin_cap),
        vector[A, GAMMA],
        vector[ALLOWED_EXTRA_PROFIT, ADJUSTMENT_STEP, MA_TIME],
        ETH_INITIAL_PRICE,
        vector[MID_FEE, OUT_FEE, 0],
        ctx(test)
      );

      burn(lp_coin);    
      interest_pool::share(pool);
      transfer::public_transfer(pool_admin, alice);
      
      test::return_shared(coin_decimals);
      test::return_shared(c);
    };
    test::end(scenario); 
  }   

  #[test]
  #[expected_failure(abort_code = clamm::errors::GAMMA_FEE_OUT_OF_RANGE, location = clamm::interest_clamm_volatile)]  
  public fun test_parameters_gamma_fee_too_high() {
    let (alice, _) = people();
    let mut scenario = scenario();

    let test = &mut scenario;
        
    setup_dependencies(test);

    next_tx(test, alice);
    {
      let c = test::take_shared<Clock>(test);
      let coin_decimals = test::take_shared<CoinDecimals>(test);
      let lp_coin_cap = test::take_from_sender<TreasuryCap<LP_COIN>>(test);

      let (pool, pool_admin, lp_coin) = interest_clamm_volatile::new_2_pool<USDC, ETH, LP_COIN>(
        &c,
        &coin_decimals,
        mint<USDC>(4500, USDC_DECIMALS, ctx(test)),
        mint<ETH>(1, ETH_DECIMALS, ctx(test)),
        coin::treasury_into_supply(lp_coin_cap),
        vector[A, GAMMA],
        vector[ALLOWED_EXTRA_PROFIT, ADJUSTMENT_STEP, MA_TIME],
        ETH_INITIAL_PRICE,
        vector[MID_FEE, OUT_FEE, PRECISION + 1],
        ctx(test)
      );

      burn(lp_coin);    
      interest_pool::share(pool);
      transfer::public_transfer(pool_admin, alice);
      
      test::return_shared(coin_decimals);
      test::return_shared(c);
    };
    test::end(scenario); 
  }   

  #[test]
  #[expected_failure(abort_code = clamm::errors::EXTRA_PROFIT_IS_TOO_BIG, location = clamm::interest_clamm_volatile)]  
  public fun test_parameters_extra_profit_is_too_high() {
    let (alice, _) = people();
    let mut scenario = scenario();

    let test = &mut scenario;
        
    setup_dependencies(test);

    next_tx(test, alice);
    {
      let c = test::take_shared<Clock>(test);
      let coin_decimals = test::take_shared<CoinDecimals>(test);
      let lp_coin_cap = test::take_from_sender<TreasuryCap<LP_COIN>>(test);

      let (pool, pool_admin, lp_coin) = interest_clamm_volatile::new_2_pool<USDC, ETH, LP_COIN>(
        &c,
        &coin_decimals,
        mint<USDC>(4500, USDC_DECIMALS, ctx(test)),
        mint<ETH>(1, ETH_DECIMALS, ctx(test)),
        coin::treasury_into_supply(lp_coin_cap),
        vector[A, GAMMA],
        vector[PRECISION + 1, ADJUSTMENT_STEP, MA_TIME],
        ETH_INITIAL_PRICE,
        vector[MID_FEE, OUT_FEE, GAMMA_FEE],
        ctx(test)
      );

      burn(lp_coin);    
      interest_pool::share(pool);
      transfer::public_transfer(pool_admin, alice);
      
      test::return_shared(coin_decimals);
      test::return_shared(c);
    };
    test::end(scenario); 
  }   

  #[test]
  #[expected_failure(abort_code = clamm::errors::ADJUSTMENT_STEP_IS_TOO_BIG, location = clamm::interest_clamm_volatile)]  
  public fun test_parameters_adjustment_step_is_too_high() {
    let (alice, _) = people();
    let mut scenario = scenario();

    let test = &mut scenario;
        
    setup_dependencies(test);

    next_tx(test, alice);
    {
      let c = test::take_shared<Clock>(test);
      let coin_decimals = test::take_shared<CoinDecimals>(test);
      let lp_coin_cap = test::take_from_sender<TreasuryCap<LP_COIN>>(test);

      let (pool, pool_admin, lp_coin) = interest_clamm_volatile::new_2_pool<USDC, ETH, LP_COIN>(
        &c,
        &coin_decimals,
        mint<USDC>(4500, USDC_DECIMALS, ctx(test)),
        mint<ETH>(1, ETH_DECIMALS, ctx(test)),
        coin::treasury_into_supply(lp_coin_cap),
        vector[A, GAMMA],
        vector[ALLOWED_EXTRA_PROFIT, PRECISION + 1, MA_TIME],
        ETH_INITIAL_PRICE,
        vector[MID_FEE, OUT_FEE, GAMMA_FEE],
        ctx(test)
      );

      burn(lp_coin);    
      interest_pool::share(pool);
      transfer::public_transfer(pool_admin, alice);
      
      test::return_shared(coin_decimals);
      test::return_shared(c);
    };
    test::end(scenario); 
  }   

  #[test]
  #[expected_failure(abort_code = clamm::errors::MA_HALF_TIME_OUT_OF_RANGE, location = clamm::interest_clamm_volatile)]  
  public fun test_parameters_ma_half_time_too_low() {
    let (alice, _) = people();
    let mut scenario = scenario();

    let test = &mut scenario;
        
    setup_dependencies(test);

    next_tx(test, alice);
    {
      let c = test::take_shared<Clock>(test);
      let coin_decimals = test::take_shared<CoinDecimals>(test);
      let lp_coin_cap = test::take_from_sender<TreasuryCap<LP_COIN>>(test);

      let (pool, pool_admin, lp_coin) = interest_clamm_volatile::new_2_pool<USDC, ETH, LP_COIN>(
        &c,
        &coin_decimals,
        mint<USDC>(4500, USDC_DECIMALS, ctx(test)),
        mint<ETH>(1, ETH_DECIMALS, ctx(test)),
        coin::treasury_into_supply(lp_coin_cap),
        vector[A, GAMMA],
        vector[ALLOWED_EXTRA_PROFIT, ADJUSTMENT_STEP, 999],
        ETH_INITIAL_PRICE,
        vector[MID_FEE, OUT_FEE, GAMMA_FEE],
        ctx(test)
      );

      burn(lp_coin);    
      interest_pool::share(pool);
      transfer::public_transfer(pool_admin, alice);
      
      test::return_shared(coin_decimals);
      test::return_shared(c);
    };
    test::end(scenario); 
  }  

  #[test]
  #[expected_failure(abort_code = clamm::errors::MA_HALF_TIME_OUT_OF_RANGE, location = clamm::interest_clamm_volatile)]  
  public fun test_parameters_ma_half_time_too_high() {
    let (alice, _) = people();
    let mut scenario = scenario();

    let test = &mut scenario;
        
    setup_dependencies(test);

    next_tx(test, alice);
    {
      let c = test::take_shared<Clock>(test);
      let coin_decimals = test::take_shared<CoinDecimals>(test);
      let lp_coin_cap = test::take_from_sender<TreasuryCap<LP_COIN>>(test);

      let (pool, pool_admin, lp_coin) = interest_clamm_volatile::new_2_pool<USDC, ETH, LP_COIN>(
        &c,
        &coin_decimals,
        mint<USDC>(4500, USDC_DECIMALS, ctx(test)),
        mint<ETH>(1, ETH_DECIMALS, ctx(test)),
        coin::treasury_into_supply(lp_coin_cap),
        vector[A, GAMMA],
        vector[ALLOWED_EXTRA_PROFIT, ADJUSTMENT_STEP, ONE_WEEK + 1],
        ETH_INITIAL_PRICE,
        vector[MID_FEE, OUT_FEE, GAMMA_FEE],
        ctx(test)
      );

      burn(lp_coin);    
      interest_pool::share(pool);
      transfer::public_transfer(pool_admin, alice);
      
      test::return_shared(coin_decimals);
      test::return_shared(c);
    };
    test::end(scenario); 
  }  
}