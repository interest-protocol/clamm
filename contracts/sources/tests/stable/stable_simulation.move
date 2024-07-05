#[test_only]
module clamm::stable_simulation {
  
  use suitears::fixed_point_wad::mul_down as fmul;

  use sui::transfer::share_object;

  use clamm::stable_math::{
    y as get_y,
    y_d as get_y_d,
    invariant_
  };

  const INITIAL_FEE_PERCENT: u256 = 250000000000000; // 0.025%

  public struct State has key {
    id: UID,
    a: u256,
    n: u64,
    fee: u256,
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

  public fun swap(state: &mut State, i: u64, j: u64, dx: u256): u256 {
    let dx = dx - fmul(dx, state.fee);
    let x = *vector::borrow(&state.xp, i) + dx;
    let y = y(state, i, j, x);
    let dy = *vector::borrow(&state.xp, j) - y;
    let fee = fmul(dy, state.fee);
    assert!(dy != 0, 0);

    let x_i_ref = vector::borrow_mut(&mut state.xp, i);
    *x_i_ref = x;

    let x_j_ref = vector::borrow_mut(&mut state.xp, j);
    *x_j_ref = y + fee;

    dy - fee
  }   

  public fun calc_withdraw_one_coin(state: &State, token_amount: u256, i: u64): u256 {
    let _xp = state.xp;
    let d0 = d(state);
    let d1 = d0 - (token_amount * d0) / state.lp_supply;
    let dy = *vector::borrow(&_xp, i) - (y_d(state, i, d1) + 1);

    dy
  } 

  public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
  }

  public fun view_state(state: &State): (vector<u256>, u256, u64, u256, u256) {
    (state.xp, state.a, state.n, state.fee, state.lp_supply)
  }
}