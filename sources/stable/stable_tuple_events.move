module amm::stable_tuple_events {
  use sui::object::ID;
  use sui::event::emit;

  friend amm::stable_tuple;

  struct NewStable3Pool<phantom CoinA, phantom CoinB, phantom CoinC, phantom LpCoin> has copy, drop {
    pool_id: ID,
  }

  struct NewStable4Pool<phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom LpCoin> has copy, drop {
    pool_id: ID,
  }

  struct NewStable5Pool<phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom CoinE, phantom LpCoin> has copy, drop {
    pool_id: ID,
  }

  struct Swap<phantom CoinIn, phantom CoinOut, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_in: u64,
    amount_out: u64
  }

  struct AddLiquidity3Pool<phantom CoinA, phantom CoinB, phantom CoinC, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64
  }

  struct AddLiquidity4Pool<phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
  }

  struct AddLiquidity5Pool<phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom CoinE, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    amount_e: u64,
  }

  struct RemoveLiquidity<phantom CoinType, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount: u64
  }

  struct RemoveLiquidity3Pool<phantom CoinA, phantom CoinB, phantom CoinC, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
  }

  struct RemoveLiquidity4Pool<phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
  }

  struct RemoveLiquidity5Pool<phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom CoinE, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    amount_e: u64,
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

  public(friend) fun emit_new_stable_5_pool<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(id: ID) {
    emit(NewStable5Pool<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin> { pool_id: id });
  }

  public(friend) fun emit_swap<CoinIn, CoinOut, LpCoin>(id: ID, amount_in: u64, amount_out: u64) {
    emit(Swap<CoinIn, CoinOut, LpCoin> { pool_id: id, amount_in, amount_out });
  }

  public(friend) fun emit_liquidity_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64
  ) {
    emit(AddLiquidity3Pool<CoinA, CoinB, CoinC, LpCoin> { pool_id: id, amount_a, amount_b, amount_c });
  }

  public(friend) fun emit_liquidity_4_pool<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64
  ) {
    emit(AddLiquidity4Pool<CoinA, CoinB, CoinC, CoinD, LpCoin> { pool_id: id, amount_a, amount_b, amount_c, amount_d });
  }

  public(friend) fun emit_liquidity_5_pool<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    amount_e: u64
  ) {
    emit(AddLiquidity5Pool<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin> { pool_id: id, amount_a, amount_b, amount_c, amount_d, amount_e });
  }

  public(friend) fun emit_remove_liquidity<CoinType, LpCoin>(id: ID, amount: u64) {
    emit(RemoveLiquidity<CoinType, LpCoin> { pool_id: id, amount });
  }

  public(friend) fun emit_remove_liquidity_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
  ) {
    emit(RemoveLiquidity3Pool<CoinA, CoinB, CoinC, LpCoin> { pool_id: id, amount_a, amount_b, amount_c });
  }

  public(friend) fun emit_remove_liquidity_4_pool<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64
  ) {
    emit(RemoveLiquidity4Pool<CoinA, CoinB, CoinC, CoinD, LpCoin> { pool_id: id, amount_a, amount_b, amount_c, amount_d });
  }

  public(friend) fun emit_remove_liquidity_5_pool<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    amount_e: u64,
  ) {
    emit(RemoveLiquidity5Pool<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin> { pool_id: id, amount_a, amount_b, amount_c, amount_d, amount_e });
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