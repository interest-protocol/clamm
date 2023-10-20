module amm::curves {

  use amm::errors;
  use amm::utils::are_types_equal;

  /*
  * We have decided to use Curve V2 formula instead of Uniswap V3 for the following reasons
  * It gives a LP Coin instead of an NFT, which is more composable than an NFT
  * It supports multiple coins
  * It rebalances the liquidity automatically based on an internal oracle to maximize the profits for LPs
  * Sui gas cost makes the higher computation negligible
  */
  // https://resources.curve.fi/base-features/understanding-crypto-pools/
  struct Volatile {}

  /**********************************************************************************************
  // invariant                                                                                 //
  // k = invariant                                                                             //
  // x = Balance of X                  k = x^3y + xy^3                                         //
  // y = Balance of Y                                                                          //
  **********************************************************************************************/
  struct StablePair {}

  /**********************************************************************************************
  // invariant                                                                                 //
  // D = invariant                                                  D^(n+1)                    //
  // A = amplification coefficient      A  n^n S + D = A D n^n + -----------                   //
  // S = sum of balances                                             n^n P                     //
  // P = product of balances                                                                   //
  // n = number of tokens                                                                      //
  **********************************************************************************************/
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

  public fun assert_is_volatile<Type>() {
    assert!(is_volatile<Type>(), errors::invalid_curve());    
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