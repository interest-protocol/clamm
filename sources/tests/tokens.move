#[test_only]
module amm::usdc {
  use std::option;

  use sui::transfer;
  use sui::coin;
  use sui::tx_context::{Self, TxContext};

  struct USDC has drop {}

  fun init(witness: USDC, ctx: &mut TxContext) {
      let (treasury_cap, metadata) = coin::create_currency<USDC>(
            witness, 
            6, 
            b"USDC", 
            b"USDC Coin", 
            b"A stable coin issued by Circle",
            option::none(), 
            ctx
        );

      transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
      transfer::public_share_object(metadata);
  }

  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(USDC {}, ctx);
  }
}

#[test_only]
module amm::usdt {
  use std::option;

  use sui::transfer;
  use sui::coin;
  use sui::tx_context::{Self, TxContext};

  struct USDT has drop {}

  fun init(witness: USDT, ctx: &mut TxContext) {
      let (treasury_cap, metadata) = coin::create_currency<USDT>(
            witness, 
            9, 
            b"USDT", 
            b"USDT Coin", 
            b"A stable coin issued by Tether",
            option::none(), 
            ctx
        );

      transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
      transfer::public_share_object(metadata);
  }

  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(USDT {}, ctx);
  }
}

#[test_only]
module amm::eth {
  use std::option;

  use sui::transfer;
  use sui::coin;
  use sui::tx_context::{Self, TxContext};

  struct ETH has drop {}

  fun init(witness: ETH, ctx: &mut TxContext) {
      let (treasury_cap, metadata) = coin::create_currency<ETH>(
            witness, 
            9, 
            b"ETH", 
            b"Ethereum Coin", 
            b"The native coin of Ethereum",
            option::none(), 
            ctx
        );

      transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
      transfer::public_share_object(metadata);
  }

  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(ETH {}, ctx);
  }
}

#[test_only]
module amm::lp_coin {
  use std::option;

  use sui::transfer;
  use sui::coin;
  use sui::tx_context::{Self, TxContext};

  struct LP_COIN has drop {}

  fun init(witness: LP_COIN, ctx: &mut TxContext) {
      let (treasury_cap, metadata) = coin::create_currency<LP_COIN>(
            witness, 
            9, 
            b"LP_COIN", 
            b"LP_COIN Coin", 
            b"Liquidity Pool",
            option::none(), 
            ctx
        );

      transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
      transfer::public_share_object(metadata);
  }

  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(LP_COIN {}, ctx);
  }
}