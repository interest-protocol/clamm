module amm::volatile_pack {
  use std::vector;

  use sui::math::pow;

  use amm::errors;

  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18
  const MASK: u256 = 18446744073709551615;

  struct PackedValues has store, copy, drop {
    value: u256,
    len: u64
  }

  struct PackedPrice has store, copy, drop {
    value: u256,
    size: u8,
    mask: u256,
    len: u64
  }

  struct UnpackedPrices has store, copy, drop {
    values: vector<u256>,
    size: u8,
    mask: u256
  }

  public fun make_unpacked_prices(
    values: vector<u256>,
  ): UnpackedPrices {

    let size = ((256 / vector::length(&values)) as u8);
    UnpackedPrices {
      values,
      size,
      mask: (pow(2, size) as u256) - 1
    }
  }

  public fun pack(values: vector<u256>): PackedValues {
    let len = vector::length(&values);

    if (len == 2) return pack_2(values);
    if (len == 3) return pack_3(values);

    abort errors::vector_too_big_to_pack()
  }

  public fun unpack(data: PackedValues): vector<u256> {
    if (data.len == 2) return unpack_2(data);

    unpack_3(data)
  }

  public fun pack_prices(data: UnpackedPrices): PackedPrice {
    let len = vector::length(&data.values);
    let packed_prices = 0;
    let index = 0;

    while (len > index) {
      packed_prices = packed_prices << data.size;
      let p = *vector::borrow(&data.values, len - 1 - index);
      assert!(data.mask > p, errors::value_overflow());

      packed_prices = p | packed_prices;
      index = index + 1;
    };

    PackedPrice {
      value: packed_prices,
      size: data.size,
      mask: data.mask,
      len
    }
  }

  public fun unpack_prices(data: PackedPrice): UnpackedPrices {
    let unpacked_values = vector::empty<u256>();

    let packed_prices = data.value;
    let index = 0;
    
    while(data.len > index) {
      vector::push_back(&mut unpacked_values, packed_prices & data.mask);
      packed_prices= packed_prices >> data.size;

      index = index + 1;
    };

    UnpackedPrices {
      values: unpacked_values,
      size: data.size,
      mask: data.mask
    }
  }

  fun pack_2(
    values: vector<u256>
  ): PackedValues  {

    let value0 = get_and_assert_max_value(&values, 0);
    let value1 = get_and_assert_max_value(&values, 1);

     PackedValues {
      value: value0 << 64 | value1,
      len: 2
     }
  }

  fun pack_3(
    values: vector<u256>
  ): PackedValues  {
    let value0 = get_and_assert_max_value(&values, 0);
    let value1 = get_and_assert_max_value(&values, 1);
    let value2 = get_and_assert_max_value(&values, 2);

    PackedValues {
      value: value0 << 128 | value1 << 64 | value2,
      len: 3
     }
  }

  fun unpack_3(data: PackedValues): vector<u256> {
    let unpacked = vector::empty();

    vector::push_back(&mut unpacked, data.value >> 128 & MASK);
    vector::push_back(&mut unpacked, data.value >> 64 & MASK);
    vector::push_back(&mut unpacked, data.value & MASK);

    unpacked
  }

  fun unpack_2(data: PackedValues): vector<u256> {
    let unpacked = vector::empty();

    vector::push_back(&mut unpacked, data.value >> 64 & MASK);
    vector::push_back(&mut unpacked, data.value & MASK);

    unpacked
  }

  fun get_and_assert_max_value(values: &vector<u256>, index: u64): u256 {
    let x = *vector::borrow(values, index);
    assert!(PRECISION >= x, errors::value_overflow());
    x
  }
}