module amm::utils {
  
  use std::type_name::get;

  public fun are_types_equal<Type0, Type1>(): bool {
    get<Type0>() == get<Type1>()
  }
}