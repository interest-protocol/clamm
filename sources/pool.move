/*
* TODO Hook Contracts should implement a standarded interface
*/
module amm::interest_pool {
  use std::type_name::TypeName;

  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;
  use sui::vec_set::{Self, VecSet};

  use amm::curves;
  use amm::errors;

  friend amm::volatile;
  friend amm::stable_pair;
  friend amm::stable_tuple;

  struct Pool<phantom Curve> has key, store {
    id: UID,
    coins: VecSet<TypeName>
  }

  public fun view_coins<Curve>(pool: &Pool<Curve>): vector<TypeName> {
    *vec_set::keys(&pool.coins)
  }

  public fun assert_is_3_pool<Curve>(pool: &Pool<Curve>) {
    assert!(vec_set::size(&pool.coins) == 3, errors::must_be_3_pool());
  }

  public fun assert_is_4_pool<Curve>(pool: &Pool<Curve>) {
    assert!(vec_set::size(&pool.coins) == 4, errors::must_be_4_pool());
  }

  public fun assert_is_5_pool<Curve>(pool: &Pool<Curve>) {
    assert!(vec_set::size(&pool.coins) == 5, errors::must_be_5_pool());
  }

  public(friend) fun borrow_mut_uid<Curve>(pool: &mut Pool<Curve>): &mut UID {
    &mut pool.id
  }

  public(friend) fun borrow_uid<Curve>(pool: &Pool<Curve>): &UID {
    &pool.id
  }

  public(friend) fun new_pool<Curve>(coins: VecSet<TypeName>, ctx: &mut TxContext): Pool<Curve>  {
    curves::assert_is_curve<Curve>();
    Pool {
      id: object::new(ctx),
      coins,
    }
  }
}