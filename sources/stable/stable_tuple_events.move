module amm::stable_tuple_events {
  use sui::object::ID;
  use sui::event::emit;
  use sui::tx_context::{Self, TxContext};

  friend amm::stable_tuple;

  struct NewStable3Pool<phantom CoinA, phantom CoinB, phantom CoinC, phantom LpCoin> has copy, drop {
    pool_id: ID,
  }

  struct NewStable4Pool<phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom LpCoin> has copy, drop {
    pool_id: ID,
  }

  struct Swap<phantom CoinIn, phantom CoinOut, phantom LpCoin> has copy, drop {
    sender: address,
    pool_id: ID,
    amount_in: u64,
    amount_out: u64
  }

  struct AddLiquidity3Pool<phantom CoinA, phantom CoinB, phantom CoinC, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    sender: address,
  }

  struct AddLiquidity4Pool<phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    sender: address,
  }

  struct RemoveLiquidity<phantom CoinType, phantom LpCoin> has copy, drop {
    pool_id: ID,
    sender: address,
    amount: u64
  }

  struct RemoveBalancedLiquidity3Pool<phantom CoinA, phantom CoinB, phantom CoinC, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    sender: address,
  }

  struct RemoveBalancedLiquidity4Pool<phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    sender: address,
  }

  struct UpdateFee has copy, drop {
    pool_id: ID,
    fee_in_percent: u256,
    fee_out_percent: u256, 
    admin_fee_percent: u256,  
  }

  struct TakeFee<phantom CoinType, phantom LpCoin> has copy, drop {
     pool_id: ID,
    amount: u64
  }


  public(friend) fun emit_new_stable_3_pool<CoinA, CoinB, CoinC, LpCoin>(id: ID) {
    emit(NewStable3Pool<CoinA, CoinB, CoinC, LpCoin> { pool_id: id });
  }

  public(friend) fun emit_new_stable_4_pool<CoinA, CoinB, CoinC, CoinD, LpCoin>(id: ID) {
    emit(NewStable4Pool<CoinA, CoinB, CoinC, CoinD, LpCoin> { pool_id: id });
  }

  public(friend) fun emit_swap<CoinIn, CoinOut, LpCoin>(id: ID, amount_in: u64, amount_out: u64, ctx: &mut TxContext) {
    emit(Swap<CoinIn, CoinOut, LpCoin> { pool_id: id, sender: tx_context::sender(ctx), amount_in, amount_out });
  }

  public(friend) fun emit_liquidity_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    ctx: &mut TxContext
  ) {
    emit(AddLiquidity3Pool<CoinA, CoinB, CoinC, LpCoin> { pool_id: id, sender: tx_context::sender(ctx), amount_a, amount_b, amount_c });
  }

  public(friend) fun emit_liquidity_4_pool<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    ctx: &mut TxContext
  ) {
    emit(AddLiquidity4Pool<CoinA, CoinB, CoinC, CoinD, LpCoin> { pool_id: id, sender: tx_context::sender(ctx), amount_a, amount_b, amount_c, amount_d });
  }

  public(friend) fun emit_remove_liquidity<CoinType, LpCoin>(id: ID, amount: u64, ctx: &mut TxContext) {
    emit(RemoveLiquidity<CoinType, LpCoin> { pool_id: id, amount, sender: tx_context::sender(ctx) });
  }

  public(friend) fun emit_remove_balance_liquidity_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    ctx: &mut TxContext
  ) {
    emit(RemoveBalancedLiquidity3Pool<CoinA, CoinB, CoinC, LpCoin> { pool_id: id, sender: tx_context::sender(ctx), amount_a, amount_b, amount_c });
  }

  public(friend) fun emit_remove_balance_liquidity_4_pool<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    ctx: &mut TxContext
  ) {
    emit(RemoveBalancedLiquidity4Pool<CoinA, CoinB, CoinC, CoinD, LpCoin> { pool_id: id, sender: tx_context::sender(ctx), amount_a, amount_b, amount_c, amount_d });
  }

  public(friend) fun emit_update_fee(
    id: ID, 
    fee_in_percent: u256,
    fee_out_percent: u256, 
    admin_fee_percent: u256,  
  ) {
    emit(UpdateFee { pool_id: id, fee_in_percent, fee_out_percent, admin_fee_percent });
  }

  public(friend) fun emit_take_fee<CoinType, LpCoin>(id: ID, amount: u64) {
    emit(TakeFee<CoinType, LpCoin> { pool_id: id, amount });
  }
}