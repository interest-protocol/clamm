module amm::amm_admin {

  use sui::transfer::transfer;
  use sui::object::{Self, UID};
  use sui::tx_context::{Self, TxContext};

  // It needs key and store to store in a DAO contract later on
  struct Admin has key, store {
    id: UID
  }

  #[allow(unused_function)]
  fun init(ctx: &mut TxContext) {
    transfer(Admin { id: object::new(ctx) }, tx_context::sender(ctx));
  }
}