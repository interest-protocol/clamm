// * All values in this contract are scaled to 1e18 for precision
module amm::stable_tuple_math {

  use std::vector;

  use sui::clock::{Self, Clock};  

  use amm::errors;

  use suitears::math256::{diff, sum};

  public fun get_amp(
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

  public fun invariant_(amp: u256, balances: &vector<u256>): u256 {
    let s = sum(balances);
    let n_coins = vector::length(balances);
    let n_coins_u256 = (n_coins as u256);

    if (s == 0) return 0;

    let d = s;
    let ann = amp * n_coins_u256;
    
    let i = 0;

    while(i < 255) {
      let d_p = d;
      let index = 0;

      while(index < n_coins) {
        d_p = d_p * d / (*vector::borrow(balances, index) * n_coins_u256);
        index = index + 1;
      };

      let prev_d = d; 
      d = (ann * s + d_p * n_coins_u256) * d / ((ann -1) * d + (n_coins_u256 + 1) * d_p);

      if (diff(d, prev_d) <= 1) return d;
 
      i = i + 1;
    };

    abort errors::failed_to_converge()
  }

  public fun calculate_amount_in(amp: u256, token_in_index: u256, token_out_index: u256, token_amount_out: u256, balances: &vector<u256>): u256 {
    assert!(token_in_index != token_out_index, errors::same_coin_index());

    let d = invariant_(amp, balances);
    let c = d;
    let s = 0;
    let n_coins = (vector::length(balances) as u256);
    let ann = amp * n_coins;

    let _x = 0;
    let index = 0;

    while (index < n_coins) {
      if (index == token_in_index) {
        _x = token_amount_out;
        s = s + _x;
        c = c * d / (_x * n_coins);
      } else if (index != token_out_index) {
        _x = *vector::borrow(balances, (index as u64));
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

      if (diff(y, prev_y) <= 1) return y;

      index = index + 1;
    };

    abort errors::failed_to_converge()
  }

  public fun calculate_new_coin_balance(
    amp: u256, 
    i: u256, 
    balances: &vector<u256>, 
    lp_burn_amount: u256,
    lp_supply_value: u256,
  ): u256 {
    let prev_invariant = invariant_(amp, balances);
    let new_invariant = prev_invariant - ((lp_burn_amount * prev_invariant) / lp_supply_value);


    calculate_new_coin_balance_logic(
      amp,
      i,
      balances,
      new_invariant
    )
  }

  fun calculate_new_coin_balance_logic(amp: u256, i: u256, balances: &vector<u256>, _invariant: u256): u256 {

    let c = 0;
    let s = 0;
    let n_coins = (vector::length(balances) as u256);
    let ann = amp * n_coins;
    let _x = 0;

    let index = 0;

    while (index < n_coins) {
      if (index != i) {
        _x = *vector::borrow(balances, (index as u64));
        s = s + _x;
        c = c * _invariant / (_x * n_coins);
      };
      index = index + 1;
    };

    c = c * _invariant / (ann * n_coins);
    let b = s + _invariant / ann;
    let y = _invariant;

    let index = 0;

    while (index < 255) {
      let prev_y = y;
      y = (y * y + c) / (2 * y + b - _invariant);

      if (diff(y, prev_y) <= 1) return y;

      index = index + 1;
    };

    abort errors::failed_to_converge()
  }
}