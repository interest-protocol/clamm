module clamm::errors {
  // === Constants ===

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
  const FUTURE_RAMP_TIME_IS_TOO_SHORT: u64 = 30;
  const FUTURE_A_IS_TOO_SMALL: u64 = 31;
  const FUTURE_A_IS_TOO_BIG: u64 = 32;
  const FUTURE_GAMMA_IS_TOO_SMALL: u64 = 33;
  const FUTURE_GAMMA_IS_TOO_BIG: u64 = 34;
  const FUTURE_A_CHANGE_IS_TOO_SMALL: u64 = 35;
  const FUTURE_A_CHANGE_IS_TOO_BIG: u64 = 36;
  const FUTURE_GAMMA_CHANGE_IS_TOO_SMALL: u64 = 37;
  const FUTURE_GAMMA_CHANGE_IS_TOO_BIG: u64 = 38;
  const OUT_FEE_OUT_OF_RANGE: u64 = 39;
  const MID_FEE_OUT_OF_RANGE: u64 = 40;
  const ADMIN_FEE_IS_TOO_BIG: u64 = 41;
  const GAMMA_FEE_OUT_OF_RANGE: u64 = 42;
  const EXTRA_PROFIT_IS_TOO_BIG: u64 = 43;
  const ADJUSTMENT_STEP_IS_TOO_BIG: u64 = 44;
  const MA_HALF_TIME_OUT_OF_RANGE: u64 = 45;
  const MISSING_COIN_BALANCE: u64 = 46;
  const VERSION_WAS_UPDATED: u64 = 47;
  const WRONG_POOL_ID: u64 = 48;
  const INVALID_VERSION: u64 = 49;
  const MUST_WAIT_TO_UPDATE_PARAMETERS: u64 = 50;
  const WRONG_HOOKS_BUILDER_POOL: u64 = 51;
  const RULE_NOT_ADDED: u64 = 52;
  const WRONG_REQUEST_POOL_ADDRESS: u64 = 53;
  const RULE_NOT_APPROVED: u64 = 54;
  const POOL_HAS_HOOKS: u64 = 55;
  const POOL_HAS_NO_HOOKS: u64 = 56;
  const POOL_HAS_NO_SWAP_HOOKS: u64 = 57;
  const POOL_HAS_NO_ADD_LIQUIDITY_HOOKS: u64 = 58;
  const POOL_HAS_NO_REMOVE_LIQUIDITY_HOOKS: u64 = 59;
  const POOL_HAS_NO_DONATE_HOOKS: u64 = 60;
  const MUST_BE_START_SWAP_REQUEST: u64 = 61;
  const MUST_BE_START_ADD_LIQUIDITY_REQUEST: u64 = 62;
  const MUST_BE_START_REMOVE_LIQUIDITY_REQUEST: u64 = 63;
  const MUST_BE_START_DONATE_REQUEST: u64 = 64;
  const MUST_BE_FINISH_REQUEST: u64 = 65;
  const MUST_WAIT_TO_UPDATE_FEES: u64 = 66;
  const POOL_IS_PAUSED: u64 = 67;
  const PAUSE_PERIOD_HAS_PASSED: u64 = 68;
  const INVALID_STABLE_FEE_AMOUNT: u64 = 69;
  const COMMIT_TO_UPDATE_FEES_FIRST: u64 = 70;
  const CURRENT_UPDATE_IS_ONGOING: u64 = 71;


  // === Public-View Functions ===

  public(package) fun invalid_curve(): u64 {
    INVALID_CURVE
  }

  public(package) fun same_coin_index(): u64 {
    SAME_COIN_INDEX
  }

  public(package) fun failed_to_converge(): u64 {
    FAILED_TO_CONVERGE
  }

  public(package) fun invalid_gamma(): u64 {
    INVALID_GAMMA
  }

  public(package) fun invalid_amplifier(): u64 {
    INVALID_AMPLIFIER
  }

  public(package) fun unsafe_value(): u64 {
    UNSAFE_VALUE
  }

  public(package) fun invalid_invariant(): u64 {
    INVALID_INVARIANT
  }  
  
  public(package) fun supply_must_have_zero_value(): u64 {
    SUPPLY_MUST_HAVE_ZERO_VALUE
  }

  public(package) fun cannot_create_empty_pool(): u64 {
    CANNOT_CREATE_EMPTY_POOL
  }

  public(package) fun cannot_swap_zero_value(): u64 {
    CANNOT_SWAP_ZERO_VALUE
  }

  public(package) fun slippage(): u64 {
    SLIPPAGE
  }

  public(package) fun invalid_fee(): u64 {
    INVALID_FEE
  }

  public(package) fun no_zero_liquidity_amounts(): u64 {
    NO_ZERO_LIQUIDITY_AMOUNTS
  }

  public(package) fun no_zero_coin(): u64 {
    NO_ZERO_COIN
  }

  public(package) fun must_be_3_pool(): u64 {
    MUST_BE_3_POOL
  }

  public(package) fun must_be_4_pool(): u64 {
    MUST_BE_4_POOL
  }

  public(package) fun must_be_5_pool(): u64 {
    MUST_BE_5_POOL
  }

  public(package) fun value_overflow(): u64 {
    VALUE_OVER_FLOW
  }

  public(package) fun vector_too_big_to_pack(): u64 {
    VECTOR_TOO_BIG_TO_PACK
  }

  public(package) fun must_have_3_values(): u64 {
    MUST_HAVE_3_VALUES
  }

  public(package) fun wrong_configuration(): u64 {
    WRONG_CONFIGURATION
  }

  public(package) fun coins_must_be_in_order(): u64 {
    COINS_MUST_BE_IN_ORDER
  }

  public(package) fun expected_a_non_zero_value(): u64 {
    EXPECTED_A_NON_ZERO_VALUE
  }

  public(package) fun incurred_a_loss(): u64 {
    INCURRED_A_LOSS
  }

  public(package) fun invalid_coin_type(): u64 {
    INVALID_COIN_TYPE
  }

  public(package) fun must_have_9_decimals(): u64 {
    MUST_HAVE_9_DECIMALS
  }

  public(package) fun wait_one_day(): u64 {
    WAIT_ONE_DAY
  }

  public(package) fun value_out_of_range(): u64 {
    VALUE_OUT_OF_RANGE
  }

  public(package) fun must_supply_one_coin(): u64 {
    MUST_SUPPLY_ONE_COIN
  }

  public(package) fun cannot_swap_same_coin(): u64 {
    CANNOT_SWAP_SAME_COIN
  }

  public(package) fun future_ramp_time_is_too_short(): u64 {
    FUTURE_RAMP_TIME_IS_TOO_SHORT
  }

  public(package) fun future_a_is_too_small(): u64 {
    FUTURE_A_IS_TOO_SMALL
  }

  public(package) fun future_a_is_too_big(): u64 {
    FUTURE_A_IS_TOO_BIG
  }

  public(package) fun future_gamma_is_too_small(): u64 {
    FUTURE_GAMMA_IS_TOO_SMALL
  }

  public(package) fun future_gamma_is_too_big(): u64 {
    FUTURE_GAMMA_IS_TOO_BIG
  }  

  public(package) fun future_a_change_is_too_small(): u64 {
    FUTURE_A_CHANGE_IS_TOO_SMALL
  }

  public(package) fun future_a_change_is_too_big(): u64 {
    FUTURE_A_CHANGE_IS_TOO_BIG
  }  

  public(package) fun future_gamma_change_is_too_small(): u64 {
    FUTURE_GAMMA_CHANGE_IS_TOO_SMALL
  }

  public(package) fun future_gamma_change_is_too_big(): u64 {
    FUTURE_GAMMA_CHANGE_IS_TOO_BIG
  }    

  public(package) fun out_fee_out_of_range(): u64 {
    OUT_FEE_OUT_OF_RANGE
  }

  public(package) fun mid_fee_out_of_range(): u64 {
    MID_FEE_OUT_OF_RANGE
  }

  public(package) fun admin_fee_is_too_big(): u64 {
    ADMIN_FEE_IS_TOO_BIG
  }

  public(package) fun gamma_fee_out_of_range(): u64 {
    GAMMA_FEE_OUT_OF_RANGE
  }

  public(package) fun extra_profit_is_too_big(): u64 {
    EXTRA_PROFIT_IS_TOO_BIG
  }

  public(package) fun adjustment_step_is_too_big(): u64 {
    ADJUSTMENT_STEP_IS_TOO_BIG
  }

  public(package) fun ma_half_time_out_of_range(): u64 {
    MA_HALF_TIME_OUT_OF_RANGE
  }

  public(package) fun missing_coin_balance(): u64 {
    MISSING_COIN_BALANCE
  }

  public(package) fun version_was_updated(): u64 {
    VERSION_WAS_UPDATED
  }

  public(package) fun wrong_pool_id(): u64 {
    WRONG_POOL_ID
  }

  public(package) fun invalid_version(): u64 {
    INVALID_VERSION
  }

  public(package) fun rule_not_added(): u64 {
    RULE_NOT_ADDED
  }

  public(package) fun wrong_request_pool_address(): u64 {
    WRONG_REQUEST_POOL_ADDRESS
  }

  public(package) fun rule_not_approved(): u64 {
    RULE_NOT_APPROVED
  }

  public(package) fun pool_has_hooks(): u64 {
    POOL_HAS_HOOKS
  }

  public(package) fun pool_has_no_hooks(): u64 {
    POOL_HAS_NO_HOOKS
  }

  public(package) fun pool_has_no_swap_hooks(): u64 {
    POOL_HAS_NO_SWAP_HOOKS
  }

  public(package) fun pool_has_no_add_liquidity_hooks(): u64 {
    POOL_HAS_NO_ADD_LIQUIDITY_HOOKS
  }

  public(package) fun pool_has_no_remove_liquidity_hooks(): u64 {
    POOL_HAS_NO_REMOVE_LIQUIDITY_HOOKS
  }

  public(package) fun pool_has_no_donate_hooks(): u64 {
    POOL_HAS_NO_DONATE_HOOKS
  }

  public(package) fun must_be_start_swap_request(): u64 {
    MUST_BE_START_SWAP_REQUEST
  }  

  public(package) fun must_be_start_add_liquidity_request(): u64 {
    MUST_BE_START_ADD_LIQUIDITY_REQUEST
  }       

  public(package) fun must_be_start_remove_liquidity_request(): u64 {
    MUST_BE_START_REMOVE_LIQUIDITY_REQUEST
  }

  public(package) fun must_be_start_donate_request(): u64 {
    MUST_BE_START_DONATE_REQUEST
  }  

  public(package) fun must_be_finish_request(): u64 {
    MUST_BE_FINISH_REQUEST
  }  

  public(package) fun wrong_hooks_builder_pool(): u64 {
    WRONG_HOOKS_BUILDER_POOL
  }  

  public(package) fun must_wait_update_fees(): u64 {
    MUST_WAIT_TO_UPDATE_FEES
  }  

  public(package) fun pool_is_paused(): u64 {
    POOL_IS_PAUSED
  }    

  public(package) fun pause_period_has_passed(): u64 {
    PAUSE_PERIOD_HAS_PASSED
  }

  public(package) fun must_wait_to_update_parameters(): u64 {
    MUST_WAIT_TO_UPDATE_PARAMETERS
  }

  public(package) fun invalid_stable_fee_amount(): u64 {
    INVALID_STABLE_FEE_AMOUNT
  }

  public(package) fun commit_to_update_fees_first(): u64 {
    COMMIT_TO_UPDATE_FEES_FIRST
  }

  public(package) fun current_update_is_ongoing(): u64 {
    CURRENT_UPDATE_IS_ONGOING
  }
}
