#[test_only]
module amm::test_utils {

  use sui::math;
  use sui::clock;
  use sui::tx_context::TxContext;
  use sui::coin::{mint_for_testing, Coin, CoinMetadata};
  use sui::test_scenario::{Self as test, Scenario, next_tx, ctx};

  use suitears::coin_decimals::{Self, CoinDecimals};

  use amm::dai::{Self, DAI};
  use amm::amm_admin as admin;
  use amm::usdt::{Self, USDT};
  use amm::usdc::{Self, USDC};
  use amm::lp_coin::{Self, LP_COIN};

  public fun scenario(): Scenario { test::begin(@0x1) }

  public fun people():(address, address) { (@0xBEEF, @0x1337)}

  public fun mint<T>(amount: u64, decimals: u8, ctx: &mut TxContext): Coin<T> {
    mint_for_testing<T>(amount * math::pow(10, decimals), ctx)
  }

  public fun add_decimals(x: u64, decimals: u8): u64 {
    x * math::pow(10, decimals)
  }

  public fun setup_dependencies(test: &mut Scenario) {
    let (alice, _) = people();

    next_tx(test, alice);
    {
      dai::init_for_testing(ctx(test));
      usdc::init_for_testing(ctx(test));
      usdt::init_for_testing(ctx(test));
      lp_coin::init_for_testing(ctx(test));
      admin::init_for_testing(ctx(test));
      coin_decimals::init_for_testing(ctx(test));
    };    

    next_tx(test, alice);
    {
      let coin_decimals_storage = test::take_shared<CoinDecimals>(test);
      let usdt_metadata = test::take_shared<CoinMetadata<USDT>>(test);
      let usdc_metadata = test::take_shared<CoinMetadata<USDC>>(test);
      let dai_metadata = test::take_shared<CoinMetadata<DAI>>(test);
      let lp_metadata = test::take_shared<CoinMetadata<LP_COIN>>(test);

      coin_decimals::register_coin<USDT>(&mut coin_decimals_storage, &usdt_metadata);
      coin_decimals::register_coin<USDC>(&mut coin_decimals_storage, &usdc_metadata);
      coin_decimals::register_coin<DAI>(&mut coin_decimals_storage, &dai_metadata);
      coin_decimals::register_coin<LP_COIN>(&mut coin_decimals_storage, &lp_metadata);

      test::return_shared(coin_decimals_storage);
      test::return_shared(lp_metadata);
      test::return_shared(dai_metadata);
      test::return_shared(usdc_metadata);
      test::return_shared(usdt_metadata);
    };

    next_tx(test, alice);
    {
      let c = clock::create_for_testing(ctx(test));
      clock::share_for_testing(c);
    }
  }
}