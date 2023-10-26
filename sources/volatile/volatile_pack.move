module amm::volatile_pack {
  use std::vector;

  use amm::errors;

  const PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18
  const MASK: u256 = 18446744073709551615;

  public fun pack(values: vector<u256>): u256 {
    let len = vector::length(&values);

    if (len == 2) return pack_2(values);
    if (len == 3) return pack_3(values);

    abort errors::vector_too_big_to_pack()
  }

  public fun unpack(value: u256, len: u64): vector<u256> {
    if (len == 2) return unpack_2(value);
    if (len == 3) return unpack_3(value);

    abort errors::invalid_unpack_length()
  }

  public fun pack_prices(prices: vector<u256>, price_mask: u256, price_size: u8): u256 {
    let len = vector::length(&prices);

    let packed_prices = 0;

    let index = 0;
    let len = vector::length(&prices);

    while (len > index) {
      packed_prices = packed_prices << price_size;
      let p = *vector::borrow(&prices, len - 1 - index);
      assert!(price_mask > p, errors::value_overflow());

      packed_prices = p | packed_prices;
      index = index + 1;
    };

    packed_prices
  }

  public fun unpack_prices(packed_prices: u256, len: u64, price_mask: u256, price_size: u8): vector<u256> {
    let data = vector::empty();

    let packed_prices = packed_prices;
    let index = 0;
    
    while(len > index) {
      vector::push_back(&mut data, packed_prices & price_mask);
      packed_prices= packed_prices >> price_size;

      index = index + 1;
    };

    data
  }

  fun pack_2(
    values: vector<u256>
  ):u256 {

    let value0 = get_and_assert_max_value(&values, 0);
    let value1 = get_and_assert_max_value(&values, 1);

     value0 << 64 | value1
  }

  fun pack_3(
    values: vector<u256>
  ):u256 {
    let value0 = get_and_assert_max_value(&values, 0);
    let value1 = get_and_assert_max_value(&values, 1);
    let value2 = get_and_assert_max_value(&values, 2);

    value0 << 128 | value1 << 64 | value2
  }

  fun unpack_3(value: u256): vector<u256> {
    let data = vector::empty();

    vector::push_back(&mut data, value >> 128 & MASK);
    vector::push_back(&mut data, value >> 64 & MASK);
    vector::push_back(&mut data, value & MASK);

    data
  }

  fun unpack_2(value: u256): vector<u256> {
    let data = vector::empty();

    vector::push_back(&mut data, value >> 64 & MASK);
    vector::push_back(&mut data, value & MASK);

    data
  }

  fun get_and_assert_max_value(values: &vector<u256>, index: u64): u256 {
    let x = *vector::borrow(values, index);
    assert!(PRECISION >= x, errors::value_overflow());
    x
  }
}