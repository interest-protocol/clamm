// No Hook function Calls
module amm::stable_pair {
  use sui::event::emit;
  use sui::balance::Supply;
  use sui::object::{Self, ID};
  use sui::tx_context::{Self, TxContext};
  use sui::transfer::public_share_object;
  use sui::coin::{Self, CoinMetadata, Coin};

  use amm::hooks; 
  use amm::errors;
  use amm::curves::StablePair;
  use amm::stable_pair_core as core;
  use amm::interest_pool::{Self, Pool, Nothing};

  struct NewStablePair<phantom Curve, phantom Label, phantom HookWitness> has drop, copy {
    pool_id: ID,
    amount_x: u64,
    amount_y: u64,
    sender: address
  }

  struct Swap<phantom Curve, phantom Label, phantom HookWitness, phantom CoinIn, phantom CoinOut> has drop, copy {
    pool_id: ID,
    amount_in: u64,
    amount_out: u64,
    sender: address
  }

  struct AddLiquidity<phantom Curve, phantom Label, phantom HookWitness, phantom CoinX, phantom CoinY> has drop, copy {
    pool_id: ID,
    amount_x: u64,
    amount_y: u64,
    shares: u64,
    sender: address
  }

  struct RemoveLiquidity<phantom Curve, phantom Label, phantom HookWitness, phantom CoinX, phantom CoinY> has drop, copy {
    pool_id: ID,
    amount_x: u64,
    amount_y: u64,
    shares: u64,
    sender: address
  }

  public fun new<Label, CoinX, CoinY, LpCoin>(
    coin_x: Coin<CoinX>,
    coin_y: Coin<CoinY>,
    lp_coin_supply: Supply<LpCoin>,
    coin_x_metadata: &CoinMetadata<CoinX>,
    coin_y_metadata: &CoinMetadata<CoinY>,      
    ctx: &mut TxContext
  ): Coin<LpCoin> {
    let amount_x = coin::value(&coin_x);
    let amount_y = coin::value(&coin_y);
    
    let (pool, lp_coin) = core::new<Label, CoinX, CoinY, LpCoin>(coin_x, coin_y, lp_coin_supply, coin_x_metadata, coin_y_metadata, ctx);

    emit(NewStablePair<StablePair, Label, Nothing> { pool_id: object::id(&pool), amount_x, amount_y, sender: tx_context::sender(ctx) });

    public_share_object(pool);

    lp_coin
  }

  public fun swap<Label, HookWitness, CoinIn, CoinOut, LpCoin>(
    pool: &mut Pool<StablePair, Label, HookWitness>, 
    coin_in: Coin<CoinIn>,
    coin_min_value: u64,
    ctx: &mut TxContext    
  ): Coin<CoinOut> {
    assert!(!hooks::has_swap_hook(interest_pool::view_hooks(pool)), errors::hooks_not_allowed());

    let amount_in = coin::value(&coin_in);
    let coin_out = core::swap<Label, HookWitness, CoinIn, CoinOut, LpCoin>(pool, coin_in, coin_min_value, ctx);

    emit(Swap<StablePair, Label, Nothing, CoinIn, CoinOut>{ pool_id: object::id(pool), amount_in, amount_out: coin::value(&coin_out), sender: tx_context::sender(ctx) });

    coin_out
  }

  public fun add_liquidity<Label, HookWitness, CoinX, CoinY, LpCoin>(
    pool: &mut Pool<StablePair, Label, HookWitness>,
    coin_x: Coin<CoinX>,
    coin_y: Coin<CoinY>,
    lp_coin_min_amount: u64,
    ctx: &mut TxContext 
  ): (Coin<LpCoin>, Coin<CoinX>, Coin<CoinY>) {
    assert!(!hooks::has_position_hook(interest_pool::view_hooks(pool)), errors::hooks_not_allowed());

    let amount_x = coin::value(&coin_x);
    let amount_y = coin::value(&coin_y);
    
    let (lp_coin, extra_x, extra_y) = core::add_liquidity<Label, HookWitness, CoinX, CoinY, LpCoin>(pool, coin_x, coin_y, lp_coin_min_amount, ctx);

    emit(AddLiquidity<StablePair, Label, Nothing, CoinX, CoinY>{ pool_id: object::id(pool), amount_x, amount_y, shares: coin::value(&lp_coin), sender: tx_context::sender(ctx) });

    (lp_coin, extra_x, extra_y)
  }

  public fun remove_liquidity<Label, HookWitness, CoinX, CoinY, LpCoin>(
    pool: &mut Pool<StablePair, Label, HookWitness>,
    lp_coin: Coin<LpCoin>,
    coin_x_min_amount: u64,
    coin_y_min_amount: u64,
    ctx: &mut TxContext
  ): (Coin<CoinX>, Coin<CoinY>) {
    assert!(!hooks::has_position_hook(interest_pool::view_hooks(pool)), errors::hooks_not_allowed());

    let shares = coin::value(&lp_coin);

    let (coin_x, coin_y) = core::remove_liquidity<Label, HookWitness, CoinX, CoinY, LpCoin>(pool, lp_coin, coin_x_min_amount, coin_y_min_amount, ctx);

    let amount_x = coin::value(&coin_x);
    let amount_y = coin::value(&coin_y);

    emit(RemoveLiquidity<StablePair, Label, Nothing, CoinX, CoinY>{ pool_id: object::id(pool), amount_x, amount_y, shares, sender: tx_context::sender(ctx) });

    (coin_x, coin_y)
  }
}