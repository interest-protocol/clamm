#[test_only]
module clamm::init_interest_amm_volatile {
  use sui::clock::Clock;
  use sui::coin::{Self, burn_for_testing as burn, TreasuryCap};
  use sui::test_scenario::{Self as test, Scenario, next_tx, ctx};

  use suitears::coin_decimals::CoinDecimals;

  use clamm::btc::BTC;
  use clamm::eth::ETH;
  use clamm::usdc::USDC;
  use clamm::interest_pool;
  use clamm::lp_coin::LP_COIN;
  use clamm::interest_clamm_volatile;
  use clamm::amm_test_utils::{people, mint, setup_dependencies};

  const A: u256  = 36450000;
  const GAMMA: u256 = 70000000000000;
  const MID_FEE: u256 = 4000000;
  const OUT_FEE: u256 = 40000000;
  const ALLOWED_EXTRA_PROFIT: u256 = 2000000000000;
  const GAMMA_FEE: u256 = 10000000000000000;
  const ADJUSTMENT_STEP: u256 = 1500000000000000;
  const MA_TIME: u256 = 600_000; // 10 minutes
  const ETH_INITIAL_PRICE: u256 = 1500 * 1_000_000_000_000_000_000;
  const BTC_INITIAL_PRICE: u256 = 47500 * 1_000_000_000_000_000_000;

  const ETH_DECIMALS: u8 = 9;
  const BTC_DECIMALS: u8 = 9;
  const USDC_DECIMALS: u8 = 6; 

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
        vector[ALLOWED_EXTRA_PROFIT, ADJUSTMENT_STEP, MA_TIME],
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
  }

  public fun setup_3pool(test: &mut Scenario, usdc_amount: u64, btc_amount: u64, eth_amount: u64) {
    let (alice, _) = people();
    
    setup_dependencies(test);

    next_tx(test, alice);
    {
      let c = test::take_shared<Clock>(test);
      let coin_decimals = test::take_shared<CoinDecimals>(test);
      let lp_coin_cap = test::take_from_sender<TreasuryCap<LP_COIN>>(test);

      let (pool, pool_admin, lp_coin) = interest_clamm_volatile::new_3_pool<USDC, BTC, ETH, LP_COIN>(
        &c,
        &coin_decimals,
        mint<USDC>(usdc_amount, USDC_DECIMALS, ctx(test)),
        mint<BTC>(btc_amount, BTC_DECIMALS, ctx(test)),
        mint<ETH>(eth_amount, ETH_DECIMALS, ctx(test)),
        coin::treasury_into_supply(lp_coin_cap),
        vector[A, GAMMA],
        vector[ALLOWED_EXTRA_PROFIT, ADJUSTMENT_STEP, MA_TIME],
        vector[BTC_INITIAL_PRICE, ETH_INITIAL_PRICE],
        vector[MID_FEE, OUT_FEE, GAMMA_FEE],
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