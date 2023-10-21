module amm::interest_pool {
  use std::type_name::TypeName;

  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;
  use sui::vec_set::{Self, VecSet};
  use sui::types::is_one_time_witness;

  use amm::errors;
  use amm::curves::{Volatile, StablePair, StableTuple};

  struct HasHooks has drop {}

  struct NoHooks has drop {}

  struct Nothing has drop {}

  struct Pool<phantom Curve, phantom WithHooks, phantom HookWitness> has key {
    id: UID,
    coins: VecSet<TypeName>
  }

  public fun view_coins<Curve, WithHooks, HookWitness>(pool: &Pool<Curve, WithHooks, HookWitness>): vector<TypeName> {
    vec_set::into_keys(pool.coins)
  }

  public(friend) fun borrow_mut_uid<Curve, WithHooks, HookWitness>(pool: &mut Pool<Curve, WithHooks, HookWitness>): &mut UID {
    &mut pool.id
  }

  public(friend) fun new_stable_pair(coins: VecSet<TypeName>, ctx: &mut TxContext): Pool<StablePair, NoHooks, Nothing>  {
    Pool {
      id: object::new(ctx),
      coins
    }
  }

  public(friend) fun new_stable_pair_with_hooks<HookWitness: drop>(
    otw: HookWitness, 
    coins: VecSet<TypeName>, 
    ctx: &mut TxContext
  ): Pool<StablePair, HasHooks, HookWitness> {
    assert!(is_one_time_witness(&otw), errors::invalid_one_time_witness());
    Pool {
      id: object::new(ctx),
      coins
    }
  }

  public(friend) fun new_stable_tuple(coins: VecSet<TypeName>, ctx: &mut TxContext): Pool<StableTuple, NoHooks, Nothing>  {
    Pool {
      id: object::new(ctx),
      coins
    }
  }

  public(friend) fun new_stable_tuple_with_hooks<HookWitness: drop>(
    otw: HookWitness, 
    coins: VecSet<TypeName>, 
    ctx: &mut TxContext
  ): Pool<StableTuple, HasHooks, HookWitness> {
    assert!(is_one_time_witness(&otw), errors::invalid_one_time_witness());
    Pool {
      id: object::new(ctx),
      coins
    }
  }

  public(friend) fun new_volatile(coins: VecSet<TypeName>, ctx: &mut TxContext): Pool<Volatile, NoHooks, Nothing>  {
    Pool {
      id: object::new(ctx),
      coins
    }
  }

  public(friend) fun new_volatile_with_hooks<HookWitness: drop>(
    otw: HookWitness, 
    coins: VecSet<TypeName>, 
    ctx: &mut TxContext
  ): Pool<Volatile, HasHooks, HookWitness> {
    assert!(is_one_time_witness(&otw), errors::invalid_one_time_witness());
    Pool {
      id: object::new(ctx),
      coins
    }
  }
}