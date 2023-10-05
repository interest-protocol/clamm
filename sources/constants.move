module amm::constants {

  const WAD: u128 = 1_000_000_000;
  
  const RAY: u256 = 1_000_000_000_000_000_000;

  public fun wad(): u128 {
    WAD
  }

  public fun ray(): u256 {
    RAY
  }
}