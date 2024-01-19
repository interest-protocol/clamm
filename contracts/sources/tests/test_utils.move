#[test_only]
module clamm::amm_test_utils {

  use sui::math;
  use sui::clock;
  use sui::transfer;
  use sui::tx_context::TxContext;
  use sui::coin::{mint_for_testing, Coin, CoinMetadata};
  use sui::test_scenario::{Self as test, Scenario, next_tx, ctx};

  use suitears::coin_decimals::{Self, CoinDecimals};
  
  use clamm::btc::{Self, BTC};
  use clamm::eth::{Self, ETH};
  use clamm::dai::{Self, DAI};
  use clamm::amm_admin as admin;
  use clamm::usdt::{Self, USDT};
  use clamm::usdc::{Self, USDC};
  use clamm::frax::{Self, FRAX};
  use clamm::lp_coin::{Self, LP_COIN};
  use clamm::true_usd::{Self, TRUE_USD};

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
      admin::init_for_testing(ctx(test));
      frax::init_for_testing(ctx(test));
      true_usd::init_for_testing(ctx(test));

      transfer::public_share_object(coin_decimals::new(ctx(test)));
    };    

    next_tx(test, alice);
    {
      let coin_decimals_storage = test::take_shared<CoinDecimals>(test);
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