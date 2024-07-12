#[test_only]
module clamm::amm_test_utils {

  use sui::{
    math,
    clock::{Self, Clock},
    coin::{mint_for_testing, Coin, CoinMetadata},
    test_scenario::{Self as test, Scenario, next_tx, ctx}
  };

  use suitears::{
    math256::diff,
    coin_decimals::{Self, CoinDecimals}
  };

  use clamm::{
    pool_admin,
    curves::Stable,
    btc::{Self, BTC},
    eth::{Self, ETH},
    dai::{Self, DAI},
    usdt::{Self, USDT},
    usdc::{Self, USDC},
    frax::{Self, FRAX},
    interest_clamm_stable,
    stable_math::invariant_,
    lp_coin::{Self, LP_COIN},
    true_usd::{Self, TRUE_USD},
    interest_pool::InterestPool,
  };

  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18

  public fun scenario(): Scenario { test::begin(@0x1) }

  public fun people():(address, address) { (@0xBEEF, @0x1337)}

  public fun mint<T>(amount: u64, decimals: u8, ctx: &mut TxContext): Coin<T> {
    mint_for_testing<T>(amount * math::pow(10, decimals), ctx)
  }

  public fun add_decimals(x: u64, decimals: u8): u64 {
    x * math::pow(10, decimals)
  }

  public fun normalize_amount(a: u256): u256 {
    a * PRECISION
  }

  public fun imbalanced_fee(fee: u256, n_coins: u64): u256 {
    fee * (n_coins as u256) / (4 * ((n_coins as u256) - 1))
  }

  public fun get_stable_add_liquidity_added_balances<LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock, 
    old_balances: vector<u256>,
    new_balances: vector<u256>,
  ): vector<u256> {

    let coins = pool.coins();

    let amp = interest_clamm_stable::a<LpCoin>(pool, clock);  

    let prev_k = invariant_(amp, old_balances);

    let num_of_coins = coins.length();

    let new_k = invariant_(amp, new_balances);    
    let supply_value = (interest_clamm_stable::lp_coin_supply<LpCoin>(pool) as u256);

    if (supply_value == 0) {
      new_balances
    } else {
      
      let stable_fee = interest_clamm_stable::fees<LpCoin>(pool);
      let fee = stable_fee.fee() * (num_of_coins as u256) / (4 * ((num_of_coins as u256) - 1));
      let mut balances_minus_fees = new_balances;

      let mut i = 0;

      while (num_of_coins > i) {

        let ideal_balance = new_k * old_balances[i] / prev_k;
        let difference = diff(ideal_balance, new_balances[i]);

        let balance_fee = fee * difference / PRECISION;

        let y = &mut balances_minus_fees[i];
        *y = (*y - stable_fee.calculate_admin_fee(balance_fee)) - old_balances[i];

        i = i + 1;
      };

      balances_minus_fees 
    }
   }

  #[lint_allow(share_owned)]
  public fun setup_dependencies(test: &mut Scenario) {
    let (alice, _) = people();

    next_tx(test, alice);
    {
      btc::init_for_testing(ctx(test));
      eth::init_for_testing(ctx(test));
      dai::init_for_testing(ctx(test));
      usdc::init_for_testing(ctx(test));
      usdt::init_for_testing(ctx(test));
      lp_coin::init_for_testing(ctx(test));
      frax::init_for_testing(ctx(test));
      true_usd::init_for_testing(ctx(test));
      pool_admin::init_for_testing(ctx(test));

      transfer::public_share_object(coin_decimals::new( ctx(test)));
    };    

    next_tx(test, alice);
    {
      let mut coin_decimals_storage = test::take_shared<CoinDecimals>(test);
      let usdt_metadata = test::take_shared<CoinMetadata<USDT>>(test);
      let usdc_metadata = test::take_shared<CoinMetadata<USDC>>(test);
      let dai_metadata = test::take_shared<CoinMetadata<DAI>>(test);
      let frax_metadata = test::take_shared<CoinMetadata<FRAX>>(test);
      let lp_metadata = test::take_shared<CoinMetadata<LP_COIN>>(test);
      let true_usd_metadata = test::take_shared<CoinMetadata<TRUE_USD>>(test);
      let eth_metadata = test::take_shared<CoinMetadata<ETH>>(test);
      let btc_metadata = test::take_shared<CoinMetadata<BTC>>(test);

      coin_decimals::add<USDT>(&mut coin_decimals_storage, &usdt_metadata);
      coin_decimals::add<USDC>(&mut coin_decimals_storage, &usdc_metadata);
      coin_decimals::add<DAI>(&mut coin_decimals_storage, &dai_metadata);
      coin_decimals::add<LP_COIN>(&mut coin_decimals_storage, &lp_metadata);
      coin_decimals::add<FRAX>(&mut coin_decimals_storage, &frax_metadata);
      coin_decimals::add<TRUE_USD>(&mut coin_decimals_storage, &true_usd_metadata);
      coin_decimals::add<ETH>(&mut coin_decimals_storage, &eth_metadata);
      coin_decimals::add<BTC>(&mut coin_decimals_storage, &btc_metadata);

      test::return_shared(btc_metadata);
      test::return_shared(eth_metadata);  
      test::return_shared(coin_decimals_storage);
      test::return_shared(lp_metadata);
      test::return_shared(dai_metadata);
      test::return_shared(usdc_metadata);
      test::return_shared(usdt_metadata);
      test::return_shared(frax_metadata);
      test::return_shared(true_usd_metadata);
    };

    next_tx(test, alice);
    {
      let c = clock::create_for_testing(ctx(test));
      clock::share_for_testing(c);
    }
  }
}