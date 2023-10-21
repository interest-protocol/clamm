module amm::utils {
  use std::type_name::get;

  public fun are_types_equal<A, B>(): bool {
    get<A>() == get<B>()
  }
}