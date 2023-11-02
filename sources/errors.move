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

  public fun no_zero_coin(): u64 {
    14
  }

  public fun must_be_3_pool(): u64 {
    15
  }

  public fun must_be_4_pool(): u64 {
    16
  }

  public fun must_be_5_pool(): u64 {
    17
  }

  public fun value_overflow(): u64 {
    18
  }

  public fun vector_too_big_to_pack(): u64 {
    19
  }

  public fun must_have_3_values(): u64 {
    20
  }

  public fun wrong_configuration(): u64 {
    21
  }

  public fun coins_must_be_in_order(): u64 {
    22
  }

  public fun expected_a_non_zero_value(): u64 {
    24
  }

  public fun incurred_a_loss(): u64 {
    25
  }

  public fun invalid_coin_type(): u64 {
    26
  }

  public fun must_have_9_decimals(): u64 {
    27
  }
}