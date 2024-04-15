// Tested agaisnt https://etherscan.io/address/0x8f68f4810cce3194b6cb6f3d50fa58c2c9bdd1d5#readContract
#[test_only]
module clamm::volatile_math_tests {
  use sui::test_utils::assert_eq; 

  use clamm::volatile_math;

  const FEE_GAMMA: u256 = 10000000000000000;
  const PRECISION: u256 = 1000000000000000000;
  const MIN_GAMMA: u256 = 10_000_000_000; // 10e10
  const MAX_GAMMA: u256 = 50_000_000_000_000_000; // 5e16

  const VALID_ANN: u256 = 270000000;

  const POW_10_20: u256 = 100_000_000_000_000_000_000;
  const POW_10_17: u256 = 100_000_000_000_000_000;
  const POW_10_16: u256 = 10_000_000_000_000_000;
  const POW_10_15: u256 = 1_000_000_000_000_000;
  const POW_10_14: u256 = 100_000_000_000_000;
  const POW_10_9: u256 = 1_000_000_000;

  #[test]
  fun geometric_mean() {
    assert_eq(volatile_math::geometric_mean(
      vector[
        95857402834957293847589374578293847598234578923456789,
        12345678901234567890123456789012345678901234567890,
        98765432109876543210987654321098765432109876543210
      ],
      true
    ),
    488932081316428026648602300982557262375330833440612
  );


    assert_eq(volatile_math::geometric_mean(
      vector[
        11111111111111111111111111111111111111111111111111,
        22222222222222222222222222222222222222222222222222,
        33333333333333333333333333333333333333333333333333
      ],
      true
    ),
    20190228809245996199293293034785411280021008731434
  );

    assert_eq(volatile_math::geometric_mean(
      vector[
        44444444444444444444444444444444444444444444444444,
        55555555555555555555555555555555555555555555555555,
        66666666666666666666666666666666666666666666666666
      ],
      true
      ),
    54804712762899335570512977627201900244000563679492 
    );


    assert_eq(volatile_math::geometric_mean(
      vector[
        77777777777777777777777777777777777777777777777777,
        88888888888888888888888888888888888888888888888888,
        99999999999999999999999999999999999999999999999999
      ],
      true
      ),
    88423493508808707927768524110508869931091779856749
    );

    assert_eq(volatile_math::geometric_mean(
      vector[
        12121212121212121212121212121212121212121212121212,
        23232323232323232323232323232323232323232323232323,
        34343434343434343434343434343434343434343434343434
      ],
      true
      ),
    21305618116999345586111097801878004333206906105628 
    );

    assert_eq(volatile_math::geometric_mean(
      vector[98765432109876543210987654, 87654321098765432109876543, 76543210987654321098765432],
      true
      ),
    87182300599334670776482378 
    );
  }

