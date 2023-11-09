#[test_only]
module amm::volatile_math_tests {
  use sui::test_utils::assert_eq; 

  use amm::volatile_math;

  const FEE_GAMMA: u256 = 10000000000000000;
  const PRECISION: u256 = 1000000000000000000;
  const MIN_GAMMA: u256 = 10_000_000_000; // 10e10
  const MAX_GAMMA: u256 = 50_000_000_000_000_000; // 5e16

  const VALID_ANN: u256 = 270000000;

  const POW_10_15: u256 = 1_000_000_000_000_000;
  const POW_10_9: u256 = 1_000_000_000;

  #[test]
  fun geometric_mean() {
    assert_eq(volatile_math::geometric_mean(
      &vector[
        95857402834957293847589374578293847598234578923456789,
        12345678901234567890123456789012345678901234567890,
        98765432109876543210987654321098765432109876543210
      ],
      true
    ),
    488932081316428026642062596805784878789761473618307 // * close enough check our TS test 4.8893208131642802669e+50
  );


    assert_eq(volatile_math::geometric_mean(
      &vector[
        11111111111111111111111111111111111111111111111111,
        22222222222222222222222222222222222222222222222222,
        33333333333333333333333333333333333333333333333333
      ],
      true
    ),
    20190228809245996198820576770880121483941530976951 // * close enough check our TS test 2.019022880924599621e+49
  );

    assert_eq(volatile_math::geometric_mean(
      &vector[
        44444444444444444444444444444444444444444444444444,
        55555555555555555555555555555555555555555555555555,
        66666666666666666666666666666666666666666666666666
      ],
      true
      ),
    54804712762899335551035345267515621318566631068384 // * close enough check our TS test 5.4804712762899335589e+49
    );


    assert_eq(volatile_math::geometric_mean(
      &vector[
        77777777777777777777777777777777777777777777777777,
        88888888888888888888888888888888888888888888888888,
        99999999999999999999999999999999999999999999999999
      ],
      true
      ),
    88423493508808707944619190210638306351113694881373 // * close enough check our TS test 8.8423493508808707992e+49
    );

    assert_eq(volatile_math::geometric_mean(
      &vector[
        12121212121212121212121212121212121212121212121212,
        23232323232323232323232323232323232323232323232323,
        34343434343434343434343434343434343434343434343434
      ],
      true
      ),
    21305618116999345586282362640576321707401596028664 // * close enough check our TS test 2.1305618116999345597e+49
    );
  }

  #[test]
  fun reduction_coefficient() {
    assert_eq(
      volatile_math::reduction_coefficient(
        &vector[
          PRECISION,
          PRECISION,
          PRECISION
        ],
        FEE_GAMMA
      ),
      PRECISION
    );

    assert_eq(
      volatile_math::reduction_coefficient(
        &vector[
          PRECISION,
          PRECISION,
          PRECISION
        ],
        0
      ),
      PRECISION
    );

    let x = volatile_math::reduction_coefficient(
        &vector[
          PRECISION,
          PRECISION,
          PRECISION / 10
        ],
        FEE_GAMMA
      );

    assert_eq(x > 0, true);
    assert_eq(PRECISION > x, true);


    let x = volatile_math::reduction_coefficient(
        &vector[
          PRECISION,
          PRECISION,
          999000000000000000
        ],
        FEE_GAMMA
      );


    assert_eq(x > 0, true);
    assert_eq(PRECISION > x, true);
    assert_eq(x > 900000000000000000, true);

    assert_eq(
      volatile_math::reduction_coefficient(
      &vector[
        12121212121212121212121212121212121212121212121212,
        23232323232323232323232323232323232323232323232323,
        34343434343434343434343434343434343434343434343434
      ],
        FEE_GAMMA
      ),
      41887718742576609 // * check TS test
    );

    assert_eq(
      volatile_math::reduction_coefficient(
      &vector[
        95857402834957293847589374578293847598234578923456789,
        12345678901234567890123456789012345678901234567890,
        98765432109876543210987654321098765432109876543210
      ],
        FEE_GAMMA
      ),
      9901025100122167 // * check TS test one digit different
    );
  }

  #[test]
  #[expected_failure(abort_code = 4)]  
  fun invariant_low_amp() {
    let invalid_amp_low = 2700 - 1; // Below MIN_A

    volatile_math::invariant_(invalid_amp_low, 1, &vector[PRECISION, PRECISION, PRECISION]);
  }

  #[test]
  #[expected_failure(abort_code = 4)]  
  fun invariant_high_amp() {
    let invalid_amp_high = 270000000 + 1; // Below MIN_A

    volatile_math::invariant_(invalid_amp_high, 1, &vector[PRECISION, PRECISION, PRECISION]);
  }

  #[test]
  #[expected_failure(abort_code = 3)]  
  fun invariant_low_gamma() {
    volatile_math::invariant_(VALID_ANN, MIN_GAMMA - 1, &vector[PRECISION, PRECISION, PRECISION]);
  }

  #[test]
  #[expected_failure(abort_code = 3)]  
  fun invariant_high_gamma() {
    volatile_math::invariant_(VALID_ANN, MAX_GAMMA + 1, &vector[PRECISION, PRECISION, PRECISION]);
  }

  #[test]
  #[expected_failure(abort_code = 5)]  
  fun invariant_low_quote_value() {
    volatile_math::invariant_(VALID_ANN, MAX_GAMMA, &vector[POW_10_9 - 1, PRECISION, PRECISION]);
  }

  #[test]
  #[expected_failure(abort_code = 5)]  
  fun invariant_high_quote_value() {
    volatile_math::invariant_(VALID_ANN, MAX_GAMMA, &vector[POW_10_15 * PRECISION + 1, PRECISION, PRECISION]);
  }

  #[test]
  #[expected_failure(abort_code = 5)]  
  fun invariant_invalid_balance_too_low() {
    volatile_math::invariant_(VALID_ANN, MAX_GAMMA / 2, &vector[POW_10_9, 100 - 1, PRECISION]);
  }
}