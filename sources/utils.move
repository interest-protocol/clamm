module amm::utils {
  use suitears::fixed_point_ray::ray_mul_up;

  public fun calculate_fee_amount(x: u64, percent: u256): u64 {
    (ray_mul_up((x as u256), percent) as u64)
  }
}