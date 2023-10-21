// Hook function Calls
module amm::stable_pair_hooks {
  use sui::object;
  use sui::balance::Supply;
  use sui::tx_context::TxContext;
  use sui::transfer::public_share_object;
  use sui::coin::{Self, CoinMetadata, Coin};

  use amm::errors;
  use amm::curves::StablePair;
  use amm::stable_pair_core as core;
  use amm::interest_pool::{Self, Pool};
  use amm::stable_pair_events as events;
  use amm::hooks::{
    Self, 
    HookConfig,
    StablePairPreSwap, 
    StablePairPostSwap,
    StablePairPreAddLiquidity,
    StablePairPostAddLiquidity
  }; 

  public fun new<Label, HookWitness: drop, CoinX, CoinY, LpCoin>(
    witness: HookWitness, // OTW forces it to have a pre-creation hook
    hook_config: HookConfig,
    coin_x: Coin<CoinX>,
    coin_y: Coin<CoinY>,
    lp_coin_supply: Supply<LpCoin>,
    coin_x_metadata: &CoinMetadata<CoinX>,
    coin_y_metadata: &CoinMetadata<CoinY>,      
    ctx: &mut TxContext
  ): StablePairPostSwap<HookWitness, LpCoin> {
    let amount_x = coin::value(&coin_x);
    let amount_y = coin::value(&coin_y);
    
    let (pool, lp_coin) = core::new_with_hooks<Label, HookWitness, CoinX, CoinY, LpCoin>(
      witness, 
      hooks::convert_config_to_map(hook_config),
      coin_x, 
      coin_y, 
      lp_coin_supply, 
      coin_x_metadata, 
      coin_y_metadata, 
      ctx
    );

    events::emit_new_pair<Label, HookWitness>(object::id(&pool), amount_x, amount_y, ctx);

    public_share_object(pool);

    hooks::post_stable_pair_swap_action(lp_coin)
  }

  public fun swap<Label, HookWitness: drop, CoinIn, CoinOut, LpCoin>(
    pool: &mut Pool<StablePair, Label, HookWitness>, 
    action: StablePairPreSwap<HookWitness, CoinIn>,
    ctx: &mut TxContext    
  ): StablePairPostSwap<HookWitness, CoinOut> {
    assert!(hooks::has_swap_hook(interest_pool::view_hooks(pool)), errors::has_no_hook());

    let (coin_in, coin_min_value) = hooks::destroy_pre_swap_action(action);

    let amount_in = coin::value(&coin_in);
    let coin_out = core::swap<Label, HookWitness, CoinIn, CoinOut, LpCoin>(pool, coin_in, coin_min_value, ctx);
    
    events::emit_swap<Label, HookWitness, CoinIn, CoinOut>(object::id(pool), amount_in, coin::value(&coin_out), ctx);

    hooks::post_stable_pair_swap_action(coin_out)
  }

  public fun add_liquidity<Label, HookWitness: drop, CoinX, CoinY, LpCoin>(
    pool: &mut Pool<StablePair, Label, HookWitness>,
    action: StablePairPreAddLiquidity<HookWitness, CoinX, CoinY>,
    ctx: &mut TxContext 
  ): StablePairPostAddLiquidity<HookWitness, LpCoin, CoinX, CoinY> {
    assert!(hooks::has_position_hook(interest_pool::view_hooks(pool)), errors::has_no_hook());

    let (coin_x, coin_y, lp_coin_min_amount) = hooks::destroy_pre_add_liquidity_action(action);

    let amount_x = coin::value(&coin_x);
    let amount_y = coin::value(&coin_y);
    
    let (lp_coin, extra_x, extra_y) = core::add_liquidity<Label, HookWitness, CoinX, CoinY, LpCoin>(pool, coin_x, coin_y, lp_coin_min_amount, ctx);

    events::emit_add_liquidity<Label, HookWitness, CoinX, CoinY>(object::id(pool), amount_x, amount_y, coin::value(&lp_coin), ctx);

    hooks::post_stable_pair_add_liquidity_action(lp_coin, extra_x, extra_y)
  }
}