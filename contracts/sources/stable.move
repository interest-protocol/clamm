module clamm::interest_clamm_stable {
  // === Imports ===

  use std::type_name::{Self, TypeName};

  use sui::{
    clock::Clock,
    bag::{Self, Bag},
    coin::{Self, Coin},
    vec_map::{Self, VecMap},
    versioned::{Self, Versioned},
    balance::{Self, Supply, Balance}
  };

  use suitears::{
    math256::{min, diff},
    coin_decimals::CoinDecimals
  };

  use clamm::{
    errors,
    curves::Stable,
    pool_admin::PoolAdmin,
    pool_events as events,
    stable_fees::{Self, StableFees},
    stable_math::{y, y_lp, y_d, a as get_a, invariant_},
    interest_pool::{Self, InterestPool, HooksBuilder, Request},
    utils::{Self, empty_vector, make_coins_vec_set_from_vector},
  };

  use fun coin::take as Balance.take;
  use fun utils::to_u64 as u256.to_u64;
  use fun utils::to_u256 as u64.to_u256;
  use fun coin::from_balance as Balance.to_coin;

  // === Constants ===

  const STATE_V1_VERSION: u64 = 1;
  const MAX_A: u256 = 1_000_000;
  const MAX_A_CHANGE: u256 = 10;
  /// @dev 1 day in milliseconds
  const MIN_RAMP_TIME: u64 = 86_400_000;
  /// @dev 1e18 
  const PRECISION: u256 = 1_000_000_000_000_000_000; 

  // === Structs ===

  public struct CoinMetadata has store {
    /// Decimals of the `sui::coin::Coin`
    decimals: u256,
    /// The index of the `sui::coin::Coin` in the state balances vector.  
    index: u64
  }

  public struct StateV1<phantom LpCoin> has key, store {
    id: UID,
    /// The supply of the pool's `LpCoin`.
    lp_coin_supply: Supply<LpCoin>,
    /// The decimal precision of the `LpCoin`.
    lp_coin_decimals_scalar: u256,
    /// The balances of the coin in the pool based in the coin index.   
    balances: vector<u256>,
    /// The initial amplifier factor.
    initial_a: u256,
    /// The new amplifier factor.
    /// We need to update the amplifier overtime to prevent impermanent loss. 
    future_a: u256,
    /// The initial ramp time.
    initial_a_time: u256,
    /// The future_a_time - initial_a_time gives us the duration of the ramp time to linearly update initial_a to future_a. 
    future_a_time: u256,
    /// Number of coins in the pool.   
    n_coins: u64,
    /// Holds the fee settings for the pool.  
    fees: StableFees,
    /// TypeName => CoinState
    coin_balances: Bag,
    coin_metadatas: VecMap<TypeName, CoinMetadata>,
    /// TypeName => Balance
    admin_balances: Bag
  }  

  // === Public-Mutative Functions ===

  public fun new_2_pool<CoinA, CoinB, LpCoin>(
    clock: &Clock,
    coin_decimals: &CoinDecimals,    
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>, 
    lp_coin_supply: Supply<LpCoin>,
    initial_a: u256,
    ctx: &mut TxContext
  ): (InterestPool<Stable>, Coin<LpCoin>)  {
    let coins = vector[type_name::get<CoinA>(), type_name::get<CoinB>()];

    let pool = new_pool<LpCoin>( 
      coin_decimals,
      initial_a, 
      lp_coin_supply, 
      coins,
      ctx
    );
    
    let (pool, lp_coin) = new_2_pool_impl<CoinA, CoinB, LpCoin>(
      pool,
      clock, 
      coin_a, 
      coin_b, 
      coin_decimals, 
      ctx
    );

    (pool, lp_coin)
  }

  public fun new_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    clock: &Clock,
    coin_decimals: &CoinDecimals,     
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    lp_coin_supply: Supply<LpCoin>,
    initial_a: u256,
    ctx: &mut TxContext
  ): (InterestPool<Stable>, Coin<LpCoin>) {
    let coins = vector[type_name::get<CoinA>(), type_name::get<CoinB>(), type_name::get<CoinC>()];

    let pool = new_pool<LpCoin>( 
      coin_decimals,
      initial_a, 
      lp_coin_supply, 
      coins,
      ctx
    );

    let (pool, lp_coin) = new_3_pool_impl<CoinA, CoinB, CoinC, LpCoin>(
      pool,
      clock, 
      coin_a, 
      coin_b,
      coin_c, 
      coin_decimals, 
      ctx
    );

    (pool, lp_coin)        
  }

  public fun new_4_pool<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    clock: &Clock,
    coin_decimals: &CoinDecimals,   
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,   
    lp_coin_supply: Supply<LpCoin>,
    initial_a: u256,
    ctx: &mut TxContext
  ): (InterestPool<Stable>, Coin<LpCoin>) {
    let coins = vector[
      type_name::get<CoinA>(), 
      type_name::get<CoinB>(), 
      type_name::get<CoinC>(), 
      type_name::get<CoinD>()
    ];

    let pool = new_pool<LpCoin>( 
      coin_decimals,
      initial_a, 
      lp_coin_supply, 
      coins,
      ctx
    );

    let (pool, lp_coin) = new_4_pool_impl<CoinA, CoinB, CoinC, CoinD, LpCoin>(
      pool,
      clock, 
      coin_a, 
      coin_b,
      coin_c, 
      coin_d,
      coin_decimals, 
      ctx
    );

    (pool, lp_coin)      
  }

  public fun new_5_pool<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    clock: &Clock,
    coin_decimals: &CoinDecimals,   
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    coin_e: Coin<CoinE>,   
    lp_coin_supply: Supply<LpCoin>,
    initial_a: u256,
    ctx: &mut TxContext
  ): (InterestPool<Stable>, Coin<LpCoin>) {
    let coins = vector[
      type_name::get<CoinA>(), 
      type_name::get<CoinB>(), 
      type_name::get<CoinC>(), 
      type_name::get<CoinD>(),
      type_name::get<CoinE>()
    ];

    let pool = new_pool<LpCoin>( 
      coin_decimals,
      initial_a, 
      lp_coin_supply, 
      coins,
      ctx
    );

    let (pool, lp_coin) = new_5_pool_impl<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
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

    (pool, lp_coin)   
  }

  public fun swap<CoinIn, CoinOut, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    coin_in: Coin<CoinIn>,
    min_amount: u64,
    ctx: &mut TxContext
  ): Coin<CoinOut> {
    assert!(!pool.has_swap_hooks(), errors::pool_has_no_swap_hooks());
    swap_impl<CoinIn, CoinOut, LpCoin>(pool, clock, coin_in, min_amount, ctx)
  }

  public fun add_liquidity_2_pool<CoinA, CoinB, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    assert!(!pool.has_add_liquidity_hooks(), errors::pool_has_no_add_liquidity_hooks());
    add_liquidity_2_pool_impl<CoinA, CoinB, LpCoin>(pool, clock, coin_a, coin_b, lp_coin_min_amount, ctx)
  }  

  public fun add_liquidity_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    assert!(!pool.has_add_liquidity_hooks(), errors::pool_has_no_add_liquidity_hooks());
    add_liquidity_3_pool_impl<CoinA, CoinB, CoinC, LpCoin>(
      pool, 
      clock, 
      coin_a, 
      coin_b, 
      coin_c,
      lp_coin_min_amount, 
      ctx
    )
  }

  public fun add_liquidity_4_pool<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    assert!(!pool.has_add_liquidity_hooks(), errors::pool_has_no_add_liquidity_hooks());
    add_liquidity_4_pool_impl<CoinA, CoinB, CoinC, CoinD, LpCoin>(
      pool, 
      clock, 
      coin_a, 
      coin_b, 
      coin_c,
      coin_d,
      lp_coin_min_amount, 
      ctx
    )    
  }

  public fun add_liquidity_5_pool<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    coin_e: Coin<CoinE>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    assert!(!pool.has_add_liquidity_hooks(), errors::pool_has_no_add_liquidity_hooks());
    add_liquidity_5_pool_impl<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
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
  }

  public fun donate<CoinType, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    coin_in: Coin<CoinType>,    
  ) {
    assert!(!pool.has_donate_hooks(), errors::pool_has_no_donate_hooks());
    donate_impl<CoinType, LpCoin>(pool, coin_in);
  } 

  public fun remove_liquidity_2_pool<CoinA, CoinB, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>) {
    assert!(!pool.has_remove_liquidity_hooks(), errors::pool_has_no_remove_liquidity_hooks());
    remove_liquidity_2_pool_impl(pool, clock, lp_coin, min_amounts, ctx)
  }

  public fun remove_liquidity_3_pool<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>, Coin<CoinC>) {
    assert!(!pool.has_remove_liquidity_hooks(), errors::pool_has_no_remove_liquidity_hooks());
    remove_liquidity_3_pool_impl(pool, clock, lp_coin, min_amounts, ctx)
  }

  public fun remove_liquidity_4_pool<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>, Coin<CoinC>, Coin<CoinD>) {
    assert!(!pool.has_remove_liquidity_hooks(), errors::pool_has_no_remove_liquidity_hooks());
    remove_liquidity_4_pool_impl(pool, clock, lp_coin, min_amounts, ctx)    
  }

  public fun remove_liquidity_5_pool<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>, Coin<CoinC>, Coin<CoinD>, Coin<CoinE>) {
    assert!(!pool.has_remove_liquidity_hooks(), errors::pool_has_no_remove_liquidity_hooks());
    remove_liquidity_5_pool_impl(pool, clock, lp_coin, min_amounts, ctx)       
  }

  public fun remove_liquidity_one_coin<CoinType, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amount: u64,
    ctx: &mut TxContext    
  ): Coin<CoinType> {
    assert!(!pool.has_remove_liquidity_hooks(), errors::pool_has_no_remove_liquidity_hooks());
    remove_liquidity_one_coin_impl(pool, clock, lp_coin, min_amount, ctx)
  }

  public fun new_2_pool_with_hooks<CoinA, CoinB, LpCoin>(
    clock: &Clock,
    coin_decimals: &CoinDecimals,  
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,   
    lp_coin_supply: Supply<LpCoin>,
    initial_a: u256,
    ctx: &mut TxContext
  ): (InterestPool<Stable>, HooksBuilder, Coin<LpCoin>)  {
    let coins = vector[type_name::get<CoinA>(), type_name::get<CoinB>()];

    let (pool, hooks_builder) = new_pool_with_hooks<LpCoin>( 
      coin_decimals,
      initial_a, 
      lp_coin_supply, 
      coins,
      ctx
    );
    
    let (pool, lp_coin) = new_2_pool_impl<CoinA, CoinB, LpCoin>(
      pool,
      clock, 
      coin_a, 
      coin_b, 
      coin_decimals, 
      ctx
    );

    (pool, hooks_builder, lp_coin)
  }

  public fun new_3_pool_with_hooks<CoinA, CoinB, CoinC, LpCoin>(
    clock: &Clock,
    coin_decimals: &CoinDecimals,    
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>, 
    lp_coin_supply: Supply<LpCoin>,
    initial_a: u256,
    ctx: &mut TxContext
  ): (InterestPool<Stable>, HooksBuilder, Coin<LpCoin>) {
    let coins = vector[type_name::get<CoinA>(), type_name::get<CoinB>(), type_name::get<CoinC>()];

    let (pool, hooks_builder) = new_pool_with_hooks<LpCoin>( 
      coin_decimals,
      initial_a, 
      lp_coin_supply, 
      coins,
      ctx
    );

    let (pool, lp_coin) = new_3_pool_impl<CoinA, CoinB, CoinC, LpCoin>(
      pool,
      clock, 
      coin_a, 
      coin_b,
      coin_c, 
      coin_decimals, 
      ctx
    );

    (pool, hooks_builder, lp_coin)        
  }

  public fun new_4_pool_with_hooks<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    clock: &Clock,
    coin_decimals: &CoinDecimals,  
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,    
    lp_coin_supply: Supply<LpCoin>,
    initial_a: u256,
    ctx: &mut TxContext
  ): (InterestPool<Stable>, HooksBuilder, Coin<LpCoin>) {
    let coins = vector[
      type_name::get<CoinA>(), 
      type_name::get<CoinB>(), 
      type_name::get<CoinC>(), 
      type_name::get<CoinD>()
    ];

    let (pool, hooks_builder) = new_pool_with_hooks<LpCoin>( 
      coin_decimals,
      initial_a, 
      lp_coin_supply, 
      coins,
      ctx
    );

    let (pool, lp_coin) = new_4_pool_impl<CoinA, CoinB, CoinC, CoinD, LpCoin>(
      pool,
      clock, 
      coin_a, 
      coin_b,
      coin_c, 
      coin_d,
      coin_decimals, 
      ctx
    );

    (pool, hooks_builder, lp_coin)      
  }

  public fun new_5_pool_with_hooks<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    clock: &Clock,
    coin_decimals: &CoinDecimals,   
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    coin_e: Coin<CoinE>,   
    lp_coin_supply: Supply<LpCoin>,
    initial_a: u256,
    ctx: &mut TxContext
  ): (InterestPool<Stable>, HooksBuilder, Coin<LpCoin>) {
    let coins = vector[
      type_name::get<CoinA>(), 
      type_name::get<CoinB>(), 
      type_name::get<CoinC>(), 
      type_name::get<CoinD>(),
      type_name::get<CoinE>()
    ];

    let (pool, hooks_builder) = new_pool_with_hooks<LpCoin>( 
      coin_decimals,
      initial_a, 
      lp_coin_supply, 
      coins,
      ctx
    );

    let (pool, lp_coin) = new_5_pool_impl<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
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

    (pool, hooks_builder, lp_coin)   
  }

  public fun swap_with_hooks<CoinIn, CoinOut, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    request: Request,
    coin_in: Coin<CoinIn>,
    min_amount: u64,
    ctx: &mut TxContext
  ): (Request, Coin<CoinOut>) {
    let request = pool.finish_swap(request);

    (
      request,
      swap_impl<CoinIn, CoinOut, LpCoin>(pool, clock, coin_in, min_amount, ctx)
    )
  }  

  public fun add_liquidity_2_pool_with_hooks<CoinA, CoinB, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    request: Request,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): (Request, Coin<LpCoin>) {
   let request = pool.finish_add_liquidity(request);

    (
      request,
      add_liquidity_2_pool_impl(pool, clock, coin_a, coin_b, lp_coin_min_amount, ctx)
    )
  } 

  public fun add_liquidity_3_pool_with_hooks<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    request: Request,   
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): (Request, Coin<LpCoin>) {
    let request = pool.finish_add_liquidity(request);

    (
      request,
      add_liquidity_3_pool_impl(pool, clock, coin_a, coin_b, coin_c, lp_coin_min_amount, ctx)
    )
  } 

  public fun add_liquidity_4_pool_with_hooks<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    pool: &mut InterestPool<Stable>,     
    clock: &Clock,
    request: Request, 
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): (Request, Coin<LpCoin>) {
    let request = pool.finish_add_liquidity(request);

    (
      request,
      add_liquidity_4_pool_impl(
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

  public fun add_liquidity_5_pool_with_hooks<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    pool: &mut InterestPool<Stable>,    
    clock: &Clock,
    request: Request,  
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    coin_e: Coin<CoinE>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): (Request, Coin<LpCoin>) {
    let request = pool.finish_add_liquidity(request);

    (
      request,
      add_liquidity_5_pool_impl(
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

  public fun donate_with_hooks<CoinType, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    request: Request,
    coin_in: Coin<CoinType>,    
  ): Request {
    let request = pool.finish_donate(request);
    donate_impl<CoinType, LpCoin>(pool, coin_in);
    
    request
  } 

  public fun remove_liquidity_2_pool_with_hooks<CoinA, CoinB, LpCoin>(
    pool: &mut InterestPool<Stable>,  
    clock: &Clock,
    request: Request, 
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Request, Coin<CoinA>, Coin<CoinB>) {
    let request = pool.finish_remove_liquidity(request);

    let (coin_a, coin_b) = remove_liquidity_2_pool_impl(
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

  public fun remove_liquidity_3_pool_with_hooks<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    request: Request, 
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Request, Coin<CoinA>, Coin<CoinB>, Coin<CoinC>) {
    let request = pool.finish_remove_liquidity(request);

    let (coin_a, coin_b, coin_c) = remove_liquidity_3_pool_impl(
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

  public fun remove_liquidity_4_pool_with_hooks<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    pool: &mut InterestPool<Stable>,  
    clock: &Clock,     
    request: Request, 
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Request, Coin<CoinA>, Coin<CoinB>, Coin<CoinC>, Coin<CoinD>) {
    let request = pool.finish_remove_liquidity(request);

    let (coin_a, coin_b, coin_c, coin_d) = remove_liquidity_4_pool_impl(
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

  public fun remove_liquidity_5_pool_with_hooks<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    pool: &mut InterestPool<Stable>,   
    clock: &Clock,    
    request: Request, 
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Request, Coin<CoinA>, Coin<CoinB>, Coin<CoinC>, Coin<CoinD>, Coin<CoinE>) {
    let request = pool.finish_remove_liquidity(request);
    
    let (coin_a, coin_b, coin_c, coin_d, coin_e) = remove_liquidity_5_pool_impl(
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

  public fun remove_liquidity_one_coin_with_hooks<CoinType, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    request: Request, 
    lp_coin: Coin<LpCoin>,
    min_amount: u64,
    ctx: &mut TxContext    
  ): (Request, Coin<CoinType>) {
    let request = pool.finish_remove_liquidity(request);

    (
      request,
      remove_liquidity_one_coin_impl(
        pool,
        clock,
        lp_coin,
        min_amount, 
        ctx
      )
    )
  } 

  // === Public-View Functions ===

  public fun balances<LpCoin>(pool: &mut InterestPool<Stable>): vector<u256> {
    load<LpCoin>(pool.state_mut()).balances
  }

  public fun initial_a<LpCoin>(pool: &mut InterestPool<Stable>): u256 {
    load<LpCoin>(pool.state_mut()).initial_a
  }

  public fun future_a<LpCoin>(pool: &mut InterestPool<Stable>): u256 {
    load<LpCoin>(pool.state_mut()).future_a
  }  

  public fun initial_a_time<LpCoin>(pool: &mut InterestPool<Stable>): u256 {
    load<LpCoin>(pool.state_mut()).initial_a_time
  }    

  public fun future_a_time<LpCoin>(pool: &mut InterestPool<Stable>): u256 {
    load<LpCoin>(pool.state_mut()).future_a_time
  }    

  public fun a<LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
  ): u256 {
    let state = load<LpCoin>(pool.state_mut());
    get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock)
  }

  public fun lp_coin_supply<LpCoin>(pool: &mut InterestPool<Stable>): u64 {
    load<LpCoin>(pool.state_mut()).lp_coin_supply.supply_value()
  }

  public fun lp_coin_decimals_scalar<LpCoin>(pool: &mut InterestPool<Stable>): u256 {
    load<LpCoin>(pool.state_mut()).lp_coin_decimals_scalar
  }  

  public fun n_coins<LpCoin>(pool: &mut InterestPool<Stable>): u64 {
    load<LpCoin>(pool.state_mut()).n_coins
  }

  public fun fees<LpCoin>(pool: &mut InterestPool<Stable>): StableFees {
    load<LpCoin>(pool.state_mut()).fees
  }

  public fun admin_balance<CoinType, LpCoin>(pool: &mut InterestPool<Stable>): u64 {
    load<LpCoin>(pool.state_mut()).admin_balances.borrow<TypeName, Balance<CoinType>>(type_name::get<CoinType>()).value()
  } 

  public fun coin_decimals_scalar<CoinType, LpCoin>(pool: &mut InterestPool<Stable>): u256 {
    let (_, decimals) = coin_state_metadata<CoinType, LpCoin>(load(pool.state_mut()));
    decimals
  } 

  public fun coin_index<CoinType, LpCoin>(pool: &mut InterestPool<Stable>): u8 {
    let (index, _) = coin_state_metadata<CoinType, LpCoin>(load(pool.state_mut()));
    (index as u8)
  }  

  public fun coin_balance<CoinType, LpCoin>(pool: &mut InterestPool<Stable>): u64 {
    coin_state_balance<CoinType, LpCoin>(load<LpCoin>(pool.state_mut())).value()
  }     
  
  // @dev Price is returned in 1e18
  public fun virtual_price<LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
  ): u256 {
    virtual_price_impl(load<LpCoin>(pool.state_mut()), clock)
  }

  public fun quote_swap<CoinIn, CoinOut, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    amount: u64    
  ): (u64, u64) {
    let state = load<LpCoin>(pool.state_mut());

    let (coin_in_index, coin_in_decimals) = coin_state_metadata<CoinIn, LpCoin>(state);
    let (coin_out_index, coin_out_decimals) = coin_state_metadata<CoinOut, LpCoin>(state);

    let normalized_value = amount.to_u256() * PRECISION / coin_in_decimals;

    let new_out_balance = y(
      get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock),
      coin_in_index.to_u256(),
      coin_out_index.to_u256(),
      state.balances[coin_in_index] + normalized_value,
      state.balances
    );

    let amount_out = state.balances[coin_out_index] - new_out_balance;
    let fee = state.fees.calculate_fee(amount_out);
    let amount_out = ((amount_out - fee) * coin_out_decimals / PRECISION).to_u64();

    (amount_out, (fee * coin_out_decimals / PRECISION).to_u64())
  }

  public fun quote_add_liquidity<LpCoin>(pool: &mut InterestPool<Stable>, clock: &Clock, amounts: vector<u64>): u64 {
    let coins = pool.coins();
    let state = load<LpCoin>(pool.state_mut());

    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock);  

    let prev_k = invariant_(amp, state.balances);

    let mut i = 0;
    let num_of_coins = coins.length();
    let mut balances = state.balances;

    while (num_of_coins > i) {
      let coin_metadata = state.coin_metadatas.get(&coins[i]);
      let normalized_value = (amounts[i]).to_u256() * PRECISION / coin_metadata.decimals;
      let ref = &mut balances[i];
      *ref = *ref + normalized_value;

      i = i + 1;
    };

    let new_k = invariant_(amp, balances);    
    let supply_value = state.lp_coin_supply.supply_value().to_u256();

    if (supply_value == 0) {
      (new_k / 1_000_000_000).to_u64() 
    }
    else {
      
      let fee = state.imbalanced_fee();
      let mut balances_minus_fees = balances;

      let mut i = 0;

      while (num_of_coins > i) {

        let ideal_balance = new_k * state.balances[i] / prev_k;
        let difference = diff(ideal_balance, balances[i]);

        let balance_fee = fee * difference / PRECISION;

        let y = &mut balances_minus_fees[i];
        *y = *y - balance_fee;

        i = i + 1;
      };

      let new_k_2 = invariant_(amp, balances_minus_fees);

      (supply_value * (new_k_2 - prev_k) / prev_k).to_u64()
    }
  }

  public fun quote_remove_liquidity<LpCoin>(
    pool: &mut InterestPool<Stable>,
    lp_coin_amount: u64      
   ): vector<u64> {
    let coins = pool.coins();
    let state = load<LpCoin>(pool.state_mut());

    let mut i = 0;
    let mut amounts = vector[];
    let num_of_coins = coins.length();
    
    while (num_of_coins > i) {
      let coin_metadata = state.coin_metadatas.get(&coins[i]);
      let denormalized_value = state.balances[i] * coin_metadata.decimals / PRECISION;
      let balance_to_remove = denormalized_value * lp_coin_amount.to_u256() / state.lp_coin_supply.supply_value().to_u256();
      amounts.push_back(balance_to_remove.to_u64());
      i = i + 1;
    };

    amounts
  }

  public fun quote_remove_liquidity_one_coin<CoinType, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock:&Clock, 
    lp_amount: u64
  ): (u64, u64) {
    let state = load<LpCoin>(pool.state_mut());

    let (amount_to_take, fee, _, _) = state.calculate_withdraw_one_coin<CoinType, LpCoin>(clock, lp_amount);

    (amount_to_take, fee)
  }

  // === Admin Functions ===

  public fun ramp<LpCoin>(pool: &mut InterestPool<Stable>, _: &PoolAdmin, clock: &Clock, future_a: u256, future_a_time: u256) {
    let current_timestamp = clock.timestamp_ms();
    let pool_address = pool.addy();
    let state = load_mut<LpCoin>(pool.state_mut());

    assert!(current_timestamp > state.initial_a_time.to_u64() + MIN_RAMP_TIME, errors::wait_one_day());
    assert!(future_a_time >= (current_timestamp + MIN_RAMP_TIME).to_u256(), errors::future_ramp_time_is_too_short());

    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock); 

    assert!(future_a != 0 && future_a < MAX_A, errors::invalid_amplifier());
    assert!((future_a > amp && amp * MAX_A_CHANGE >= future_a) || (amp > future_a && future_a * MAX_A_CHANGE >= amp), errors::invalid_amplifier());

    state.initial_a = amp;
    state.initial_a_time = current_timestamp.to_u256();
    state.future_a = future_a;
    state.future_a_time = future_a_time;

    events::ramp_a(pool_address, amp, future_a, future_a_time, current_timestamp);
  }

  public fun stop_ramp<LpCoin>(pool: &mut InterestPool<Stable>, _: &PoolAdmin, clock: &Clock) {
    let current_timestamp = clock.timestamp_ms();

    let pool_address = pool.addy();
    let state = load_mut<LpCoin>(pool.state_mut());

    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock); 

    state.initial_a = amp;
    state.initial_a_time = current_timestamp.to_u256();
    state.future_a = amp;
    state.future_a_time = current_timestamp.to_u256();

    events::stop_ramp_a(pool_address, amp, current_timestamp);
  }

  public fun commit_fee<LpCoin>(
    pool: &mut InterestPool<Stable>,
    _: &PoolAdmin,
    fee: Option<u256>,
    admin_fee: Option<u256>,
    ctx: &mut TxContext
  ) {
    let pool_address = pool.addy();
    let state = load_mut<LpCoin>(pool.state_mut());

    assert!(state.fees.deadline() == 0, errors::current_update_is_ongoing());

    state.fees.commit_fee(fee, ctx);
    state.fees.commit_admin_fee(admin_fee, ctx);

    events::commit_stable_fee(
      pool_address, 
      state.fees.future_fee(), 
      state.fees.future_admin_fee()
    );
  }

  public fun update_fee<LpCoin>(
    pool: &mut InterestPool<Stable>,
    _: &PoolAdmin,
    ctx: &mut TxContext
  ) {

    let pool_address = pool.addy();
    let state = load_mut<LpCoin>(pool.state_mut());

    assert!(state.fees.deadline() != 0, errors::commit_to_update_fees_first());

    state.fees.update_fee(ctx);
    state.fees.update_admin_fee(ctx);

    state.fees.reset_deadline();

    events::update_stable_fee(
      pool_address, 
      state.fees.fee(), 
      state.fees.admin_fee()
    );
  }

  public fun take_fees<CoinType, LpCoin>(
    pool: &mut InterestPool<Stable>,
    _: &PoolAdmin,
    ctx: &mut TxContext
  ): Coin<CoinType> {
    let pool_address = pool.addy();

    let admin_balance = admin_balance_mut<CoinType, LpCoin>(load_mut(pool.state_mut()));
    let amount = admin_balance.value();

    events::take_fees(pool_address, type_name::get<CoinType>(), amount);

    admin_balance.take(amount, ctx)
  }

  // === Private Functions ===

  fun new_state_v1<LpCoin>(
    coin_decimals: &CoinDecimals,  
    initial_a: u256,
    lp_coin_supply: Supply<LpCoin>,
    n_coins: u64,
    ctx: &mut TxContext    
  ): StateV1<LpCoin> {
    assert!(lp_coin_supply.supply_value() == 0, errors::supply_must_have_zero_value());
    assert!(coin_decimals.decimals<LpCoin>() == 9, errors::must_have_9_decimals());
    assert!(initial_a != 0 && initial_a < MAX_A, errors::invalid_amplifier());

    StateV1 {
        id: object::new(ctx),
        balances: empty_vector(n_coins.to_u256()),
        initial_a,
        future_a: initial_a,
        initial_a_time: 0,
        future_a_time: 0,
        lp_coin_supply,
        lp_coin_decimals_scalar: coin_decimals.scalar<LpCoin>().to_u256(),
        n_coins,
        fees: stable_fees::new(),
        coin_balances: bag::new(ctx),
        coin_metadatas: vec_map::empty(),
        admin_balances: bag::new(ctx)
    }  
  }

  fun new_pool<LpCoin>(
    coin_decimals: &CoinDecimals,  
    initial_a: u256,
    lp_coin_supply: Supply<LpCoin>,
    coins: vector<TypeName>,
    ctx: &mut TxContext
  ): InterestPool<Stable> {
    let state_v1 = new_state_v1(
      coin_decimals,
      initial_a,
      lp_coin_supply,
      coins.length(),
      ctx
    );

    interest_pool::new<Stable>(
      make_coins_vec_set_from_vector(coins),
      versioned::create(STATE_V1_VERSION, state_v1, ctx), 
      ctx
    )
  }

  fun new_pool_with_hooks<LpCoin>(
    coin_decimals: &CoinDecimals,  
    initial_a: u256,
    lp_coin_supply: Supply<LpCoin>,
    coins: vector<TypeName>,
    ctx: &mut TxContext
  ): (InterestPool<Stable>, HooksBuilder) {
    let state_v1 = new_state_v1(
      coin_decimals,
      initial_a,
      lp_coin_supply,
      coins.length(),
      ctx
    );

    interest_pool::new_with_hooks<Stable>(
      make_coins_vec_set_from_vector(coins),
      versioned::create(STATE_V1_VERSION, state_v1, ctx), 
      ctx
    )
  }

  fun new_2_pool_impl<CoinA, CoinB, LpCoin>(
    mut pool: InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_decimals: &CoinDecimals,     
    ctx: &mut TxContext
  ): (InterestPool<Stable>, Coin<LpCoin>)  {
    assert!(coin_a.value() != 0 && coin_b.value() != 0, errors::no_zero_liquidity_amounts());

    let pool_address = pool.addy();
    let coins = pool.coins();
    let state = load_mut<LpCoin>(pool.state_mut());  

    // * IMPORTANT Make sure the indexes and CoinTypes match the make_coins vector and they are in the correct order
    add_coin<CoinA, LpCoin>(state, coin_decimals, 0);
    add_coin<CoinB, LpCoin>(state, coin_decimals, 1);

    let lp_coin = add_liquidity_2_pool_impl(&mut pool, clock, coin_a, coin_b, 0, ctx);

    events::new_pool(pool_address, coins, type_name::get<LpCoin>(), true);

    (pool, lp_coin)
  }

  fun new_3_pool_impl<CoinA, CoinB, CoinC, LpCoin>(
    mut pool: InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_decimals: &CoinDecimals,     
    ctx: &mut TxContext
  ): (InterestPool<Stable>, Coin<LpCoin>) {
    assert!(coin_a.value() != 0 && coin_b.value() != 0 && coin_c.value() != 0, errors::no_zero_liquidity_amounts());

    let pool_address = pool.addy();
    let coins = pool.coins();
    let state = load_mut<LpCoin>(pool.state_mut());

    // * IMPORTANT Make sure the indexes and CoinTypes match the make_coins vector and they are in the correct order
    add_coin<CoinA, LpCoin>(state, coin_decimals, 0);
    add_coin<CoinB, LpCoin>(state, coin_decimals, 1);
    add_coin<CoinC, LpCoin>(state, coin_decimals, 2);

    let lp_coin = add_liquidity_3_pool_impl(&mut pool, clock, coin_a, coin_b, coin_c, 0, ctx);

    events::new_pool(pool_address, coins, type_name::get<LpCoin>(), true);

    (pool, lp_coin)
  }

  fun new_4_pool_impl<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    mut pool: InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    coin_decimals: &CoinDecimals,      
    ctx: &mut TxContext
  ): (InterestPool<Stable>, Coin<LpCoin>) {
    assert!(
      coin_a.value() != 0 
      && coin_b.value() != 0 
      && coin_c.value() != 0
      && coin_d.value() != 0,
      errors::no_zero_liquidity_amounts()
    );

    let pool_address = pool.addy();
    let coins = pool.coins();
    let state = load_mut<LpCoin>(pool.state_mut());

    // * IMPORTANT Make sure the indexes and CoinTypes match the make_coins vector and they are in the correct order
    add_coin<CoinA, LpCoin>(state, coin_decimals, 0);
    add_coin<CoinB, LpCoin>(state, coin_decimals, 1);
    add_coin<CoinC, LpCoin>(state, coin_decimals, 2);
    add_coin<CoinD, LpCoin>(state, coin_decimals, 3);

    let lp_coin = add_liquidity_4_pool_impl(&mut pool, clock, coin_a, coin_b, coin_c, coin_d, 0, ctx);

    events::new_pool(pool_address, coins, type_name::get<LpCoin>(), true);

    (pool, lp_coin)
  }

  fun new_5_pool_impl<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    mut pool: InterestPool<Stable>,    
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    coin_e: Coin<CoinE>,
    coin_decimals: &CoinDecimals,      
    ctx: &mut TxContext
  ): (InterestPool<Stable>, Coin<LpCoin>) {
    assert!(
      coin_a.value() != 0 
      && coin_b.value() != 0 
      && coin_c.value() != 0
      && coin_d.value() != 0
      && coin_e.value() != 0,
      errors::no_zero_liquidity_amounts()
    );

    let pool_address = pool.addy();
    let coins = pool.coins();
    let state = load_mut<LpCoin>(pool.state_mut());

    // * IMPORTANT Make sure the indexes and CoinTypes match the make_coins vector and they are in the correct order
    add_coin<CoinA, LpCoin>(state, coin_decimals, 0);
    add_coin<CoinB, LpCoin>(state, coin_decimals, 1);
    add_coin<CoinC, LpCoin>(state, coin_decimals, 2);
    add_coin<CoinD, LpCoin>(state, coin_decimals, 3);
    add_coin<CoinE, LpCoin>(state, coin_decimals, 4);


    let lp_coin = add_liquidity_5_pool_impl(&mut pool, clock, coin_a, coin_b, coin_c, coin_d, coin_e, 0, ctx);

    events::new_pool(pool_address, coins, type_name::get<LpCoin>(), true);

    (pool, lp_coin)
  }

 fun swap_impl<CoinIn, CoinOut, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    coin_in: Coin<CoinIn>,
    min_amount: u64,
    ctx: &mut TxContext
  ): Coin<CoinOut> {
    pool.assert_is_live();
    assert!(type_name::get<CoinIn>() != type_name::get<CoinOut>(), errors::cannot_swap_same_coin());
    
    let coin_in_value = coin_in.value();
    assert!(coin_in_value != 0, errors::cannot_swap_zero_value());

    let pool_address = pool.addy();
    let state = load_mut<LpCoin>(pool.state_mut());

    let (coin_in_index, coin_in_decimals) = coin_state_metadata<CoinIn, LpCoin>(state);
    let (coin_out_index, coin_out_decimals) = coin_state_metadata<CoinOut, LpCoin>(state);

    // Has no fees to properly calculate new out balance
    let normalized_value = coin_in_value.to_u256() * PRECISION / coin_in_decimals;

    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock);

    let prev_k = invariant_(amp, state.balances);

    let new_out_balance = y(
      amp,
      coin_in_index.to_u256(),
      coin_out_index.to_u256(),
      state.balances[coin_in_index] + normalized_value,
      state.balances
    );

    let normalized_amount_out = state.balances[coin_out_index] - new_out_balance;

    let fee = state.fees.calculate_fee(normalized_amount_out);
    let admin_fee = state.fees.calculate_admin_fee(fee);    
    
    let amount_out = ((normalized_amount_out - fee) * coin_out_decimals / PRECISION).to_u64();

    assert!(
      (normalized_amount_out * coin_out_decimals / PRECISION).to_u64() > amount_out
      || fee == 0, 
      errors::invalid_stable_fee_amount()
    );
    assert!(amount_out >= min_amount, errors::slippage());

    let coin_in_balance = &mut state.balances[coin_in_index];
    *coin_in_balance = *coin_in_balance + normalized_value;

    let coin_out_balance = &mut state.balances[coin_out_index];
    // We need to remove the admin fee from balance
    *coin_out_balance = *coin_out_balance - ((normalized_amount_out - fee) + admin_fee); 

    // * Invariant must hold after all balances updates
    assert!(invariant_(amp, state.balances) >= prev_k, errors::invalid_invariant());

    /*
    * The admin fees are not part of the liquidity (do not accrue swap fees) and not counted on the invariant calculation
    * Fees are applied both on coin in and coin out to keep the balance in the pool
    * 1 - Deposit coin_in (without admin fees) to balance
    * 2 - Deposit coin_admin_in (admin fees on coin)
    * 3 - Deposit coin_admin_out (admin fees on coin out)
    * 4 - Take coin_out for user
    */
    coin_state_balance_mut<CoinIn, LpCoin>(state).join(coin_in.into_balance());

    let coin_out_balance = coin_state_balance_mut<CoinOut, LpCoin>(state);

    let admin_balance_in = coin_out_balance.split((admin_fee * coin_out_decimals / PRECISION).to_u64());

    let coin_out = coin_out_balance.take(amount_out, ctx);

    admin_balance_mut<CoinOut, LpCoin>(state).join(admin_balance_in);

    events::swap(
      pool_address, 
      type_name::get<CoinIn>(), 
      type_name::get<CoinOut>(), 
      coin_in_value, 
      amount_out,
      (fee * coin_out_decimals / PRECISION).to_u64() 
    );

    coin_out
  }

  fun add_liquidity_2_pool_impl<CoinA, CoinB, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    pool.assert_is_live();
    assert!(pool.are_coins_ordered(vector[type_name::get<CoinA>(), type_name::get<CoinB>()]), errors::coins_must_be_in_order());

    let pool_address = pool.addy();
    let coins = pool.coins();
    let state = load_mut<LpCoin>(pool.state_mut());

    let prev_invariant = virtual_price_impl(state, clock);
    
    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock);    

    let prev_k = invariant_(amp, state.balances);
    let old_balances = state.balances;

    let coin_a_value = deposit_coin<CoinA, LpCoin>(state, coin_a);
    let coin_b_value = deposit_coin<CoinB, LpCoin>(state, coin_b);

    let mint_amount = calculate_mint_amount(state, amp, prev_k, old_balances, lp_coin_min_amount);

    events::add_liquidity(
      pool_address, 
      coins,
      vector[coin_a_value, coin_b_value],
      mint_amount
    );

    let lp_coin = state.lp_coin_supply.increase_supply(mint_amount).to_coin(ctx);

    assert!(virtual_price_impl(load<LpCoin>(pool.state_mut()), clock) >= prev_invariant, errors::invalid_invariant());

    lp_coin
  }

  fun add_liquidity_3_pool_impl<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    pool.assert_is_live();
    assert!(pool.are_coins_ordered(vector[type_name::get<CoinA>(), type_name::get<CoinB>(), type_name::get<CoinC>()]), errors::coins_must_be_in_order());

    let pool_address = pool.addy();
    let coins = pool.coins();
    let state = load_mut<LpCoin>(pool.state_mut());

    let prev_invariant = virtual_price_impl(state, clock);
    
    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock);    

    let prev_k = invariant_(amp, state.balances);
    let old_balances = state.balances;

    let coin_a_value = deposit_coin<CoinA, LpCoin>(state, coin_a);
    let coin_b_value = deposit_coin<CoinB, LpCoin>(state, coin_b);
    let coin_c_value = deposit_coin<CoinC, LpCoin>(state, coin_c);

    let mint_amount = calculate_mint_amount(state, amp, prev_k, old_balances, lp_coin_min_amount);

    events::add_liquidity(
      pool_address, 
      coins,
      vector[coin_a_value, coin_b_value, coin_c_value],
      mint_amount
    );

    let lp_coin = state.lp_coin_supply.increase_supply(mint_amount).to_coin(ctx);

    assert!(virtual_price_impl(load<LpCoin>(pool.state_mut()), clock) >= prev_invariant, errors::invalid_invariant());

    lp_coin
  }

  fun add_liquidity_4_pool_impl<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    pool.assert_is_live();
    assert!(
      pool.are_coins_ordered(
        vector[type_name::get<CoinA>(), type_name::get<CoinB>(), type_name::get<CoinC>(), type_name::get<CoinD>()]
      ), 
      errors::coins_must_be_in_order()
    );
    
    let pool_address = pool.addy();
    let coins = pool.coins();
    let state = load_mut<LpCoin>(pool.state_mut());
    let prev_invariant = virtual_price_impl(state, clock);
    
    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock);    
    let prev_k = invariant_(amp, state.balances);
    let old_balances = state.balances;

    let coin_a_value = deposit_coin<CoinA, LpCoin>(state, coin_a);
    let coin_b_value = deposit_coin<CoinB, LpCoin>(state, coin_b);
    let coin_c_value = deposit_coin<CoinC, LpCoin>(state, coin_c);
    let coin_d_value = deposit_coin<CoinD, LpCoin>(state, coin_d);

    let mint_amount = calculate_mint_amount(state, amp, prev_k, old_balances, lp_coin_min_amount);

    events::add_liquidity(
      pool_address, 
      coins,
      vector[coin_a_value, coin_b_value, coin_c_value, coin_d_value],
      mint_amount
    );

    let lp_coin = state.lp_coin_supply.increase_supply(mint_amount).to_coin(ctx);

    assert!(virtual_price_impl(load<LpCoin>(pool.state_mut()), clock) >= prev_invariant, errors::invalid_invariant());

    lp_coin
  }

  fun add_liquidity_5_pool_impl<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    pool: &mut InterestPool<Stable>,
    clock: &Clock,
    coin_a: Coin<CoinA>,
    coin_b: Coin<CoinB>,
    coin_c: Coin<CoinC>,
    coin_d: Coin<CoinD>,
    coin_e: Coin<CoinE>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext     
  ): Coin<LpCoin> {
    pool.assert_is_live();
    assert!(
      pool.are_coins_ordered( 
        vector[type_name::get<CoinA>(), type_name::get<CoinB>(), type_name::get<CoinC>(), type_name::get<CoinD>(), type_name::get<CoinE>()]
      ), 
      errors::coins_must_be_in_order()
    );

    let pool_address = pool.addy();
    let coins = pool.coins();
    let state = load_mut<LpCoin>(pool.state_mut());

    let prev_invariant = virtual_price_impl(state, clock);
    
    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock);    
    let prev_k = invariant_(amp, state.balances);
    let old_balances = state.balances;

    let coin_a_value = deposit_coin<CoinA, LpCoin>(state, coin_a);
    let coin_b_value = deposit_coin<CoinB, LpCoin>(state, coin_b);
    let coin_c_value = deposit_coin<CoinC, LpCoin>(state, coin_c);
    let coin_d_value = deposit_coin<CoinD, LpCoin>(state, coin_d);
    let coin_e_value = deposit_coin<CoinE, LpCoin>(state, coin_e);

    let mint_amount = calculate_mint_amount(state, amp, prev_k, old_balances, lp_coin_min_amount);

    events::add_liquidity(
      pool_address, 
      coins,
      vector[coin_a_value, coin_b_value, coin_c_value, coin_d_value, coin_e_value],
      mint_amount
    );

    let lp_coin = state.lp_coin_supply.increase_supply(mint_amount).to_coin(ctx);

    assert!(virtual_price_impl(load<LpCoin>(pool.state_mut()), clock) >= prev_invariant, errors::invalid_invariant());

    lp_coin
  }

  fun donate_impl<CoinType, LpCoin>(
    pool: &mut InterestPool<Stable>,
    coin_in: Coin<CoinType>
  ) {
    let pool_address = pool.addy();
    let state = load_mut<LpCoin>(pool.state_mut());

    let coin_in_value = deposit_coin<CoinType, LpCoin>(state, coin_in);
    assert!(coin_in_value != 0, errors::no_zero_coin());  

    events::donate(pool_address, type_name::get<CoinType>(), coin_in_value);
  }

  fun remove_liquidity_2_pool_impl<CoinA, CoinB, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>) {
    assert!(
      pool.are_coins_ordered( 
        vector[type_name::get<CoinA>(), type_name::get<CoinB>()]), 
      errors::coins_must_be_in_order()
    );

    let lp_coin_value = lp_coin.value();
    assert!(lp_coin_value != 0, errors::no_zero_coin());

    let pool_address = pool.addy();
    let coins = pool.coins();
    let state = load_mut<LpCoin>(pool.state_mut());

    let prev_invariant = virtual_price_impl(state, clock);

    let (coin_a, coin_b) = (
      take_coin<CoinA, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinB, LpCoin>(state, lp_coin_value, min_amounts, ctx),
    );

    state.lp_coin_supply.decrease_supply(lp_coin.into_balance());

    events::remove_liquidity(
      pool_address, 
      coins,
      vector[coin_a.value(), coin_b.value()],
      lp_coin_value
    );

    let current_supply = state.lp_coin_supply.supply_value();

    assert!(virtual_price_impl(load<LpCoin>(pool.state_mut()), clock) >= prev_invariant || current_supply == 0, errors::invalid_invariant());

    (coin_a, coin_b)
  }

  fun remove_liquidity_3_pool_impl<CoinA, CoinB, CoinC, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>, Coin<CoinC>) {
    assert!(
      pool.are_coins_ordered( 
        vector[type_name::get<CoinA>(), type_name::get<CoinB>(), type_name::get<CoinC>()]), 
      errors::coins_must_be_in_order()
    );

    let lp_coin_value = lp_coin.value();
    assert!(lp_coin_value != 0, errors::no_zero_coin());

    let pool_address = pool.addy();
    let coins = pool.coins();
    let state = load_mut<LpCoin>(pool.state_mut());

    let prev_invariant = virtual_price_impl(state, clock);

    let (coin_a, coin_b, coin_c) = (
      take_coin<CoinA, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinB, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinC, LpCoin>(state, lp_coin_value, min_amounts, ctx),
    );

    state.lp_coin_supply.decrease_supply(lp_coin.into_balance());

    events::remove_liquidity(
      pool_address, 
      coins,
      vector[coin_a.value(), coin_b.value(), coin_c.value()],
      lp_coin_value
    );

    assert!(virtual_price_impl(load<LpCoin>(pool.state_mut()), clock) >= prev_invariant, errors::invalid_invariant());

    (coin_a, coin_b, coin_c)
  }

  fun remove_liquidity_4_pool_impl<CoinA, CoinB, CoinC, CoinD, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>, Coin<CoinC>, Coin<CoinD>) {
    assert!(
      pool.are_coins_ordered( 
        vector[type_name::get<CoinA>(), type_name::get<CoinB>(), type_name::get<CoinC>(), type_name::get<CoinD>()]), 
      errors::coins_must_be_in_order()
    );

    let lp_coin_value = lp_coin.value();
    assert!(lp_coin_value != 0, errors::no_zero_coin());

    let pool_address = pool.addy();
    let coins = pool.coins();
    let state = load_mut<LpCoin>(pool.state_mut()); 

    let prev_invariant = virtual_price_impl(state, clock);

    let (coin_a, coin_b, coin_c, coin_d) = (
      take_coin<CoinA, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinB, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinC, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinD, LpCoin>(state, lp_coin_value, min_amounts, ctx),
    );

    state.lp_coin_supply.decrease_supply(lp_coin.into_balance());

    events::remove_liquidity(
      pool_address, 
      coins,
      vector[coin_a.value(), coin_b.value(), coin_c.value(), coin_d.value()],
      lp_coin_value
    );

    assert!(virtual_price_impl(load<LpCoin>(pool.state_mut()), clock) >= prev_invariant, errors::invalid_invariant());

    (coin_a, coin_b, coin_c, coin_d)
  }

  fun remove_liquidity_5_pool_impl<CoinA, CoinB, CoinC, CoinD, CoinE, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amounts: vector<u64>,
    ctx: &mut TxContext
  ): (Coin<CoinA>, Coin<CoinB>, Coin<CoinC>, Coin<CoinD>, Coin<CoinE>) {
    assert!(
      pool.are_coins_ordered( 
        vector[type_name::get<CoinA>(), type_name::get<CoinB>(), type_name::get<CoinC>(), type_name::get<CoinD>(), type_name::get<CoinE>()]), 
      errors::coins_must_be_in_order()
    );

    let lp_coin_value = lp_coin.value();
    assert!(lp_coin_value != 0, errors::no_zero_coin());

    let pool_address = pool.addy();
    let coins = pool.coins();
    let state = load_mut<LpCoin>(pool.state_mut());

    let prev_invariant = virtual_price_impl(state, clock);

    let (coin_a, coin_b, coin_c, coin_d, coin_e) = (
      take_coin<CoinA, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinB, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinC, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinD, LpCoin>(state, lp_coin_value, min_amounts, ctx),
      take_coin<CoinE, LpCoin>(state, lp_coin_value, min_amounts, ctx),
    );

    state.lp_coin_supply.decrease_supply(lp_coin.into_balance());

    events::remove_liquidity(
      pool_address, 
      coins,
      vector[coin_a.value(), coin_b.value(), coin_c.value(), coin_d.value(), coin_e.value()],
      lp_coin_value
    );

    assert!(virtual_price_impl(load<LpCoin>(pool.state_mut()), clock) >= prev_invariant, errors::invalid_invariant());    

    (coin_a, coin_b, coin_c, coin_d, coin_e)
  }

  fun calculate_mint_amount<LpCoin>(
    state: &mut StateV1<LpCoin>, 
    amp: u256, 
    prev_k: u256, 
    old_balances: vector<u256>,
    lp_coin_min_amount: u64
  ): u64 {
    let new_k = invariant_(amp, state.balances);

    assert!(new_k > prev_k, errors::invalid_invariant());
    
    let supply_value = state.lp_coin_supply.supply_value().to_u256();

    let mint_amount = if (supply_value == 0) {
      (new_k / 1_000_000_000).to_u64()
    } else {
      let fee = state.imbalanced_fee();

      let len = state.n_coins;
      let mut i = 0;  

      let mut balances_minus_fees = state.balances;
      while (len > i) {

        let ideal_balance = new_k * old_balances[i] / prev_k;
        let difference = diff(ideal_balance, state.balances[i]);

        let balance_fee = fee * difference / PRECISION;
        let x = &mut state.balances[i];
        *x = *x- state.fees.calculate_admin_fee(balance_fee);

        let y = &mut balances_minus_fees[i];
        *y = *y - balance_fee;

        i = i + 1;
      };

      let new_k_2 = invariant_(amp, balances_minus_fees);

      // Sanity check
      assert!(new_k_2 > prev_k, errors::invalid_invariant());

      (supply_value * (new_k_2 - prev_k) / prev_k).to_u64()
    };

    assert!(mint_amount >= lp_coin_min_amount, errors::slippage());

    mint_amount
  }

  fun remove_liquidity_one_coin_impl<CoinType, LpCoin>(
    pool: &mut InterestPool<Stable>, 
    clock: &Clock,
    lp_coin: Coin<LpCoin>,
    min_amount: u64,
    ctx: &mut TxContext    
  ): Coin<CoinType> {
    pool.assert_is_live();
    let lp_coin_value = lp_coin.value();
    assert!(lp_coin_value != 0, errors::no_zero_coin());

    let pool_address = pool.addy();
    let state = load_mut<LpCoin>(pool.state_mut());

    let prev_invariant = virtual_price_impl(state, clock);

    let (
      amount_to_take, 
      _, 
      balance_out, 
      index
    ) = state.calculate_withdraw_one_coin<CoinType, LpCoin>(clock, lp_coin.value());

    *&mut state.balances[index] = state.balances[index] - balance_out;

    assert!(amount_to_take >= min_amount, errors::slippage());

    state.lp_coin_supply.decrease_supply(lp_coin.into_balance());

    events::remove_liquidity(
      pool_address, 
      vector[type_name::get<CoinType>()], 
      vector[amount_to_take], 
      lp_coin_value
    );

    let coin_out = coin_state_balance_mut<CoinType, LpCoin>(state).take(amount_to_take, ctx);

    let lp_coin_supply = state.lp_coin_supply.supply_value();

    assert!(
      virtual_price_impl(load<LpCoin>(pool.state_mut()), clock) >= prev_invariant || lp_coin_supply == 0, errors::invalid_invariant()
    );

    coin_out
  }

  fun deposit_coin<CoinType, LpCoin>(state: &mut StateV1<LpCoin>, coin_in: Coin<CoinType>): u64 {
    let coin_value = coin_in.value().to_u256();

    if (coin_value == 0) {
      coin_in.destroy_zero();
      return 0
    };

    let (index, decimals) = coin_state_metadata<CoinType, LpCoin>(state);

    // Update the balance for the coin
    let current_balance = &mut state.balances[index];
    *current_balance = *current_balance + (coin_value * PRECISION / decimals);

    coin_state_balance_mut<CoinType, LpCoin>(state).join(coin_in.into_balance());

    (coin_value as u64)
  }

  fun take_coin<CoinType, LpCoin>(
    state: &mut StateV1<LpCoin>, 
    lp_coin_value: u64, 
    min_amounts: vector<u64>, 
    ctx: &mut TxContext
  ): Coin<CoinType> {
    let (index, decimals) = coin_state_metadata<CoinType, LpCoin>(state);    

    let current_balance = &mut state.balances[index];

    let denormalized_value = *current_balance * decimals / PRECISION;

    let balance_to_remove = denormalized_value * lp_coin_value.to_u256() / state.lp_coin_supply.supply_value().to_u256();

    assert!(balance_to_remove.to_u64() >= min_amounts[index], errors::slippage());

    *current_balance = *current_balance - (balance_to_remove * PRECISION / decimals);

    coin_state_balance_mut<CoinType, LpCoin>(state).take(balance_to_remove.to_u64(), ctx)
  }

  fun add_coin<CoinType, LpCoin>(state: &mut StateV1<LpCoin>, coin_decimals: &CoinDecimals, index: u64) {
    let coin_name = type_name::get<CoinType>();

    state.admin_balances.add(coin_name, balance::zero<CoinType>());
    state.coin_balances.add(coin_name, balance::zero<CoinType>());
    state.coin_metadatas.insert(coin_name, CoinMetadata {
      decimals: coin_decimals.scalar<CoinType>().to_u256(),
      index
    });
  }

  fun calculate_withdraw_one_coin<CoinOut, LpCoin>(
    state: &StateV1<LpCoin>, 
    clock: &Clock,
    lp_burn_amount: u64
  ): (u64, u64, u256, u64) {
    let amp = get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock);

    let prev_invariant = invariant_(amp, state.balances);
    let lp_supply_value = state.lp_coin_supply.supply_value().to_u256();

    let new_invariant = prev_invariant - lp_burn_amount.to_u256() * prev_invariant / lp_supply_value;

    let (index, decimals) = coin_state_metadata<CoinOut, LpCoin>(state);

    let mut balances_reduced = state.balances;

    let initial_coin_balance = state.balances[index];

    let fee = state.imbalanced_fee();

    let new_out_balance = y_lp(
      get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock),
      index.to_u256(),
      state.balances,
      lp_burn_amount.to_u256(),
      lp_supply_value
    ) + 1;

    let mut i = 0;
    let n_coins = state.n_coins;

    while (n_coins > i) {
      let coin_balance = if (i == index)
        state.balances[i] * new_invariant / prev_invariant - new_out_balance
      else 
        state.balances[i] - state.balances[i] * new_invariant / prev_invariant;

      *&mut balances_reduced[i] = balances_reduced[i] - (fee * coin_balance / PRECISION);

      i = i + 1;
    };

    let new_out_balance_with_fee = y_d(
      get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock),
      index.to_u256(),
      balances_reduced,
      new_invariant
    );    

    let amount_to_take = (balances_reduced[index] - min(balances_reduced[index], new_out_balance_with_fee));
    let amount_to_take_without_fees = (initial_coin_balance - min(initial_coin_balance, new_out_balance));

    let fee = amount_to_take_without_fees - amount_to_take;
    let admin_fee = fee * state.fees.admin_fee() / PRECISION;

    let amount_out = (amount_to_take * decimals / PRECISION).to_u64();
    let fee_out = (fee * decimals / PRECISION).to_u64();

    (amount_out, fee_out, amount_to_take + admin_fee, index)
  }

  fun imbalanced_fee<LpCoin>(state: &StateV1<LpCoin>): u256 {
    state.fees.fee() * state.n_coins.to_u256() / (4 * (state.n_coins.to_u256() - 1))
  }

  fun virtual_price_impl<LpCoin>(state: &StateV1<LpCoin>, clock: &Clock): u256 {
    let supply = state.lp_coin_supply.supply_value().to_u256();

    if (supply == 0) return 0;

    let k = invariant_(
      get_a(state.initial_a, state.initial_a_time, state.future_a, state.future_a_time, clock), 
      state.balances
    );

    k * state.lp_coin_decimals_scalar / supply
  }

  fun load<LpCoin>(versioned: &mut Versioned): &StateV1<LpCoin> {
    maybe_upgrade_state_to_latest(versioned);
    versioned.load_value()
  }

  fun load_mut<LpCoin>(versioned: &mut Versioned): &mut StateV1<LpCoin> {
    maybe_upgrade_state_to_latest(versioned);
    versioned.load_value_mut()
  }

  #[allow(unused_mut_parameter)]
  fun maybe_upgrade_state_to_latest(versioned: &mut Versioned) {
    // * IMPORTANT: When new versions are added, we need to explicitly upgrade here.
    assert!(versioned.version() == STATE_V1_VERSION, errors::invalid_version());
  }  

  fun coin_state_balance<CoinType, LpCoin>(state: &StateV1<LpCoin>): &Balance<CoinType> {
    state.coin_balances.borrow<TypeName, Balance<CoinType>>(type_name::get<CoinType>())
  }  

  fun coin_state_balance_mut<CoinType, LpCoin>(state: &mut StateV1<LpCoin>): &mut Balance<CoinType> {
    state.coin_balances.borrow_mut<TypeName, Balance<CoinType>>(type_name::get<CoinType>())
  }

  fun coin_state_metadata<CoinType, LpCoin>(state: &StateV1<LpCoin>): (u64, u256) {
    let coin_state = state.coin_metadatas.get<TypeName, CoinMetadata>(&type_name::get<CoinType>());
    (coin_state.index, coin_state.decimals)
  }

  fun admin_balance_mut<CoinType, LpCoin>(state: &mut StateV1<LpCoin>): &mut Balance<CoinType> {
    state.admin_balances.borrow_mut(type_name::get<CoinType>())
  } 
}