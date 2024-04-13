#[test_only]
module clamm::utils_tests {
  // use std::type_name::get;

  // use sui::vec_set;
  // use sui::test_utils::assert_eq;
  // use sui::test_scenario::{Self as test, next_tx};

  // use clamm::utils;
  // use clamm::dai::DAI;
  // use clamm::usdc::USDC;
  // use clamm::usdt::USDT;
  // use clamm::curves::StableTuple;
  // use clamm::interest_pool::Pool;
  // use clamm::init_stable_tuple::setup_3pool;
  // use clamm::test_utils::{people, scenario};

  // #[test]
  // fun correct_coins_order() {
  //   let scenario = scenario();
  //   let (alice, _) = people();

  //   let test = &mut scenario;
    
  //   setup_3pool(test, 100, 100, 100);

  //   next_tx(test, alice);
  //   {
  //     let pool = test::take_shared<Pool<StableTuple>>(test);
      
  //     assert_eq(utils::are_coins_ordered(&pool, vector[get<DAI>(), get<USDC>(), get<USDT>()]), true);
  //     assert_eq(utils::are_coins_ordered(&pool, vector[get<USDC>(), get<DAI>(), get<USDT>()]), false);

  //     test::return_shared(pool);
  //   };
  //   test::end(scenario);      
  // }

  // #[test]
  // fun make_coins_set() {
  //   let array = vector[get<USDC>(), get<DAI>(), get<USDT>()];
  //   let set = utils::make_coins_from_vector(array);  

  //   let set_keys = vec_set::into_keys(set);

  //   assert_eq(set_keys, array);
  // }

  // #[test]
  // fun vector_utils() {
  //   let array = vector[0, 1];

  //   let (x, y) = utils::vector_2_to_tuple(array);

  //   assert_eq(x, 0);
  //   assert_eq(y, 1);


  //   let array = vector[0, 1, 2];

  //   let (x, y, z) = utils::vector_3_to_tuple(array);

  //   assert_eq(x, 0);
  //   assert_eq(y, 1);
  //   assert_eq(z, 2);
    
  //   assert_eq(utils::empty_vector(5), vector[0, 0, 0, 0, 0]);
  // }

  // #[test]
  // #[expected_failure]  
  // fun fails_to_make_coin_set() {
  //   // * will throw
  //   utils::make_coins_from_vector(vector[get<USDC>(), get<DAI>(), get<USDT>(), get<USDT>()]);  
  // }
}