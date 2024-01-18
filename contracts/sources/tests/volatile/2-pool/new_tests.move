// * 2 Pool - USDC - ETH
#[test_only]
module amm::volatile_2pool_new_tests {
  use std::type_name;
  
  use sui::clock;

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx}; 

  use amm::interest_amm_volatile;
  use amm::eth::ETH;
  use amm::usdc::USDC;
  use amm::lp_coin::LP_COIN;
  use amm::curves::Volatile;
  use amm::interest_pool::InterestPool;
  use amm::init_interest_amm_volatile::setup_2pool;
  use amm::amm_test_utils ::{people, scenario, normalize_amount};

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
  const INITIAL_ADMIN_FEE: u256 = 2000000000;

  const ETH_DECIMALS_SCALAR: u64 = 1000000000;
  const USDC_DECIMALS_SCALAR: u64 = 1000000; 

  #[test]
  fun sets_2pool_state_correctly() {
   let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 15000, 10);

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      let c = clock::create_for_testing(ctx(test));

      assert_eq(
        interest_amm_volatile::a<LP_COIN>(&pool, &c),
        A
      );

      assert_eq(
        interest_amm_volatile::gamma<LP_COIN>(&pool, &c),
        GAMMA
      );

      assert_eq(interest_amm_volatile::lp_coin_supply<LP_COIN>(&pool), 387298334620);
      assert_eq(interest_amm_volatile::balances<LP_COIN>(&pool), vector[normalize_amount(15000), normalize_amount(10)]);
      assert_eq(interest_amm_volatile::xcp_profit<LP_COIN>(&pool), PRECISION);
      assert_eq(interest_amm_volatile::xcp_profit_a<LP_COIN>(&pool), PRECISION);
      assert_eq(interest_amm_volatile::virtual_price<LP_COIN>(&pool), PRECISION);
      assert_eq(interest_amm_volatile::extra_profit<LP_COIN>(&pool), ALLOWED_EXTRA_PROFIT);
      assert_eq(interest_amm_volatile::adjustment_step<LP_COIN>(&pool), ADJUSTMENT_STEP);
      assert_eq(interest_amm_volatile::ma_half_time<LP_COIN>(&pool), MA_TIME);
      assert_eq(interest_amm_volatile::mid_fee<LP_COIN>(&pool), MID_FEE);
      assert_eq(interest_amm_volatile::out_fee<LP_COIN>(&pool), OUT_FEE);
      assert_eq(interest_amm_volatile::gamma_fee<LP_COIN>(&pool), FEE_GAMMA);
      assert_eq(interest_amm_volatile::admin_fee<LP_COIN>(&pool), INITIAL_ADMIN_FEE);
      assert_eq(interest_amm_volatile::last_prices_timestamp<LP_COIN>(&pool), 0);
      assert_eq(interest_amm_volatile::last_prices_timestamp<LP_COIN>(&pool), 0);
      assert_eq(interest_amm_volatile::coin_price<USDC, LP_COIN>(&pool), 0);
      assert_eq(interest_amm_volatile::coin_price<ETH, LP_COIN>(&pool), INITIAL_ETH_PRICE);
      assert_eq(interest_amm_volatile::coin_index<USDC, LP_COIN>(&pool), 0);
      assert_eq(interest_amm_volatile::coin_index<ETH, LP_COIN>(&pool), 1);
      assert_eq(interest_amm_volatile::coin_price_oracle<USDC, LP_COIN>(&pool), 0);
      assert_eq(interest_amm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool), INITIAL_ETH_PRICE);      
      assert_eq(interest_amm_volatile::coin_price_oracle<USDC, LP_COIN>(&pool), 0);
      assert_eq(interest_amm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool), INITIAL_ETH_PRICE);     
      assert_eq(interest_amm_volatile::coin_decimals_scalar<USDC, LP_COIN>(&pool), (USDC_DECIMALS_SCALAR as u256));
      assert_eq(interest_amm_volatile::coin_decimals_scalar<ETH, LP_COIN>(&pool), (ETH_DECIMALS_SCALAR as u256)); 
      assert_eq(interest_amm_volatile::coin_type<USDC, LP_COIN>(&pool), type_name::get<USDC>());
      assert_eq(interest_amm_volatile::coin_type<ETH, LP_COIN>(&pool), type_name::get<ETH>()); 
      assert_eq(interest_amm_volatile::balances_in_price<LP_COIN>(&pool), vector[normalize_amount(15000), 10 * INITIAL_ETH_PRICE]);

      clock::destroy_for_testing(c);

      test::return_shared(pool);
    };
    test::end(scenario);   
  }
}