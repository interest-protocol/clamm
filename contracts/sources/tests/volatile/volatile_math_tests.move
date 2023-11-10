#[test_only]
module amm::volatile_math_tests {
  use sui::test_utils::assert_eq; 

  use amm::volatile_math;

  const FEE_GAMMA: u256 = 10000000000000000;
  const PRECISION: u256 = 1000000000000000000;
  const MIN_GAMMA: u256 = 10_000_000_000; // 10e10
  const MAX_GAMMA: u256 = 50_000_000_000_000_000; // 5e16

  const VALID_ANN: u256 = 270000000;

  const POW_10_17: u256 = 100_000_000_000_000_000;
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
    21305618116999345593384235346242770238529674477412 // * close enough check our TS test 2.1305618116999345597e+49
    );

    assert_eq(volatile_math::geometric_mean(
      &vector[98765432109876543210987654, 87654321098765432109876543, 76543210987654321098765432],
      true
      ),
    87182300599334670776482378 // * close enough check our TS test 5.4804712762899335589e+49
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

  // * This is tested agaisnt the Curve contract
  #[test]
  fun invariant_() {
    assert_eq(
      volatile_math::invariant_(
        27000, 
        10000000000, 
        &vector[
          1000000000010000000000,
          1000000000010000000000,
          1000000000010000000000
        ]
      ),
      3000000000030000000000
    );

    assert_eq(
      volatile_math::invariant_(
        27000, 
        10000000000, 
        &vector[
          23456789012345678901234567,
          34567890123456789012345678,
          45678901234567890123456789
        ]
      ),
      100001671685781977817457539
    );

    assert_eq(
      volatile_math::invariant_(
        27000, 
        10000000000, 
        &vector[
          12345678901234567890123456,
          23456789012345678901234567,
          34567890123456789012345678
        ]
      ),
      64655748097706163049735054
    );

    assert_eq(
      volatile_math::invariant_(
        27000, 
        10000000000, 
        &vector[
          98765432109876543210987654,
          87654321098765432109876543,
          76543210987654321098765432,
        ]
      ),
       261547000160376643742836627
    );

    assert_eq(
      volatile_math::invariant_(
        27000, 
        10000000000, 
        &vector[
          33333333333333333333333333,
          22222222222222222222222222,
          11111111111111111111111111,
        ]
      ),
       60570746993165292455004669
    );

    assert_eq(
      volatile_math::invariant_(
        27000, 
        10000000000, 
        &vector[
          66666666666666666666666666,
          55555555555555555555555555,
          44444444444444444444444444,
        ]
      ),
       164414222681119968767118758
    );

    assert_eq(
      volatile_math::invariant_(
        27000, 
        10000000000, 
        &vector[
          99999999999999999999999999,
          88888888888888888888888888,
          11111111111111111111111111,
        ]
      ),
       138672482182892387902464828
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
    let invalid_amp_high = 270000000 + 1; // Above MAX_A

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

  #[test]
  #[expected_failure(abort_code = 4)] 
  fun y_low_amp() {
    let invalid_amp_low = 2700 - 1; // Below MIN_A
    volatile_math::y(invalid_amp_low, MAX_GAMMA / 2, &vector[2 * PRECISION, 3 * PRECISION, PRECISION], 15 * PRECISION, 1);
  }

  #[test]
  #[expected_failure(abort_code = 4)] 
  fun y_high_amp() {
    let invalid_amp_high = 270000000 + 1; // Above MAX_A
    volatile_math::y(invalid_amp_high, MAX_GAMMA / 2, &vector[2 * PRECISION, 3 * PRECISION, PRECISION], 15 * PRECISION, 1);
  }

  #[test]
  #[expected_failure(abort_code = 3)]  
  fun y_low_gamma() {
    volatile_math::y(VALID_ANN, MIN_GAMMA - 1, &vector[PRECISION, PRECISION, PRECISION], 15 * PRECISION, 1);
  }

  #[test]
  #[expected_failure(abort_code = 3)]  
  fun y_high_gamma() {
    volatile_math::y(VALID_ANN, MAX_GAMMA + 1, &vector[PRECISION, PRECISION, PRECISION], 15 * PRECISION, 1);
  }

  #[test]
  #[expected_failure(abort_code = 6)]  
  fun y_low_invariant() {
    volatile_math::y(VALID_ANN, MAX_GAMMA / 2, &vector[PRECISION, PRECISION, PRECISION], POW_10_17 - 1, 1);
  }

  #[test]
  #[expected_failure(abort_code = 6)]  
  fun y_high_invariant() {
    volatile_math::y(VALID_ANN, MAX_GAMMA / 2, &vector[PRECISION, PRECISION, PRECISION], POW_10_15 * PRECISION + 1, 1);
  }
}
