module clamm::amm_admin {

  use sui::transfer::transfer;
  use sui::object::{Self, UID};
  use sui::tx_context::{Self, TxContext};

  // It needs key and store to store in a DAO contract later on
  struct Admin has key, store {
    id: UID
  }

  fun init(ctx: &mut TxContext) {
    transfer(Admin { id: object::new(ctx) }, tx_context::sender(ctx));
  }

  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
  }
}