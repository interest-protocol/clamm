// * 2 Pool - USDC - ETH
// All values tested agaisnt Curve pool
#[test_only]
module clamm::volatile_donate_tests {
  use sui::clock;
  use sui::coin::{Self, mint_for_testing, burn_for_testing as burn};

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx}; 

  use clamm::interest_clamm_volatile;
  use clamm::eth::ETH;
  use clamm::usdc::USDC;
  use clamm::lp_coin::LP_COIN;
  use clamm::curves::Volatile;
  use clamm::interest_pool::InterestPool;
  use clamm::init_interest_amm_volatile::setup_2pool;
  use clamm::amm_test_utils ::{people, scenario, mint};

  const POW_10_18: u256 = 1_000_000_000_000_000_000;
  const POW_10_9: u256 = 1_000_000_000; 

  #[test]
  fun donate() {
    let mut scenario = scenario();
    let (alice, bob) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let c = clock::create_for_testing(ctx(test));

    next_tx(test, bob);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      burn(interest_clamm_volatile::add_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(6000, 6, ctx(test)),
        mint<ETH>(5, 9, ctx(test)),
        0,
        ctx(test)
      ));

      test::return_shared(pool);
    };

    next_tx(test, alice);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      let (usdc_coin, eth_coin) = interest_clamm_volatile::remove_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        mint_for_testing(38729833462, ctx(test)),
        vector[0, 0],
        ctx(test)
      );

      burn(usdc_coin);
      burn(eth_coin);
      
      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 251448807860);
      // Tested via hardhat
      assert_eq(251448807861, 251448807861405855986 / POW_10_9);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[9098576209855357549995, 6932248540842177181]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<USDC, LP_COIN>(&mut pool),
        9098576210
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<ETH, LP_COIN>(&mut pool),
        6932248541
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        1367804588351518548120
      );      
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );      
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1000056223494887386
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1000056223494887386
      );        
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        19478235978246022657288
      );        

      test::return_shared(pool);
    };      


   next_tx(test, bob);
    {
      let mut pool = test::take_shared<InterestPool<Volatile>>(test);

      burn(interest_clamm_volatile::add_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        &c,
        mint<USDC>(3555, 6, ctx(test)),
        coin::zero(ctx(test)),
        0,
        ctx(test)
      ));

      let (usdc_coin, eth_coin) = interest_clamm_volatile::remove_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        mint_for_testing(219195769861, ctx(test)),
        vector[0, 0],
        ctx(test)
      );

      burn(usdc_coin);
      burn(eth_coin);

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 77459666921);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[3303973826401858475884, 1810078617870579249]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<USDC, LP_COIN>(&mut pool),
        3303973827
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<ETH, LP_COIN>(&mut pool),
        1810078619
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        1539916488713355128601
      );      
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );      
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1000222557976786111
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1000222557976786111
      );        
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        6001335347621701613022
      );        

      test::return_shared(pool);
    };  

    clock::destroy_for_testing(c);
    test::end(scenario);
  }
}