module amm::interest_pool {
  use std::type_name::TypeName;

  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;
  use sui::vec_set::{Self, VecSet};
  use sui::types::is_one_time_witness;

  use amm::errors;
  use amm::curves::assert_is_curve;

  friend amm::stable_pair_core;

  struct Nothing has drop {}

  struct Pool<phantom Curve, phantom Label, phantom HookWitness> has key {
    id: UID,
    coins: VecSet<TypeName>
  }

  public fun view_coins<Curve, Label, HookWitness>(pool: &Pool<Curve, Label, HookWitness>): vector<TypeName> {
    *vec_set::keys(&pool.coins)
  }

  public(friend) fun borrow_mut_uid<Curve, Label, HookWitness>(pool: &mut Pool<Curve, Label, HookWitness>): &mut UID {
    &mut pool.id
  }

  public(friend) fun borrow_uid<Curve, Label, HookWitness>(pool: &Pool<Curve, Label, HookWitness>): &UID {
    &pool.id
  }

  public(friend) fun new_pool<Curve, Label>(coins: VecSet<TypeName>, ctx: &mut TxContext): Pool<Curve, Label, Nothing>  {
    assert_is_curve<Curve>();
    Pool {
      id: object::new(ctx),
      coins
    }
  }

  public(friend) fun new_pool_hooks<HookWitness: drop, Curve, Label>(
    otw: HookWitness, 
    coins: VecSet<TypeName>, 
    ctx: &mut TxContext
  ): Pool<Curve, Label, HookWitness> {
    assert_is_curve<Curve>();
    assert!(is_one_time_witness(&otw), errors::invalid_one_time_witness());
    Pool {
      id: object::new(ctx),
      coins
    }
  }
}