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

  /*
  * @param x0 New balance of the Token In
  * @param xy Invariant before the swap
  * @param y Current balance of the Token Out
  */
    public fun calculate_balance_out(x0: u256, xy: u256, y: u256): u256 {
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