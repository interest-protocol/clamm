module clamm::amm_admin {
  // === Imports ===

  use sui::transfer::transfer;

  // === Structs ===

  // It needs key and store to store in a DAO contract later on
  public struct Admin has key, store {
    id: UID
  }

  // === Public-Mutative Functions ===

  fun init(ctx: &mut TxContext) {
    transfer(Admin { id: object::new(ctx) }, ctx.sender());
  }

  // === Test Functions ===

  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
  }
}