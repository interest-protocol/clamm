module amm::errors {

  public fun invalid_curve(): u64 {
    0
  }

  public fun same_coin_index(): u64 {
    1
  }

  public fun failed_to_converge(): u64 {
    2
  }

  public fun invalid_gamma(): u64 {
    3
  }

  public fun invalid_amplifier(): u64 {
    4
  }

  public fun unsafe_value(): u64 {
    5
  }

  public fun invalid_invariant(): u64 {
    6
  }  

  public fun invalid_one_time_witness(): u64 {
    7
  }
}