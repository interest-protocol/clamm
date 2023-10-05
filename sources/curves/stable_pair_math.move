module amm::stable_pair_math {

  use amm::constants::ray;

  public fun k(
    x: u64, 
    y: u64,
    decimals_x: u64,
    decimals_y: u64
  ): u256 {
    let precision = ray();
    let (x, y, decimals_x, decimals_y) =
    (
      (x as u256),
      (y as u256),
      (decimals_x as u256),
      (decimals_y as u256)
    );  

      let x = (x * precision) / decimals_x;
      let y = (y * precision) / decimals_y;
      let a = (x * y) / precision; // xy
      let b = ((x * x) / precision + (y * y) / precision); // x^2 + y^2
      (a * b) / precision // x^3y + y^3x  
    }

    public fun y(x0: u256, xy: u256, y: u256): u256 {
      let i = 0;
      let precision = ray();
      // Here it is using the Newton's method to to make sure that y and and y_prev are equal   
      while (i < 255) {
        i = i + 1;
        let y_prev = y;
        let k = f(x0, y);
        
        if (k < xy) {
          let dy = (((xy - k) * precision) / d(x0, y)) + 1; // round up
            y = y + dy;
          } else {
            y = y - ((k - xy) * precision) / d(x0, y);
          };

        if (y > y_prev) {
            if (y - y_prev <= 1) break
          } else {
            if (y_prev - y <= 1) break
          };
      };
      y
    }

  fun d(x0: u256, y: u256): u256 {
    let precision = ray();

    (3 * x0 * ((y * y) / precision)) /
            precision +
            ((((x0 * x0) / precision) * x0) / precision)
  }

  fun f(x0: u256, y: u256): u256 {
    let precision = ray();

    (x0 * ((((y * y) / precision) * y) / precision)) /
            precision +
            (((((x0 * x0) / precision) * x0) / precision) * y) /
            precision
  }

}