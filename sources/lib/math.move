module amm::math {

  use amm::errors;
  use amm::constants::{wad, ray};

  public fun wad_mul(x:u128, y: u128): u128 {
    mul_div(x, y, wad())
  }

  public fun wad_div(x: u128, y: u128): u128 {
    assert!(y != 0, errors::zero_division());
    mul_div(x, wad(), y)
  }

  public fun ray_mul(x: u256, y: u256): u256 {
    (x * y) / ray()
  }

  public fun ray_div(x: u256, y: u256): u256 {
    assert!(y != 0, errors::zero_division());
    (x * ray()) / y
  }

  public fun mul_div(x: u128, y: u128, z: u128): u128 {
      if (y == z) {
          return x
      };
      if (x == z) {
          return y
      };
      let a = x / z;
      let b = x % z;
      //x = a * z + b;
      let c = y / z;
      let d = y % z;
      //y = c * z + d;
      a * c * z + a * d + b * c + b * d / z
  }

  public fun sqrt_u256(y: u256): u256 {
        let z = 0;
        if (y > 3) {
            z = y;
            let x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        };
        z
  }

  /// Return the absolute value of x - y
  public fun diff_u256(x: u256, y: u256): u256 {
    if (x > y) {
      x - y
    } else {
      y - x
    }
  }

}