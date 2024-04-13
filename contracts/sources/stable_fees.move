module clamm::stable_fees {
  // === Imports ===

  use suitears::fixed_point_wad::mul_up;

  use clamm::errors;

  // === Constants ===

  const INITIAL_FEE_PERCENT: u256 = 250000000000000; // 0.025%
  const MAX_FEE_PERCENT: u256 = 20000000000000000; // 2%
  const MAX_ADMIN_FEE: u256 = 200000000000000000; // 20%  

  // === Structs ===

  public struct StableFees has store, copy, drop {
    fee_in_percent: u256,
    fee_out_percent: u256, 
    admin_fee_percent: u256,     
  }

  // === Public-Mutative Functions ===

  public fun new(): StableFees {
    StableFees {
      fee_in_percent: INITIAL_FEE_PERCENT,
      fee_out_percent: INITIAL_FEE_PERCENT,
      admin_fee_percent: 0
    }
  }

  public fun update_fee_in_percent(fee: &mut StableFees, mut fee_in_percent: Option<u256>) {
    if (option::is_none(&fee_in_percent)) return;
    let fee_in_percent = fee_in_percent.extract();
    
    assert!(MAX_FEE_PERCENT >= fee_in_percent, errors::invalid_fee());
    fee.fee_in_percent = fee_in_percent;
  }

  public fun update_fee_out_percent(fee: &mut StableFees, mut fee_out_percent: Option<u256>) {
    if (option::is_none(&fee_out_percent)) return;
    let fee_out_percent = fee_out_percent.extract();
    
    assert!(MAX_FEE_PERCENT >= fee_out_percent, errors::invalid_fee());
    fee.fee_out_percent = fee_out_percent;
  }

  public fun update_admin_fee_percent(fee: &mut StableFees, mut admin_fee_percent: Option<u256>) {
    if (option::is_none(&admin_fee_percent)) return;
    let admin_fee_percent = admin_fee_percent.extract();

    assert!(MAX_ADMIN_FEE >= admin_fee_percent, errors::invalid_fee());
    fee.admin_fee_percent = admin_fee_percent;
  }

  // === Public-View Functions ===

  public fun fee_in_percent(fees: &StableFees): u256 {
    fees.fee_in_percent
  }

  public fun fee_out_percent(fees: &StableFees): u256 {
    fees.fee_out_percent
  }

  public fun admin_fee_percent(fees: &StableFees): u256 {
    fees.admin_fee_percent
  }

  public fun calculate_fee_in_amount(fees: &StableFees, amount: u64): u64 {
    calculate_fee_amount(amount, fees.fee_in_percent)
  }

  public fun calculate_fee_out_amount(fees: &StableFees, amount: u64): u64 {
    calculate_fee_amount(amount, fees.fee_out_percent)
  }

  public fun calculate_admin_amount(fees: &StableFees, amount: u64): u64 {
    calculate_fee_amount(amount, fees.admin_fee_percent)
  }

  // === Private Functions ===

  fun calculate_fee_amount(x: u64, percent: u256): u64 {
    (mul_up((x as u256), percent) as u64)
  }
}