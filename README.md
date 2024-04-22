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

### Publish

```bash
  cd contracts
  sui client publish --gas-budget 500000000
```

## Repo Structure

- **assets:** Brand assets.
- **contracts:** CLAMM Move code.
- **hardhat-volatile** Curve contracts to run tests.
- **scripts** TS publish scripts.

## Package

The CLAMM is deployed on Sui's testnet using under the branch `framework/testnet`.

To include on your package please use add the code below on your Move.toml:

```toml
[dependencies.CLAMM]
git = "https://github.com/interest-protocol/clamm.git"
subdir = "contracts"
rev = "testnet/1.0.0-alpha"

[addresses]
clamm = "0xe7bace36469cf724dc17b7faf63050d38b83fe639ca295ed567758bcfed0d53c"
```

Please find all objectIds under this [JSON file](./clamm.json).

## Functionality

### DEX

The Interest Protocol CLAMM DEX allows users to create pools, add/remove liquidity and swap.

The DEX supports two types of [Curve](https://curve.fi/) pools denoted as:

- **[Volatile](https://resources.curve.fi/base-features/understanding-crypto-pools/)**
- **[Stable](https://miguelmota.com/blog/understanding-stableswap-curve/)**

## Contact Us

- Twitter: [@IPXSui](https://twitter.com/IPXSui)
- Discord: https://discord.gg/interest
- Telegram: https://t.me/interestprotocol
- Email: [contact@interestprotocol.com](mailto:contact@interestprotocol.com)
- Medium: [@interestprotocol](https://medium.com/@interestprotocol)
