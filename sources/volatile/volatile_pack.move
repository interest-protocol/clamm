module amm::volatile_pack {
  use std::vector;

  use sui::math::pow;

  use amm::errors;

  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18
  const MASK: u256 = 18_446_744_073_709_551_615;

  // @dev Wrapper to ensure this has 3 values less than 1e18 each
  struct PackedValues has store, copy, drop {
    value: u256,
  }


  // Contains prices of coins can be 2 or 3
  struct PackedPrices has store, copy, drop {
    value: u256,
    size: u8,
    mask: u256,
    len: u64
  }

  public fun view_packed_prices(data: PackedPrices): (vector<u256>, u256, u8) {
    (unpack_prices(data), data.mask, data.size)
  }
  
  public fun make_empty_packed_values(): PackedValues {
    PackedValues {
      value: 0,
    }
  }

  public fun is_packed_values_empty(data: PackedValues): bool {
    data.value == 0
  }

  public fun pack(values: vector<u256>): PackedValues {
    let len = vector::length(&values);

    assert!(len == 3, errors::vector_too_big_to_pack());

    let value0 = get_and_assert_max_value(&values, 0);
    let value1 = get_and_assert_max_value(&values, 1);
    let value2 = get_and_assert_max_value(&values, 2);

    PackedValues {
      value: value0 << 128 | value1 << 64 | value2,
     }
  }

  public fun unpack(data: PackedValues): vector<u256> {
    let unpacked = vector::empty();

    vector::push_back(&mut unpacked, data.value >> 128 & MASK);
    vector::push_back(&mut unpacked, data.value >> 64 & MASK);
    vector::push_back(&mut unpacked, data.value & MASK);

    unpacked
  }

  public fun pack_prices(values: vector<u256>): PackedPrices {
    let size = ((256 / vector::length(&values)) as u8);
    let mask = (pow(2, size) as u256) - 1;

    let len = vector::length(&values);
    let packed_prices = 0;
    let index = 0;

    while (len > index) {
      packed_prices = packed_prices << size;
      let p = *vector::borrow(&values, len - 1 - index);
      assert!(mask > p, errors::value_overflow());

      packed_prices = p | packed_prices;
      index = index + 1;
    };

    PackedPrices {
      value: packed_prices,
      size,
      mask,
      len
    }
  }

  public fun unpack_prices(data: PackedPrices): vector<u256> {
    let unpacked_values = vector::empty<u256>();

    let packed_prices = data.value;
    let index = 0;
    
    while(data.len > index) {
      vector::push_back(&mut unpacked_values, packed_prices & data.mask);
      packed_prices= packed_prices >> data.size;

      index = index + 1;
    };

    unpacked_values
  }

  fun get_and_assert_max_value(values: &vector<u256>, index: u64): u256 {
    let x = *vector::borrow(values, index);
    assert!(PRECISION >= x, errors::value_overflow());
    x
  }
}