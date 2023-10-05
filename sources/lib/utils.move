module amm::utils {
  
  use std::ascii;
  use std::type_name;

  use amm::comparator;

  public fun get_type_name_bytes<T>(): vector<u8> {
    ascii::into_bytes(type_name::into_string(type_name::get<T>()))
  }

  public fun are_types_equal<Type0, Type1>(): bool {
    comparator::is_equal(&comparator::compare_u8_vector(get_type_name_bytes<Type0>(), get_type_name_bytes<Type1>()))
  }
}