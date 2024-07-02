module clamm::pool_admin {
  // === Structs ===

  // It needs key and store to store in a DAO contract later on
  public struct PoolAdmin has key, store {
    id: UID
  }

  // === Public-Mutative Functions ===

  fun init(ctx: &mut TxContext) {
    let admin = PoolAdmin {
      id: object::new(ctx)
    };

    transfer::transfer(admin, ctx.sender());
  }

  // === Public Package Functions ===

  // === Public-View Functions === 

  // === Test Functions ===

  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
  }
}