#[test_only]
module clamm::stable_fees_tests {
  use std::option;

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx};

  use clamm::stable_fees;
  
  use clamm::amm_test_utils::{people, scenario};

  const INITIAL_FEE_PERCENT: u256 = 250000000000000; // 0.025%
  const MAX_FEE_PERCENT: u256 = 20000000000000000; // 2%
  const MAX_ADMIN_FEE: u256 = 200000000000000000; // 20%

  #[test]
  fun sets_initial_state_correctly() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    

    next_tx(test, alice);
    {
      
      let fees = stable_fees::new();

      let fee_in = stable_fees::fee_in_percent(&fees);
      let fee_out = stable_fees::fee_out_percent(&fees);
      let fee_admin = stable_fees::admin_fee_percent(&fees);

      assert_eq(fee_in, INITIAL_FEE_PERCENT);
      assert_eq(fee_out, INITIAL_FEE_PERCENT);
      assert_eq(fee_admin, 0);

    };
    test::end(scenario);      
  }

  #[test]
  fun updates_fees_correctly() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    

    next_tx(test, alice);
    {
      let fees = stable_fees::new();

      stable_fees::update_fee_in_percent(&mut fees, option::some(MAX_FEE_PERCENT));
      stable_fees::update_fee_out_percent(&mut fees, option::some(MAX_FEE_PERCENT));
      stable_fees::update_admin_fee_percent(&mut fees, option::some(1));

      let fee_in = stable_fees::fee_in_percent(&fees);
      let fee_out = stable_fees::fee_out_percent(&fees);
      let fee_admin = stable_fees::admin_fee_percent(&fees);

      assert_eq(fee_in, MAX_FEE_PERCENT);
      assert_eq(fee_out, MAX_FEE_PERCENT);
      assert_eq(fee_admin, 1);

      stable_fees::update_fee_in_percent(&mut fees, option::none());
      stable_fees::update_fee_out_percent(&mut fees, option::none());
      stable_fees::update_admin_fee_percent(&mut fees, option::none());

      let fee_in = stable_fees::fee_in_percent(&fees);
      let fee_out = stable_fees::fee_out_percent(&fees);
      let fee_admin = stable_fees::admin_fee_percent(&fees);

      assert_eq(fee_in, MAX_FEE_PERCENT);
      assert_eq(fee_out, MAX_FEE_PERCENT);
      assert_eq(fee_admin, 1);

      stable_fees::update_fee_in_percent(&mut fees, option::some(0));
      stable_fees::update_fee_out_percent(&mut fees, option::some(0));
      stable_fees::update_admin_fee_percent(&mut fees, option::some(0));

      let fee_in = stable_fees::fee_in_percent(&fees);
      let fee_out = stable_fees::fee_out_percent(&fees);
      let fee_admin = stable_fees::admin_fee_percent(&fees);

      assert_eq(fee_in, 0);
      assert_eq(fee_out, 0);
      assert_eq(fee_admin, 0);
    };
    test::end(scenario);
  }

  #[test]
  fun calculates_fees_properly() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    

    next_tx(test, alice);
    {
      let fees = stable_fees::new();

      stable_fees::update_fee_in_percent(&mut fees, option::some(MAX_FEE_PERCENT)); // 2%
      stable_fees::update_fee_out_percent(&mut fees, option::some(MAX_FEE_PERCENT / 2)); // 1%
      stable_fees::update_admin_fee_percent(&mut fees, option::some(MAX_FEE_PERCENT * 2)); // 4%

      let amount = 100;

      assert_eq(stable_fees::calculate_fee_in_amount(&fees, amount), 2);
      assert_eq(stable_fees::calculate_fee_out_amount(&fees, amount), 1);
      assert_eq(stable_fees::calculate_admin_amount(&fees, amount), 4);
    };
    test::end(scenario);
  }

#[test]
#[expected_failure(abort_code = 11, location = clamm::stable_fees)]  
fun aborts_max_fee_in() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    next_tx(test, alice);
    {
      let fees = stable_fees::new();

      stable_fees::update_fee_in_percent(&mut fees, option::some(MAX_FEE_PERCENT + 1));
    };
    test::end(scenario);
  }

#[test]
#[expected_failure(abort_code = 11, location = clamm::stable_fees)]  
fun aborts_max_fee_out() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
   
    next_tx(test, alice);
    {
      let fees = stable_fees::new();

      stable_fees::update_fee_out_percent(&mut fees, option::some(MAX_FEE_PERCENT + 1));
    };
    test::end(scenario);
  }

#[test]
#[expected_failure(abort_code = 11, location = clamm::stable_fees)]  
fun aborts_max_admin_fee() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
   
    next_tx(test, alice);
    {
      let fees = stable_fees::new();

      stable_fees::update_admin_fee_percent(&mut fees, option::some(MAX_ADMIN_FEE + 1));
    };
    test::end(scenario);
  }
}