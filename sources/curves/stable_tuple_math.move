module amm::stable_tuple_math {
  use std::vector;

  use sui::clock::{Self, Clock};  

  use amm::errors;

  public fun get_a(
    a0: u256,
    t0: u256,
    a1: u256,
    t1: u256, 
    clock_object: &Clock
  ): u256 {
    let current_timestamp = (clock::timestamp_ms(clock_object) as u256);

    if (current_timestamp >= t1) return a1;


    if (a1 > a0) { a0 + (a1 - a0) } else { a0 - (a0 - a1) }  * (current_timestamp - t0) / (t1 - t0)
  }

  public fun get_d(xp: &vector<u256>, amp: u256): u256 {
    let s = 0;
    let i = 0;
    let n_coins = vector::length(xp);
    let n_coins_u256 = (n_coins as u256);

    while (i < n_coins) {
      s = s + *vector::borrow(xp, i);
      i = i + 1;
    };

    if (s == 0) return 0;

    let d = s;
    let ann = amp * n_coins_u256;
    
    let i = 0;

    while(i < 255) {
      let d_p = d;
      let index = 0;

      while(index < n_coins) {
        d_p = d_p * d / (*vector::borrow(xp, index) * n_coins_u256);
        index = index + 1;
      };

      let prev_d = d; 
      d = (ann * s + d_p * n_coins_u256) * d / ((ann -1) * d + (n_coins_u256+ 1) * d_p);

      if (d > prev_d) {
        if (d - prev_d <= 1) break;
      } else {
        if (prev_d - d <= 1) break;
      };
      i = i + 1;
    };

    d
  }

  public fun get_y(amp: u256, i: u256, j: u256, x: u256, xp: &vector<u256>): u256 {
    assert!(i != j, errors::same_coin_index());

    let d = get_d(xp, amp);
    let c = d;
    let s = 0;
    let n_coins = (vector::length(xp) as u256);
    let ann = amp * n_coins;

    let _x = 0;
    let index = 0;

    while (index < n_coins) {
      if (index == i) {
        _x = x;
        s = s + _x;
        c = c * d / (_x * n_coins);
      } else if (index != j) {
        _x = *vector::borrow(xp, (index as u64));
        s = s + _x;
        c = c * d / (_x * n_coins);
      };

      index = index + 1;
    };

    c = c * d / (ann * n_coins);
    let b = s + d / ann;
    let y = d;

    let index = 0;

    while (index < 255) {
      let prev_y = y;
      y = (y * y + c) / (2 * y + b - d);

      if (y > prev_y) {
        if (y - prev_y <= 1) break;
      };

      if (prev_y - y <= 1) break;

      index = index + 1;
    };

    y
  }

  public fun get_y_d(a: u256, i: u256, xp: &vector<u256>, d: u256): u256 {

    let c = 0;
    let s = 0;
    let n_coins = (vector::length(xp) as u256);
    let ann = a * n_coins;
    let _x = 0;

    let index = 0;

    while (index < n_coins) {
      if (index != i) {
        _x = *vector::borrow(xp, (index as u64));
        s = s + _x;
        c = c * d / (_x * n_coins);
      };
      index = index + 1;
    };

    c = c * d / (ann * n_coins);
    let b = s + d / ann;
    let y = d;

    let index = 0;

    while (index < 255) {
      let prev_y = y;
      y = (y * y + c) / (2 * y + b - d);

      if (y > prev_y) {
        if (y - prev_y <= 1) break;
      };

      if (prev_y - y <= 1) break;

      index = index + 1;
    };

    y
  }

}