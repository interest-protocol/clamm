module amm::sum_pair_math {

  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18

  public fun invariant_(x: u64, y: u64): u256 {
    (x as u256) * (y as u256)
  }

  public fun calculate_amount_out(amount_in: u64, fee_percent: u256): u64 {
    ((amount_in as u256) - (((amount_in as u256) * fee_percent) / PRECISION) as u64)
  }
}