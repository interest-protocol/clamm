/*
* @title Volatile Math. 
* @author @josemvcerqueira
* @notice It contain utility functions to calculate the volatile invariant and pool balance changes.
*/
module clamm::volatile_math {
  // === Imports ===

  use sui::math::pow;
  use suitears::math256::{diff, sum, max};
  use suitears::vectors::descending_insertion_sort;

  use clamm::utils;
  use clamm::errors;

  use fun pow as u64.pow;
  use fun sum as vector.sum; 
  use fun utils::to_u8 as u64.to_u8;
  use fun utils::head as vector.head;
  use fun utils::to_u256 as u64.to_u256;

  // === Constants ===

  const A_MULTIPLIER: u256 = 10_000; // 1e4
  const MIN_GAMMA: u256 = 10_000_000_000; // 10e10
  const MAX_GAMMA: u256 = 50_000_000_000_000_000; // 5e16
  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18 
  
  // Constants for powers of 10
  const POW_10_9: u256 = 1_000_000_000; // 1e9
  const POW_10_11: u256 = 100_000_000_000; // 1e11
  const POW_10_14: u256 = 100_000_000_000_000; // 1e14 
  const POW_10_15: u256 = 1_000_000_000_000_000; // 1e15 
  const POW_10_16: u256 = 10_000_000_000_000_000; // 1e16 
  const POW_10_17: u256 = 100_000_000_000_000_000; // 1e17
  const POW_10_20: u256 = 100_000_000_000_000_000_000; // 1e20

  // === Public-View Functions ===
  
  /*
  * @notice It calculates the minimum amplifier value based on the number of coins in the pool.  
  *
  * @n_coins The number of coins in the pool 
  * @return u256 The minimum amplifier value
  */
  public fun min_a(n_coins: u64): u256 {
    n_coins.pow(n_coins.to_u8()).to_u256() * A_MULTIPLIER / 100
  }

  /*
  * @notice It calculates the maximum amplifier value based on the number of coins in the pool.  
  *
  * @n_coins The number of coins in the pool 
  * @return u256 The maximum amplifier value
  */
  public fun max_a(n_coins: u64): u256 {
    n_coins.pow(n_coins.to_u8()).to_u256() * A_MULTIPLIER * 1000    
  }

  /*
  * @notice It calculates the geometric mean of all the balances in the pool 
  *
  * @dev The `unsorted_balances` have been normalized to a fixed-point value with a precision of 1e18. 
  * @dev The `unsorted_balances` are the coin balances * their prices in Coin at index 0 in the pool. 
  *
  * @param unsorted_balances The balances in the pool. 
  * @param sort If we should sort before calculating the geometric mean 
  * @return u256 The geometric mean of `balances`
  */
  public fun geometric_mean(unsorted_balances: vector<u256>, sort: bool): u256 {
    let balances = if (sort) descending_insertion_sort(unsorted_balances) else unsorted_balances;

    let len = balances.length();
    let mut d = balances.head(); 
    let mut prev_d = 0;

    while (diff(prev_d, d) > 1 && diff(prev_d, d) * PRECISION >= d) {
      prev_d = d;
      let mut temp = PRECISION;

      let mut i = 0;
      while (len > i) {
        temp = temp * *&balances[i] / d;  
        i = i + 1;
      };
      d = d * ((len.to_u256() - 1) * PRECISION + temp) / (len.to_u256() * PRECISION);
    };
    d
  }

  /*
  * @notice It calculates the geometric mean of all the balances in the pool 
  *
  * @dev The `unsorted_balances` have been normalized to a fixed-point value with a precision of 1e18. 
  * @dev The `unsorted_balances` are the coin balances * their prices in Coin at index 0 in the pool. 
  *
  * @param unsorted_balances The balances in the pool. 
  * @param sort If we should sort before calculating the geometric mean 
  * @return u256 The geometric mean of `balances`
  */
  public fun reduction_coefficient(x: vector<u256>, fee_gamma: u256): u256 {
    let s = x.sum();
    let n_coins = x.length();

    let mut i = 0;
    let mut k = PRECISION;

    while(i < n_coins) {
      k = k * n_coins.to_u256() * *&x[i] / s;
      i = i + 1;
    };

    if (fee_gamma != 0)
      fee_gamma * PRECISION / (fee_gamma + PRECISION - k)
    else
      k
  }

