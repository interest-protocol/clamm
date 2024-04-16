module clamm::interest_pool {
  // === Imports ===

  use std::type_name::TypeName;

  use sui::vec_set::VecSet;
  use sui::versioned::Versioned;

  use clamm::curves;
  use clamm::errors;
  use clamm::pool_admin::{Self, PoolAdmin};

  // === Structs ===

  public struct InterestPool<phantom Curve> has key {
    id: UID,
    coins: VecSet<TypeName>,
    state: Versioned,
    pool_admin_address: address
  }

  // === Public-View Functions ===

  public fun addy<Curve>(self: &InterestPool<Curve>): address {
    self.id.to_address()
  }

  public fun coins<Curve>(self: &InterestPool<Curve>): vector<TypeName> {
    *self.coins.keys()
  }

  public fun pool_admin_address<Curve>(self: &InterestPool<Curve>): address {
    self.pool_admin_address
  }

  // === Public Mutative Functions ===

  public fun share<Curve>(self: InterestPool<Curve>) {
    transfer::share_object(self);
  }

  public fun assert_pool_admin<Curve>(self: &InterestPool<Curve>, pool_admin: &PoolAdmin) {
    assert!(self.pool_admin_address == pool_admin.addy(), errors::invalid_pool_admin());
  }

  // === Admin Functions ===

  public fun uid_mut<Curve>(self: &mut InterestPool<Curve>, pool_admin: &PoolAdmin): &mut UID {
    assert_pool_admin(self, pool_admin);
    &mut self.id
  }

  // === Public-Package Functions ===

  public(package) fun state<Curve>(self: &InterestPool<Curve>): &Versioned {
    &self.state
  }

  public(package) fun state_mut<Curve>(self: &mut InterestPool<Curve>): &mut Versioned {
    &mut self.state
  }

  public(package) fun new<Curve>(coins: VecSet<TypeName>, state: Versioned, ctx: &mut TxContext): (InterestPool<Curve>, PoolAdmin)  {
    curves::assert_curve<Curve>();
    let pool_admin = pool_admin::new(ctx);
    let pool = InterestPool {
      id: object::new(ctx),
      coins,
      state,
      pool_admin_address: pool_admin.addy()
    };

    (pool, pool_admin)
  }
}