module amm::curves {

  use amm::utils::are_types_equal;
  use amm::errors;

  /*
  * We have decided to use Curve V2 formula instead of Uniswap V3 for the following reasons
  * It gives a LP Coin instead of an NFT, which is more composable than an NFT
  * It supports multiple coins
  * It rebalances the liquidity automatically based on an internal oracle to maximize the profits for LPs
  * Sui gas cost makes the higher computation negligible
  */
  // https://resources.curve.fi/base-features/understanding-crypto-pools/
  struct Volatile {}

  /*
  * For a pool of two pegged assets.
  * The most effective stable algorithm is  k = x^3y + xy^3 by Andre Cronje
  */
  struct StablePair {}

  /*
  * Curve V1 Stable formula has been battle tested and the high gas cost by brute forcing the newton method is fine on a low gas cost chain
  */
  struct StableTuple {}


  public fun is_volatile<Type>(): bool {
    are_types_equal<Type, Volatile>() 
  }

  public fun is_stable_pair<Type>(): bool {
    are_types_equal<Type, StablePair>() 
  }

  public fun is_stable_tuple<Type>(): bool {
    are_types_equal<Type, StableTuple>() 
  }

  public fun is_curve<Type>(): bool {
    is_volatile<Type>() || is_stable_pair<Type>() || is_stable_tuple<Type>()
  }

  public fun assert_is_stable_pair<Type>() {
    assert!(is_stable_pair<Type>(), errors::invalid_curve());
  }

  public fun assert_is_stable_tuple<Type>() {
    assert!(is_stable_tuple<Type>(), errors::invalid_curve());
  }

  public fun assert_is_curve<Type>() {
    assert!(is_curve<Type>(), errors::invalid_curve());
  }
}