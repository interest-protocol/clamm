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
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        9098576210
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
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
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        3303973827
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
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

  #[test]
  fun remove_liquidity_extreme_eth_swaps() {
    let mut scenario = scenario();
    let (alice, bob) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let mut c = clock::create_for_testing(ctx(test));

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

      let mut i = 0;

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
      
      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 251448807860);
      
      // Tested via hardhat
      assert_eq(251448807861, 251448807861405855986 / POW_10_9);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[3587414965616019089300, 17330621352105442953]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        3587414968
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
        17330621353
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        246565883037842960398
      );      
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1499933264493766793129
      );      
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1002087792956895040
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1002087792956895040
      );        
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        19517805142912330595522
      );        

      test::return_shared(pool);
    };       

    clock::destroy_for_testing(c);
    test::end(scenario);
  }

  #[test]
  fun remove_liquidity_extreme_usdc_swaps() {
    let mut scenario = scenario();
    let (alice, bob) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let mut c = clock::create_for_testing(ctx(test));

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

      let mut i = 0;

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
      
      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 251448807860);
      
      // Tested via hardhat
      assert_eq(251448807861, 251448807861405855986 / POW_10_9);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[32321608821676651106172, 1920807053509066272]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        32321608822
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
        1920807056
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        13639228872865109276453
      );      
     assert_eq(
        interest_clamm_volatile::coin_price<ETH, LP_COIN>(&mut pool),
        1500000000000000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_price_oracle<ETH, LP_COIN>(&mut pool),
        1500284960352159814125
      );      
     assert_eq(
        interest_clamm_volatile::xcp_profit<LP_COIN>(&mut pool),
        1003051490489599446
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1003051490489599446
      );        
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        19536575215546913682971
      );        

      test::return_shared(pool);
    };       

    clock::destroy_for_testing(c);
    test::end(scenario);
  }  

  #[test]
  fun remove_liquidity_one_coin() {
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

      let usdc_coin = interest_clamm_volatile::remove_liquidity_one_coin<USDC, LP_COIN>(
        &mut pool,
        &c,
        mint_for_testing(38729833462, ctx(test)),
        0,
        ctx(test)
      );

      burn(usdc_coin);
      
      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 251448807860);
      // Tested via hardhat
      assert_eq(251448807861, 251448807861405855986 / POW_10_9);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[7851351910820630387868, 8000000000000000000]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        7851351911
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
        8000000000
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        1168084846215123664094
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
        1000172342468238067
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1000172342468238067
      );        
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        19480497643847614287979
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

      let eth_coin = interest_clamm_volatile::remove_liquidity_one_coin<ETH, LP_COIN>(
        &mut pool,
        &c,
        mint_for_testing(224642009232, ctx(test)),
        0,
        ctx(test)
      );

      burn(eth_coin);

      assert_eq(interest_clamm_volatile::lp_coin_supply<LP_COIN>(&mut pool), 77459666920);

      assert_eq(
        interest_clamm_volatile::balances<LP_COIN>(&mut pool),
        vector[11406351910820630387868, 513445449702642408]
      );
      assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, USDC>(&mut pool),
        11406351911
      );
     assert_eq(
        interest_clamm_volatile::coin_balance<LP_COIN, ETH>(&mut pool),
        513445450
      );
     assert_eq(
        interest_clamm_volatile::coin_last_price<ETH, LP_COIN>(&mut pool),
        5515585533267870899068
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
        1001121548095451631
      );  
     assert_eq(
        interest_clamm_volatile::xcp_profit_a<LP_COIN>(&mut pool),
        POW_10_18
      );  
     assert_eq(
        interest_clamm_volatile::virtual_price<LP_COIN>(&mut pool),
        1001121548095451631
      );        
     assert_eq(
        interest_clamm_volatile::invariant_<LP_COIN>(&mut pool),
        6006729288251020546217
      );        

      test::return_shared(pool);
    };  

    clock::destroy_for_testing(c);
    test::end(scenario);
  }  
}