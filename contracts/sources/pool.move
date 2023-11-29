/*
* TODO Hook Contracts should implement a standarded interface
*/
module amm::interest_pool {
  use std::type_name::TypeName;

  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;
  use sui::vec_set::{Self, VecSet};

  use amm::curves;

  friend amm::stable_implementation;
  friend amm::volatile;

  struct InterestPool<phantom Curve> has key, store {
    id: UID,
    coins: VecSet<TypeName>
  }

  public fun view_coins<Curve>(self: &InterestPool<Curve>): vector<TypeName> {
    *vec_set::keys(&self.coins)
  }

  public(friend) fun borrow_mut_uid<Curve>(self: &mut InterestPool<Curve>): &mut UID {
    &mut self.id
  }

  public(friend) fun borrow_uid<Curve>(self: &InterestPool<Curve>): &UID {
    &self.id
  }

  public(friend) fun new_pool<Curve>(coins: VecSet<TypeName>, ctx: &mut TxContext): InterestPool<Curve>  {
    curves::assert_is_curve<Curve>();
    InterestPool{
      id: object::new(ctx),
      coins,
    }
  }
}