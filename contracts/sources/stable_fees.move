module clamm::stable_fees {
  // === Imports ===

  use suitears::math256::mul_div_up;

  use clamm::errors;

  // === Constants ===

  const PRECISION: u256 = 1_000_000_000_000_000_000;
  const INITIAL_FEE_PERCENT: u256 = 500000000000000; // 0.05%
  const MAX_FEE_PERCENT: u256 = 20000000000000000; // 2%
  const MAX_ADMIN_FEE: u256 = 200000000000000000; // 20%  
  const UPDATE_DELAY: u64 = 3; // 3 epochs

  // === Structs ===

  public struct StableFees has store, copy, drop {
    fee: u256,
    admin_fee: u256,     
    future_fee: Option<u256>,
    future_admin_fee: Option<u256>,
    // epoch
    deadline: u64
  }

  // === Public-Mutative Functions ===

  public fun new(): StableFees {
    StableFees {
      fee: INITIAL_FEE_PERCENT,
      admin_fee: MAX_ADMIN_FEE,
      future_fee: option::none(),
      future_admin_fee: option::none(),
      deadline: 0
    }
  }

  public fun commit_fee(self: &mut StableFees, fee: Option<u256>, ctx: &mut TxContext) {
    if (fee.is_none()) return;
  
    assert!(MAX_FEE_PERCENT >= *fee.borrow(), errors::invalid_fee());

    self.update_deadline(ctx);
    self.future_fee = fee;
  }

  public fun update_fee(self: &mut StableFees, ctx: &mut TxContext) {
    if (self.future_fee.is_none()) return;
    
    self.assert_epoch(ctx);

    self.fee = self.future_fee.extract();
  }

  public fun commit_admin_fee(self: &mut StableFees, fee: Option<u256>, ctx: &mut TxContext) {
    if (fee.is_none()) return;
    
    assert!(MAX_ADMIN_FEE >= *fee.borrow(), errors::invalid_fee());
    
    self.update_deadline(ctx);
    self.future_admin_fee = fee;
  }

  public fun update_admin_fee(self: &mut StableFees, ctx: &mut TxContext) {
    if (self.future_admin_fee.is_none()) return;

    self.assert_epoch(ctx);

    self.admin_fee = self.future_admin_fee.extract();
  }

  // === Public-View Functions ===

  public fun fee(self: &StableFees): u256 {
    self.fee
  }

  public fun future_fee(self: &StableFees): Option<u256> {
    self.future_fee
  }

  public fun admin_fee(self: &StableFees): u256 {
    self.admin_fee
  }

  public fun future_admin_fee(self: &StableFees): Option<u256> {
    self.future_admin_fee
  }

  public fun deadline(self: &StableFees): u64 {
    self.deadline
  }

  public fun calculate_fee(self: &StableFees, amount: u256): u256 {
    calculate_fee_amount(amount, self.fee)
  }

  public fun calculate_admin_fee(fees: &StableFees, amount: u256): u256 {
    calculate_fee_amount(amount, fees.admin_fee)
  }

  // === Private Functions ===

  fun assert_epoch(self: &StableFees, ctx: &TxContext) {
    assert!(ctx.epoch() > self.deadline, errors::must_wait_update_fees());
  }

  fun update_deadline(self: &mut StableFees, ctx: &TxContext) {
    self.deadline = ctx.epoch() + UPDATE_DELAY;
  }

  fun calculate_fee_amount(x: u256, percent: u256): u256 {
    mul_div_up(x, percent, PRECISION)
  }
}