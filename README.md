# [Interest Protocol CLAMM](https://www.interestprotocol.com/)

 <p> <img width="50px"height="50px" src="./asset/logo.png" /></p> 
 
 CLAMM DEX on [Sui](https://sui.io/) Network.  
  
## Quick start  
  
Make sure you have the latest version of the Sui binaries installed on your machine

[Instructions here](https://docs.sui.io/devnet/build/install)

### Run tests

**To run the tests on the dex directory**

```bash
  cd contracts
  sui move test --gas-limit 5000000000
```

Only the UniV2 invariant has been formally verified.

### Publish

```bash
  cd contracts
  sui client publish --gas-budget 500000000
```

## Repo Structure

- **contracts:** CLAMM Move code.
- **hardhat-volatile** Curve contracts to run tests.

## Functionality

### DEX

The Interest Protocol CLAMM DEX allows users to create pools, add/remove liquidity and swap.

The DEX supports two types of [Curve](https://curve.fi/) pools denoted as:

- **[Volatile](https://resources.curve.fi/base-features/understanding-crypto-pools/)**
- **[Stable](https://miguelmota.com/blog/understanding-stableswap-curve/)**

## Contact Us

- Twitter: [@interest_dinero](https://twitter.com/interest_dinero)
- Discord: https://discord.gg/interest
- Telegram: https://t.me/interestprotocol
- Email: [contact@interestprotocol.com](mailto:contact@interestprotocol.com)
- Medium: [@interestprotocol](https://medium.com/@interestprotocol)
