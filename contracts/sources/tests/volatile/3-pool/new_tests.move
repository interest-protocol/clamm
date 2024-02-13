// * 3 Pool - USDC - ETH - btc
#[test_only]
module clamm::volatile_3pool_new_tests {
  use std::type_name;
  
  use sui::clock;

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx}; 

  use clamm::interest_clamm_volatile;
  use clamm::eth::ETH;
  use clamm::btc::BTC;
  use clamm::usdc::USDC;
  use clamm::lp_coin::LP_COIN;
  use clamm::curves::Volatile;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_volatile::setup_3pool;
  use clamm::amm_test_utils ::{people, scenario, normalize_amount};

  const A: u256  = 36450000;
  const GAMMA: u256 = 70000000000000;
  const MID_FEE: u256 = 4000000;
  const OUT_FEE: u256 = 40000000;
  const ALLOWED_EXTRA_PROFIT: u256 = 2000000000000;
  const FEE_GAMMA: u256 = 10000000000000000;
  const ADJUSTMENT_STEP: u256 = 1500000000000000;
  const MA_TIME: u256 = 600_000; // 10 minutes
  const PRECISION: u256 = 1_000_000_000_000_000_000;
  const INITIAL_ETH_PRICE: u256 = 1500 * 1_000_000_000_000_000_000;
  const INITIAL_BTC_PRICE: u256 = 47500 * 1_000_000_000_000_000_000;
  const INITIAL_ADMIN_FEE: u256 = 2000000000;

  const BTC_DECIMALS_SCALAR: u64 = 1_000_000_000;
  const ETH_DECIMALS_SCALAR: u64 = 1_000_000_000;
  const USDC_DECIMALS_SCALAR: u64 = 1_000_000;   

  #[test]
  fun sets_3pool_state_correctly() {
    let scenario = scenario();
    let (alice, _) = people();    

    let test = &mut scenario;

    setup_3pool(test, 150_000, 3, 100);

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      let c = clock::create_for_testing(ctx(test));

      assert_eq(
        interest_clamm_volatile::a<LP_COIN>(&pool, &c),
        A
      );

      assert_eq(
        interest_clamm_volatile::gamma<LP_COIN>(&pool, &c),
        GAMMA
      );    

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&pool), 355781584449);
      assert_eq(interest_clamm_volatile::balances<LP_COIN>(&pool), vector[normalize_amount(150_000), normalize_amount(3), normalize_amount(100)]);
      assert_eq(interest_clamm_volatile::xcp_profit<LP_COIN>(&pool), PRECISION);
      assert_eq(interest_clamm_volatile::xcp_profit_a<LP_COIN>(&pool), PRECISION);
      assert_eq(interest_clamm_volatile::virtual_price<LP_COIN>(&pool), PRECISION);
      assert_eq(interest_clamm_volatile::extra_profit<LP_COIN>(&pool), ALLOWED_EXTRA_PROFIT);
      assert_eq(interest_clamm_volatile::adjustment_step<LP_COIN>(&pool), ADJUSTMENT_STEP);
      assert_eq(interest_clamm_volatile::ma_half_time<LP_COIN>(&pool), MA_TIME);
      assert_eq(interest_clamm_volatile::mid_fee<LP_COIN>(&pool), MID_FEE);
      assert_eq(interest_clamm_volatile::out_fee<LP_COIN>(&pool), OUT_FEE);
      assert_eq(interest_clamm_volatile::gamma_fee<LP_COIN>(&pool), FEE_GAMMA);
      assert_eq(interest_clamm_volatile::admin_fee<LP_COIN>(&pool), INITIAL_ADMIN_FEE);
      assert_eq(interest_clamm_volatile::last_prices_timestamp<LP_COIN>(&pool), 0);
      assert_eq(interest_clamm_volatile::last_prices_timestamp<LP_COIN>(&pool), 0);
      assert_eq(interest_clamm_volatile::coin_price<USDC, LP_COIN>(&pool), PRECISION);
      assert_eq(interest_clamm_volatile::coin_price<BTC, LP_COIN>(&pool), INITIAL_BTC_PRICE); 
      assert_eq(interest_clamm_volatile::coin_price<ETH, LP_COIN>(&pool), INITIAL_ETH_PRICE);
      assert_eq(interest_clamm_volatile::coin_index<USDC, LP_COIN>(&pool), 0);
      assert_eq(interest_clamm_volatile::coin_index<BTC, LP_COIN>(&pool), 1);
      assert_eq(interest_clamm_volatile::coin_index<ETH, LP_COIN>(&pool), 2);
      assert_eq(interest_clamm_volatile::coin_price_oracle<USDC, LP_COIN>(&pool), PRECISION);
      assert_eq(interest_clamm_volatile::coin_price_oracle<BTC, LP_COIN>(&pool), INITIAL_BTC_PRICE); 
      assert_eq(interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool), INITIAL_ETH_PRICE);      
      assert_eq(interest_clamm_volatile::coin_last_price<USDC, LP_COIN>(&pool), PRECISION);
      assert_eq(interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&pool), INITIAL_BTC_PRICE); 
      assert_eq(interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&pool), INITIAL_ETH_PRICE);     
      assert_eq(interest_clamm_volatile::coin_decimals_scalar<USDC, LP_COIN>(&pool), (USDC_DECIMALS_SCALAR as u256));
      assert_eq(interest_clamm_volatile::coin_decimals_scalar<BTC, LP_COIN>(&pool), (BTC_DECIMALS_SCALAR as u256)); 
      assert_eq(interest_clamm_volatile::coin_decimals_scalar<ETH, LP_COIN>(&pool), (ETH_DECIMALS_SCALAR as u256)); 
      assert_eq(interest_clamm_volatile::coin_type<USDC, LP_COIN>(&pool), type_name::get<USDC>());
      assert_eq(interest_clamm_volatile::coin_type<BTC, LP_COIN>(&pool), type_name::get<BTC>()); 
      assert_eq(interest_clamm_volatile::coin_type<ETH, LP_COIN>(&pool), type_name::get<ETH>()); 
      assert_eq(interest_clamm_volatile::balances_in_price<LP_COIN>(&pool), vector[normalize_amount(150_000), 3 * INITIAL_BTC_PRICE, 100 * INITIAL_ETH_PRICE]);        

      clock::destroy_for_testing(c);

      test::return_shared(pool);
    };

    test::end(scenario);
  }  
} 