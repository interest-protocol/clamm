module clamm::interest_clamm_stable_hooks {
  // === Imports ===

  use std::type_name;

  use sui::coin::Coin;
  use sui::clock::Clock;
  use sui::balance::Supply;

  use suitears::coin_decimals::CoinDecimals;

  use clamm::hooks;
  use clamm::curves::Stable;
  use clamm::interest_clamm_stable;
  use clamm::pool_admin::PoolAdmin;
  use clamm::interest_pool::{InterestPool, HooksBuilder, Request};

  public fun new_2_pool<CoinA, CoinB, LpCoin>(
    clock: &Clock,
    hooks_builder: HooksBuilder,
    initial_a: u256,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_decimals: &CoinDecimals,     
    lp_coin_supply: Supply<LpCoin>,
    ctx: &mut TxContext
  ): (InterestPool<Stable>, PoolAdmin, Coin<LpCoin>)  {
    let coins = vector[type_name::get<CoinA>(), type_name::get<CoinB>()];

    let (pool, pool_admin) = interest_clamm_stable::new_pool_with_hooks<LpCoin>( 
      hooks_builder,
      coin_decimals,
      initial_a, 
      lp_coin_supply, 
      coins,
      ctx
    );
    
    let (pool, lp_coin) = interest_clamm_stable::new_2_pool_impl<CoinA, CoinB, LpCoin>(
      pool,
      clock, 
      coin_a, 
      coin_b, 
      coin_decimals, 
      ctx
    );

    (pool, pool_admin, lp_coin)
  }

  public fun new_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    clock: &Clock,
    hooks_builder: HooksBuilder,
    initial_a: u256,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_decimals: &CoinDecimals,     
    lp_coin_supply: Supply<LpCoin>,
    ctx: &mut TxContext
  ): (InterestPool<Stable>, PoolAdmin, Coin<LpCoin>) {
    let coins = vector[type_name::get<CoinA>(), type_name::get<CoinB>(), type_name::get<CoinC>()];

    let (pool, pool_admin) = interest_clamm_stable::new_pool_with_hooks<LpCoin>( 
      hooks_builder,
      coin_decimals,
      initial_a, 
      lp_coin_supply, 
      coins,
      ctx
    );

    let (pool, lp_coin) = interest_clamm_stable::new_3_pool_impl<CoinA, CoinB, CoinC, LpCoin>(
      pool,
      clock, 
      coin_a, 
      coin_b,
      coin_c, 
      coin_decimals, 
      ctx
    );

    (pool, pool_admin, lp_coin)        
  }

  public fun new_4_pool<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    clock: &Clock,
    hooks_builder: HooksBuilder,
    initial_a: u256,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    coin_decimals: &CoinDecimals,      
    lp_coin_supply: Supply<LpCoin>,
    ctx: &mut TxContext
  ): (InterestPool<Stable>, PoolAdmin, Coin<LpCoin>) {
    let coins = vector[
      type_name::get<CoinA>(), 
      type_name::get<CoinB>(), 
      type_name::get<CoinC>(), 
      type_name::get<CoinD>()
    ];

    let (pool, pool_admin) = interest_clamm_stable::new_pool_with_hooks<LpCoin>( 
      hooks_builder,
      coin_decimals,
      initial_a, 
      lp_coin_supply, 
      coins,
      ctx
    );

    let (pool, lp_coin) = interest_clamm_stable::new_4_pool_impl<CoinA, CoinB, CoinC, CoinD, LpCoin>(
      pool,
      clock, 
      coin_a, 
      coin_b,
      coin_c, 
      coin_d,
      coin_decimals, 
      ctx
    );

    (pool, pool_admin, lp_coin)      
  }

  public fun new_5_pool<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    clock: &Clock,
    hooks_builder: HooksBuilder,
    initial_a: u256,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    coin_e: Coin<CoinE>,
    coin_decimals: &CoinDecimals,      
    lp_coin_supply: Supply<LpCoin>,
    ctx: &mut TxContext
  ): (InterestPool<Stable>, PoolAdmin, Coin<LpCoin>) {
    let coins = vector[
      type_name::get<CoinA>(), 
      type_name::get<CoinB>(), 
      type_name::get<CoinC>(), 
      type_name::get<CoinD>(),
      type_name::get<CoinE>()
    ];

    let (pool, pool_admin) = interest_clamm_stable::new_pool_with_hooks<LpCoin>( 
      hooks_builder,
      coin_decimals,
      initial_a, 
      lp_coin_supply, 
      coins,
      ctx
    );

    let (pool, lp_coin) = interest_clamm_stable::new_5_pool_impl<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
      pool,
      clock, 
      coin_a, 
      coin_b,
      coin_c, 
      coin_d,
      coin_e,
      coin_decimals, 
      ctx
    );

    (pool, pool_admin, lp_coin)   
  }

  public fun swap<CoinIn, CoinOut, LpCoin>(
    pool: &mut InterestPool<Stable>,
    request: Request,
    clock: &Clock,
    coin_in: Coin<CoinIn>,
    min_amount: u64,
    ctx: &mut TxContext
  ): (Request, Coin<CoinOut>) {
    let request = hooks::finish_swap(pool, request);

    (
      request,
      interest_clamm_stable::swap_impl<CoinIn, CoinOut, LpCoin>(pool, clock, coin_in, min_amount, ctx)
    )
  }  

  public fun add_liquidity_2_pool<CoinA, CoinB, LpCoin>(
    pool: &mut InterestPool<Stable>,
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
      interest_clamm_stable::add_liquidity_2_pool_impl(pool, clock, coin_a, coin_b, lp_coin_min_amount, ctx)
    )
  } 

  public fun add_liquidity_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Stable>,
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
      interest_clamm_stable::add_liquidity_3_pool_impl(pool, clock, coin_a, coin_b, coin_c, lp_coin_min_amount, ctx)
    )
  } 

  public fun add_liquidity_4_pool<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    pool: &mut InterestPool<Stable>,
    request: Request,      
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): (Request, Coin<LpCoin>) {
    let request = hooks::finish_add_liquidity(pool, request);

    (
      request,
      interest_clamm_stable::add_liquidity_4_pool_impl(
        pool, 
        clock, 
        coin_a, 
        coin_b, 
        coin_c, 
        coin_d, 
        lp_coin_min_amount, 
        ctx
      )      
    )    
  }

  public fun add_liquidity_5_pool<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    pool: &mut InterestPool<Stable>,
    request: Request,      
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    coin_e: Coin<CoinE>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): (Request, Coin<LpCoin>) {
    let request = hooks::finish_add_liquidity(pool, request);

    (
      request,
      interest_clamm_stable::add_liquidity_5_pool_impl(
        pool, 
        clock, 
        coin_a, 
        coin_b, 
        coin_c, 
        coin_d, 
        coin_e,
        lp_coin_min_amount, 
        ctx
      )        
    )    
  } 

  public fun remove_liquidity_2_pool<CoinA, CoinB, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    request: Request,  
    lp_coin: Coin<LpCoin>,
    clock: &Clock,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Request, Coin<CoinA>, Coin<CoinB>) {
    let request = hooks::finish_remove_liquidity(pool, request);

    let (coin_a, coin_b) = interest_clamm_stable::remove_liquidity_2_pool_impl(
      pool,
      clock,
      lp_coin,        
      min_amounts, 
      ctx
    );

    (
      request,
      coin_a,
      coin_b
    )
  }   

  public fun remove_liquidity_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    request: Request,  
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Request, Coin<CoinA>, Coin<CoinB>, Coin<CoinC>) {
    let request = hooks::finish_remove_liquidity(pool, request);

    let (coin_a, coin_b, coin_c) = interest_clamm_stable::remove_liquidity_3_pool_impl(
      pool,
      clock,
      lp_coin,        
      min_amounts, 
      ctx
    );

    (
      request,
      coin_a,
      coin_b,
      coin_c,
    )
  }  

  public fun remove_liquidity_4_pool<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    request: Request,     
    clock: &Clock,     
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Request, Coin<CoinA>, Coin<CoinB>, Coin<CoinC>, Coin<CoinD>) {
    let request = hooks::finish_remove_liquidity(pool, request);

    let (coin_a, coin_b, coin_c, coin_d) = interest_clamm_stable::remove_liquidity_4_pool_impl(
      pool,
      clock,
      lp_coin,        
      min_amounts, 
      ctx
    );

    (
      request,
      coin_a,
      coin_b,
      coin_c,
      coin_d
    )
  }

  public fun remove_liquidity_5_pool<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    request: Request,         
    lp_coin: Coin<LpCoin>,
    clock: &Clock,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Request, Coin<CoinA>, Coin<CoinB>, Coin<CoinC>, Coin<CoinD>, Coin<CoinE>) {
    let request = hooks::finish_remove_liquidity(pool, request);
    
    let (coin_a, coin_b, coin_c, coin_d, coin_e) = interest_clamm_stable::remove_liquidity_5_pool_impl(
      pool,
      clock,
      lp_coin,        
      min_amounts, 
      ctx
    );

    (
      request,
      coin_a,
      coin_b,
      coin_c,
      coin_d,
      coin_e
    )    
  }

  public fun remove_one_coin_liquidity<CoinType, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    request: Request,  
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amount: u64,
    ctx: &mut TxContext    
  ): (Request, Coin<CoinType>) {
    let request = hooks::finish_remove_liquidity(pool, request);

    (
      request,
      interest_clamm_stable::remove_one_coin_liquidity_impl(
        pool,
        clock,
        lp_coin,
        min_amount, 
        ctx
      )
    )
  }        
}
