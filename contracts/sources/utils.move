module clamm::utils {
  // === Imports ===

  use std::type_name::TypeName;

  use sui::vec_set::{Self, VecSet};

  // === Public-Mutative Functions ===

  public fun make_coins_vec_set_from_vector(data: vector<TypeName>): VecSet<TypeName> {
    let len = data.length();
    let mut set = vec_set::empty();
    let mut i = 0;

    while (len > i) {
      set.insert(data[i]);
      i = i + 1;
    };

    set
  }

  public fun vector_2_to_tuple(x: vector<u256>): (u256, u256) {
    (
      x[0],
      x[1],
    )
  }

  public fun vector_3_to_tuple(x: vector<u256>): (u256, u256, u256) {
    (
      x[0],
      x[1],
      x[2]
    )
  }

  public fun empty_vector(x: u256): vector<u256> {
    let mut data = vector::empty();

    let mut i = 0;
    while (x > i) {
      data.push_back(0);
      i = i + 1;
    };

    data
  }

  // === Public-View Functions ===

  public fun to_u8(x: u64): u8 {
    (x as u8)
  }

  public fun to_u64(x: u256): u64 {
    (x as u64)
  }

  public fun to_u256(x: u64): u256 {
    (x as u256)
  }

  public fun head<T: copy + drop>(x: vector<T>): T {
    x[0]
  }  
}