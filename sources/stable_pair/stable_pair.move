// No Hook function Calls
module amm::stable_pair {
  use sui::object;
  use sui::balance::Supply;
  use sui::coin::{Self, Coin};
  use sui::tx_context::TxContext;
  use sui::transfer::public_share_object;

  use amm::hooks; 
  use amm::errors;
  use amm::metadata::Metadata;
  use amm::curves::StablePair;
  use amm::stable_pair_core as core;
  use amm::stable_pair_events as events;
  use amm::interest_pool::{Self, Pool, Nothing};

  public fun new<Label, CoinX, CoinY, LpCoin>(
    coin_x: Coin<CoinX>,
    coin_y: Coin<CoinY>,
    lp_coin_supply: Supply<LpCoin>,
    metadata: &Metadata,        
    ctx: &mut TxContext
  ): Coin<LpCoin> {
    let amount_x = coin::value(&coin_x);
    let amount_y = coin::value(&coin_y);
    
    let (pool, lp_coin) = core::new<Label, CoinX, CoinY, LpCoin>(coin_x, coin_y, lp_coin_supply, metadata, ctx);

    events::emit_new_pair<Label, Nothing>(object::id(&pool), amount_x, amount_y, ctx);

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
    
    events::emit_swap<Label, Nothing, CoinIn, CoinOut>(object::id(pool), amount_in, coin::value(&coin_out), ctx);

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

    events::emit_add_liquidity<Label, Nothing, CoinX, CoinY>(object::id(pool), amount_x, amount_y, coin::value(&lp_coin), ctx);

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

    events::emit_remove_liquidity<Label, Nothing, CoinX, CoinY>(object::id(pool), amount_x, amount_y, shares, ctx);

    (coin_x, coin_y)
  }
}