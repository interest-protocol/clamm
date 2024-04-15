module clamm::interest_pool {
  // === Imports ===

  use std::type_name::TypeName;

  use sui::vec_set::VecSet;
  use sui::versioned::Versioned;

  use clamm::curves;

  // === Structs ===

  public struct InterestPool<phantom Curve> has key, store {
    id: UID,
    coins: VecSet<TypeName>,
    state: Versioned
  }

  // === Public-View Functions ===

  public fun addy<Curve>(self: &InterestPool<Curve>): address {
    self.id.to_address()
  }

  public fun coins<Curve>(self: &InterestPool<Curve>): vector<TypeName> {
    *self.coins.keys()
  }

  // === Public-Package Functions ===

  public(package) fun uid<Curve>(self: &InterestPool<Curve>): &UID {
    &self.id
  }

  public(package) fun uid_mut<Curve>(self: &mut InterestPool<Curve>): &mut UID {
    &mut self.id
  }

  public(package) fun state<Curve>(self: &InterestPool<Curve>): &Versioned {
    &self.state
  }

  public(package) fun state_mut<Curve>(self: &mut InterestPool<Curve>): &mut Versioned {
    &mut self.state
  }

  public(package) fun new<Curve>(coins: VecSet<TypeName>, state: Versioned, ctx: &mut TxContext): InterestPool<Curve>  {
    curves::assert_curve<Curve>();
    InterestPool {
      id: object::new(ctx),
      coins,
      state
    }
  }
}