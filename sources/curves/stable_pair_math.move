// * All values in this contract are scaled to 1e18 for precision
module amm::stable_pair_math {

  use suitears::math256::diff;
  use suitears::math64::mul_div_up;

  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18

  /*
  * @param x Balance of Coin<X>
  * @param y Balance of Coin<T>
  * @param decimals_x Decimal factor of Coin<X>
  * @param decimals_y Decimal factor of Coin<Y>
  */
  public fun invariant_(
    x: u64, 
    y: u64,
    decimals_x: u64,
    decimals_y: u64
  ): u256 {
    f(
      ((x as u256) * PRECISION) / (decimals_x as u256),
      ((y as u256) * PRECISION) / (decimals_y as u256)
    )
  }

  public fun calculate_amount_in(
    k: u256,
    coin_amount: u64,
    balance_x: u64,
    balance_y:u64,
    decimals_x: u64,
    decimals_y: u64,
    is_x: bool
  ): u64 {
    // Precision is used to scale the number for more precise calculations. 
    // We convert them to u256 for more precise calculations and to avoid overflows.
    let (coin_amount, balance_x, balance_y, decimals_x, decimals_y) =
      (
        (coin_amount as u256),
        (balance_x as u256),
        (balance_y as u256),
        (decimals_x as u256),
        (decimals_y as u256)
      );

    // Calculate the stable curve invariant k = x3y+y3x 
    // We need to consider stable coins with different decimal values
    let reserve_x = (balance_x * PRECISION) / decimals_x;
    let reserve_y = (balance_y * PRECISION) / decimals_y;

    let amount_out = (coin_amount * PRECISION) / if (is_x) { decimals_x } else {decimals_y };

    let y = if (is_x) 
                y(reserve_x - amount_out, k, reserve_y) -  reserve_y
              else 
                 y( reserve_y - amount_out, k, reserve_x) - reserve_x;

    ((y * if (is_x) { decimals_y } else { decimals_x }) / PRECISION as u64)   
  }   

  public fun calculate_amount_out(
    k: u256,
    coin_amount: u64,
    balance_x: u64,
    balance_y:u64,
    decimals_x: u64,
    decimals_y: u64,
    is_x: bool
  ): u64 {
    // Precision is used to scale the number for more precise calculations. 
    // We convert them to u256 for more precise calculations and to avoid overflows.
    let (coin_amount, balance_x, balance_y, decimals_x, decimals_y) =
      (
        (coin_amount as u256),
        (balance_x as u256),
        (balance_y as u256),
        (decimals_x as u256),
        (decimals_y as u256)
      );

    // Calculate the stable curve invariant k = x3y+y3x 
    // We need to consider stable coins with different decimal values
    let reserve_x = (balance_x * PRECISION) / decimals_x;
    let reserve_y = (balance_y * PRECISION) / decimals_y;

    let amount_in = (coin_amount * PRECISION) / if (is_x) { decimals_x } else {decimals_y };

    let y = if (is_x) 
                reserve_y - y(amount_in + reserve_x, k, reserve_y) 
              else 
                reserve_x - y(amount_in + reserve_y, k, reserve_x);

    ((y * if (is_x) { decimals_y } else { decimals_x }) / PRECISION as u64)   
  } 

  public fun calculate_optimal_add_liquidity(
    desired_amount_x: u64,
    desired_amount_y: u64,
    reserve_x: u64,
    reserve_y: u64
  ): (u64, u64) {

    if (reserve_x == 0 && reserve_y == 0) return (desired_amount_x, desired_amount_y);

    let optimal_y_amount = quote_liquidity(desired_amount_x, reserve_x, reserve_y);
    if (desired_amount_y >= optimal_y_amount) return (desired_amount_x, optimal_y_amount);

    let optimal_x_amount = quote_liquidity(desired_amount_y, reserve_y, reserve_x);
    (optimal_x_amount, desired_amount_y)
  }  

  public fun quote_liquidity(amount_a: u64, reserves_a: u64, reserves_b: u64): u64 {
    // @dev gie the propocol an edge
    mul_div_up(amount_a, reserves_b, reserves_a)
  }
   

  /*
  * @param x0 New balance of the Token In
  * @param xy Invariant before the swap
  * @param y Current balance of the Token Out
  */
  fun y(x0: u256, xy: u256, y: u256): u256 {
    let y_prev = 0;
    while (diff(y, y_prev) > 1) {
      y_prev = y;
      let k = f(x0, y);
        
      y = if (k < xy)
            y + ((((xy - k) * PRECISION) / d(x0, y)) + 1) // round up
          else
            y - ((k - xy) * PRECISION) / d(x0, y);
    };
    y
  }

  /// Implements 3 * x0 * y^2 + x0^3 = 3 * x0 * (y * y / 1e8) / 1e8 + (x0 * x0 / 1e8 * x0) / 1e8
  public fun d(x0: u256, y: u256): u256 {
    (3 * x0 * ((y * y) / PRECISION)) /
            PRECISION +
            ((((x0 * x0) / PRECISION) * x0) / PRECISION)
  }

  /// Implements x0*y^3 + x0^3*y = x0*(y*y/1e18*y/1e18)/1e18+(x0*x0/1e18*x0/1e18)*y/1e18
  public fun f(x: u256, y: u256): u256 {
    let a = (x * y) / PRECISION; // xy
    let b = ((x * x) / PRECISION + (y * y) / PRECISION); // x^2 + y^2
    (a * b) / PRECISION // x^3y + y^3x  
  }

}