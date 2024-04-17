module clamm::hooks {
  // === Imports ===

  use std::string;

  use clamm::errors;
  use clamm::interest_pool::{Self, InterestPool, Request};

  use fun string::utf8 as vector.utf8;

  public fun start_swap<Curve>(pool: &InterestPool<Curve>): Request {
    interest_pool::new_request(pool, interest_pool::start_swap().utf8())
  }

  public fun finish_swap<Curve>(pool: &InterestPool<Curve>, request: Request) {
    assert!(request.name().bytes() == interest_pool::finish_swap(), errors::must_be_finish_swap_request());
    interest_pool::confirm(pool, request);    
  }

  public fun start_add_liquidity<Curve>(pool: &InterestPool<Curve>): Request {
    interest_pool::new_request(pool, interest_pool::start_add_liquidity().utf8())
  }

  public fun finish_add_liquidity<Curve>(pool: &InterestPool<Curve>, request: Request) {
    assert!(
      request.name().bytes() == interest_pool::finish_add_liquidity(), 
      errors::must_be_finish_add_liquidity_request()
    );
    interest_pool::confirm(pool, request);      
  } 

  public fun start_remove_liquidity<Curve>(pool: &InterestPool<Curve>): Request {
    interest_pool::new_request(pool, interest_pool::start_remove_liquidity().utf8())
  }  

  public fun finish_remove_liquidity<Curve>(pool: &InterestPool<Curve>, request: Request) {
    assert!(
      request.name().bytes() == interest_pool::finish_remove_liquidity(), 
      errors::must_be_finish_remove_liquidity_request()
    );
    interest_pool::confirm(pool, request);      
  }  
}