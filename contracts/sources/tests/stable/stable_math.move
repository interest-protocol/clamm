#[test_only]
module amm::stable_math_tests {

  use sui::clock;
  use sui::tx_context;
  use sui::test_utils::assert_eq; 

  use amm::stable_math::{a, invariant_};

  #[test]
  fun test_a() {
    let c = clock::create_for_testing(&mut tx_context::dummy());

    clock::set_for_testing(&mut c, 50);

    // t1 > current_time
    // A0 > A1
    assert_eq(
      a(20, 10, 15, 100, &c),
      18
    );
    
    // t1 > current_time
    // A0 > A1
    assert_eq(
      a(37, 10, 45, 100, &c),
      40
    );

    assert_eq(
      a(0, 0, 0, 0, &c),
      0
    );

    clock::set_for_testing(&mut c, 100);

    // current_time > t1
    assert_eq(
      a(0, 0, 15, 99, &c),
      15
    );

    clock::destroy_for_testing(c);
  }

  #[test]
  fun test_invariant() {
    
    assert_eq(
      invariant_(
        255,
        vector[
          45128763921876458230192756389561204,
          892347610982734610982346198237461,
          7098237461098237461098237461098
        ]
      ),
    19835507236928744512883382297835175
    );

    assert_eq(
      invariant_(
        17,
        vector[
          92756389561204876543891027456389,
          56789012345678901234567890123456,
          7098237461098237461098237461098
        ]
      ),
    149800434007778834198060138210028
    );    

    assert_eq(
      invariant_(
        9,
        vector[
          987654321098765,
          384109823746109,
          752784590271893
        ]
      ),
     2107803805217679
    );        

    assert_eq(
      invariant_(
        0,
        vector[
          0,
          0,
          0
        ]
      ),
    0
    );    
  }  
}