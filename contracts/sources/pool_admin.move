module clamm::pool_admin {
  // === Structs ===

  // It needs key and store to store in a DAO contract later on
  public struct PoolAdmin has key, store {
    id: UID
  }

  // === Public-Mutative Functions ===

  public fun destroy(self: PoolAdmin) {
    let PoolAdmin { id } = self;
    
    id.delete();
  }

  // === Public Package Functions ===

  public(package) fun new(ctx: &mut TxContext): PoolAdmin {
    PoolAdmin { id: object::new(ctx) }
  }

  // === Public-View Functions ===

  public fun addy(self: &PoolAdmin): address {
    self.id.to_address()
  }  

  // === Test Functions ===

  #[test_only]
  public fun new_for_testing(ctx: &mut TxContext): PoolAdmin {
    new(ctx)
  }
}