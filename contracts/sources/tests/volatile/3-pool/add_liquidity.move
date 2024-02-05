// * 2 Pool - USDC - BTC - ETH
// All values tested agaisnt Curve pool
#[test_only]
module clamm::volatile_3pool_add_liquidity_tests {
  use sui::clock;
  use sui::coin::{Self, burn_for_testing as burn};

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx}; 

  use clamm::interest_clamm_volatile;
  use clamm::btc::BTC;
  use clamm::eth::ETH;
  use clamm::usdc::USDC;
  use clamm::lp_coin::LP_COIN;
  use clamm::curves::Volatile;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_volatile::setup_3pool;
  use clamm::amm_test_utils ::{people, scenario, mint};

  const BTC_DECIMALS_SCALAR: u64 = 1000000000;
  const ETH_DECIMALS_SCALAR: u64 = 1000000000;
  const USDC_DECIMALS_SCALAR: u64 = 1000000; 
  const TWENTY_MILLISECONDS: u64 = 22000;

  const POW_10_18: u256 = 1_000_000_000_000_000_000;
  const POW_10_9: u256 = 1_000_000_000;   

  #[test]
  fun mints_correct_lp_coin_amount() {
    let scenario = scenario();
    let (alice, bob) = people();

    let test = &mut scenario;
    
    setup_3pool(test, 150000, 3, 100);

    let c = clock::create_for_testing(ctx(test));

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&pool), 355781584449);
      assert_eq(355781584449, 355781584449860319361 / POW_10_9);
      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&pool),
        vector[150000 * POW_10_18, 3 * POW_10_18, 100 * POW_10_18]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        150000 * USDC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, BTC>(&pool),
        3 * BTC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        100 * ETH_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&pool),
        47500000000000000000000
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );  
     assert_eq(
        interest_clamm_volatile::coin_price<BTC, LP_COIN>(&pool),
        47500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<BTC, LP_COIN>(&pool),
        47500000000000000000000
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500000000000000000000
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&pool),
        POW_10_18
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&pool),
        442486144074400445244930
      );  

      test::return_shared(pool);
    };

    next_tx(test, bob);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      burn(interest_clamm_volatile::add_liquidity_3_pool<USDC, BTC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(6000, 6, ctx(test)),
        mint<BTC>(2, 9, ctx(test)),
        mint<ETH>(5, 9, ctx(test)),
        0,
        ctx(test)
      ));

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&pool), 355781584449);
      assert_eq(355781584449, 355781584449860319361 / POW_10_9);
      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&pool),
        vector[150000 * POW_10_18, 3 * POW_10_18, 100 * POW_10_18]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        150000 * USDC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, BTC>(&pool),
        3 * BTC_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        100 * ETH_DECIMALS_SCALAR
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<BTC, LP_COIN>(&pool),
        47500000000000000000000
      );  
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );  
     assert_eq(
        interest_clamm_volatile::coin_price<BTC, LP_COIN>(&pool),
        47500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<BTC, LP_COIN>(&pool),
        47500000000000000000000
      ); 
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500000000000000000000
      ); 
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&pool),
        POW_10_18
      ); 
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&pool),
        442486144074400445244930
      );        

      test::return_shared(pool);
    };

    clock::destroy_for_testing(c);
    test::end(scenario);
  }  
}