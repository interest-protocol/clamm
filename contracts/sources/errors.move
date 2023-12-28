module amm::errors {

  const INVALID_CURVE: u64 = 0;
  const SAME_COIN_INDEX: u64 = 1;
  const FAILED_TO_CONVERGE: u64 = 2;
  const INVALID_GAMMA: u64 = 3;
  const INVALID_AMPLIFIER: u64 = 4;
  const UNSAFE_VALUE: u64 = 5;
  const INVALID_INVARIANT: u64 = 6;
  const SUPPLY_MUST_HAVE_ZERO_VALUE: u64 = 7;
  const CANNOT_CREATE_EMPTY_POOL: u64 = 8;
  const CANNOT_SWAP_ZERO_VALUE: u64 = 9;
  const SLIPPAGE: u64 = 10;
  const INVALID_FEE: u64 = 11;
  const NO_ZERO_LIQUIDITY_AMOUNTS: u64 = 12;
  const NO_ZERO_COIN: u64 = 13;
  const MUST_BE_3_POOL: u64 = 14;
  const MUST_BE_4_POOL: u64 = 15;
  const MUST_BE_5_POOL: u64 = 16;
  const VALUE_OVER_FLOW: u64 = 17;
  const VECTOR_TOO_BIG_TO_PACK: u64 = 18;
  const MUST_HAVE_3_VALUES: u64 = 19;
  const WRONG_CONFIGURATION: u64 = 20;
  const COINS_MUST_BE_IN_ORDER: u64 = 21;
  const EXPECTED_A_NON_ZERO_VALUE: u64 = 22;
  const INCURRED_A_LOSS: u64 = 23;
  const INVALID_COIN_TYPE: u64 = 24;
  const MUST_HAVE_9_DECIMALS: u64 = 25;
  const WAIT_ONE_DAY: u64 = 26;
  const VALUE_OUT_OF_RANGE: u64 = 27;
  const MUST_SUPPLY_ONE_COIN: u64 = 28;
  const CANNOT_SWAP_SAME_COIN: u64 = 29;
  const FUTURE_TAMP_TIME_IS_TOO_SHORT: u64 = 30;
  
  public fun invalid_curve(): u64 {
    INVALID_CURVE
  }

  public fun same_coin_index(): u64 {
    SAME_COIN_INDEX
  }

  public fun failed_to_converge(): u64 {
    FAILED_TO_CONVERGE
  }

  public fun invalid_gamma(): u64 {
    INVALID_GAMMA
  }

  public fun invalid_amplifier(): u64 {
    INVALID_AMPLIFIER
  }

  public fun unsafe_value(): u64 {
    UNSAFE_VALUE
  }

  public fun invalid_invariant(): u64 {
    INVALID_INVARIANT
  }  
  
  public fun supply_must_have_zero_value(): u64 {
    SUPPLY_MUST_HAVE_ZERO_VALUE
  }

  public fun cannot_create_empty_pool(): u64 {
    CANNOT_CREATE_EMPTY_POOL
  }

  public fun cannot_swap_zero_value(): u64 {
    CANNOT_SWAP_ZERO_VALUE
  }

  public fun slippage(): u64 {
    SLIPPAGE
  }

  public fun invalid_fee(): u64 {
    INVALID_FEE
  }

  public fun no_zero_liquidity_amounts(): u64 {
    NO_ZERO_LIQUIDITY_AMOUNTS
  }

  public fun no_zero_coin(): u64 {
    NO_ZERO_COIN
  }

  public fun must_be_3_pool(): u64 {
    MUST_BE_3_POOL
  }

  public fun must_be_4_pool(): u64 {
    MUST_BE_4_POOL
  }

  public fun must_be_5_pool(): u64 {
    MUST_BE_5_POOL
  }

  public fun value_overflow(): u64 {
    VALUE_OVER_FLOW
  }

  public fun vector_too_big_to_pack(): u64 {
    VECTOR_TOO_BIG_TO_PACK
  }

  public fun must_have_3_values(): u64 {
    MUST_HAVE_3_VALUES
  }

  public fun wrong_configuration(): u64 {
    WRONG_CONFIGURATION
  }

  public fun coins_must_be_in_order(): u64 {
    COINS_MUST_BE_IN_ORDER
  }

  public fun expected_a_non_zero_value(): u64 {
    EXPECTED_A_NON_ZERO_VALUE
  }

  public fun incurred_a_loss(): u64 {
    INCURRED_A_LOSS
  }

  public fun invalid_coin_type(): u64 {
    INVALID_COIN_TYPE
  }

  public fun must_have_9_decimals(): u64 {
    MUST_HAVE_9_DECIMALS
  }

  public fun wait_one_day(): u64 {
    WAIT_ONE_DAY
  }

  public fun value_out_of_range(): u64 {
    VALUE_OUT_OF_RANGE
  }

  public fun must_supply_one_coin(): u64 {
    MUST_SUPPLY_ONE_COIN
  }

  public fun cannot_swap_same_coin(): u64 {
    CANNOT_SWAP_SAME_COIN
  }

  public fun future_ramp_time_is_too_short(): u64 {
    FUTURE_TAMP_TIME_IS_TOO_SHORT
  }
}