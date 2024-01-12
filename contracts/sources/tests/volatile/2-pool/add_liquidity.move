// * 2 Pool - USDC - ETH
#[test_only]
module amm::volatile_2pool_add_liquidity_tests {
  use std::vector;
  use std::type_name;
  
  use sui::clock;
  use sui::coin::{Self, burn_for_testing as burn, TreasuryCap};

  use sui::test_utils::assert_eq;
  use sui::test_scenario::{Self as test, next_tx, ctx}; 

  use amm::interest_amm_volatile;
  use amm::eth::ETH;
  use amm::usdc::USDC;
  use amm::lp_coin::LP_COIN;
  use amm::curves::Volatile;
  use amm::interest_pool::InterestPool;
  use amm::init_interest_amm_volatile::setup_2pool;
  use amm::amm_test_utils ::{people, scenario, normalize_amount};

  const POW_10_9: u256 = 1_000_000_000; 

  #[test]
  fun mints_correct_lp_coin_amount() {
    let scenario = scenario();
    let (alice, _) = people();

    let test = &mut scenario;
    
    setup_2pool(test, 4500, 3);
    let c = clock::create_for_testing(ctx(test));

    next_tx(test, alice);
    {
      let pool = test::take_shared<InterestPool<Volatile>>(test);

      assert_eq(interest_amm_volatile::lp_coin_supply<LP_COIN>(&pool), 116189500386);
      assert_eq(116189500386, 116189500386222506555 / POW_10_9);
      // expect(await lpCoin.totalSupply()).to.be.equal(116189500386222506555n);

      // expect(await lpCoin.balanceOf(alice.address)).to.be.equal(
      //   116189500386222506555n
      // );

      // expect(await pool.balances(0n)).to.be.equal(4500000000n);
      // expect(await pool.balances(1n)).to.be.equal(3000000000000000000n);
      // expect(await pool.last_prices()).to.be.equal(1500000000000000000000n);
      // expect(await pool.price_scale()).to.be.equal(1500000000000000000000n);
      // expect(await pool.price_oracle()).to.be.equal(1500000000000000000000n);
      // expect(await pool.xcp_profit()).to.be.equal(1000000000000000000n);
      // expect(await pool.xcp_profit_a()).to.be.equal(1000000000000000000n);
      // expect(await pool.virtual_price()).to.be.equal(1000000000000000000n);
      // expect(await pool.D()).to.be.equal(9000000000000000000000n);      

      test::return_shared(pool);
    };
    clock::destroy_for_testing(c);
    test::end(scenario);     
  }
}