  /*
  * @notice It calculates the invariant of the pool. 
  *
  * @dev The `unsorted_balances` have been normalized to a fixed-point value with a precision of 1e18. 
  * @dev The `unsorted_balances` are the coin balances * their prices in Coin at index 0 in the pool. 
  *
  * @param ann The amplifier value. 
  * @param gamma The gamma value. 
  * @param unsorted_balances The balances in the pool. 
  * @return u256 The invariant of the pool
  */
  public fun invariant_(ann: u256, gamma: u256, unsorted_balances: vector<u256>): u256 {
    let n_coins = unsorted_balances.length();
    
    assert_ann_is_within_range(ann, n_coins);
    assert_gamma_is_within_range(gamma);

    let x = descending_insertion_sort(unsorted_balances);
    let fst = x.head();

    assert!(fst >= POW_10_9 && fst <= POW_10_15 * PRECISION, errors::unsafe_value());

    let n_coins_u256 = n_coins.to_u256();

    let mut i = 1;
    while (n_coins > i) {
      let frac = *&x[i] * PRECISION / fst;
      assert!(frac >= POW_10_11, errors::unsafe_value());
      i = i + 1;
    };

    let mut d = n_coins_u256 * geometric_mean(x, false);
    let s = x.sum();
    let mut d_prev = 0;

    while (diff(d, d_prev) * POW_10_14 >= max(POW_10_16, d)) {
      d_prev = d;
      let mut k0 = PRECISION;

      let mut i = 0;
      while (i < n_coins) {
        k0 = k0 * *&x[i] * n_coins_u256 / d;
        i = i + 1;
      };

      let g1k0 = diff(gamma + PRECISION, k0) + 1;

      let mul1 = PRECISION * d / gamma * g1k0 / gamma * g1k0 * A_MULTIPLIER / ann;

      let mul2 = (2 * PRECISION) * n_coins_u256 * k0 / g1k0;
      
      let neg_fprime = (s + s * mul2 / PRECISION) + mul1 * n_coins_u256 / k0 - mul2 * d / PRECISION;

      let d_plus = d * (neg_fprime  + s) / neg_fprime;
      let mut d_minus = d * d / neg_fprime;
      
      d_minus = if (PRECISION > k0)
        d_minus + d * (mul1 / neg_fprime) / PRECISION * (PRECISION - k0) / k0
      else
        d_minus - d * (mul1 / neg_fprime) / PRECISION * (k0 - PRECISION) / k0;

      d = if (d_plus > d_minus) d_plus - d_minus else (d_minus - d_plus) / 2;
    };
    
    let mut i = 0;
    while (n_coins > i) {
      let frac = *&x[i] * PRECISION / d;
      assert_balance_is_within_range(frac);
      i = i + 1;
    };

    d
  }

