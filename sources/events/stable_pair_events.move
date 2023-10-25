module amm::stable_pair_events {
  use sui::object::ID;
  use sui::event::emit;
  use sui::tx_context::{Self, TxContext};
  
  use amm::curves::StablePair;

  friend amm::stable_pair;

  struct NewStablePair<phantom Curve, phantom Label, phantom HookWitness> has drop, copy {
    pool_id: ID,
    amount_x: u64,
    amount_y: u64,
    sender: address
  }

  struct Swap<phantom Curve, phantom Label, phantom HookWitness, phantom CoinIn, phantom CoinOut> has drop, copy {
    pool_id: ID,
    amount_in: u64,
    amount_out: u64,
    sender: address
  }

  struct AddLiquidity<phantom Curve, phantom Label, phantom HookWitness, phantom CoinX, phantom CoinY> has drop, copy {
    pool_id: ID,
    amount_x: u64,
    amount_y: u64,
    shares: u64,
    sender: address
  }

  struct RemoveLiquidity<phantom Curve, phantom Label, phantom HookWitness, phantom CoinX, phantom CoinY> has drop, copy {
    pool_id: ID,
    amount_x: u64,
    amount_y: u64,
    shares: u64,
    sender: address
  }

  public(friend) fun emit_new_pair<Label, HookWitness>(pool_id: ID, amount_x: u64, amount_y: u64, ctx: &mut TxContext) {
    emit(NewStablePair<StablePair, Label, HookWitness>{ pool_id, amount_x, amount_y, sender: tx_context::sender(ctx) });
  }

  public(friend) fun emit_swap<Label, HookWitness, CoinIn, CoinOut>(pool_id: ID, amount_in: u64, amount_out: u64, ctx: &mut TxContext) {
    emit(Swap<StablePair, Label, HookWitness, CoinIn, CoinOut>{ pool_id, amount_in, amount_out, sender: tx_context::sender(ctx) });
  }

  public(friend) fun emit_add_liquidity<Label, HookWitness, CoinX, CoinY>(pool_id: ID, amount_x: u64, amount_y: u64, shares: u64, ctx: &mut TxContext) {
   emit(AddLiquidity<StablePair, Label, HookWitness, CoinX, CoinY>{ pool_id, amount_x, amount_y, shares, sender: tx_context::sender(ctx) });    
  }

  public(friend) fun emit_remove_liquidity<Label, HookWitness, CoinX, CoinY>(pool_id: ID, amount_x: u64, amount_y: u64, shares: u64, ctx: &mut TxContext) {
    emit(RemoveLiquidity<StablePair, Label, HookWitness, CoinX, CoinY>{ pool_id, amount_x, amount_y, shares, sender: tx_context::sender(ctx) });
  }
}