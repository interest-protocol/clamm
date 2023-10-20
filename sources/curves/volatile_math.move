module amm::volatile_math {
  
  use std::vector;

  use sui::math::pow;

  use suitears::math256::{diff, sum, max};
  use suitears::vectors::descending_insertion_sort;

  use amm::errors;

  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18
  const A_MULTIPLIER: u256 = 10000;
  const MIN_GAMMA: u256 = 10_000_000_000; // 10e6
  const MAX_GAMMA: u256 = 50_000_000_000_000_000; // 5e16

  public fun get_min_a(n_coins: u64): u256 {
    (pow(n_coins, (n_coins as u8)) as u256) * A_MULTIPLIER / 100
  }

  public fun get_max_a(n_coins: u64): u256 {
    (pow(n_coins, (n_coins as u8)) as u256) * A_MULTIPLIER * 1000      
  }

  public fun geometric_mean(unsorted: &vector<u256>, sort: bool): u256 {
    let x = if (sort) { descending_insertion_sort(unsorted) } else { *unsorted };

    let len = vector::length(&x);
    let d = *vector::borrow(&x, 0); 
    let i = 0;

    while (i < 255) {
      let prev_d = d;
      let temp = PRECISION;

      let j = 0;
      while (j < len) {
        temp = temp * (*vector::borrow(&x, j)) / d;  
        j = j + 1;
      };
      d = d * (((len as u256) - 1) * PRECISION + temp) / ((len as u256) * PRECISION);

      let diff = diff(d, prev_d);
      
      if (diff <= 1 || diff * PRECISION < d) return d;
      
      i = i + 1;
    };
    abort errors::failed_to_converge()
  }

  public fun reduction_coefficient(x: &vector<u256>, fee_gamma: u256): u256 {
    let s = sum(x);
    let n_coins = vector::length(x);

    let i = 0;
    let k = 0;
    while(i < n_coins) {
      k = k * (n_coins as u256) * *vector::borrow(x, i) / s;
      i = i + 1;
    };

    if (fee_gamma != 0) {
      fee_gamma * PRECISION / (fee_gamma + (PRECISION - k))
    } else {
      k
    }
  }

  public fun newton_d(ann: u256, gamma: u256, x_unsorted: &vector<u256>): u256 {
    let n_coins = vector::length(x_unsorted);
    assert!(ann > get_min_a(n_coins) - 1 && ann < get_max_a(n_coins) + 1, errors::invalid_amplifier());
    assert!(gamma > MIN_GAMMA - 1 && gamma < MAX_GAMMA + 1, errors::invalid_gamma());

    let x = descending_insertion_sort(x_unsorted);
    let fst = *vector::borrow(&x, 0);
    assert!(fst > 999999999 && fst < 1000000000000000 * PRECISION + 1, errors::unsafe_value());

    let i = 0;
    while (i < n_coins) {
      let frac = *vector::borrow(&x, (i as u64)) * PRECISION / fst;
      assert!(frac > 99999999999, errors::unsafe_value());
      i = i + 1;
    };

    let d = (n_coins as u256) * geometric_mean(&x, false);
    let s = sum(&x);

    let i = 0;
    while (i < 255) {
      i = i + 1;
      let d_prev = d;
      let k0 = PRECISION;

      let j = 0;
      while (j < n_coins) {
        k0 = k0 * *vector::borrow(&x, j) * (n_coins as u256) / d;
        j = j + 1;
      };

      let g1k0 = diff(gamma + PRECISION, k0) + 1;
      let mul1 = PRECISION * d / gamma * g1k0 / gamma * g1k0 * A_MULTIPLIER / ann;
      let mul2 = (2 * PRECISION) * (n_coins as u256) * k0 / g1k0;
      let neg_fprime = (s + s * mul2 / PRECISION) + mul1 * (n_coins as u256) / k0 - mul2 * d / PRECISION;
      let d_plus = d * (neg_fprime  + s) / neg_fprime;
      let d_minus = d * d / neg_fprime;
      
      if (PRECISION > k0) {
        d_minus = d_minus + d * (mul1 / neg_fprime) / PRECISION * (PRECISION - k0) / k0;
      } else {
        d_minus = d_minus - d * (mul1 / neg_fprime) / PRECISION * (k0 - PRECISION) / k0;
      };

      d = if (d_plus > d_minus) { d_plus - d_minus } else { (d_minus - d_plus) / 2 };
      let diff = diff(d, d_prev);

      if (diff * 100000000000000 < max(10000000000000000, d)) {
        let j = 0;
        while (j < n_coins) {
          let frac = *vector::borrow(&x, j) * PRECISION / d;
          assert!(frac > 10000000000000000 - 1 && frac < 100000000000000000001, errors::unsafe_value());
          j = j + 1;
        };
        return d
      };
    };
    abort errors::failed_to_converge()
  }

  public fun newton_y(ann: u256, gamma: u256, x: &vector<u256>, d: u256, i: u256): u256 {
    let n_coins = vector::length(x);
    
    assert!(ann > get_min_a(n_coins) - 1 && ann < get_max_a(n_coins) + 1, errors::invalid_amplifier());
    assert!(gamma > MIN_GAMMA - 1 && gamma < MAX_GAMMA + 1, errors::invalid_gamma());
    assert!(d > 100000000000000000 - 1 && d < 1000000000000000 * PRECISION + 1, errors::invalid_invariant());

    let j = 0;
    while (j < 3) {
      let frac = *vector::borrow(x, j) * PRECISION / d;
      assert!(frac > 10000000000000000 - 1 && frac < 100000000000000000001, errors::unsafe_value());
      j = j + 1;
    };

    let y = d / (n_coins as u256);
    let k0_i = PRECISION;
    let s_i = 0;

    let new_x = *x;
    *vector::borrow_mut(&mut new_x, (i as u64)) = 0;
    let x_sorted = descending_insertion_sort(&new_x);

    let converge_limit = max(max(*vector::borrow(&x_sorted, 0) / 100000000000000, d / 100000000000000), 100);

    j = 2;
    while (j < n_coins + 1) {
      let x = *vector::borrow(&x_sorted, n_coins - j);
      y = y * d / (x * (n_coins as u256));
      s_i = s_i + x;
      j = j + 1;
    };

    j = 0;
    while (j < n_coins - 1) {
      k0_i = k0_i * *vector::borrow(&x_sorted, j) * (n_coins as u256) / d;
      j = j + 1;
    };

    j = 0;
    while (j < 255) {
      let y_prev = y;
      let k0 = k0_i * y * (n_coins as u256) / d;
      let s = s_i + y;

      let g1k0 = diff(gamma + PRECISION, k0) + 1;
      let mul1 = PRECISION * d / gamma * g1k0 / gamma * g1k0 * A_MULTIPLIER / ann;
      let mul2 = PRECISION + (2 * PRECISION) * k0 / g1k0;

      let yfprime = PRECISION * y + s * mul2 + mul1;
      let dyfprime = d * mul2;
      if (yfprime < dyfprime) { y = y_prev / 2; continue } else { yfprime = yfprime - dyfprime; };

      let fprime = yfprime / y;

      let y_minus = mul1 / fprime;
      let y_plus = (yfprime + PRECISION * d) / fprime + y_minus * PRECISION / k0;
      y_minus = y_minus + PRECISION * s / fprime;

      if (y_plus < y_minus) { y = y_prev / 2; } else { y = y_plus - y_minus; };
      
      let diff = diff(y, y_prev);

      if (diff < max(converge_limit, y / 100000000000000)) {
        let frac = y * PRECISION / d;
        assert!(frac > 10000000000000000 - 1 && frac < 100000000000000000001, errors::unsafe_value());
        return y
      };
    };
    abort errors::failed_to_converge()
  }

  public fun half_pow(power: u256, precision: u256): u256 {
    let intpow = power / PRECISION;
    
    if (intpow > 59) return 0;

    let otherpow = power - intpow * PRECISION;
    let result = PRECISION / (pow(2, (intpow as u8)) as u256);
    
    if (otherpow == 0) return result;

    let x = 500000000000000000; // 0.5e17
    let term = PRECISION;
    let s = PRECISION;
    let neg = false;

    let i = 0;
    while (i < 256) {
      i = i + 1;

      let k = i * PRECISION;
      let c = k - PRECISION;
      if (otherpow > c) {
        c = otherpow - c;
        neg = !neg;
      } else {
        c = c - otherpow;
      };

      term = term * (c * x / PRECISION) / k;
      if (neg) { s = s - term; } else { s = s + term; };
      if (term < precision) return result * s
    };
    abort errors::failed_to_converge()
  }
}