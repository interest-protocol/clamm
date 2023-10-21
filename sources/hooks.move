module amm::hooks {

  const CREATION_HOOK: u8 = 1; // 0001
  const SWAP_HOOK: u8 = 2; // 0010
  const POSITION_HOOK: u8 = 4; // 0100

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
}