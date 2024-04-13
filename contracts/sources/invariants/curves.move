/*
* @title Curves. 
* @author @josemvcerqueira
* @notice It defines the two invariants supported by the AMM and provides utility functions to check the curve types.
*/
module clamm::curves {
  // === Imports ===  
  
  use std::type_name;

  use clamm::errors;

  // === Structs ===  

  /*
  * @dev We implement the Curve V2 formula instead of Uniswap V3 for the following reasons:
  * - It gives a LP Coin instead of an NFT, which is more composable than an NFT
  * - It supports multiple coins
  * - It rebalances the liquidity automatically based on an internal oracle to maximize the profits for LPs
  * - Sui gas cost makes the higher computation negligible
  *
  * @dev Read more at https://resources.curve.fi/base-features/understanding-crypto-pools/
  */
  public struct Volatile {}

  /*
  * @dev We implement the CurveV1 invariant which supports multiple stable coins                                                                                 
  * D = invariant                                                  D^(n+1)                    
  * A = amplification coefficient      A  n^n S + D = A D n^n + -----------                   
  * S = sum of balances                                             n^n P                     
  * P = product of balances                                                                   
  * n = number of tokens                                                                      
  */
  public struct Stable {}

  // === Public View Functions ===  

  /*
  * @notice Checks if the `Type` is equal to `Volatile`
  *
  * @return bool 
  */
  public fun is_volatile<Type>(): bool {
    are_equal<Type, Volatile>() 
  }

  /*
  * @notice Checks if the `Type` is equal to `Stable`
  *
  * @return bool 
  */
  public fun is_stable<Type>(): bool {
    are_equal<Type, Stable>() 
  }

  /*
  * @notice Checks if the `Type` is equal to `Stable` or `Volatile`
  *
  * @return bool 
  */
  public fun is_curve<Type>(): bool {
    is_volatile<Type>() || is_stable<Type>()
  }

  // === Assert Function ===  

  /*
  * @notice Asserts if the `Type` is `Volatile` or `Stable`
  * 
  * aborts-if 
  *   - The `Type` is not `Volatile` nor `Stable`
  */
  public fun assert_curve<Type>() {
    assert!(is_curve<Type>(), errors::invalid_curve());
  }

  // === Private Functions ===  

  /*
  * @notice Checks if `A` is equal to `B`
  *
  * @return bool 
  */
  fun are_equal<A, B>(): bool {
    type_name::get<A>() == type_name::get<B>()
  }
}