module amm::hooks {

  use sui::coin::Coin;

  const CREATION_HOOK: u8 = 1; // 0001
  const SWAP_HOOK: u8 = 2; // 0010
  const POSITION_HOOK: u8 = 4; // 0100

  friend amm::stable_pair;
  friend amm::stable_pair_hooks;

  struct HookMap has store {
    bits: u8
  }

  struct HookConfig has store, drop, copy {
    creation: bool,
    swap: bool,
    position: bool
  }

  public fun no_hook_map(): HookMap {
    HookMap {
      bits: 0
    }
  }

  public fun make_hook_config(
    creation: bool,
    swap: bool,
    position: bool
  ): HookConfig {
    HookConfig {
      creation,
      swap, 
      position
    }
  }

  public fun convert_config_to_map(config: HookConfig): HookMap {
    let HookConfig { creation, swap, position } = config;

    let bits = 0;

    if (creation) bits = bits | CREATION_HOOK;
    if (swap) bits = bits | SWAP_HOOK;
    if (position) bits = bits | POSITION_HOOK;

    HookMap {
      bits
    }
  }

  public fun has_creation_hook(map: &HookMap): bool {
    (map.bits & CREATION_HOOK) != 0
  }

  public fun has_swap_hook(map: &HookMap): bool {
    (map.bits & SWAP_HOOK) != 0
  }

  public fun has_position_hook(map: &HookMap): bool {
    (map.bits & POSITION_HOOK) != 0
  }

  // * Hook hot Potatoes

  // * Hot potato DO NOT ADD ABILITIES

  struct StablePairPreSwap<phantom Witness: drop, phantom CoinType> {
    coin_in: Coin<CoinType>,
    coin_min_value: u64,
  }

  public fun pre_stable_pair_swap_action<Witness: drop, CoinIn>(
    _: Witness,
    coin_in: Coin<CoinIn>,
    coin_min_value: u64,  
  ): StablePairPreSwap<Witness, CoinIn> {
    StablePairPreSwap {
      coin_in,
      coin_min_value
    }
  }

  public(friend) fun destroy_pre_swap_action<Witness: drop, CoinIn>(action: StablePairPreSwap<Witness, CoinIn>): (Coin<CoinIn>, u64) {
    let StablePairPreSwap { coin_in, coin_min_value } = action;
    (coin_in, coin_min_value)
  }

  // * Used after swaps and Pool creation is a swap
  struct StablePairPostSwap<phantom Witness: drop, phantom CoinType> {
    coin_out: Coin<CoinType>
  }

  public(friend) fun post_stable_pair_swap_action<Witness: drop, CoinOut>(
    coin_out: Coin<CoinOut>
  ): StablePairPostSwap<Witness, CoinOut> {
    StablePairPostSwap {
      coin_out
    }
  }

  public fun destroy_post_swap_action<Witness: drop, CoinOut>(_: Witness, action: StablePairPostSwap<Witness, CoinOut>): Coin<CoinOut> {
    let StablePairPostSwap { coin_out } = action;
    coin_out
  }

  struct StablePairPreAddLiquidity<phantom Witness: drop, phantom CoinX, phantom CoinY> {
    coin_x: Coin<CoinX>,
    coin_y: Coin<CoinY>,
    lp_coin_min_amount: u64,
  }

  public fun pre_stable_pair_add_liquidity_action<Witness: drop, CoinX, CoinY>(
    _: Witness,
    coin_x: Coin<CoinX>,
    coin_y: Coin<CoinY>,
    lp_coin_min_amount: u64, 
  ): StablePairPreAddLiquidity<Witness, CoinX, CoinY> {
    StablePairPreAddLiquidity {
      coin_x,
      coin_y,
      lp_coin_min_amount
    }
  }

  public(friend) fun destroy_pre_add_liquidity_action<Witness: drop, CoinX, CoinY>(
    action: StablePairPreAddLiquidity<Witness, CoinX, CoinY>
  ): (Coin<CoinX>, Coin<CoinY>, u64) {
    let StablePairPreAddLiquidity { coin_x, coin_y, lp_coin_min_amount } = action;
    (coin_x, coin_y, lp_coin_min_amount)
  }

  // * Used after swaps and Pool creation is a swap
  struct StablePairPostAddLiquidity<phantom Witness: drop, phantom LpCoin, phantom CoinX, phantom CoinY> {
    lp_coin: Coin<LpCoin>, 
    coin_x: Coin<CoinX>, 
    coin_y: Coin<CoinY>
  }

  public(friend) fun post_stable_pair_add_liquidity_action<Witness: drop, LpCoin, CoinX, CoinY>(
    lp_coin: Coin<LpCoin>, 
    coin_x: Coin<CoinX>, 
    coin_y: Coin<CoinY>
  ): StablePairPostAddLiquidity<Witness, LpCoin, CoinX, CoinY> {
    StablePairPostAddLiquidity {
      lp_coin,
      coin_x,
      coin_y
    }
  }

  public fun destroy_post_add_liquidity_action<Witness: drop, LpCoin, CoinX, CoinY>(
    _: Witness, 
    action: StablePairPostAddLiquidity<Witness, LpCoin, CoinX, CoinY>
  ): (Coin<LpCoin>, Coin<CoinX>, Coin<CoinY>) {
    let StablePairPostAddLiquidity { lp_coin, coin_x, coin_y } = action;
    (lp_coin, coin_x, coin_y)
  }
}