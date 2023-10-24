module amm::metadata {
  use std::type_name::{get, TypeName};

  use sui::math::pow;
  use sui::dynamic_field as df;
  use sui::object::{Self, UID};
  use sui::tx_context::TxContext;
  use sui::transfer::share_object;
  use sui::coin::{Self, CoinMetadata};

  struct CoinData has store, drop, copy {
    decimals: u8,
    decimals_scalar: u64
  }

  struct Metadata has key {
    id: UID
  }

  #[allow(unused_function)]
  fun init(ctx: &mut TxContext) {
    share_object(Metadata { id: object::new(ctx) });
  }

  public fun register_coin<CoinType>(metadata: &mut Metadata, coin_metadata: &CoinMetadata<CoinType>) {
    let decimals = coin::get_decimals(coin_metadata);
    df::add(&mut metadata.id, get<CoinType>(), CoinData { decimals, decimals_scalar: pow(10, decimals) });
  }

  public fun get_decimals_scalar<CoinType>(metadata: &Metadata): u64 {
    let data = df::borrow<TypeName, CoinData>(&metadata.id, get<CoinType>());
    data.decimals_scalar
  }

  public fun get_decimals<CoinType>(metadata: &Metadata): u8 {
    let data = df::borrow<TypeName, CoinData>(&metadata.id, get<CoinType>());
    data.decimals
  }
}