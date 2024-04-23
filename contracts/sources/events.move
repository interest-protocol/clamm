module clamm::pool_events {
  // === Imports ===

  use sui::event::emit;

  use clamm::curves::Volatile;

  // === Structs ===

  public struct New2Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom LpCoin> has drop, copy {
    pool: address
  }

  public struct New3Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom LpCoin> has copy, drop {
    pool: address
  }

  public struct New4Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom LpCoin> has copy, drop {
    pool: address
  }

  public struct New5Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom CoinE, phantom LpCoin> has copy, drop {
    pool: address
  }

  public struct AddLiquidity2Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom LpCoin> has copy, drop {
    pool: address,
    amount_a: u64,
    amount_b: u64,
    shares: u64
  }

  public struct AddLiquidity3Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom LpCoin> has copy, drop {
    pool: address,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    shares: u64
  }

  public struct AddLiquidity4Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom LpCoin> has copy, drop {
    pool: address,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    shares: u64
  }

  public struct AddLiquidity5Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom CoinE, phantom LpCoin> has copy, drop {
    pool: address,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    amount_e: u64,
    shares: u64
  }

  public struct Swap<phantom Curve, phantom CoinIn, phantom CoinOut, phantom LpCoin> has drop, copy {
    pool: address,
    amount_in: u64,
    amount_out: u64
  }

  public struct RemoveLiquidity<phantom Curve, phantom CoinType, phantom LpCoin> has copy, drop {
    pool: address,
    amount: u64,
    shares: u64
  }

  public struct RemoveLiquidity2Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom LpCoin> has copy, drop {
    pool: address,
    amount_a: u64,
    amount_b: u64,
    shares: u64
  }  

  public struct RemoveLiquidity3Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom LpCoin> has copy, drop {
    pool: address,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    shares: u64
  }

  public struct RemoveLiquidity4Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom LpCoin> has copy, drop {
    pool: address,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    shares: u64
  }

  public struct RemoveLiquidity5Pool<phantom Curve, phantom CoinA, phantom CoinB, phantom CoinC, phantom CoinD, phantom CoinE, phantom LpCoin> has copy, drop {
    pool: address,
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    amount_e: u64,
    shares: u64
  }

  public struct UpdateFee<phantom Curve, phantom LpCoin> has copy, drop {
    pool: address,
    fee_in_percent: u256,
    fee_out_percent: u256, 
    admin_fee_percent: u256,     
  }

  public struct TakeFee<phantom Curve, phantom CoinType, phantom LpCoin> has copy, drop {
    pool: address,
    amount: u64
  }

  public struct RampA<phantom LpCoin> has drop, copy {
    pool: address,
    initial_a: u256,
    future_a: u256,
    future_a_time: u256,
    timestamp: u64,
  }

  public struct StopRampA<phantom LpCoin> has drop, copy {
    pool: address,
    a: u256,
    timestamp: u64
  }

  public struct RampAGamma<phantom LpCoin> has drop, copy {
    pool: address,
    a: u256,
    gamma: u256,
    initial_time: u64,
    future_a: u256,
    future_gamma: u256,
    future_time: u64
  }

  public struct StopRampAGamma<phantom LpCoin> has drop, copy {
    pool: address,
    a: u256,
    gamma: u256,
    timestamp: u64,
  }

  public struct UpdateParameters<phantom LpCoin> has drop, copy {
    pool: address,
    admin_fee: u256,
    out_fee: u256,
    mid_fee: u256,
    gamma_fee: u256,
    allowed_extra_profit: u256,
    adjustment_step: u256,
    ma_half_time: u256
  }

  public struct ClaimAdminFees<phantom Curve, phantom LpCoin> has drop, copy {
    amount: u64
  }  

  public struct Donate<phantom Curve, phantom CoinType, phantom LpCoin> has copy, drop {
    pool: address,
    amount: u64
  }

  // === Public-Package Functions ===

  public(package) fun emit_new_2_pool<Curve, CoinA, CoinB, LpCoin>(id: address) {
    emit(New2Pool<Curve, CoinA, CoinB, LpCoin> { pool: id });
  }

  public(package) fun emit_new_3_pool<Curve, CoinA, CoinB, CoinC, LpCoin>(id: address) {
    emit(New3Pool<Curve, CoinA, CoinB, CoinC, LpCoin> { pool: id });
  }

  public(package) fun emit_new_4_pool<Curve, CoinA, CoinB, CoinC, CoinD, LpCoin>(id: address) {
    emit(New4Pool<Curve, CoinA, CoinB, CoinC, CoinD, LpCoin> { pool: id });
  }

  public(package) fun emit_new_5_pool<Curve, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(id: address) {
    emit(New5Pool<Curve, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin> { pool: id });
  }

  public(package) fun emit_swap<Curve, CoinIn, CoinOut, LpCoin>(pool: address, amount_in: u64, amount_out: u64) {
    emit(Swap<Curve, CoinIn, CoinOut, LpCoin>{ pool, amount_in, amount_out });
  }

  public(package) fun emit_add_liquidity_2_pool<Curve, CoinA, CoinB, LpCoin>(
    id: address, 
    amount_a: u64,
    amount_b: u64,
    shares: u64
  ) {
    emit(AddLiquidity2Pool<Curve, CoinA, CoinB, LpCoin> { pool: id, amount_a, amount_b, shares });
  }  

  public(package) fun emit_add_liquidity_3_pool<Curve, CoinA, CoinB, CoinC, LpCoin>(
    id: address, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    shares: u64
  ) {
    emit(AddLiquidity3Pool<Curve, CoinA, CoinB, CoinC, LpCoin> { pool: id, amount_a, amount_b, amount_c, shares });
  }

  public(package) fun emit_add_liquidity_4_pool<Curve, CoinA, CoinB, CoinC, CoinD, LpCoin>(
    id: address, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    shares: u64
  ) {
    emit(AddLiquidity4Pool<Curve, CoinA, CoinB, CoinC, CoinD, LpCoin> { pool: id, amount_a, amount_b, amount_c, amount_d, shares });
  }

  public(package) fun emit_add_liquidity_5_pool<Curve, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    id: address, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    amount_e: u64,
    shares: u64
  ) {
    emit(AddLiquidity5Pool<Curve, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin> { pool: id, amount_a, amount_b, amount_c, amount_d, amount_e, shares });
  }

  public(package) fun emit_remove_liquidity<Curve, CoinType, LpCoin>(id: address, amount: u64, shares: u64) {
    emit(RemoveLiquidity<Curve, CoinType, LpCoin> { pool: id, amount, shares });
  }

  public(package) fun emit_remove_liquidity_2_pool<Curve, CoinA, CoinB,  LpCoin>(
    id: address, 
    amount_a: u64,
    amount_b: u64,
    shares: u64
  ) {
    emit(RemoveLiquidity2Pool<Curve, CoinA, CoinB, LpCoin> { pool: id, amount_a, amount_b, shares });
  }  

  public(package) fun emit_remove_liquidity_3_pool<Curve, CoinA, CoinB, CoinC, LpCoin>(
    id: address, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    shares: u64
  ) {
    emit(RemoveLiquidity3Pool<Curve, CoinA, CoinB, CoinC, LpCoin> { pool: id, amount_a, amount_b, amount_c, shares });
  }

  public(package) fun emit_remove_liquidity_4_pool<Curve, CoinA, CoinB, CoinC, CoinD, LpCoin>(
    id: address, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    shares: u64
  ) {
    emit(RemoveLiquidity4Pool<Curve, CoinA, CoinB, CoinC, CoinD, LpCoin> { pool: id, amount_a, amount_b, amount_c, amount_d, shares });
  }

  public(package) fun emit_remove_liquidity_5_pool<Curve, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    id: address, 
    amount_a: u64,
    amount_b: u64,
    amount_c: u64,
    amount_d: u64,
    amount_e: u64,
    shares: u64
  ) {
    emit(RemoveLiquidity5Pool<Curve, CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin> { pool: id, amount_a, amount_b, amount_c, amount_d, amount_e, shares });
  }

  public(package) fun emit_update_stable_fee<Curve, LpCoin>(
    pool: address, 
    fee_in_percent: u256,
    fee_out_percent: u256, 
    admin_fee_percent: u256,     
  ) {
    emit(UpdateFee<Curve, LpCoin> { pool, fee_in_percent, fee_out_percent, admin_fee_percent });
  }

  public(package) fun emit_take_fees<Curve, CoinType, LpCoin>(pool: address, amount: u64) {
    emit(TakeFee<Curve, CoinType, LpCoin> { pool, amount });
  }

  public(package) fun emit_claim_admin_fees<LpCoin>(amount: u64) {
    emit(ClaimAdminFees<Volatile, LpCoin> {  amount });
  }

  public(package) fun emit_ramp_a<LpCoin>(
    pool: address,
    initial_a: u256,
    future_a: u256,
    future_a_time: u256,
    timestamp: u64,
  ) {
    emit(RampA<LpCoin> {  pool, initial_a, future_a, future_a_time, timestamp });
  }

  public(package) fun emit_stop_ramp_a<LpCoin>(pool: address, a: u256, timestamp: u64) {
    emit(StopRampA<LpCoin> {  pool, a, timestamp });
  }

  public(package) fun emit_ramp_a_gamma<LpCoin>(
    pool: address,
    a: u256,
    gamma: u256,
    initial_time: u64,
    future_a: u256,
    future_gamma: u256,
    future_time: u64,
  ) {
    emit(RampAGamma<LpCoin> { pool, a, gamma, initial_time, future_a, future_gamma, future_time });
  }

  public(package) fun emit_stop_ramp_a_gamma<LpCoin>(
    pool: address,
    a: u256,
    gamma: u256,
    timestamp: u64
  ) {
    emit(StopRampAGamma<LpCoin> { pool, a, gamma, timestamp });
  }

  public(package) fun emit_update_parameters<LpCoin>(
    pool: address,
    admin_fee: u256,
    out_fee: u256,
    mid_fee: u256,
    gamma_fee: u256,
    allowed_extra_profit: u256,
    adjustment_step: u256,
    ma_half_time: u256    
  ) {
    emit(UpdateParameters<LpCoin> { 
      pool,
      admin_fee,
      out_fee,
      mid_fee,
      gamma_fee,
      allowed_extra_profit,
      adjustment_step,
      ma_half_time
    });
  }

  public(package) fun emit_donate<Curve, CoinType, LpCoin>(pool: address, amount: u64) {
    emit(Donate<Curve, CoinType, LpCoin> { pool, amount });
  }
} 