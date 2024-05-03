module clamm::pool_events {
  // === Imports ===
  use std::type_name::TypeName;

  use sui::event::emit;

  use clamm::curves::Volatile;

  // === Structs ===

  public struct NewPool<phantom Curve, phantom LpCoin> has drop, copy {
    pool: address,
    coins: vector<TypeName>
  }

  public struct AddLiquidity<phantom Curve, phantom LpCoin> has copy, drop {
    pool: address,
    coins: vector<TypeName>,
    amounts: vector<u64>,
    shares: u64
  }

  public struct Swap<phantom Curve, phantom CoinIn, phantom CoinOut, phantom LpCoin> has drop, copy {
    pool: address,
    amount_in: u64,
    amount_out: u64
  }

  public struct RemoveLiquidity<phantom Curve, phantom LpCoin> has copy, drop {
    pool: address,
    coins: vector<TypeName>,
    amounts: vector<u64>,
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

  public(package) fun new_pool<Curve, LpCoin>(pool: address, coins: vector<TypeName>) {
    emit(NewPool<Curve, LpCoin> { pool, coins });
  }

  public(package) fun swap<Curve, CoinIn, CoinOut, LpCoin>(pool: address, amount_in: u64, amount_out: u64) {
    emit(Swap<Curve, CoinIn, CoinOut, LpCoin>{ pool, amount_in, amount_out });
  }

  public(package) fun add_liquidity<Curve, LpCoin>(
    pool: address,
    coins: vector<TypeName>,
    amounts: vector<u64>,
    shares: u64
  ) {
    emit(AddLiquidity<Curve, LpCoin> { pool, coins, amounts, shares });
  }  

  public(package) fun remove_liquidity<Curve, LpCoin>(
    pool: address,
    coins: vector<TypeName>,
    amounts: vector<u64>,
    shares: u64    
  ) {
    emit(RemoveLiquidity<Curve, LpCoin> { pool, coins, amounts, shares });
  }

  public(package) fun update_stable_fee<Curve, LpCoin>(
    pool: address, 
    fee_in_percent: u256,
    fee_out_percent: u256, 
    admin_fee_percent: u256,     
  ) {
    emit(UpdateFee<Curve, LpCoin> { pool, fee_in_percent, fee_out_percent, admin_fee_percent });
  }

  public(package) fun take_fees<Curve, CoinType, LpCoin>(pool: address, amount: u64) {
    emit(TakeFee<Curve, CoinType, LpCoin> { pool, amount });
  }

  public(package) fun claim_admin_fees<LpCoin>(amount: u64) {
    emit(ClaimAdminFees<Volatile, LpCoin> {  amount });
  }

  public(package) fun ramp_a<LpCoin>(
    pool: address,
    initial_a: u256,
    future_a: u256,
    future_a_time: u256,
    timestamp: u64,
  ) {
    emit(RampA<LpCoin> {  pool, initial_a, future_a, future_a_time, timestamp });
  }

  public(package) fun stop_ramp_a<LpCoin>(pool: address, a: u256, timestamp: u64) {
    emit(StopRampA<LpCoin> {  pool, a, timestamp });
  }

  public(package) fun ramp_a_gamma<LpCoin>(
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

  public(package) fun stop_ramp_a_gamma<LpCoin>(
    pool: address,
    a: u256,
    gamma: u256,
    timestamp: u64
  ) {
    emit(StopRampAGamma<LpCoin> { pool, a, gamma, timestamp });
  }

  public(package) fun update_parameters<LpCoin>(
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

  public(package) fun donate<Curve, CoinType, LpCoin>(pool: address, amount: u64) {
    emit(Donate<Curve, CoinType, LpCoin> { pool, amount });
  }
} 