  #[test]
  fun reduction_coefficient() {
    assert_eq(
      volatile_math::reduction_coefficient(
        vector[
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
        vector[
          PRECISION,
          PRECISION,
          PRECISION
        ],
        0
      ),
      PRECISION
    );

    let x = volatile_math::reduction_coefficient(
        vector[
          PRECISION,
          PRECISION,
          PRECISION / 10
        ],
        FEE_GAMMA
      );

    assert_eq(x, 13918759891247007);

    let x = volatile_math::reduction_coefficient(
        vector[
          PRECISION,
          PRECISION,
          999000000000000000
        ],
        FEE_GAMMA
      );


    assert_eq(x, 999966638131559899);

    assert_eq(
      volatile_math::reduction_coefficient(
      vector[
        12121212121212121212121212121212121212121212121212,
        23232323232323232323232323232323232323232323232323,
        34343434343434343434343434343434343434343434343434
      ],
        FEE_GAMMA
      ),
       41887718742576609
    );

    assert_eq(
      volatile_math::reduction_coefficient(
      vector[
        95857402834957293847589374578293847598234578923456789,
        12345678901234567890123456789012345678901234567890,
        98765432109876543210987654321098765432109876543210
      ],
        FEE_GAMMA
      ),
       9901025100122167
    );
  }

  // * This is tested agaisnt the Curve contract
  #[test]
  fun invariant_() {
    assert_eq(
      volatile_math::invariant_(
        27000, 
        10000000000, 
        vector[
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
        vector[
          23456789012345678901234567,
          34567890123456789012345678,
          45678901234567890123456789
        ]
      ),
      100001671685781977852490804
    );

    assert_eq(
      volatile_math::invariant_(
        27000, 
        10000000000, 
        vector[
          12345678901234567890123456,
          23456789012345678901234567,
          34567890123456789012345678
        ]
      ),
      64655748097706163074764667
    );

    assert_eq(
      volatile_math::invariant_(
        27000, 
        10000000000, 
        vector[
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
        vector[
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
        vector[
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
        vector[
          99999999999999999999999999,
          88888888888888888888888888,
          11111111111111111111111111,
        ]
      ),
       138672482182892387902464828
    );
  }

  // * Tested agaisnt Curve contract
  #[test]
  fun y() {
    let ann = 27000;
    let gamma = 10000000000;
    let balances = vector[1000000000010000000000 + 3 * PRECISION, 1000000000010000000000, 1000000000010000000000];
    let d: u256 = 3000000000030000000000;

    assert_eq(
      volatile_math::y(ann, gamma, &balances, d, 0),
      1000000000010000000164
    );

    assert_eq(
      volatile_math::y(ann, gamma, &balances, d, 1),
      997008887067534938648
    );

    assert_eq(
      volatile_math::y(ann, gamma, &balances, d, 2),
      997008887067534938648
    );

    let balances = vector[23456789012345678901234567,34567890123456789012345678,45678901234567890123456789 + 4 * PRECISION];
    let d: u256 = 100001671685781977852490804;

    assert_eq(
      volatile_math::y(ann, gamma, &balances, d, 0),
      23456786958278052267490556
    );

    assert_eq(
      volatile_math::y(ann, gamma, &balances, d, 1),
      34567887096417113472229743
    );

    assert_eq(
      volatile_math::y(ann, gamma, &balances, d, 2),
      45678901234567890179195521
    );

    let balances = vector[98765432109876543210987654, 87654321098765432109876543, 51028807325102880732510288];
    let d: u256 = 261547000160376643742836627;

    assert_eq(
      volatile_math::y(ann, gamma, &balances, d, 0),
      148147876841464101893259752
    );

    assert_eq(
      volatile_math::y(ann, gamma, &balances, d, 1),
      131481271806238708565846354
    );

    assert_eq(
      volatile_math::y(ann, gamma, &balances, d, 2),
      76543210987654321058114319
    );

    let balances = vector[99999999999999999999999999,88888888888888888888888888,27111111111111111111111111];
    let d: u256 = 138672482182892387902464828;

    assert_eq(
      volatile_math::y(ann, gamma, &balances, d, 0),
      40983673484263694029988653
    );

    assert_eq(
      volatile_math::y(ann, gamma, &balances, d, 1),
      36429919106610415936464197
    );

    assert_eq(
      volatile_math::y(ann, gamma, &balances, d, 2),
      11111111111111111110978167
    );
  }

  #[test]
  fun sqrt() {
    assert_eq(
      volatile_math::sqrt(0),
      0
    );

    assert_eq(
      volatile_math::sqrt(11111111111111111110978167),
      3333333333333333333313
    );

    assert_eq(
      volatile_math::sqrt(1234567890123456789012345678906),
      1111111106111111099361111
    );

    assert_eq(
      volatile_math::sqrt(987654321098765432109876543210),
      993807990055808231178923
    );

    assert_eq(
      volatile_math::sqrt(314159265358979323846264338327),
      560499121639792869931128
    );

    assert_eq(
      volatile_math::sqrt(271828182845904523536028747135),
      521371444217943838412954
    );

    assert_eq(
      volatile_math::sqrt(112358132134558914423207911489),
      335198645782704370434704
    );        
  }

  #[test]
  fun half_pow() {
    assert_eq(
      volatile_math::half_pow(POW_10_17, POW_10_15),
      933392445312500000
    );

    assert_eq(
      volatile_math::half_pow(2 * PRECISION, POW_10_16),
      250000000000000000
    );

    assert_eq(
      volatile_math::half_pow(60 * PRECISION, POW_10_17),
      0
    );

    assert_eq(
      volatile_math::half_pow(5 * PRECISION + 5 * POW_10_15, POW_10_14),
      31143560648651123
    );

    assert_eq(
      volatile_math::half_pow(0, PRECISION),
      1000000000000000000
    );
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_AMPLIFIER, location = clamm::volatile_math)]  
  fun invariant_low_amp() {
    let invalid_amp_low = 2700 - 1; // Below MIN_A

    volatile_math::invariant_(invalid_amp_low, 1, vector[PRECISION, PRECISION, PRECISION]);
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_AMPLIFIER, location = clamm::volatile_math)]  
  fun invariant_high_amp() {
    let invalid_amp_high = 270000000 + 1; // Above MAX_A

    volatile_math::invariant_(invalid_amp_high, 1, vector[PRECISION, PRECISION, PRECISION]);
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_GAMMA, location = clamm::volatile_math)]  
  fun invariant_low_gamma() {
    volatile_math::invariant_(VALID_ANN, MIN_GAMMA - 1, vector[PRECISION, PRECISION, PRECISION]);
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_GAMMA, location = clamm::volatile_math)]  
  fun invariant_high_gamma() {
    volatile_math::invariant_(VALID_ANN, MAX_GAMMA + 1, vector[PRECISION, PRECISION, PRECISION]);
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::UNSAFE_VALUE, location = clamm::volatile_math)]  
  fun invariant_low_quote_value() {
    volatile_math::invariant_(VALID_ANN, MAX_GAMMA, vector[POW_10_9 - 1, PRECISION, PRECISION]);
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::UNSAFE_VALUE, location = clamm::volatile_math)]  
  fun invariant_high_quote_value() {
    volatile_math::invariant_(VALID_ANN, MAX_GAMMA, vector[POW_10_15 * PRECISION + 1, PRECISION, PRECISION]);
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::UNSAFE_VALUE, location = clamm::volatile_math)]  
  fun invariant_invalid_balance_too_low() {
    volatile_math::invariant_(VALID_ANN, MAX_GAMMA / 2, vector[POW_10_9, 100 - 1, PRECISION]);
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_AMPLIFIER, location = clamm::volatile_math)] 
  fun y_low_amp() {
    let invalid_amp_low = 2700 - 1; // Below MIN_A
    volatile_math::y(invalid_amp_low, MAX_GAMMA / 2, &vector[2 * PRECISION, 3 * PRECISION, PRECISION], 15 * PRECISION, 1);
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_AMPLIFIER, location = clamm::volatile_math)] 
  fun y_high_amp() {
    let invalid_amp_high = 270000000 + 1; // Above MAX_A
    volatile_math::y(invalid_amp_high, MAX_GAMMA / 2, &vector[2 * PRECISION, 3 * PRECISION, PRECISION], 15 * PRECISION, 1);
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_GAMMA, location = clamm::volatile_math)]  
  fun y_low_gamma() {
    volatile_math::y(VALID_ANN, MIN_GAMMA - 1, &vector[PRECISION, PRECISION, PRECISION], 15 * PRECISION, 1);
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_GAMMA, location = clamm::volatile_math)]  
  fun y_high_gamma() {
    volatile_math::y(VALID_ANN, MAX_GAMMA + 1, &vector[PRECISION, PRECISION, PRECISION], 15 * PRECISION, 1);
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_INVARIANT, location = clamm::volatile_math)]  
  fun y_low_invariant() {
    volatile_math::y(VALID_ANN, MAX_GAMMA / 2, &vector[PRECISION, PRECISION, PRECISION], POW_10_17 - 1, 1);
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::INVALID_INVARIANT, location = clamm::volatile_math)]  
  fun y_high_invariant() {
    volatile_math::y(VALID_ANN, MAX_GAMMA / 2, &vector[PRECISION, PRECISION, PRECISION], POW_10_15 * PRECISION + 1, 1);
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::UNSAFE_VALUE, location = clamm::volatile_math)]  
  fun y_low_balance() {
    volatile_math::y(VALID_ANN, MAX_GAMMA / 2, &vector[POW_10_16 * POW_10_15 - 1, POW_10_16 * POW_10_15, POW_10_16 * POW_10_15], POW_10_15 * PRECISION, 1);
  }

  #[test]
  #[expected_failure(abort_code = clamm::errors::UNSAFE_VALUE, location = clamm::volatile_math)]  
  fun y_high_balance() {
    volatile_math::y(VALID_ANN, MAX_GAMMA / 2, &vector[(POW_10_20 * POW_10_15) * 10, POW_10_16 * POW_10_15, POW_10_16 * POW_10_15], POW_10_15 * PRECISION, 1);
  }
}
