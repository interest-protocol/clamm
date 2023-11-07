// * All values in this contract are scaled to 1e18 for precision
module amm::stable_tuple_math {

  use std::vector;

  use sui::clock::{Self, Clock};  

  use amm::errors;

  use suitears::math256::{diff, sum};

  public fun get_a(
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

  public fun invariant_(amp: u256, balances: &vector<u256>): u256 {
    let s = sum(balances);
    if (s == 0) return 0;
    
    let n_coins = vector::length(balances);
    let n_coins_u256 = (n_coins as u256);

    let prev_d = 0;
    let d = s;
    let ann = amp * n_coins_u256;
  
    while(diff(d, prev_d) > 1) {
      let d_p = d;
      let index = 0;

      while(index < n_coins) {
        d_p = d_p * d / (*vector::borrow(balances, index) * n_coins_u256);
        index = index + 1;
      };

      prev_d = d; 
      d = (ann * s + d_p * n_coins_u256) * d / ((ann -1) * d + (n_coins_u256 + 1) * d_p);
    };

    d
  }

  public fun y(
    amp: u256, 
    token_in_index: u256, 
    token_out_index: u256,
    new_balance_in: u256, 
    balances: &vector<u256>
  ): u256 {
    assert!(token_in_index != token_out_index, errors::same_coin_index());

    let d = invariant_(amp, balances);
    let c = d;
    let s = 0;
    let n_coins = (vector::length(balances) as u256);
    let ann = amp * n_coins;

    let index = 0;

    while (n_coins > index) {
      if (index == token_in_index) {
        s = s + new_balance_in;
        c = c * d / (new_balance_in * n_coins);
      } else if (index != token_out_index) {
        let x = *vector::borrow(balances, (index as u64));
        s = s + x;
        c = c * d / (x * n_coins);
      };

      index = index + 1;
    };

    c = c * d / (ann * n_coins);
    let b = s + d / ann;
    let y = d;
    let prev_y = 0;

    while(diff(y, prev_y) > 1) {
      prev_y = y;
      y = (y * y + c) / (2 * y + b - d);
    };

    y
  }

  public fun y_lp(
    amp: u256, 
    i: u256, 
    balances: &vector<u256>, 
    lp_burn_amount: u256,
    lp_supply_value: u256,
  ): u256 {
    let prev_invariant = invariant_(amp, balances);
    y_d(
      amp,
      i,
      balances,
      prev_invariant - lp_burn_amount * prev_invariant / lp_supply_value
    )
  }

  public fun y_d(amp: u256, i: u256, balances: &vector<u256>, _invariant: u256): u256 {
    let c = _invariant;
    let s = 0;
    let n_coins = (vector::length(balances) as u256);
    let ann = amp * n_coins;

    let index = 0;

    while (n_coins > index) {
      if (index != i) {
        let x = *vector::borrow(balances, (index as u64));
        s = s + x;
        c = c * _invariant / (x * n_coins);
      };
      index = index + 1;
    };

    c = c * _invariant / (ann * n_coins);
    let b = s + _invariant / ann;
    let y = _invariant;
    let prev_y = 0;

    while (diff(y, prev_y) > 1) {
      prev_y = y;
      y = (y * y + c) / (2 * y + b - _invariant);
    };
    y
  }
}