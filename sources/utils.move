module amm::utils {
  use std::vector;
  use std::type_name::TypeName;

  use sui::vec_set::{Self, VecSet};

  public fun make_coins_from_vector(data: vector<TypeName>): VecSet<TypeName> {
    let len = vector::length(&data);
    let set = vec_set::empty();
    let i = 0;

    while (len > i) {
      vec_set::insert(&mut set, *vector::borrow(&data, i));
      i = i + 1;
    };

    set
  }
}