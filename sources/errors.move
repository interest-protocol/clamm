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

  public fun supply_must_have_zero_value(): u64 {
    8
  }

  public fun cannot_create_empty_pool(): u64 {
    9
  }

  public fun cannot_swap_zero_value(): u64 {
    10
  }

  public fun slippage(): u64 {
    11
  }

  public fun invalid_fee(): u64 {
    12
  }

  public fun no_zero_liquidity_amounts(): u64 {
    13
  }
}