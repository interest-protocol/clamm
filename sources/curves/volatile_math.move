module amm::volatile_math {
  
  use std::vector;

  use sui::math::pow;

  use amm::errors;
  use amm::constants::ray;
  use amm::math::diff_u256;

  const A_MULTIPLIER: u256 = 10000;
  const MIN_GAMMA: u256 = 10_000_000_000; // 10e6
  const MAX_GAMMA: u256 = 50_000_000_000_000_000; // 5e16

  public fun get_min_a(n_coins: u64): u256 {
    (pow(n_coins, (n_coins as u8)) as u256) * A_MULTIPLIER / 100
  }

  public fun get_max_a(n_coins: u64): u256 {
    (pow(n_coins, (n_coins as u8)) as u256) * A_MULTIPLIER * 1000      
  }

  public fun geometric_mean(unsorted: &vector<u256>, sort: bool): u256 {
    let x = if (sort) { descending_insertion_sort(unsorted) } else { *unsorted };

    let len = vector::length(&x);
    let d = *vector::borrow(&x, 0); 
    let diff: u256;
    let i = 0;
    let ray = ray();

    while (i < 255) {
      let prev_d = d;
      let temp = ray;

      let j = 0;
      while (j < len) {
        temp = temp * (*vector::borrow(&x, j)) / d;  
        j = j + 1;
      };
      d = d * (((len as u256) - 1) * ray + temp) / ((len as u256) * ray);

      diff = diff_u256(d, prev_d);
      
      if (diff <= 1 || diff * ray < d) return d;
      
      i = i + 1;
    };
    abort errors::failed_to_converge()
  }

  // Our pools will not have more than 4 tokens
  // Bubble sort is enough
  fun descending_insertion_sort(x: &vector<u256>): vector<u256> {
    let x = *x;
    let len = vector::length(&x) - 1;
    let i = 0;

    while (i < len) {
      let j = i;
      while (j > 0 && *vector::borrow(&x, j - 1) <  *vector::borrow(&x, j)) {
        vector::swap(&mut x, j, j - 1);
        j = j - 1;
      };

      i = i + 1;
    }; 

    x
  }
}