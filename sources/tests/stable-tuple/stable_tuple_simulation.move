#[test_only]
module amm::stable_tuple_simulation {
  use std::vector;

  use suitears::math256::{sum, diff};
  use suitears::fixed_point_wad::{wad_mul_down as fmul, wad_div_down as fdiv};

  use sui::math;
  use amm::utils;
  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;
  use sui::transfer::share_object;

  const FEE_PRECISION: u256 = 10000000000;

  struct State has key {
    id: UID,
    a: u256,
    n: u64,
    fee: u256,
    p: vector<u256>,
    x: vector<u256>,
    tokens: u256
  }

  #[allow(unused_function)]
  fun init(ctx: &mut TxContext) {
    share_object(
      State {
        id: object::new(ctx),
        a: 0,
        n: 0,
        fee: 100000000,
        p: vector[],
        x: vector[],
        tokens: 0
      }
    );
  }

  public fun set_state(
    state: &mut State,
    a: u256,
    n: u64,      
    x: vector<u256>,
    p: vector<u256>,
    tokens: u256    
  ) {
    state.a = a;
    state.n = n;
    state.p = p;
    state.x = x;
    state.tokens = tokens;
  }

  public fun xp(state: &State): vector<u256> {
    let i = 0;
    let data = vector[];
    while(state.n > i) {
      let _x = *vector::borrow(&state.x, i);
      let _p = *vector::borrow(&state.p, i);
      vector::push_back(&mut data, fmul(_x, _p));
      i = i + 1;
    };

    data
  }

  public fun d(state: &State): u256 {
    let d_prev = 0;
    let _xp = xp(state);
    let s = sum(&_xp);
    let d = s;
    let ann = state.a * (state.n as u256);

    while (diff(d, d_prev) > 1) {
      let d_p = d;

      let i = 0;
      while (state.n > i) {
        d_p = d_p * d / ((state.n as u256) * *vector::borrow(&_xp, i));
        i = i + 1;
      };

      d_prev = d;
      d = (ann * s + d_p * (state.n as u256)) * d / ((ann - 1) * d + ((state.n as u256) + 1) * d_p);
    };

    d
  }

  public fun y(state: &State, i: u64, j: u64, x: u256): u256 {
    let _d = d(state);
    let xx = xp(state);
    let xx_fst_ref = vector::borrow_mut(&mut xx, i);
    *xx_fst_ref = x;
    vector::remove(&mut xx, j);
    let n_u256 = (state.n as u256);
    let ann = state.a * (n_u256);
    let c = _d;
    let xx_len = vector::length(&xx);
    {
      let i = 0;
      while (xx_len > i) {
        c = (c * _d) / ((i as u256) * n_u256);
        i = i + 1;
      };
    };

    c = (c * _d) / (n_u256 * ann);
    let b = sum(&xx) + _d;
    let y_prev = 0;
    let y = _d;
    while (diff(y, y_prev) > 1) {
      y_prev = y;
      y = (pow(y, 2) + c) / (2 * y + b); 
    };
    y
  }

  public fun y_d(state: &State, i: u64, _d: u256): u256 {
    let xx = xp(state);
    vector::remove(&mut xx, i);
    let s = sum(&xx);
    let n_u256 = (state.n as u256);
    let ann = state.a * n_u256;
    let c = _d;
    
    {
      let len = vector::length(&xx);
      let i = 0;
      while (len > i) {
        c = (c * _d) / ((i as u256) * n_u256);
        i = i + 1;
      }
    };

    c = (c * _d) / (n_u256 * ann);
    let b = s + _d / ann;
    let y_prev = 0;
    let y = _d;

    while (diff(y, y_prev) > 1) {
      y_prev = y;
      y = (pow(y, 2) + c) / (2 * y + b - _d);
    };

    y
  }

  public fun dy(state: &State, i: u64, j: u64, dx: u256): u256 {
    let _xp = xp(state);
    *vector::borrow(&_xp, j) - y(state, i, j, *vector::borrow(&_xp, i) + dx)
  }

  public fun exchange(state: &mut State, i: u64, j: u64, dx: u256): u256 {
    let _xp = xp(state);
    let x = *vector::borrow(&_xp, i) + dx;
    let y = y(state, i, j, x);
    let dy = *vector::borrow(&_xp, j) - y;
    let fee = (dy * state.fee) / FEE_PRECISION;
    assert!(dy != 0, 0);

    let x_i_ref = vector::borrow_mut(&mut state.x, i);
    *x_i_ref = fdiv(x, *vector::borrow(&state.p, i));

    let x_j_ref = vector::borrow_mut(&mut state.x, j);
    *x_j_ref = fdiv(y + fee, *vector::borrow(&state.p, j));

    dy - fee
  }   

  public fun remove_liquidity_imabalance(state: &mut State, amounts: vector<u256>): u256 {
    let n_u256 = (state.n as u256);
    let _fee = (state.fee * n_u256) / (4 * (n_u256 - 1));

    let old_balances = state.x;
    let new_balances = state.x;
    let d0 = d(state);

    {
      let len = vector::length(&new_balances);
      let i = 0;
      while (len > i) {
        let ref = vector::borrow_mut(&mut new_balances, i);
        *ref = *ref - *vector::borrow(&amounts, i);
        i = i + 1;
      };
    };

    state.x = new_balances;
    let d1 = d(state);
    state.x = old_balances;
    let fees = utils::empty_vector(n_u256);

    {
      let i = 0;
      while (state.n > i) {
        let ideal_balance = (d1 * *vector::borrow(&old_balances, i)) / d0;
        let _diff = diff(ideal_balance, *vector::borrow(&new_balances, i));
        let fee_ref = vector::borrow_mut(&mut fees, i);
        *fee_ref = (_fee * _diff) / FEE_PRECISION;
        let new_bal_ref = vector::borrow_mut(&mut new_balances, i);
        *new_bal_ref = *new_bal_ref - *fee_ref;

        i = i + 1;
      };
    };

    state.x = new_balances;
    let d2 = d(state);
    state.x = old_balances;

    ((d0 - d2) * state.tokens) / d0 
  }

  public fun calc_withdraw_one_coin(state: &State, token_amount: u256, i: u64): u256 {
    let _xp = xp(state);
    let fee = if (state.fee != 0) 
        state.fee - (state.fee * *vector::borrow(&_xp, i)) /  sum(&_xp)
      else 
        0;
    let d0 = d(state);
    let d1 = d0 - (token_amount * d0) / state.tokens;
    let dy = *vector::borrow(&_xp, i) - y_d(state, i, d1);

    dy - (dy * fee) / FEE_PRECISION
  } 

  fun pow(x: u256, e: u8): u256 {
    (math::pow((x as u64), e) as u256)
  }

  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
  }
}