module clamm::interest_clamm_volatile_hooks {
  // === Imports ===

  use std::type_name;

  use sui::coin::Coin;
  use sui::clock::Clock;
  use sui::balance::Supply;
  
  use suitears::coin_decimals::CoinDecimals;

  use clamm::hooks;
  use clamm::curves::Volatile;
  use clamm::pool_admin::PoolAdmin;
  use clamm::pool_events as events;
  use clamm::interest_clamm_volatile;
  use clamm::interest_pool::{HooksBuilder, Request, InterestPool};

  public fun new_2_pool<CoinA, CoinB, LpCoin>(
    clock: &Clock,
    hooks_builder: HooksBuilder,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_decimals: &CoinDecimals,     
    lp_coin_supply: Supply<LpCoin>,
    initial_a_gamma: vector<u256>,
    rebalancing_params: vector<u256>,
    price: u256, // @ on a pool with 2 coins, we only need 1 price
    fee_params: vector<u256>, 
    ctx: &mut TxContext
  ): (InterestPool<Volatile>, PoolAdmin, Coin<LpCoin>) {
    let (mut pool, pool_admin) = interest_clamm_volatile::new_pool_with_hooks<LpCoin>(
      clock,
      hooks_builder,
      vector[type_name::get<CoinA>(), type_name::get<CoinB>()],
      coin_decimals,
      lp_coin_supply,
      vector[0, 0],
      initial_a_gamma,
      rebalancing_params,
      fee_params,
      ctx
    );

    let lp_coin = interest_clamm_volatile::register_2_pool(
      &mut pool,
      clock,
      coin_a,
      coin_b,
      coin_decimals,
      price,
      ctx
    );

    events::emit_new_2_pool<Volatile, CoinA, CoinB, LpCoin>(pool.addy());

    (pool, pool_admin, lp_coin)   
  }  

  public fun new_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    clock: &Clock,
    hooks_builder: HooksBuilder,    
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_decimals: &CoinDecimals,     
    lp_coin_supply: Supply<LpCoin>,
    initial_a_gamma: vector<u256>,
    rebalancing_params: vector<u256>,
    prices: vector<u256>, // @ on a pool with 3 coins, we only need 2 prices
    fee_params: vector<u256>, 
    ctx: &mut TxContext
  ): (InterestPool<Volatile>, PoolAdmin, Coin<LpCoin>) {
    let (mut pool, pool_admin) = interest_clamm_volatile::new_pool_with_hooks<LpCoin>(
      clock,
      hooks_builder,
      vector[type_name::get<CoinA>(), type_name::get<CoinB>(), type_name::get<CoinC>()],
      coin_decimals,
      lp_coin_supply,
      vector[0, 0, 0],
      initial_a_gamma,
      rebalancing_params,
      fee_params,
      ctx
    );

    let lp_coin = interest_clamm_volatile::register_3_pool(
      &mut pool,
      clock,
      coin_a,
      coin_b,
      coin_c,
      coin_decimals,
      prices,
      ctx
    );    

    events::emit_new_3_pool<Volatile, CoinA, CoinB, CoinC, LpCoin>(pool.addy());

    (pool, pool_admin, lp_coin)
  }  

  public fun swap<CoinIn, CoinOut, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    request: Request,
    clock: &Clock,
    coin_in: Coin<CoinIn>,
    mint_amount: u64,
    ctx: &mut TxContext
  ): (Request, Coin<CoinOut>) {
    let request = hooks::finish_swap(pool, request);

    (
     request,
     interest_clamm_volatile::swap_impl<CoinIn, CoinOut, LpCoin>(pool, clock, coin_in, mint_amount, ctx)
    )
  }  

  public fun add_liquidity_2_pool<CoinA, CoinB, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    request: Request,    
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext      
  ): (Request, Coin<LpCoin>) {
   let request = hooks::finish_add_liquidity(pool, request);

   (
     request,
     interest_clamm_volatile::add_liquidity_2_pool_impl(pool, clock, coin_a, coin_b, lp_coin_min_amount, ctx)
   )
  }  

  public fun add_liquidity_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    request: Request,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext      
  ): (Request, Coin<LpCoin>) {
   let request = hooks::finish_add_liquidity(pool, request);

   (
     request,
     interest_clamm_volatile::add_liquidity_3_pool_impl(pool, clock, coin_a, coin_b, coin_c, lp_coin_min_amount, ctx)
   )
  }  

  public fun remove_liquidity_2_pool<CoinA, CoinB, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    request: Request,    
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Request, Coin<CoinA>, Coin<CoinB>) {
   let request = hooks::finish_remove_liquidity(pool, request);

   let (coin_a, coin_b) = interest_clamm_volatile::remove_liquidity_2_pool_impl(pool, lp_coin, min_amounts, ctx);

   (
    request,
    coin_a,
    coin_b
   )
  } 

  public fun remove_liquidity_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    request: Request,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Request, Coin<CoinA>, Coin<CoinB>, Coin<CoinC>) {
   let request = hooks::finish_remove_liquidity(pool, request);

   let (coin_a, coin_b, coin_c) = interest_clamm_volatile::remove_liquidity_3_pool_impl(pool, lp_coin, min_amounts, ctx);

   (
    request,
    coin_a,
    coin_b,
    coin_c
   )
  }   

  public fun remove_liquidity_one_coin<CoinOut, LpCoin>(
    pool: &mut InterestPool<Volatile>,
    request: Request,
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amount: u64,
    ctx: &mut TxContext    
  ): (Request, Coin<CoinOut>) {
   let request = hooks::finish_remove_liquidity(pool, request);

   (
    request,
    interest_clamm_volatile::remove_liquidity_one_coin_impl(pool, clock, lp_coin, min_amount, ctx)
   )
  }
 }
