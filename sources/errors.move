module amm::errors {

  public fun invalid_curve(): u64 {
    0
  }

  public fun zero_division(): u64 {
    1
  }

  public fun same_coin_index(): u64 {
    2
  }

  public fun failed_to_converge(): u64 {
    3
  }
}