module amm::pool_events {
  use sui::object::ID;
  use sui::event::emit;

  use amm::curves::StablePair;

  friend amm::volatile;
  friend amm::stable_pair;
  friend amm::stable_tuple;

  struct NewPair<phantom Curve, phantom CoinX, phantom CoinY> has drop, copy {
    pool_id: ID,
    amount_x: u64,
    amount_y: u64
  }

  struct New3Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom LpCoin> has copy, drop {
    pool_id: ID,
  }

  struct New4Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom LpCoin> has copy, drop {
    pool_id: ID,
  }

  struct New5Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom CoinE, phantom LpCoin> has copy, drop {
    pool_id: ID,
  }

  struct AddLiquidity3Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64
  }

  struct AddLiquidity4Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
  }

  struct AddLiquidity5Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom CoinE, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    amount_e: u64,
  }

  struct Swap<phantom Curve, phantom CoinIn, phantom CoinOut> has drop, copy {
    pool_id: ID,
    amount_in: u64,
    amount_out: u64
  }

  struct AddLiquidity<phantom Curve, phantom CoinX, phantom CoinY> has drop, copy {
    pool_id: ID,
    amount_x: u64,
    amount_y: u64,
    shares: u64
  }

  struct RemoveStablePairLiquidity<phantom Curve, phantom CoinX, phantom CoinY> has drop, copy {
    pool_id: ID,
    amount_x: u64,
    amount_y: u64,
    shares: u64
  }

    struct RemoveLiquidity<phantom Curve, phantom CoinType, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount: u64
  }

  struct RemoveLiquidity3Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
  }

  struct RemoveLiquidity4Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
  }

  struct RemoveLiquidity5Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom CoinE, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    amount_e: u64,
  }


  struct UpdateFee<phantom Curve> has copy, drop {
    pool_id: ID,
    fee_in_percent: u256,
    fee_out_percent: u256, 
    admin_fee_percent: u256,     
  }

  struct TakeStablePairFees<phantom Curve, phantom CoinX, phantom CoinY> has copy, drop {
    pool_id: ID,
    amount_x: u64,
    amount_y: u64
  }

  struct TakeFee<phantom Curve, phantom CoinType, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount: u64
  }

  public(friend) fun emit_new_3_pool<Curve, CoinA, CoinB, CoinC, LpCoin>(id: ID) {
    emit(New3Pool<Curve, CoinA, CoinB, CoinC, LpCoin> { pool_id: id });
  }

  public(friend) fun emit_new_4_pool<Curve, CoinA, CoinB, CoinC, CoinD, LpCoin>(id: ID) {
    emit(New4Pool<Curve, CoinA, CoinB, CoinC, CoinD, LpCoin> { pool_id: id });
  }

  public(friend) fun emit_new_5_pool<Curve, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(id: ID) {
    emit(New5Pool<Curve, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin> { pool_id: id });
  }

  public(friend) fun emit_new_pair<Curve, CoinX, CoinY>(pool_id: ID, amount_x: u64, amount_y: u64) {
    emit(NewPair<Curve, CoinX, CoinY>{ pool_id, amount_x, amount_y });
  }

  public(friend) fun emit_swap<Curve, CoinIn, CoinOut>(pool_id: ID, amount_in: u64, amount_out: u64) {
    emit(Swap<Curve, CoinIn, CoinOut>{ pool_id, amount_in, amount_out });
  }

  public(friend) fun emit_add_pair_liquidity<Curve, CoinX, CoinY>(pool_id: ID, amount_x: u64, amount_y: u64, shares: u64) {
   emit(AddLiquidity<Curve, CoinX, CoinY>{ pool_id, amount_x, amount_y, shares });    
  }

    public(friend) fun emit_add_liquidity_3_pool<Curve, CoinA, CoinB, CoinC, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64
  ) {
    emit(AddLiquidity3Pool<Curve, CoinA, CoinB, CoinC, LpCoin> { pool_id: id, amount_a, amount_b, amount_c });
  }

  public(friend) fun emit_add_liquidity_4_pool<Curve, CoinA, CoinB, CoinC, CoinD, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64
  ) {
    emit(AddLiquidity4Pool<Curve, CoinA, CoinB, CoinC, CoinD, LpCoin> { pool_id: id, amount_a, amount_b, amount_c, amount_d });
  }

  public(friend) fun emit_add_liquidity_5_pool<Curve, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    amount_e: u64
  ) {
    emit(AddLiquidity5Pool<Curve, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin> { pool_id: id, amount_a, amount_b, amount_c, amount_d, amount_e });
  }

  public(friend) fun emit_remove_stable_pair_liquidity<CoinX, CoinY>(pool_id: ID, amount_x: u64, amount_y: u64, shares: u64) {
    emit(RemoveStablePairLiquidity<StablePair, CoinX, CoinY>{ pool_id, amount_x, amount_y, shares});
  }

  public(friend) fun emit_remove_liquidity<Curve, CoinType, LpCoin>(id: ID, amount: u64) {
    emit(RemoveLiquidity<Curve, CoinType, LpCoin> { pool_id: id, amount });
  }

  public(friend) fun emit_remove_liquidity_3_pool<Curve, CoinA, CoinB, CoinC, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
  ) {
    emit(RemoveLiquidity3Pool<Curve, CoinA, CoinB, CoinC, LpCoin> { pool_id: id, amount_a, amount_b, amount_c });
  }

  public(friend) fun emit_remove_liquidity_4_pool<Curve, CoinA, CoinB, CoinC, CoinD, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64
  ) {
    emit(RemoveLiquidity4Pool<Curve, CoinA, CoinB, CoinC, CoinD, LpCoin> { pool_id: id, amount_a, amount_b, amount_c, amount_d });
  }

  public(friend) fun emit_remove_liquidity_5_pool<Curve, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    amount_e: u64,
  ) {
    emit(RemoveLiquidity5Pool<Curve, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin> { pool_id: id, amount_a, amount_b, amount_c, amount_d, amount_e });
  }

  public(friend) fun emit_update_stable_fee<Curve>(
    pool_id: ID, 
    fee_in_percent: u256,
    fee_out_percent: u256, 
    admin_fee_percent: u256,     
  ) {
    emit(UpdateFee<Curve> { pool_id, fee_in_percent, fee_out_percent, admin_fee_percent });
  }

  public(friend) fun emit_take_stable_pair_fees<CoinX, CoinY>(pool_id: ID, amount_x: u64, amount_y: u64 ) {
    emit(TakeStablePairFees<StablePair, CoinX, CoinY> { pool_id, amount_x, amount_y });
  }  

  public(friend) fun emit_take_fees<Curve, CoinType, LpCoin>(pool_id: ID, amount: u64 ) {
    emit(TakeFee<Curve, CoinType, LpCoin> { pool_id, amount });
  } 
}