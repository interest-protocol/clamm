module amm::stable_tuple_core {
  use std::vector;
  use std::type_name::{TypeName, get};
  
  use sui::clock::Clock;
  use sui::coin::{Self, Coin};
  use sui::object::{Self, UID};
  use sui::dynamic_field as df;
  use sui::tx_context::TxContext;
  use sui::vec_set::{Self, VecSet};
  use sui::dynamic_object_field as dof;
  use sui::balance::{Self, Supply, Balance};

  use amm::errors;
  use amm::asserts;
  use amm::curves::StableTuple;
  use amm::metadata::{
    Metadata,
    get_decimals_scalar, 
  };
  use amm::stable_tuple_math::{
    get_amp,
    invariant_
  };
  use amm::interest_pool::{
    Self as core,
    Pool,
    Nothing,
    new_pool,
    new_pool_hooks,
  };

  const INITIAL_FEE_PERCENT: u256 = 250000000000000; // 0.025%
  const MAX_FEE_PERCENT: u256 = 20000000000000000; // 2%
  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18

  struct StateKey has drop, copy, store {}

  struct CoinStatekey has drop, copy, store { type: TypeName }

  struct AdminCoinBalanceKey has drop, copy, store { type: TypeName }

  struct CoinState<phantom CoinType> has store {
    decimals: u256,
    index: u64,
    balance: Balance<CoinType>
  }

  struct State<phantom LpCoin> has key, store {
    id: UID,
    lp_coin_supply: Supply<LpCoin>,
    balances: vector<u256>,
    initial_a: u256,
    future_a: u256,
    initial_a_time: u256,
    future_a_time: u256,
    fee_percent: u256,
    n_coins: u64
  }

  public(friend) fun new_3_pool<Label, CoinA, CoinB, CoinC, LpCoin>(
    c: &Clock,
    initial_a: u256,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    metadata: &Metadata,     
    lp_coin_supply: Supply<LpCoin>,
    ctx: &mut TxContext
  ): (Pool<StableTuple, Label, Nothing>, Coin<LpCoin>) {
    assert!(coin::value(&coin_a) != 0 && coin::value(&coin_b) != 0 && coin::value(&coin_c) != 0, errors::no_zero_liquidity_amounts());

    let pool = new_pool<StableTuple,  Label>(make_coins(vector[get<CoinA>(), get<CoinB>(), get<CoinC>()]), ctx);
    // * IMPORTANT Make sure the n_coins argument is correct
    add_state<LpCoin>(core::borrow_mut_uid(&mut pool), initial_a, lp_coin_supply, 3, ctx);

    let state = load_mut_state<LpCoin>(core::borrow_mut_uid(&mut pool));

    // * IMPORTANT Make sure the indexes and CoinTypes match the make_coins vector and they are in the correct order
    register_coin<CoinA>(&mut state.id, metadata, 0);
    register_coin<CoinB>(&mut state.id, metadata, 1);
    register_coin<CoinC>(&mut state.id, metadata, 2);

    let lp_coin = add_liquidity_3_pool(&mut pool, c, coin_a, coin_b, coin_c, 0, ctx);

    (pool, lp_coin)
  }

  public(friend) fun new_4_pool<Label, CoinA, CoinB, CoinC, CoinD, LpCoin>(
    c: &Clock,
    initial_a: u256,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    metadata: &Metadata,     
    lp_coin_supply: Supply<LpCoin>,
    ctx: &mut TxContext
  ): (Pool<StableTuple, Label, Nothing>, Coin<LpCoin>) {
    assert!(
      coin::value(&coin_a) != 0 
      && coin::value(&coin_b) != 0 
      && coin::value(&coin_c) != 0
      && coin::value(&coin_d) != 0,
      errors::no_zero_liquidity_amounts()
    );

    let pool = new_pool<StableTuple,  Label>(
      make_coins(vector[get<CoinA>(), get<CoinB>(), get<CoinC>(), get<CoinD>()]), 
      ctx
    );

    // * IMPORTANT Make sure the n_coins argument is correct
    add_state<LpCoin>(core::borrow_mut_uid(&mut pool), initial_a, lp_coin_supply, 4, ctx);

    let state = load_mut_state<LpCoin>(core::borrow_mut_uid(&mut pool));

    // * IMPORTANT Make sure the indexes and CoinTypes match the make_coins vector and they are in the correct order
    register_coin<CoinA>(&mut state.id, metadata, 0);
    register_coin<CoinB>(&mut state.id, metadata, 1);
    register_coin<CoinC>(&mut state.id, metadata, 2);
    register_coin<CoinD>(&mut state.id, metadata, 3);

    let lp_coin = add_liquidity_4_pool(&mut pool, c, coin_a, coin_b, coin_c, coin_d, 0, ctx);

    (pool, lp_coin)
  }


  public(friend) fun add_liquidity_3_pool<Label, HookWitness, CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut Pool<StableTuple, Label, HookWitness>,
    c: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    let state = load_mut_state<LpCoin>(core::borrow_mut_uid(pool));
    
    let amp = get_amp(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, c);    
    let supply_value = (balance::supply_value(&state.lp_coin_supply) as u256);

    let prev_k = invariant_(amp, &state.balances);

    deposit_coin<CoinA, LpCoin>(state, coin_a);
    deposit_coin<CoinB, LpCoin>(state, coin_b);
    deposit_coin<CoinC, LpCoin>(state, coin_c);

    coin::from_balance(
      balance::increase_supply(
        &mut state.lp_coin_supply, 
        calculate_mint_amount(state, amp, prev_k, lp_coin_min_amount)
      ), 
      ctx
    )
  }

  public(friend) fun add_liquidity_4_pool<Label, HookWitness, CoinA, CoinB, CoinC, CoinD, LpCoin>(
    pool: &mut Pool<StableTuple, Label, HookWitness>,
    c: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    let state = load_mut_state<LpCoin>(core::borrow_mut_uid(pool));
    
    let amp = get_amp(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, c);    
    let prev_k = invariant_(amp, &state.balances);

    deposit_coin<CoinA, LpCoin>(state, coin_a);
    deposit_coin<CoinB, LpCoin>(state, coin_b);
    deposit_coin<CoinC, LpCoin>(state, coin_c);
    deposit_coin<CoinD, LpCoin>(state, coin_d);

    coin::from_balance(
      balance::increase_supply(
        &mut state.lp_coin_supply, 
        calculate_mint_amount(state, amp, prev_k, lp_coin_min_amount)
      ), 
      ctx
    )
  }

  fun calculate_mint_amount<LpCoin>(state: &State<LpCoin>, amp: u256, prev_k: u256, lp_coin_min_amount: u64): u64 {
    let new_k = invariant_(amp, &state.balances);

    assert!(new_k > prev_k, errors::invalid_invariant());

    let supply_value = (balance::supply_value(&state.lp_coin_supply) as u256);

    let mint_amount = if (supply_value == 0) { (new_k as u64) } else { ((supply_value * (new_k - prev_k) / prev_k) as u64) };

    assert!(mint_amount >= lp_coin_min_amount, errors::slippage());

    mint_amount
  }

  fun deposit_coin<CoinType, LpCoin>(state: &mut State<LpCoin>, coin_in: Coin<CoinType>) {
    let coin_value = (coin::value(&coin_in) as u256);

    if (coin_value == 0) {
      coin::destroy_zero(coin_in);
      return
    };

    let coin_state = load_coin_state<CoinType>(&mut state.id);

    // Update the balance for the coin
    let current_balance = vector::borrow_mut(&mut state.balances, coin_state.index);
    *current_balance = *current_balance + (coin_value * PRECISION / coin_state.decimals);

    balance::join(&mut coin_state.balance, coin::into_balance(coin_in));
  }

  fun register_coin<CoinType>(id: &mut UID, metadata: &Metadata, index: u64) {
    let coin_name = get<CoinType>();

    df::add(id, AdminCoinBalanceKey { type: coin_name }, balance::zero<CoinType>());
    df::add(id, CoinStatekey { type: coin_name }, CoinState {
      decimals: (get_decimals_scalar<CoinType>(metadata) as u256),
      balance: balance::zero<CoinType>(),
      index
    });
  }

  fun add_state<LpCoin>(
    id: &mut UID,
    initial_a: u256,
    lp_coin_supply: Supply<LpCoin>,
    n_coins: u64,
    ctx: &mut TxContext
  ) {
    asserts::assert_supply_has_zero_value(&lp_coin_supply);
    dof::add(id, StateKey {}, 
      State {
        id: object::new(ctx),
        balances: vector[],
        initial_a,
        future_a: initial_a,
        initial_a_time: 0,
        future_a_time: 0,
        fee_percent: INITIAL_FEE_PERCENT,
        lp_coin_supply,
        n_coins
      }
    );
  }

  // @dev It makes sure that all coins are unique
  fun make_coins(data: vector<TypeName>): VecSet<TypeName> {
    let len = vector::length(&data);
    let set = vec_set::empty();
    let i = 0;

    while (len > i) {
      vec_set::insert(&mut set, *vector::borrow(&data, i));
      i = i + 1;
    };

    set
  }

  fun load_coin_state<CoinType>(id: &mut UID): &mut CoinState<CoinType> {
    df::borrow_mut(id, CoinStatekey { type: get<CoinType>() })
  } 

  fun load_state<LpCoin>(id: &UID): &State<LpCoin> {
    dof::borrow(id, StateKey {})
  }

  fun load_mut_state<LpCoin>(id: &mut UID): &mut State<LpCoin> {
    dof::borrow_mut(id, StateKey {})
  }
}