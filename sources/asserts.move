module amm::asserts {

  use sui::coin::{Self, Coin};
  use sui::balance::{Self, Supply};

  use amm::errors;

  public fun assert_coin_has_value<CoinType>(asset: &Coin<CoinType>) {
    assert!(coin::value(asset) != 0, errors::cannot_swap_zero_value());
  }

  public fun assert_supply_has_zero_value<CoinType>(supply: &Supply<CoinType>) {
    assert!(balance::supply_value(supply) == 0, errors::supply_must_have_zero_value());
  }
}