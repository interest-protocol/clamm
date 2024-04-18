module clamm::hooks {
  // === Imports ===

  use std::string;

  use clamm::errors;
  use clamm::interest_pool::{Self, InterestPool, Request};

  // === Aliases ===

  use fun string::utf8 as vector.utf8;

  // === Public Mutative Functions ===

  public fun start_swap<Curve>(pool: &InterestPool<Curve>): Request {
    assert!(pool.has_swap_hook(), errors::this_pool_has_no_hooks());
    interest_pool::new_request(pool, interest_pool::start_swap().utf8())
  }

  public fun start_add_liquidity<Curve>(pool: &InterestPool<Curve>): Request {
    assert!(pool.has_add_liquidity_hook(), errors::this_pool_has_no_hooks());
    interest_pool::new_request(pool, interest_pool::start_add_liquidity().utf8())
  }

  public fun start_remove_liquidity<Curve>(pool: &InterestPool<Curve>): Request {
    assert!(pool.has_remove_liquidity_hook(), errors::this_pool_has_no_hooks());
    interest_pool::new_request(pool, interest_pool::start_remove_liquidity().utf8())
  }  

  public fun finish<Curve>(pool: &InterestPool<Curve>, request: Request) {
    assert!(
      request.name().index_of(&b"F".utf8()) == 0, 
      errors::must_be_finish_request()
    );
    interest_pool::confirm(pool, request);      
  }  

  // === Public-Package Functions ===

  public(package) fun finish_swap<Curve>(pool: &InterestPool<Curve>, request: Request): Request {
    assert!(pool.has_swap_hook(), errors::this_pool_has_no_hooks());
    assert!(request.name().bytes() == interest_pool::start_swap(), errors::must_be_start_swap_request());
    
    pool.confirm(request);

    pool.new_request(interest_pool::finish_swap().utf8())     
  }

  public(package) fun finish_add_liquidity<Curve>(pool: &InterestPool<Curve>, request: Request): Request {
    assert!(pool.has_add_liquidity_hook(), errors::this_pool_has_no_hooks());
    assert!(
      request.name().bytes() == interest_pool::start_add_liquidity(), 
      errors::must_be_start_add_liquidity_request()
    );
    
    pool.confirm(request);

    pool.new_request(interest_pool::finish_add_liquidity().utf8())    
  }

  public(package) fun finish_remove_liquidity<Curve>(pool: &InterestPool<Curve>, request: Request): Request {
    assert!(pool.has_remove_liquidity_hook(), errors::this_pool_has_no_hooks());
    assert!(
      request.name().bytes() == interest_pool::start_remove_liquidity(), 
      errors::must_be_start_remove_liquidity_request()
    );
    
    pool.confirm(request);

    pool.new_request(interest_pool::finish_remove_liquidity().utf8())
  }  
}