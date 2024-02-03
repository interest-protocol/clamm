module clamm::interest_pool {
  use std::type_name::TypeName;

  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;
  use sui::vec_set::{Self, VecSet};

  use clamm::curves;

  friend clamm::interest_clamm_stable;
  friend clamm::interest_clamm_volatile;

  struct InterestPool<phantom Curve> has key, store {
    id: UID,
    coins: VecSet<TypeName>
  }

  public fun coins<Curve>(self: &InterestPool<Curve>): vector<TypeName> {
    *vec_set::keys(&self.coins)
  }

  public(friend) fun borrow_mut_uid<Curve>(self: &mut InterestPool<Curve>): &mut UID {
    &mut self.id
  }

  public(friend) fun borrow_uid<Curve>(self: &InterestPool<Curve>): &UID {
    &self.id
  }

  public(friend) fun new<Curve>(coins: VecSet<TypeName>, ctx: &mut TxContext): InterestPool<Curve>  {
    curves::assert_curve<Curve>();
    InterestPool{
      id: object::new(ctx),
      coins,
    }
  }
}