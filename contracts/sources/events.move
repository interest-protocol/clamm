module clamm::pool_events {
  // === Imports ===
  use std::type_name::TypeName;

  use sui::event::emit;

  // === Structs ===

  public struct NewPool has drop, copy {
    pool: address,
    coins: vector<TypeName>,
    lpCoin: TypeName,
    isStable: bool
  }

  public struct Swap has drop, copy {
    pool: address, 
    coinIn: TypeName,
    coinOut: TypeName,    
    amount_in: u64, 
    amount_out: u64,
    fee: u64
  }

  public struct AddLiquidity has copy, drop {
    pool: address,
    coins: vector<TypeName>,  
    amounts: vector<u64>,
    shares: u64
  }

  public struct RemoveLiquidity has copy, drop {
    pool: address,
    coins: vector<TypeName>,
    amounts: vector<u64>,
    shares: u64
  }

  public struct CommitFee has copy, drop {
    pool: address,
    future_fee: Option<u256>,
    future_admin_fee: Option<u256>,     
  }

  public struct UpdateFee has copy, drop {
    pool: address,
    fee: u256,
    admin_fee: u256,     
  }

  public struct TakeFee has copy, drop {
    pool: address,
    coin: TypeName,
    amount: u64
  }

  public struct RampA has drop, copy {
    pool: address,
    initial_a: u256,
    future_a: u256,
    future_a_time: u256,
    timestamp: u64,
  }

  public struct StopRampA has drop, copy {
    pool: address,
    a: u256,
    timestamp: u64
  }

  public struct RampAGamma has drop, copy {
    pool: address,
    a: u256,
    gamma: u256,
    initial_time: u64,
    future_a: u256,
    future_gamma: u256,
    future_time: u64
  }

  public struct StopRampAGamma has drop, copy {
    pool: address,
    a: u256,
    gamma: u256,
    timestamp: u64,
  }

  public struct CommitParameters has drop, copy {
    pool: address,
    admin_fee: u256,
    out_fee: u256,
    mid_fee: u256,
    gamma_fee: u256,
    allowed_extra_profit: u256,
    adjustment_step: u256,
    ma_half_time: u256
  }

  public struct UpdateParameters has drop, copy {
    pool: address,
    admin_fee: u256,
    out_fee: u256,
    mid_fee: u256,
    gamma_fee: u256,
    allowed_extra_profit: u256,
    adjustment_step: u256,
    ma_half_time: u256
  }

  public struct ClaimAdminFees has drop, copy {
    pool: address,
    coin: TypeName,
    amount: u64
  }  

  public struct Donate has copy, drop {
    pool: address,
    coin: TypeName,
    amount: u64
  }

  public struct Pause has copy, drop {
    pool: address
  }

  public struct UnPause has copy, drop {
    pool: address
  }

  // === Public-Package Functions ===

  public(package) fun new_pool(
    pool: address, 
    coins: vector<TypeName>,
    lpCoin: TypeName,
    isStable: bool
  ) {
    emit(NewPool { pool, coins, lpCoin, isStable });
  }

  public(package) fun swap(
    pool: address, 
    coinIn: TypeName,
    coinOut: TypeName,    
    amount_in: u64, 
    amount_out: u64,
    fee: u64
  ) {
    emit(Swap { pool, coinIn, coinOut, amount_in, amount_out, fee });
  }

  public(package) fun add_liquidity(
    pool: address,
    coins: vector<TypeName>,  
    amounts: vector<u64>,
    shares: u64
  ) {
    emit(AddLiquidity { pool, coins, amounts, shares });
  }  

  public(package) fun remove_liquidity(
    pool: address,
    coins: vector<TypeName>,
    amounts: vector<u64>,
    shares: u64    
  ) {
    emit(RemoveLiquidity { pool, coins, amounts, shares });
  }

  public(package) fun commit_stable_fee(
    pool: address,
    future_fee: Option<u256>,
    future_admin_fee: Option<u256>
  ) {
    emit(CommitFee { pool, future_fee, future_admin_fee });
  }

  public(package) fun update_stable_fee(
    pool: address, 
    fee: u256,
    admin_fee: u256,     
  ) {
    emit(UpdateFee { pool, fee, admin_fee });
  }

  public(package) fun take_fees(pool: address, coin: TypeName, amount: u64) {
    emit(TakeFee { pool, coin, amount });
  }

  public(package) fun claim_admin_fees( pool: address, coin: TypeName, amount: u64) {
    emit(ClaimAdminFees{ pool, coin, amount });
  }

  public(package) fun ramp_a(
    pool: address,
    initial_a: u256,
    future_a: u256,
    future_a_time: u256,
    timestamp: u64,
  ) {
    emit(RampA {  pool, initial_a, future_a, future_a_time, timestamp });
  }

  public(package) fun stop_ramp_a(pool: address, a: u256, timestamp: u64) {
    emit(StopRampA {  pool, a, timestamp });
  }

  public(package) fun ramp_a_gamma(
    pool: address,
    a: u256,
    gamma: u256,
    initial_time: u64,
    future_a: u256,
    future_gamma: u256,
    future_time: u64,
  ) {
    emit(RampAGamma { pool, a, gamma, initial_time, future_a, future_gamma, future_time });
  }

  public(package) fun stop_ramp_a_gamma(
    pool: address,
    a: u256,
    gamma: u256,
    timestamp: u64
  ) {
    emit(StopRampAGamma { pool, a, gamma, timestamp });
  }

  public(package) fun commit_parameters(
    pool: address,
    admin_fee: u256,
    out_fee: u256,
    mid_fee: u256,
    gamma_fee: u256,
    allowed_extra_profit: u256,
    adjustment_step: u256,
    ma_half_time: u256    
  ) {
    emit(CommitParameters { 
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

  public(package) fun update_parameters(
    pool: address,
    admin_fee: u256,
    out_fee: u256,
    mid_fee: u256,
    gamma_fee: u256,
    allowed_extra_profit: u256,
    adjustment_step: u256,
    ma_half_time: u256    
  ) {
    emit(UpdateParameters { 
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

  public(package) fun donate(pool: address, coin: TypeName, amount: u64) {
    emit(Donate { pool, coin, amount });
  }

  public(package) fun pause(pool: address) {
    emit(Pause { pool });
  }

  public(package) fun unpause(pool: address) {
    emit(UnPause { pool });
  }
} 