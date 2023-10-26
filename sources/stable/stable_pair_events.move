module amm::stable_pair_events {
  use sui::object::ID;
  use sui::event::emit;
  use sui::tx_context::{Self, TxContext};
  
  use amm::curves::StablePair;

  friend amm::stable_pair;

  struct NewStablePair<phantom Curve> has drop, copy {
    pool_id: ID,
    amount_x: u64,
    amount_y: u64,
    sender: address
  }

  struct Swap<phantom Curve, phantom CoinIn, phantom CoinOut> has drop, copy {
    pool_id: ID,
    amount_in: u64,
    amount_out: u64,
    sender: address
  }

  struct AddLiquidity<phantom Curve, phantom CoinX, phantom CoinY> has drop, copy {
    pool_id: ID,
    amount_x: u64,
    amount_y: u64,
    shares: u64,
    sender: address
  }

  struct RemoveLiquidity<phantom Curve, phantom CoinX, phantom CoinY> has drop, copy {
    pool_id: ID,
    amount_x: u64,
    amount_y: u64,
    shares: u64,
    sender: address
  }


  struct UpdateFee<phantom Curve> has copy, drop {
    pool_id: ID,
    fee_in_percent: u256,
    fee_out_percent: u256, 
    admin_fee_percent: u256,     
  }

  struct TakeFees<phantom Curve, phantom CoinX, phantom CoinY> has copy, drop {
    pool_id: ID,
    amount_x: u64,
    amount_y: u64
  }

  public(friend) fun emit_new_pair(pool_id: ID, amount_x: u64, amount_y: u64, ctx: &mut TxContext) {
    emit(NewStablePair<StablePair>{ pool_id, amount_x, amount_y, sender: tx_context::sender(ctx) });
  }

  public(friend) fun emit_swap<CoinIn, CoinOut>(pool_id: ID, amount_in: u64, amount_out: u64, ctx: &mut TxContext) {
    emit(Swap<StablePair, CoinIn, CoinOut>{ pool_id, amount_in, amount_out, sender: tx_context::sender(ctx) });
  }

  public(friend) fun emit_add_liquidity<CoinX, CoinY>(pool_id: ID, amount_x: u64, amount_y: u64, shares: u64, ctx: &mut TxContext) {
   emit(AddLiquidity<StablePair, CoinX, CoinY>{ pool_id, amount_x, amount_y, shares, sender: tx_context::sender(ctx) });    
  }

  public(friend) fun emit_remove_liquidity<CoinX, CoinY>(pool_id: ID, amount_x: u64, amount_y: u64, shares: u64, ctx: &mut TxContext) {
    emit(RemoveLiquidity<StablePair, CoinX, CoinY>{ pool_id, amount_x, amount_y, shares, sender: tx_context::sender(ctx) });
  }

  public(friend) fun emit_update_fee(
    pool_id: ID, 
    fee_in_percent: u256,
    fee_out_percent: u256, 
    admin_fee_percent: u256,     
  ) {
    emit(UpdateFee<StablePair> { pool_id,fee_in_percent, fee_out_percent, admin_fee_percent });
  }

  public(friend) fun emit_take_fees<CoinX, CoinY>(pool_id: ID, amount_x: u64, amount_y: u64 ) {
    emit(TakeFees<StablePair, CoinX, CoinY> { pool_id, amount_x, amount_y });
  }
}