  /*
  * @notice It calculates the invariant of the pool. 
  *
  * @dev The `balances` have been normalized to a fixed-point value with a precision of 1e18. 
  * @dev The `balances` are the coin balances * their prices in Coin at index 0 in the pool. 
  *
  * @param ann The amplifier value. 
  * @param gamma The gamma value. 
  * @param balances The balances in the pool. 
  * @param d The invariant of the pool  
  * @return u256 The new balance for the Coin at `coin_out_index`. 
  */
  public fun y(ann: u256, gamma: u256, balances: &vector<u256>, d: u256, coin_out_index: u64): u256 {
    let n_coins = balances.length();
    
    assert_ann_is_within_range(ann, n_coins);
    assert_gamma_is_within_range(gamma);

    assert!(d >= POW_10_17 && d <= POW_10_15 * PRECISION, errors::invalid_invariant());

    let mut j = 0;
    while (n_coins > j) {
      if (j != coin_out_index) {
        let frac = *&balances[j] * PRECISION / d;
        assert_balance_is_within_range(frac);
      };
      j = j + 1;
    };

    let n_coins_u256 = n_coins.to_u256();
    let mut y = d / n_coins_u256;
    let mut k0_i = PRECISION;
    let mut s_i = 0;

    let mut new_x = *balances;
    *&mut new_x[coin_out_index] = 0;
    let x_sorted = descending_insertion_sort(new_x);

    let converge_limit = max(max(x_sorted.head() / POW_10_14, d / POW_10_14), 100);

    let mut j = 2;
    while (j < n_coins + 1) {
      let x = *&x_sorted[n_coins - j];
      y = y * d / (x * n_coins_u256);
      s_i = s_i + x;
      j = j + 1;
    };

    let mut j = 0;
    while (j < n_coins - 1) {
      k0_i = k0_i * *&x_sorted[j] * n_coins_u256 / d;
      j = j + 1;
    };

    let mut y_prev = 0;

    while(diff(y, y_prev) >= max(converge_limit, y / POW_10_14)) {
      y_prev = y;

      let k0 = k0_i * y * n_coins_u256 / d;
      
      let s = s_i + y;

      let g1k0 = diff(gamma + PRECISION, k0) + 1;

      let mul1 = PRECISION * d / gamma * g1k0 / gamma * g1k0 * A_MULTIPLIER / ann;
      
      let mul2 = PRECISION + (2 * PRECISION) * k0 / g1k0;

      let mut yfprime = PRECISION * y + s * mul2 + mul1;

      let dyfprime = d * mul2;
      
      if (yfprime < dyfprime) { y = y_prev / 2; continue } else { yfprime = yfprime - dyfprime; };

      let fprime = yfprime / y;

      let mut y_minus = mul1 / fprime;
      
      let y_plus = (yfprime + PRECISION * d) / fprime + y_minus * PRECISION / k0;
      y_minus = y_minus + PRECISION * s / fprime;

      y = if (y_plus < y_minus) y_prev / 2 else y_plus - y_minus;
    };
    
    let frac = y * PRECISION / d;
    assert_balance_is_within_range(frac);

    y
  }

  /*
  * @notice It calculates the half power for number `power`. 
  *
  * @param power The initial value.  
  * @param precision The maximum return value  
  * @return u256 the half power of `power`
  */
  public fun half_pow(power: u256, precision: u256): u256 {
    let intpow = power / PRECISION;
    
    if (intpow > 59) return 0;

    let otherpow = power - intpow * PRECISION;
    let result = PRECISION / pow(2, (intpow as u8)).to_u256();
    
    if (otherpow == 0) return result;

    let x = 500000000000000000; // 0.5e17
    let mut term = PRECISION;
    let mut s = PRECISION;
    let mut neg = false;

    let mut i = 1;
    while (i < 256) {
      let k = i * PRECISION;
      let mut c = k - PRECISION;
      if (otherpow > c) {
        c = otherpow - c;
        neg = !neg;
      } else {
        c = c - otherpow;
      };

      term = term * (c * x / PRECISION) / k;
      s = if (neg) s - term else s + term;
      if (term < precision) return result * s / PRECISION;

      i = i + 1;
    };
    abort errors::failed_to_converge()
  }

  /*
  * @notice It calculates the square root of `x`. 
  *
  * @param x The initial value.  
  * @return u256 the square root of `x`
  */
  public fun sqrt(x: u256): u256 {
    if (x == 0) return 0;

    let mut z = (x + PRECISION) / 2;
    let mut y = x;

    while (z != y) {
      y = z;
      z = (x * PRECISION / z + z) / 2;
    };

    y
  }

  // === Private Assert Functions ===

  /*
  * @notice It assers that the amplifier is within a valid range. 
  *
  * @param ann The amplifier.  
  * @param n_coins The number of coins in the pool. 
  */
  fun assert_ann_is_within_range(ann: u256, n_coins: u64) {
    assert!(ann >= min_a(n_coins) && ann <= max_a(n_coins), errors::invalid_amplifier());
  }

  /*
  * @notice It assers that gamma is within a valid range. 
  *
  * @param gamma The gamma.  
  */
  fun assert_gamma_is_within_range(gamma: u256) {
    assert!(gamma >= MIN_GAMMA && gamma <= MAX_GAMMA, errors::invalid_gamma());    
  }

  /*
  * @notice It assers that a Coin balance is within a valid range. 
  *
  * @param balance The balance. 
  */
  fun assert_balance_is_within_range(balance: u256) {
    assert!(balance >= POW_10_16 && balance <= POW_10_20, errors::unsafe_value());
  }
}

