#[test_only]
module amm::test_utils {

  use sui::math;
  use sui::tx_context::TxContext;
  use sui::coin::{mint_for_testing, Coin};
  use sui::test_scenario::{Self as test, Scenario};

  public fun scenario(): Scenario { test::begin(@0x1) }

  public fun people():(address, address) { (@0xBEEF, @0x1337)}

  public fun mint<T>(amount: u64, decimals: u8, ctx: &mut TxContext): Coin<T> {
    mint_for_testing<T>(amount * math::pow(10, decimals), ctx)
  }

  public fun add_decimals(x: u64, decimals: u8): u64 {
    x * math::pow(10, decimals)
  }
}