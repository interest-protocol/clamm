module amm::stable_pair_math_tests {
  use sui::test_utils::assert_eq;

  use suitears::fixed_point_wad::{wad_div_down as fdiv, wad_mul_down as fmul};

  use amm::stable_pair_math;

  #[test]
  fun quote_liquidity() {
    assert_eq(stable_pair_math::quote_liquidity(10, 200, 300), 15);
    assert_eq(stable_pair_math::quote_liquidity(10, 200, 350), 18); // rounds up
    assert_eq(stable_pair_math::quote_liquidity(10, 557, 300), 6); // rounds up
    assert_eq(stable_pair_math::quote_liquidity(227, 557, 900), 367); // rounds up
  }

  #[test]
  fun calculate_optimal_add_liquidity () {
    let (x, y) = stable_pair_math::calculate_optimal_add_liquidity(10, 200, 0, 0);
    assert_eq(x, 10);
    assert_eq(y, 200);

    let (x, y) = stable_pair_math::calculate_optimal_add_liquidity(10, 18, 200, 300);
    assert_eq(x, 10);
    assert_eq(y, 15);

    let (x, y) = stable_pair_math::calculate_optimal_add_liquidity(10, 12, 200, 300);
    assert_eq(x, stable_pair_math::quote_liquidity(12, 300, 200));
    assert_eq(y, 12);
  }

  #[test]
  fun invariant_() {

    let x = fdiv(300000, 1000000);
    let y = fdiv(500000, 1000000);
    assert_eq(stable_pair_math::invariant_(300000, 500000, 1000000, 1000000), fmul(fmul(fmul(x, x), x), y) + fmul(fmul(fmul(y, y), y), x));


    let x = fdiv(500000899318256, 1000000);
    let y = fdiv(25000567572582123, 1000000000000);
    assert_eq(stable_pair_math::invariant_(500000899318256, 25000567572582123, 1000000, 1000000000000), fmul(fmul(x, y), fmul(x, x) + fmul(y, y)));
  }

  #[test]
  fun calculate_amounts() {
    let k = stable_pair_math::invariant_(25582858050757, 2558285805075712, 1000000, 100000000);
    assert_eq(
      stable_pair_math::calculate_amount_out(k, 2513058000,  25582858050757, 2558285805075712, 1000000, 100000000, true),
      251305799999
    );

    assert_eq(
      stable_pair_math::calculate_amount_out(k, 2513058000,  25582858050757, 2558285805075712, 1000000, 100000000, false),
      25130579
    );

    let k = stable_pair_math::invariant_(2558285805075701, 25582858050757, 100000000, 1000000);
    assert_eq(
      stable_pair_math::calculate_amount_in(k, 251305800000,  2558285805075701, 25582858050757, 100000000, 1000000, true),
      2513058000
    );

    assert_eq(
      stable_pair_math::calculate_amount_in(k, 2513058000,  2558285805075701, 25582858050757, 100000000, 1000000, false),
      251305800000
    );
  }

  #[test]
  fun f() {
    let x0 = 10000518365287 * 1_000_000_000;
    let y = 2520572000001255 * 1_000_000_000;

    let r = stable_pair_math::f(x0, y);
    assert_eq(r, 160149899619106589403934712464197978496548);

    let r = stable_pair_math::f(0, 0);
    assert_eq(r, 0);
  }

  #[test]
  fun d() {
    let x0 = 10000518365287 * 1_000_000_000;
    let y = 2520572000001255 * 1_000_000_000;

    let z = stable_pair_math::d(x0, y);
    assert_eq(z, 190609376335646708870399576464086697);

    let x0 = 5000000000 * 1_000_000_000;
    let y = 10000000000000000 * 1_000_000_000;

    let z = stable_pair_math::d(x0, y);

    assert_eq(z,  1500000000000125000000000000000000);

    let x0 = 1 * 1_000_000_000_000_000_000;
    let y = 2 * 1_000_000_000_000_000_000;

    let z = stable_pair_math::d(x0, y);
    assert_eq(z, 13000000000000000000);
  }
}