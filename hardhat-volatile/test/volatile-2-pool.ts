import { loadFixture } from '@nomicfoundation/hardhat-toolbox-viem/network-helpers';
import { expect } from 'chai';
import hre from 'hardhat';

const A = '36450000';
const GAMMA = '70000000000000';
const MID_FEE = '4000000';
const OUT_FEE = '40000000';
const ALLOWED_EXTRA_PROFIT = '2000000000000';
const FEE_GAMMA = '10000000000000000';
const ADJUSTMENT_STEP = '1500000000000000';
const ADMIN_FEE = '2000000000';
const MA_HALF_TIME = '600000';
const ETH_INITIAL_PRICE = 1500n * 1_000_000_000_000_000_000n;

describe('Volatile 2 Pool', function () {
  async function deploy2PoolFixture() {
    const [owner, otherAccount] = await hre.ethers.getSigners();

    const weth = await hre.ethers.deployContract('ETH');

    let lpCoin = await hre.viem.deployContract('LpCoin');
    let usdc = await hre.viem.deployContract('USDC');
    let eth = await hre.viem.deployContract('ETH');

    // owner: address,
    // admin_fee_receiver: address,
    // A: uint256,
    // gamma: uint256,
    // mid_fee: uint256,
    // out_fee: uint256,
    // allowed_extra_profit: uint256,
    // fee_gamma: uint256,
    // adjustment_step: uint256,
    // admin_fee: uint256,
    // ma_half_time: uint256,
    // initial_price: uint256,
    // _token: address,
    // _coins: address[2]

    const pool = await hre.viem.deployContract('2-pool', [
      owner.address,
      owner.address,
      A,
      GAMMA,
      MID_FEE,
      OUT_FEE,
      ALLOWED_EXTRA_PROFIT,
      FEE_GAMMA,
      ADJUSTMENT_STEP,
      ADMIN_FEE,
      MA_HALF_TIME,
      ETH_INITIAL_PRICE,
      lpCoin.address,
      [usdc.address, eth.address],
    ]);

    return {
      pool,
      owner,
      lpCoin,
      eth,
      usdc,
      weth,
      otherAccount,
    };
  }

  describe('Add liquidity', function () {
    it('Has the correct metadata', async function () {
      const { pool } = await loadFixture(deploy2PoolFixture);
      expect(await pool.read.A()).to.equal(A);
    });
  });
});
