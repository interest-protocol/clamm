module clamm::utils {
  use std::vector;
  use std::type_name::TypeName;

  use sui::vec_set::{Self, VecSet};

  use suitears::comparator::{compare, eq};

  use clamm::interest_pool::{Self, InterestPool};

  public fun are_coins_ordered<Curve>(pool: &InterestPool<Curve>, coins: vector<TypeName>): bool {
    eq(&compare(&interest_pool::coins(pool), &coins))
  }

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

  public fun vector_3_to_tuple(x: vector<u256>): (u256, u256, u256) {
    (
      *vector::borrow(&x, 0),
      *vector::borrow(&x, 1),
      *vector::borrow(&x, 2)
    )
  }

  public fun vector_2_to_tuple(x: vector<u256>): (u256, u256) {
    (
      *vector::borrow(&x, 0),
      *vector::borrow(&x, 1),
    )
  }

  public fun empty_vector(x: u256): vector<u256> {
    let data = vector::empty();

    let i = 0;
    while (x > i) {
      vector::push_back(&mut data, 0);
      i = i + 1;
    };

    data
  }
}