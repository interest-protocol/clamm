module amm::interest_pool {
  use std::type_name::TypeName;

  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;
  use sui::vec_set::{Self, VecSet};

  use amm::curves::assert_is_curve;
  use amm::hooks::{HookMap, no_hook_map};

  friend amm::stable_pair_core;

  struct Nothing has drop {}

  struct Pool<phantom Curve, phantom Label, phantom HookWitness> has key, store {
    id: UID,
    hook_map: HookMap,
    coins: VecSet<TypeName>
  }

  public fun view_coins<Curve, Label, HookWitness>(pool: &Pool<Curve, Label, HookWitness>): vector<TypeName> {
    *vec_set::keys(&pool.coins)
  }


  public fun view_hooks<Curve, Label, HookWitness>(pool: &Pool<Curve, Label, HookWitness>): &HookMap {
    &pool.hook_map
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
      hook_map: no_hook_map(),
      coins
    }
  }

  public(friend) fun new_pool_hooks<HookWitness: drop, Curve, Label>(
    _: HookWitness, 
    hook_map: HookMap,
    coins: VecSet<TypeName>, 
    ctx: &mut TxContext
  ): Pool<Curve, Label, HookWitness> {
    assert_is_curve<Curve>();
    Pool {
      id: object::new(ctx),
      hook_map,
      coins
    }
  }
}