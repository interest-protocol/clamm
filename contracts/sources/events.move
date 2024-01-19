module clamm::pool_events {
  use sui::object::ID;
  use sui::event::emit;

  use clamm::curves::Volatile;

  friend clamm::interest_clamm_stable;
  friend clamm::interest_clamm_volatile;
  
  struct New2Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom LpCoin> has drop, copy {
    pool_id: ID
  }

  struct New3Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom LpCoin> has copy, drop {
    pool_id: ID
  }

  struct New4Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom LpCoin> has copy, drop {
    pool_id: ID
  }

  struct New5Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom CoinE, phantom LpCoin> has copy, drop {
    pool_id: ID
  }

  struct AddLiquidity2Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    shares: u64
  }

  struct AddLiquidity3Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    shares: u64
  }

  struct AddLiquidity4Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    shares: u64
  }

  struct AddLiquidity5Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom CoinE, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    amount_e: u64,
    shares: u64
  }

  struct Swap<phantom Curve, phantom CoinIn, phantom CoinOut, phantom LpCoin> has drop, copy {
    pool_id: ID,
    amount_in: u64,
    amount_out: u64
  }

  struct RemoveLiquidity<phantom Curve, phantom CoinType, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount: u64,
    shares: u64
  }

  struct RemoveLiquidity2Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    shares: u64
  }  

  struct RemoveLiquidity3Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    shares: u64
  }

  struct RemoveLiquidity4Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    shares: u64
  }

  struct RemoveLiquidity5Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom CoinE, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    amount_e: u64,
    shares: u64
  }


  struct UpdateFee<phantom Curve, phantom LpCoin> has copy, drop {
    pool_id: ID,
    fee_in_percent: u256,
    fee_out_percent: u256, 
    admin_fee_percent: u256,     
  }

  struct TakeFee<phantom Curve, phantom CoinType, phantom LpCoin> has copy, drop {
    pool_id: ID,
    amount: u64
  }

  struct RampA<phantom LpCoin> has drop, copy {
    pool_id: ID,
    initial_a: u256,
    future_a: u256,
    future_a_time: u256,
    timestamp: u64,
  }

  struct StopRampA<phantom LpCoin> has drop, copy {
    pool_id: ID,
    a: u256,
    timestamp: u64
  }

  struct RampAGamma<phantom LpCoin> has drop, copy {
    pool_id: ID,
    a: u256,
    gamma: u256,
    initial_time: u64,
    future_a: u256,
    future_gamma: u256,
    future_time: u64
  }

  struct StopRampAGamma<phantom LpCoin> has drop, copy {
    pool_id: ID,
    a: u256,
    gamma: u256,
    timestamp: u64,
  }

  struct UpdateParameters<phantom LpCoin> has drop, copy {
    pool_id: ID,
    admin_fee: u256,
    out_fee: u256,
    mid_fee: u256,
    gamma_fee: u256,
    allowed_extra_profit: u256,
    adjustment_step: u256,
    ma_half_time: u256
  }

  struct ClaimAdminFees<phantom Curve, phantom LpCoin> has drop, copy {
    amount: u64
  }  

  public(friend) fun emit_new_2_pool<Curve, CoinA, CoinB, LpCoin>(id: ID) {
    emit(New2Pool<Curve, CoinA, CoinB, LpCoin> { pool_id: id });
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

  public(friend) fun emit_swap<Curve, CoinIn, CoinOut, LpCoin>(pool_id: ID, amount_in: u64, amount_out: u64) {
    emit(Swap<Curve, CoinIn, CoinOut, LpCoin>{ pool_id, amount_in, amount_out });
  }

  public(friend) fun emit_add_liquidity_2_pool<Curve, CoinA, CoinB, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    shares: u64
  ) {
    emit(AddLiquidity2Pool<Curve, CoinA, CoinB, LpCoin> { pool_id: id, amount_a, amount_b, shares });
  }  

  public(friend) fun emit_add_liquidity_3_pool<Curve, CoinA, CoinB, CoinC, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    shares: u64
  ) {
    emit(AddLiquidity3Pool<Curve, CoinA, CoinB, CoinC, LpCoin> { pool_id: id, amount_a, amount_b, amount_c, shares });
  }

  public(friend) fun emit_add_liquidity_4_pool<Curve, CoinA, CoinB, CoinC, CoinD, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    shares: u64
  ) {
    emit(AddLiquidity4Pool<Curve, CoinA, CoinB, CoinC, CoinD, LpCoin> { pool_id: id, amount_a, amount_b, amount_c, amount_d, shares });
  }

  public(friend) fun emit_add_liquidity_5_pool<Curve, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    amount_e: u64,
    shares: u64
  ) {
    emit(AddLiquidity5Pool<Curve, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin> { pool_id: id, amount_a, amount_b, amount_c, amount_d, amount_e, shares });
  }

  public(friend) fun emit_remove_liquidity<Curve, CoinType, LpCoin>(id: ID, amount: u64, shares: u64) {
    emit(RemoveLiquidity<Curve, CoinType, LpCoin> { pool_id: id, amount, shares });
  }

  public(friend) fun emit_remove_liquidity_2_pool<Curve, CoinA, CoinB,  LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    shares: u64
  ) {
    emit(RemoveLiquidity2Pool<Curve, CoinA, CoinB, LpCoin> { pool_id: id, amount_a, amount_b, shares });
  }  

  public(friend) fun emit_remove_liquidity_3_pool<Curve, CoinA, CoinB, CoinC, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    shares: u64
  ) {
    emit(RemoveLiquidity3Pool<Curve, CoinA, CoinB, CoinC, LpCoin> { pool_id: id, amount_a, amount_b, amount_c, shares });
  }

  public(friend) fun emit_remove_liquidity_4_pool<Curve, CoinA, CoinB, CoinC, CoinD, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    shares: u64
  ) {
    emit(RemoveLiquidity4Pool<Curve, CoinA, CoinB, CoinC, CoinD, LpCoin> { pool_id: id, amount_a, amount_b, amount_c, amount_d, shares });
  }

  public(friend) fun emit_remove_liquidity_5_pool<Curve, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    id: ID, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    amount_e: u64,
    shares: u64
  ) {
    emit(RemoveLiquidity5Pool<Curve, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin> { pool_id: id, amount_a, amount_b, amount_c, amount_d, amount_e, shares });
  }

  public(friend) fun emit_update_stable_fee<Curve, LpCoin>(
    pool_id: ID, 
    fee_in_percent: u256,
    fee_out_percent: u256, 
    admin_fee_percent: u256,     
  ) {
    emit(UpdateFee<Curve, LpCoin> { pool_id, fee_in_percent, fee_out_percent, admin_fee_percent });
  }

  public(friend) fun emit_take_fees<Curve, CoinType, LpCoin>(pool_id: ID, amount: u64) {
    emit(TakeFee<Curve, CoinType, LpCoin> { pool_id, amount });
  }

  public(friend) fun emit_claim_admin_fees<LpCoin>(amount: u64) {
    emit(ClaimAdminFees<Volatile, LpCoin> {  amount });
  }

  public(friend) fun emit_ramp_a<LpCoin>(
    pool_id: ID,
    initial_a: u256,
    future_a: u256,
    future_a_time: u256,
    timestamp: u64,
  ) {
    emit(RampA<LpCoin> {  pool_id, initial_a, future_a, future_a_time, timestamp });
  }

  public(friend) fun emit_stop_ramp_a<LpCoin>(pool_id: ID, a: u256, timestamp: u64) {
    emit(StopRampA<LpCoin> {  pool_id, a, timestamp });
  }

  public(friend) fun emit_ramp_a_gamma<LpCoin>(
    pool_id: ID,
    a: u256,
    gamma: u256,
    initial_time: u64,
    future_a: u256,
    future_gamma: u256,
    future_time: u64,
  ) {
    emit(RampAGamma<LpCoin> { pool_id, a, gamma, initial_time, future_a, future_gamma, future_time });
  }

  public(friend) fun emit_stop_ramp_a_gamma<LpCoin>(
    pool_id: ID,
    a: u256,
    gamma: u256,
    timestamp: u64
  ) {
    emit(StopRampAGamma<LpCoin> { pool_id, a, gamma, timestamp });
  }

  public(friend) fun emit_update_parameters<LpCoin>(
    pool_id: ID,
    admin_fee: u256,
    out_fee: u256,
    mid_fee: u256,
    gamma_fee: u256,
    allowed_extra_profit: u256,
    adjustment_step: u256,
    ma_half_time: u256    
  ) {
    emit(UpdateParameters<LpCoin> { 
      pool_id,
      admin_fee,
      out_fee,
      mid_fee,
      gamma_fee,
      allowed_extra_profit,
      adjustment_step,
      ma_half_time
    });
  }
} 