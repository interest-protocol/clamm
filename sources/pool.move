/*
* TODO Hook Contracts should implement a standarded interface
*/
module amm::interest_pool {
  use std::type_name::{get, TypeName};

  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;
  use sui::vec_set::{Self, VecSet};

  use amm::curves::assert_is_curve;

  friend amm::stable_pair;
  friend amm::stable_tuple;

  struct Pool has key {
    id: UID,
    curve: TypeName,
    coins: VecSet<TypeName>
  }

  public fun view_coins(pool: &Pool): vector<TypeName> {
    *vec_set::keys(&pool.coins)
  }

  public(friend) fun borrow_mut_uid(pool: &mut Pool): &mut UID {
    &mut pool.id
  }

  public(friend) fun borrow_uid(pool: &Pool): &UID {
    &pool.id
  }

  public(friend) fun new_pool<Curve>(coins: VecSet<TypeName>, ctx: &mut TxContext): Pool  {
    assert_is_curve<Curve>();
    Pool {
      id: object::new(ctx),
      coins,
      curve: get<Curve>()
    }
  }
}