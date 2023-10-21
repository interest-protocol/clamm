module amm::interest_pool {
  use std::type_name::TypeName;

  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;
  use sui::vec_set::{Self, VecSet};
  use sui::types::is_one_time_witness;

  use amm::errors;
  use amm::curves::{Volatile, StablePair, StableTuple};

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

  public(friend) fun new_stable_pair<Label>(coins: VecSet<TypeName>, ctx: &mut TxContext): Pool<StablePair, Label, Nothing>  {
    Pool {
      id: object::new(ctx),
      coins
    }
  }

  public(friend) fun new_stable_pair_with_hooks<HookWitness: drop, Label>(
    otw: HookWitness, 
    coins: VecSet<TypeName>, 
    ctx: &mut TxContext
  ): Pool<StablePair, Label, HookWitness> {
    assert!(is_one_time_witness(&otw), errors::invalid_one_time_witness());
    Pool {
      id: object::new(ctx),
      coins
    }
  }

  public(friend) fun new_stable_tuple<Label>(coins: VecSet<TypeName>, ctx: &mut TxContext): Pool<StableTuple, Label, Nothing>  {
    Pool {
      id: object::new(ctx),
      coins
    }
  }

  public(friend) fun new_stable_tuple_with_hooks<HookWitness: drop, Label>(
    otw: HookWitness, 
    coins: VecSet<TypeName>, 
    ctx: &mut TxContext
  ): Pool<StableTuple, Label, HookWitness> {
    assert!(is_one_time_witness(&otw), errors::invalid_one_time_witness());
    Pool {
      id: object::new(ctx),
      coins
    }
  }

  public(friend) fun new_volatile<Label>(coins: VecSet<TypeName>, ctx: &mut TxContext): Pool<Volatile, Label, Nothing>  {
    Pool {
      id: object::new(ctx),
      coins
    }
  }

  public(friend) fun new_volatile_with_hooks<HookWitness: drop, Label>(
    otw: HookWitness, 
    coins: VecSet<TypeName>, 
    ctx: &mut TxContext
  ): Pool<Volatile, Label, HookWitness> {
    assert!(is_one_time_witness(&otw), errors::invalid_one_time_witness());
    Pool {
      id: object::new(ctx),
      coins
    }
  }
}