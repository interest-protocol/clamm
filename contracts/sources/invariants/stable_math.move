/*
* @title Stable Math. 
* @author @josemvcerqueira
* @notice It contain utility functions to calculate the stable invariant and pool balance changes.
*/
module clamm::stable_math {
  // === Imports === 
  
  use std::vector;

  use sui::clock::{Self, Clock};  

  use clamm::errors;

  use suitears::math256::{diff, sum};

  // === Public-View Functions ===

  /*
  * @notice It calculates the amplifier for the Stable invariant. A higher `A` makes the bonding curve more linear. 
  * @dev The `A` needs to be updated over time to avoid impermanent loss as it flattens the bonding curve.  
  * @param a0 The amplifier at the initial time. 
  * @param t0 The initial timestamp.  
  * @param a1 The amplifier at the final time.  
  * @param t1 The final timestamp.  
  * @return u256 The current `A` value. 
  */
  public fun a(
    a0: u256,
    t0: u256,
    a1: u256,
    t1: u256, 
    clock_object: &Clock
  ): u256 {
    let current_timestamp = (clock::timestamp_ms(clock_object) as u256);

    if (current_timestamp >= t1) return a1;

    if (a1 > a0) 
      a0 + (a1 - a0) * (current_timestamp - t0) / (t1 - t0) 
    else 
      a0 - (a0 - a1) * (current_timestamp - t0) / (t1 - t0)
  }

  /*
  * @notice It calculates the stable invariant. 
  * @dev The `balances` have been normalized to a fixed-point value with a precision of 1e18. 
  * @param amp The current amplifier value.   
  * @param balances All coin balances in the pool. 
  * @return u256 The current invariant 
  */
  public fun invariant_(amp: u256, balances: vector<u256>): u256 {
    let s = sum(balances);
    if (s == 0) return 0;
    
    let n_coins = vector::length(&balances);
    let n_coins_u256 = (n_coins as u256);

    let _prev_d = 0;
    let d = s;
    let ann = amp * n_coins_u256;

    let i = 0;
    while(255 > i) {
      let d_p = d;

      let j = 0;
      while(j < n_coins) {
        d_p = d_p * d / (*vector::borrow(&balances, j) * n_coins_u256);
        j = j + 1;
      };

      _prev_d = d; 
      d = (ann * s + d_p * n_coins_u256) * d / ((ann -1) * d + (n_coins_u256 + 1) * d_p);

      if (1 >= diff(d, _prev_d)) return d;

      i = i + 1;
    };

    d
  }

  /*
  * @notice It calculates the new balance for the Coin at `coin_out_index` from a new balance of Coin at `coin_in_index`. 
  * @dev `balances` and `new_balance_in` have been normalized to a fixed-point value with a precision of 1e18. 
  * @param amp The current amplifier value.   
  * @param coin_in_index The index of the Coin `new_balance_in` being added to `balances`. 
  * @param coin_out_index The index of the Coin we wish to remove from `balances`. 
  * @param new_balance_in The new balance for the Coin at `coin_in_index`. 
  * @param balances All coin balances in the pool. 
  * @return u256 The current invariant 
  */
  public fun y(
    amp: u256, 
    coin_in_index: u256, 
    coin_out_index: u256,
    new_balance_in: u256, 
    balances: vector<u256>
  ): u256 {
    assert!(coin_in_index != coin_out_index, errors::same_coin_index());

    let d = invariant_(amp, balances);
    let c = d;
    let s = 0;
    let n_coins = (vector::length(&balances) as u256);
    let ann = amp * n_coins;

    let i = 0;

    while (n_coins > i) {
      if (i == coin_in_index) {
        s = s + new_balance_in;
        c = c * d / (new_balance_in * n_coins);
      } else if (i != coin_out_index) {
        let x = *vector::borrow(&balances, (i as u64));
        s = s + x;
        c = c * d / (x * n_coins);
      };

      i = i + 1;
    };

    c = c * d / (ann * n_coins);
    let b = s + d / ann;
    let y = d;
    let _prev_y = 0;

    let i = 0;

    while(255 > i) {
      _prev_y = y;
      y = (y * y + c) / (2 * y + b - d);

      if (1 >= diff(y, _prev_y)) return y;

      i = i + 1;
    };

    y
  }

  /*
  * @notice It calculates the new balance for the Coin at `coin_index` when removing liquidity. 
  * @dev `balances` have been normalized to a fixed-point value with a precision of 1e18. 
  * @param amp The current amplifier value.   
  * @param coin_index The index of the Coin balance that needs to be updated. 
  * @param balances All coin balances in the pool. 
  * @param lp_burn_amount The value f LpCoin being burned
  * @param lp_supply_value The current Lp Coin supply before burning `lp_burn_amount`. 
  * @return u256 The new balance for Coin at index `coin_index`. 
  */
  public fun y_lp(
    amp: u256, 
    coin_index: u256, 
    balances: vector<u256>, 
    lp_burn_amount: u256,
    lp_supply_value: u256,
  ): u256 {
    let prev_invariant = invariant_(amp, balances);
    y_d(
      amp,
      coin_index,
      balances,
      prev_invariant - lp_burn_amount * prev_invariant / lp_supply_value
    )
  }

  /*
  * @notice It calculates the new balance for the Coin at `coin_index` when the invariant changes. 
  * @dev `balances` have been normalized to a fixed-point value with a precision of 1e18. 
  * @param amp The current amplifier value.   
  * @param coin_index The index of the Coin balance that needs to be updated. 
  * @param balances All coin balances in the pool. 
  * @param _invariant The new invariant of the pool. 
  * @return u256 The new balance for Coin at index `coin_index`. 
  */
  public fun y_d(amp: u256, coin_index: u256, balances: vector<u256>, _invariant: u256): u256 {
    let c = _invariant;
    let s = 0;
    let n_coins = (vector::length(&balances) as u256);
    let ann = amp * n_coins;

    let i = 0;

    while (n_coins > i) {
      if (i != coin_index) {
        let x = *vector::borrow(&balances, (i as u64));
        s = s + x;
        c = c * _invariant / (x * n_coins);
      };
      i = i + 1;
    };

    c = c * _invariant / (ann * n_coins);
    let b = s + _invariant / ann;
    let y = _invariant;
    let _prev_y = 0;

    let i = 0;
    while (255 > i) {
      _prev_y = y;
      y = (y * y + c) / (2 * y + b - _invariant);

      if (1 >= diff(y, _prev_y)) return y;
    };
    y
  }
}