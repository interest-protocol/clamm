#[test_only]
module clamm::utils_tests {
  use std::type_name;

  use sui::vec_set;
  use sui::test_utils::assert_eq;

  use clamm::utils;
  use clamm::eth::ETH;
  use clamm::usdc::USDC;

  #[test]
  fun test_make_coins_vec_set_from_vector() {
    let mut set = vec_set::empty();
    let eth = type_name::get<ETH>();
    let usdc = type_name::get<USDC>();

    set.insert(usdc);
    set.insert(eth);

    assert_eq(
      utils::make_coins_vec_set_from_vector(vector[usdc, eth]), 
      set
    );     
  }

  #[test]
  fun test_vector_to_tuple() {
    let vec1 = vector[0, 1];
    let vec2 = vector[2, 3, 4];

    let (zero, one) = utils::vector_2_to_tuple(vec1); 

    assert_eq(zero, vec1[0]);
    assert_eq(one, vec1[1]);

    let (two, three, four) = utils::vector_3_to_tuple(vec2); 

    assert_eq(two, vec2[0]);
    assert_eq(three, vec2[1]);
    assert_eq(four, vec2[2]);    
  }

  #[test]
  fun test_empty_vector() {
    assert_eq(utils::empty_vector(5), vector[0, 0, 0, 0, 0]);
    assert_eq(utils::empty_vector(7), vector[0, 0, 0, 0, 0, 0, 0]);
  }

  #[test]
  fun test_head() {
    let vec = vector[2, 3, 4];

    assert_eq(utils::head(vec), 2);
  }

  #[test]
  fun test_convert_uint() {
    assert_eq(utils::to_u8(1), 1);
    assert_eq(utils::to_u64(2), 2);
    assert_eq(utils::to_u256(3), 3);
  }
}