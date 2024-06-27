#[test_only]
module clamm::stable_simulation {

  use suitears::math256::mul_div_up;

  use sui::transfer::share_object;

  use clamm::stable_math::{
    y_lp,
    y as get_y,
    y_d as get_y_d,
    invariant_
  };

  const PRECISION: u256 = 1_000_000_000_000_000_000;
  const INITIAL_FEE_PERCENT: u256 = 500000000000000; // 0.05%
  const MAX_ADMIN_FEE: u256 = 200000000000000000; // 20%  

  public struct State has key {
    id: UID,
    a: u256,
    n: u64,
    fee: u256,
    admin_fee: u256,
    xp: vector<u256>,
    lp_supply: u256
  }

  #[allow(unused_function)]
  fun init(ctx: &mut TxContext) {
    share_object(
      State {
        id: object::new(ctx),
        a: 0,
        n: 0,
        fee: INITIAL_FEE_PERCENT,
        admin_fee: MAX_ADMIN_FEE,
        xp: vector[],
        lp_supply: 0
      }
    );
  }

  public fun set_state(
    state: &mut State,
    a: u256,
    n: u64,      
    xp: vector<u256>,
    lp_supply: u256    
  ) {
    state.a = a;
    state.n = n;
    state.xp = xp;
    state.lp_supply = lp_supply;
  }

  public fun d(state: &State): u256 {
    invariant_(state.a, state.xp)
  }

  public fun y(state: &State, i: u64, j: u64, x: u256): u256 {
    get_y(state.a, (i as u256), (j as u256), x, state.xp)
  }

  public fun y_d(state: &State, i: u64, d: u256): u256 {
    get_y_d(state.a, (i as u256), state.xp, d)
  }

  public fun dy(state: &State, i: u64, j: u64, dx: u256): u256 {
    *vector::borrow(&state.xp, j) - y(state, i, j, *vector::borrow(&state.xp, i) + dx)
  }

  public fun set_admin_fee(state: &mut State, fee: u256) {
    state.admin_fee = fee;
  }

  public fun xp(state: &State): vector<u256> {
    state.xp
  }

  public fun swap(state: &mut State, i: u64, j: u64, dx: u256): (u256, u256) {
    let dx = dx;
    let x = *vector::borrow(&state.xp, i) + dx;
    let y = y(state, i, j, x);
    let dy = *vector::borrow(&state.xp, j) - y;
    let fee = mul_div_up(dy, state.fee, PRECISION);
    let admin_fee = mul_div_up(fee, state.admin_fee, PRECISION);
    assert!(dy != 0, 0);

    let x_i_ref = vector::borrow_mut(&mut state.xp, i);
    *x_i_ref = x;

    let x_j_ref = vector::borrow_mut(&mut state.xp, j);
    *x_j_ref = y + fee - admin_fee;

    (dy, fee)
  }   

  public fun calc_withdraw_one_coin(state: &State, amp: u256, token_amount: u256, i: u64): (u256, u256) {
    let _xp = state.xp;
    let d0 = invariant_(amp, _xp);
    let d1 = d0 - (token_amount * d0) / state.lp_supply;

    let mut xp_reduced = _xp;
    let init_b = _xp[0];

    let n_coins = state.n;
    let fee = state.fee * (n_coins as u256) / (4 * ((n_coins - 1) as u256));
    let dy0 = y_lp(amp, (i as u256), _xp, token_amount, state.lp_supply) + 1;

    let mut j = 0;

    while(n_coins > j) {
      let coin_balance = if (j == (i as u64))
        _xp[j] * d1 / d0 - dy0
      else 
        _xp[j] - _xp[j] * d1 / d0;

      *&mut xp_reduced[j] = xp_reduced[j] - (fee * coin_balance / PRECISION);

      j = j + 1;      
    };

    let dy1 = get_y_d(amp, (i as u256), xp_reduced, d1);

    let amount_to_take = (xp_reduced[i] - dy1);
    let amount_to_take_without_fees = (init_b - dy0);

    let fee = amount_to_take_without_fees - amount_to_take;
    let admin_fee = fee * state.admin_fee / PRECISION;

    (amount_to_take, admin_fee)
  } 

  public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
  }

  public fun view_state(state: &State): (vector<u256>, u256, u64, u256, u256) {
    (state.xp, state.a, state.n, state.fee, state.lp_supply)
  }
}