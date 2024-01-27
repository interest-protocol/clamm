// * 2 Pool - USDC - ETH
// All values tested agaisnt Curve pool
#[test_only]
module clamm::volatile_2pool_remove_liquidity_tests {
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

  const TWENTY_MILLISECONDS: u64 = 22000;
  const POW_10_18: u256 = 1_000_000_000_000_000_000;
  const POW_10_9: u256 = 1_000_000_000; 

  #[test]
  fun remove_liquidity() {
    let scenario = scenario();
    let (alice, bob) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let c = clock::create_for_testing(ctx(test));

    next_tx(test, bob);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

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
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      let (usdc_coin, eth_coin) = interest_clamm_volatile::remove_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        mint_for_testing(38729833462, ctx(test)),
        vector[0, 0],
        ctx(test)
      );

      burn(usdc_coin);
      burn(eth_coin);
      
      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&pool), 251448807860);
      // Tested via hardhat
      assert_eq(251448807861, 251448807861405855986 / POW_10_9);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&pool),
        vector[9098576209819172943326, 6932248540814607957]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        9098576210
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        6932248541
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        1367804588351518548120
      );      
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );      
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&pool),
        1000056223491914378
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&pool),
        1000056223491914378
      );        
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&pool),
        19478235978246022657288
      );        

      test::return_shared(pool);
    };      


   next_tx(test, bob);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

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

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&pool), 77459666920);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&pool),
        vector[3303973826318239492047, 1810078617822746243]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        3303973827
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        1810078619
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        1539916488761882793572
      );      
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );      
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&pool),
        1000222557975363577
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&pool),
        1000222557975363577
      );        
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&pool),
        6001335347543997799284
      );        

      test::return_shared(pool);
    };  

    clock::destroy_for_testing(c);
    test::end(scenario);
  }

  #[test]
  fun remove_liquidity_extreme_eth_swaps() {
    let scenario = scenario();
    let (alice, bob) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let c = clock::create_for_testing(ctx(test));

    next_tx(test, bob);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

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
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      let i = 0;

      while (4 > i) {
        burn(interest_clamm_volatile::swap<ETH, USDC, LP_COIN>(
          &mut pool,
          &c,
          mint(3, 9, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        i = i + 1;
      };

      let (usdc_coin, eth_coin) = interest_clamm_volatile::remove_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        mint_for_testing(38729833462, ctx(test)),
        vector[0, 0],
        ctx(test)
      );

      burn(usdc_coin);
      burn(eth_coin);
      
      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&pool), 251448807860);
      
      // Tested via hardhat
      assert_eq(251448807861, 251448807861405855986 / POW_10_9);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&pool),
        vector[3587414965601752109885, 17330621352036519893]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        3587414968
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        17330621353
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        246565883037842960398
      );      
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1499933439881252717241
      );      
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&pool),
        1002087792956895040
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&pool),
        1002087792956895040
      );        
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&pool),
        19517805142912330595522
      );        

      test::return_shared(pool);
    };       

    clock::destroy_for_testing(c);
    test::end(scenario);
  }

  #[test]
  fun remove_liquidity_extreme_usdc_swaps() {
    let scenario = scenario();
    let (alice, bob) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let c = clock::create_for_testing(ctx(test));

    next_tx(test, bob);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

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
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      let i = 0;

      while (4 > i) {
        burn(interest_clamm_volatile::swap<USDC, ETH, LP_COIN>(
          &mut pool,
          &c,
          mint(6700, 6, ctx(test)),
          0,
          ctx(test)
          )
        );

        clock::increment_for_testing(&mut c, TWENTY_MILLISECONDS);

        i = i + 1;
      };

      let (usdc_coin, eth_coin) = interest_clamm_volatile::remove_liquidity_2_pool<USDC, ETH, LP_COIN>(
        &mut pool,
        mint_for_testing(38729833462, ctx(test)),
        vector[0, 0],
        ctx(test)
      );

      burn(usdc_coin);
      burn(eth_coin);
      
      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&pool), 251448807860);
      
      // Tested via hardhat
      assert_eq(251448807861, 251448807861405855986 / POW_10_9);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&pool),
        vector[32321608821548109598672, 1920807053501427313]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&pool),
        32321608822
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&pool),
        1920807056
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&pool),
        13639228872865109276453
      );      
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&pool),
        1500284211441601879898
      );      
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&pool),
        1003051490489599446
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&pool),
        1003051490489599446
      );        
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&pool),
        19536575215546913682971
      );        

      test::return_shared(pool);
    };       

    clock::destroy_for_testing(c);
    test::end(scenario);
  }  
}