module amm::utils {
  use std::type_name::get;

  public fun are_types_equal<A, B>(): bool {
    get<A>() == get<B>()
  }

  public fun remove_fee(amount: u256, fee_percent: u256, fee_precision: u256): u256 {
    amount - ((amount * fee_percent) / fee_precision)
  }
}