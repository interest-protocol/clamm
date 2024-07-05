#[test_only]
module clamm::stable_fees_tests {

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx};

  use clamm::stable_fees;
  
  use clamm::amm_test_utils::{people, scenario};

  const INITIAL_FEE_PERCENT: u256 = 500000000000000; // 0.05%
  const MAX_FEE_PERCENT: u256 = 20000000000000000; // 2%
  const MAX_ADMIN_FEE: u256 = 200000000000000000; // 20%  

  #[test]
  fun sets_initial_state_correctly() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    

    next_tx(test, alice);
    {
      
      let fees = stable_fees::new();

      let fee = stable_fees::fee(&fees);
      let fee_admin = stable_fees::admin_fee(&fees);

      assert_eq(fee, INITIAL_FEE_PERCENT);
      assert_eq(fee_admin, MAX_ADMIN_FEE);

    };
    test::end(scenario);      
  }

  #[test]
  fun updates_fees_correctly() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    

    next_tx(test, alice);
    {
      let mut fees = stable_fees::new();

      stable_fees::commit_fee(&mut fees, option::some(MAX_FEE_PERCENT), test.ctx());
      stable_fees::commit_admin_fee(&mut fees, option::some(1), test.ctx());

      let fee = stable_fees::fee(&fees);
      let fee_admin = stable_fees::admin_fee(&fees);

      assert_eq(fee, INITIAL_FEE_PERCENT);
      assert_eq(fee_admin, MAX_ADMIN_FEE);

      test.next_epoch(@0x0);
      test.next_epoch(@0x0);
      test.next_epoch(@0x0);
      test.next_epoch(@0x0);

      stable_fees::update_fee(&mut fees, test.ctx());
      stable_fees::update_admin_fee(&mut fees, test.ctx());

      let fee = stable_fees::fee(&fees);
      let fee_admin = stable_fees::admin_fee(&fees);

      assert_eq(fee, MAX_FEE_PERCENT);
      assert_eq(fee_admin, 1);

      stable_fees::commit_fee(&mut fees, option::none(), test.ctx());
      stable_fees::commit_admin_fee(&mut fees, option::none(), test.ctx());

      test.next_epoch(@0x0);
      test.next_epoch(@0x0);
      test.next_epoch(@0x0);
      test.next_epoch(@0x0);

      stable_fees::update_fee(&mut fees, test.ctx());
      stable_fees::update_admin_fee(&mut fees, test.ctx());

      let fee = stable_fees::fee(&fees);
      let fee_admin = stable_fees::admin_fee(&fees);

      assert_eq(fee, MAX_FEE_PERCENT);
      assert_eq(fee_admin, 1);

      stable_fees::commit_fee(&mut fees, option::some(0), test.ctx());
      stable_fees::commit_admin_fee(&mut fees, option::some(0), test.ctx());

      test.next_epoch(@0x0);
      test.next_epoch(@0x0);
      test.next_epoch(@0x0);
      test.next_epoch(@0x0);

      stable_fees::update_fee(&mut fees, test.ctx());
      stable_fees::update_admin_fee(&mut fees, test.ctx());

      let fee = stable_fees::fee(&fees);
      let fee_admin = stable_fees::admin_fee(&fees);

      assert_eq(fee, 0);
      assert_eq(fee_admin, 0);
    };
    test::end(scenario);
  }

  #[test]
  fun calculates_fees_properly() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    

    next_tx(test, alice);
    {
      let mut fees = stable_fees::new();

      stable_fees::commit_fee(&mut fees, option::some(MAX_FEE_PERCENT), test.ctx());
      stable_fees::commit_admin_fee(&mut fees, option::some(MAX_FEE_PERCENT / 2), test.ctx());

      let fee = stable_fees::fee(&fees);
      let fee_admin = stable_fees::admin_fee(&fees);

      assert_eq(fee, INITIAL_FEE_PERCENT);
      assert_eq(fee_admin, MAX_ADMIN_FEE);

      test.next_epoch(@0x0);
      test.next_epoch(@0x0);
      test.next_epoch(@0x0);
      test.next_epoch(@0x0);

      stable_fees::update_fee(&mut fees, test.ctx());
      stable_fees::update_admin_fee(&mut fees, test.ctx());

      let amount = 100;

      assert_eq(stable_fees::calculate_fee(&fees, amount), 2);
      assert_eq(stable_fees::calculate_admin_fee(&fees, amount), 1);
    };
    test::end(scenario);
  }

#[test]
#[expected_failure(abort_code = clamm::errors::INVALID_FEE, location = clamm::stable_fees)]  
fun aborts_max_fee() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;

    next_tx(test, alice);
    {
      let mut fees = stable_fees::new();

      stable_fees::commit_fee(&mut fees, option::some(MAX_FEE_PERCENT + 1), test.ctx());
    };
    test::end(scenario);
  }

#[test]
#[expected_failure(abort_code = clamm::errors::INVALID_FEE, location = clamm::stable_fees)]  
fun aborts_max_admin_fee() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
   
    next_tx(test, alice);
    {
      let mut fees = stable_fees::new();

      stable_fees::commit_admin_fee(&mut fees, option::some(MAX_ADMIN_FEE + 1), test.ctx());
    };
    test::end(scenario);
  }

#[test]
#[expected_failure(abort_code = clamm::errors::MUST_WAIT_TO_UPDATE_FEES, location = clamm::stable_fees)]  
fun commit_fee_aborts_on_early_update() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
   
    next_tx(test, alice);
    {
      let mut fees = stable_fees::new();

      stable_fees::commit_fee(&mut fees, option::some(2), test.ctx());
      test.next_epoch(@0x0);
      test.next_epoch(@0x0);

      stable_fees::update_fee(&mut fees, test.ctx());
    };
    test::end(scenario);
  }

#[test]
#[expected_failure(abort_code = clamm::errors::MUST_WAIT_TO_UPDATE_FEES, location = clamm::stable_fees)]  
fun commit_admin_fee_aborts_on_early_update() {
    let mut scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
   
    next_tx(test, alice);
    {
      let mut fees = stable_fees::new();

      stable_fees::commit_admin_fee(&mut fees, option::some(2), test.ctx());
      test.next_epoch(@0x0);

      stable_fees::update_admin_fee(&mut fees, test.ctx());
    };
    test::end(scenario);
  }
}