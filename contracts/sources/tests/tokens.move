#[test_only]
module clamm::dai {
  use std::option;

  use sui::transfer;
  use sui::coin;
  use sui::tx_context::{Self, TxContext};

  struct DAI has drop {}

  #[lint_allow(share_owned)]
  fun init(witness: DAI, ctx: &mut TxContext) {
      let (treasury_cap, metadata) = coin::create_currency<DAI>(
            witness, 
            9, 
            b"DAI", 
            b"DAI", 
            b"Market DAO",
            option::none(), 
            ctx
        );

      transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
      transfer::public_share_object(metadata);
  }

  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(DAI {}, ctx);
  }
}

#[test_only]
module clamm::usdc {
  use std::option;

  use sui::transfer;
  use sui::coin;
  use sui::tx_context::{Self, TxContext};

  struct USDC has drop {}

  #[lint_allow(share_owned)]
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
module clamm::usdt {
  use std::option;

  use sui::transfer;
  use sui::coin;
  use sui::tx_context::{Self, TxContext};

  struct USDT has drop {}

  #[lint_allow(share_owned)]
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
module clamm::true_usd {
  use std::option;

  use sui::transfer;
  use sui::coin;
  use sui::tx_context::{Self, TxContext};

  struct TRUE_USD has drop {}

  #[lint_allow(share_owned)]
  fun init(witness: TRUE_USD, ctx: &mut TxContext) {
      let (treasury_cap, metadata) = coin::create_currency<TRUE_USD>(
            witness, 
            9, 
            b"TRUE_USD", 
            b"TRUE_USD Coin", 
            b"",
            option::none(), 
            ctx
        );

      transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
      transfer::public_share_object(metadata);
  }

  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(TRUE_USD {}, ctx);
  }
}

#[test_only]
module clamm::frax {
  use std::option;

  use sui::transfer;
  use sui::coin;
  use sui::tx_context::{Self, TxContext};

  struct FRAX has drop {}

  #[lint_allow(share_owned)]
  fun init(witness: FRAX, ctx: &mut TxContext) {
      let (treasury_cap, metadata) = coin::create_currency<FRAX>(
            witness, 
            9, 
            b"FRAX", 
            b"FRAX Coin", 
            b"",
            option::none(), 
            ctx
        );

      transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
      transfer::public_share_object(metadata);
  }

  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(FRAX {}, ctx);
  }
}

#[test_only]
module clamm::btc {
  use std::option;

  use sui::transfer;
  use sui::coin;
  use sui::tx_context::{Self, TxContext};

  struct BTC has drop {}

  #[lint_allow(share_owned)]
  fun init(witness: BTC, ctx: &mut TxContext) {
      let (treasury_cap, metadata) = coin::create_currency<BTC>(
            witness, 
            9, 
            b"BTC", 
            b"Bitcoin", 
            b"P2P Network",
            option::none(), 
            ctx
        );

      transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
      transfer::public_share_object(metadata);
  }

  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(BTC {}, ctx);
  }
}

#[test_only]
module clamm::eth {
  use std::option;

  use sui::transfer;
  use sui::coin;
  use sui::tx_context::{Self, TxContext};

  struct ETH has drop {}

  #[lint_allow(share_owned)]
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
module clamm::lp_coin {
  use std::option;

  use sui::transfer;
  use sui::coin;
  use sui::tx_context::{Self, TxContext};

  struct LP_COIN has drop {}

  #[lint_allow(share_owned)]
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

#[test_only]
module clamm::lp_coin_2 {
  use std::option;

  use sui::transfer;
  use sui::coin;
  use sui::tx_context::{Self, TxContext};

  struct LP_COIN_2 has drop {}

  #[lint_allow(share_owned)]
  fun init(witness: LP_COIN_2, ctx: &mut TxContext) {
      let (treasury_cap, metadata) = coin::create_currency<LP_COIN_2>(
            witness, 
            9, 
            b"LP_COIN_2", 
            b"LP_COIN_2 Coin", 
            b"Liquidity Pool",
            option::none(), 
            ctx
        );

      transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
      transfer::public_share_object(metadata);
  }

  #[test_only]
  public fun init_for_testing(ctx: &mut TxContext) {
    init(LP_COIN_2 {}, ctx);
  }
}