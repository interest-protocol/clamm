// * All values in this contract are scaled to 1e18 for precision
module amm::stable_pair_math {

  use suitears::math256::diff;

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
    let (x, y, decimals_x, decimals_y) =
    (
      (x as u256),
      (y as u256),
      (decimals_x as u256),
      (decimals_y as u256)
    );  

      let x = (x * PRECISION) / decimals_x;
      let y = (y * PRECISION) / decimals_y;
      let a = (x * y) / PRECISION; // xy
      let b = ((x * x) / PRECISION + (y * y) / PRECISION); // x^2 + y^2
      (a * b) / PRECISION // x^3y + y^3x  
    }

  public fun calculate_amount_out(
    k: u256,
    coin_amount: u64,
    balance_x: u64,
    balance_y:u64,
    decimals_x: u64,
    decimals_y: u64,
    fee_percent: u256,
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

    // We calculate the amount being sold after the fee. 
    // We calculate the amount being sold after the fee. 
    let token_in_amount_minus_fees_adjusted = coin_amount - ((coin_amount * fee_percent) / PRECISION);

    // Calculate the stable curve invariant k = x3y+y3x 
    // We need to consider stable coins with different decimal values
    let reserve_x = (balance_x * PRECISION) / decimals_x;
    let reserve_y = (balance_y * PRECISION) / decimals_y;

    let amount_in = (token_in_amount_minus_fees_adjusted * PRECISION) / if (is_x) { decimals_x } else {decimals_y };

    let y = if (is_x) 
                reserve_y - calculate_balance_out(amount_in + reserve_x, k, reserve_y) 
              else 
                reserve_x - calculate_balance_out(amount_in + reserve_y, k, reserve_x);

    let y = y - ((y * fee_percent) / PRECISION);

    ((y * if (is_x) { decimals_y } else { decimals_x }) / PRECISION as u64)   
  }      

  /*
  * @param x0 New balance of the Token In
  * @param xy Invariant before the swap
  * @param y Current balance of the Token Out
  */
  fun calculate_balance_out(x0: u256, xy: u256, y: u256): u256 {
      let i = 0;
      // Here it is using the Newton's method to to make sure that y and and y_prev are equal   
      while (i < 255) {
        i = i + 1;
        let y_prev = y;
        let k = f(x0, y);
        
        if (k < xy) {
          let dy = (((xy - k) * PRECISION) / d(x0, y)) + 1; // round up
            y = y + dy;
          } else {
            y = y - ((k - xy) * PRECISION) / d(x0, y);
          };

        if (diff(y, y_prev) <= 1) break
      };
      y
    }

  fun d(x0: u256, y: u256): u256 {
    (3 * x0 * ((y * y) / PRECISION)) /
            PRECISION +
            ((((x0 * x0) / PRECISION) * x0) / PRECISION)
  }

  fun f(x0: u256, y: u256): u256 {
    (x0 * ((((y * y) / PRECISION) * y) / PRECISION)) /
            PRECISION +
            (((((x0 * x0) / PRECISION) * x0) / PRECISION) * y) /
            PRECISION
  }

}