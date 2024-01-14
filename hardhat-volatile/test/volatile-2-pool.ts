import {
  loadFixture,
  time,
} from '@nomicfoundation/hardhat-toolbox-viem/network-helpers';
import { expect } from 'chai';
import { mine } from '@nomicfoundation/hardhat-network-helpers';

import hre from 'hardhat';

const A = '36450000';
const GAMMA = '70000000000000';
const ETH_PRECISION = 1_000_000_000_000_000_000n;
const USDC_PRECISION = 1_000_000n;
const MID_FEE = '4000000';
const OUT_FEE = '40000000';
const ALLOWED_EXTRA_PROFIT = '2000000000000';
const FEE_GAMMA = '10000000000000000';
const ADJUSTMENT_STEP = '1500000000000000';
const ADMIN_FEE = '2000000000';
const MA_HALF_TIME = '600000';
const ETH_INITIAL_PRICE = 1500n * ETH_PRECISION;
const MAX_U256 =
  '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

describe('Volatile 2 Pool', function () {
  async function deploy2PoolFixture() {
    const [owner, bob, alice] = await hre.ethers.getSigners();

    const weth = await hre.ethers.deployContract('ETH');

    let lpCoin = await hre.ethers.deployContract('LpCoin');
    let usdc = await hre.ethers.deployContract('USDC');
    let eth = await hre.ethers.deployContract('ETH');

    let lpCoinAddress = await lpCoin.getAddress();
    let usdcAddress = await usdc.getAddress();
    let ethAddress = await eth.getAddress();

    const pool = (await hre.ethers.deployContract('2-pool', [
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
      lpCoinAddress,
      [usdcAddress, ethAddress],
    ])) as any;

    await pool.waitForDeployment();

    const poolAddress = (await pool.getAddress()) as `0x${string}`;

    // Approve
    await Promise.all([
      usdc.connect(alice).approve(poolAddress, BigInt(MAX_U256)),
      usdc.connect(bob).approve(poolAddress, BigInt(MAX_U256)),
      eth.connect(alice).approve(poolAddress, BigInt(MAX_U256)),
      eth.connect(bob).approve(poolAddress, BigInt(MAX_U256)),
    ]);

    // Mint Coins
    await Promise.all([
      usdc.connect(alice).mint(alice.address, 1_000_000n * USDC_PRECISION),
      usdc.connect(bob).mint(bob.address, 1_000_000n * USDC_PRECISION),
      eth.connect(alice).mint(alice.address, 1_000_000n * ETH_PRECISION),
      eth.connect(alice).mint(bob.address, 1_000_000n * ETH_PRECISION),
    ]);

    return {
      pool,
      lpCoin,
      eth,
      usdc,
      weth,
      owner,
      alice,
      bob,
      poolAddress,
    };
  }

  describe('Add liquidity', function () {
    it('mints the correct lp coin amount when adding both tokens', async function () {
      const { pool, alice, bob, lpCoin } = await loadFixture(
        deploy2PoolFixture
      );

      expect(await lpCoin.totalSupply()).to.be.equal(0n);
      expect(await pool.balances(0n)).to.be.equal(0n);
      expect(await pool.balances(1n)).to.be.equal(0n);

      await pool
        .connect(alice)
        .add_liquidity([4500n * USDC_PRECISION, 3n * ETH_PRECISION], 0n);

      expect(await lpCoin.totalSupply()).to.be.equal(116189500386222506555n);

      expect(await lpCoin.balanceOf(alice.address)).to.be.equal(
        116189500386222506555n
      );

      expect(await pool.balances(0n)).to.be.equal(4500000000n);
      expect(await pool.balances(1n)).to.be.equal(3000000000000000000n);
      expect(await pool.last_prices()).to.be.equal(1500000000000000000000n);
      expect(await pool.price_scale()).to.be.equal(1500000000000000000000n);
      expect(await pool.price_oracle()).to.be.equal(1500000000000000000000n);
      expect(await pool.xcp_profit()).to.be.equal(1000000000000000000n);
      expect(await pool.xcp_profit_a()).to.be.equal(1000000000000000000n);
      expect(await pool.virtual_price()).to.be.equal(1000000000000000000n);
      expect(await pool.D()).to.be.equal(9000000000000000000000n);

      await pool
        .connect(bob)
        .add_liquidity([6000n * USDC_PRECISION, 5n * ETH_PRECISION], 0n);

      expect(await lpCoin.totalSupply()).to.be.equal(290178641323480024837n);
      expect(await pool.balances(0n)).to.be.equal(10500000000n);
      expect(await pool.balances(1n)).to.be.equal(8000000000000000000n);
      expect(await pool.last_prices()).to.be.equal(1367804588351816940129n);
      expect(await pool.price_scale()).to.be.equal(1500000000000000000000n);
      expect(await pool.price_oracle()).to.be.equal(1500000000000000000000n);
      expect(await pool.xcp_profit()).to.be.equal(1000056223489999239n);
      expect(await pool.xcp_profit_a()).to.be.equal(1000000000000000000n);
      expect(await pool.virtual_price()).to.be.equal(1000056223489999239n);
      expect(await pool.D()).to.be.equal(22478404648725576997253n);

      await pool.connect(bob).add_liquidity([3555n * USDC_PRECISION, 0], 0n);

      expect(await lpCoin.totalSupply()).to.be.equal(335767435234073784787n);
      expect(await pool.balances(0n)).to.be.equal(14055000000n);
      expect(await pool.balances(1n)).to.be.equal(8000000000000000000n);
      expect(await pool.last_prices()).to.be.equal(1516005048653128990338n);
      expect(await pool.price_scale()).to.be.equal(1500000000000000000000n);
      expect(await pool.price_oracle()).to.be.equal(1499999847722906425348n);
      expect(await pool.xcp_profit()).to.be.equal(1000178579896382236n);
      expect(await pool.xcp_profit_a()).to.be.equal(1000000000000000000n);
      expect(await pool.virtual_price()).to.be.equal(1000178579896382236n);
      expect(await pool.D()).to.be.equal(26013078280601615791473n);
    });

    it('mints the correct lp coin amount after swaps', async function () {
      const { pool, alice, bob, lpCoin } = await loadFixture(
        deploy2PoolFixture
      );

      await pool
        .connect(alice)
        .add_liquidity([4500n * USDC_PRECISION, 3n * ETH_PRECISION], 0n);

      expect(await lpCoin.totalSupply()).to.be.equal(116189500386222506555n);

      expect(await lpCoin.balanceOf(alice.address)).to.be.equal(
        116189500386222506555n
      );

      // Nuke the pool in one direction
      await pool.connect(bob).exchange(0, 1, 500n * USDC_PRECISION, 0);
      await pool.connect(bob).exchange(0, 1, 500n * USDC_PRECISION, 0);
      await pool.connect(bob).exchange(0, 1, 500n * USDC_PRECISION, 0);
      await pool.connect(bob).exchange(0, 1, 500n * USDC_PRECISION, 0);
      await pool.connect(bob).exchange(0, 1, 500n * USDC_PRECISION, 0);
      await pool.connect(bob).exchange(0, 1, 500n * USDC_PRECISION, 0);
      await pool.connect(bob).exchange(0, 1, 500n * USDC_PRECISION, 0);
      await pool.connect(bob).exchange(0, 1, 500n * USDC_PRECISION, 0);

      await pool
        .connect(alice)
        .add_liquidity([4500n * USDC_PRECISION, 3n * ETH_PRECISION], 0n);

      expect(await lpCoin.totalSupply()).to.be.equal(244539028190137475954n);
      expect(await pool.balances(0n)).to.be.equal(13000000000n);
      expect(await pool.balances(1n)).to.be.equal(4567622127595462231n);
      expect(await pool.last_prices()).to.be.equal(2786752167064038352149n);
      expect(await pool.price_scale()).to.be.equal(1500000000000000000000n);
      expect(await pool.price_oracle()).to.be.equal(1500015648683286431117n);
      expect(await pool.xcp_profit()).to.be.equal(1001168132261547627n);
      expect(await pool.xcp_profit_a()).to.be.equal(1000000000000000000n);
      expect(await pool.virtual_price()).to.be.equal(1001168132261547627n);
      expect(await pool.D()).to.be.equal(18964038331684244298722n);

      await pool.connect(alice).add_liquidity([0, 7n * ETH_PRECISION], 0n);

      expect(await lpCoin.totalSupply()).to.be.equal(388129423446248101851n);
      expect(await pool.balances(0n)).to.be.equal(13000000000n);
      expect(await pool.balances(1n)).to.be.equal(11567622127595462231n);
      expect(await pool.last_prices()).to.be.equal(1767841266387619535092n);
      expect(await pool.price_scale()).to.be.equal(1500000000000000000000n);
      expect(await pool.price_oracle()).to.be.equal(1500017130886751532092n);
      expect(await pool.xcp_profit()).to.be.equal(1001695159717659519n);
      expect(await pool.xcp_profit_a()).to.be.equal(1000000000000000000n);
      expect(await pool.virtual_price()).to.be.equal(1001695159717659519n);
      expect(await pool.D()).to.be.equal(30115339782508672015786n);
    });

    it('mints the correct lp coin amount after swaps with a time delay', async function () {
      const { pool, alice, bob, lpCoin } = await loadFixture(
        deploy2PoolFixture
      );

      await pool
        .connect(alice)
        .add_liquidity([4500n * USDC_PRECISION, 3n * ETH_PRECISION], 0n);

      expect(await lpCoin.totalSupply()).to.be.equal(116189500386222506555n);

      expect(await lpCoin.balanceOf(alice.address)).to.be.equal(
        116189500386222506555n
      );

      await time.increase(20);
      await mine();

      // Nuke the pool in one direction
      await pool.connect(bob).exchange(0, 1, 500n * USDC_PRECISION, 0);
      await time.increase(20);
      await mine();

      await pool.connect(bob).exchange(0, 1, 500n * USDC_PRECISION, 0);
      await time.increase(20);
      await mine();

      await pool.connect(bob).exchange(0, 1, 500n * USDC_PRECISION, 0);
      await time.increase(20);
      await mine();

      await pool.connect(bob).exchange(0, 1, 500n * USDC_PRECISION, 0);
      await time.increase(20);
      await mine();

      await pool.connect(bob).exchange(0, 1, 500n * USDC_PRECISION, 0);
      await time.increase(20);
      await mine();

      await pool.connect(bob).exchange(0, 1, 500n * USDC_PRECISION, 0);
      await time.increase(20);
      await mine();

      await pool.connect(bob).exchange(0, 1, 500n * USDC_PRECISION, 0);
      await time.increase(20);
      await mine();

      await pool.connect(bob).exchange(0, 1, 500n * USDC_PRECISION, 0);
      await time.increase(20);
      await mine();

      await pool
        .connect(alice)
        .add_liquidity([4500n * USDC_PRECISION, 3n * ETH_PRECISION], 0n);

      expect(await lpCoin.totalSupply()).to.be.equal(244539028190137475954n);
      expect(await pool.balances(0n)).to.be.equal(13000000000n);
      expect(await pool.balances(1n)).to.be.equal(4567622127595462231n);
      expect(await pool.last_prices()).to.be.equal(2786752167064038352149n);
      expect(await pool.price_scale()).to.be.equal(1500000000000000000000n);
      expect(await pool.price_oracle()).to.be.equal(1500345157438641016993n);
      expect(await pool.xcp_profit()).to.be.equal(1001168132261547627n);
      expect(await pool.xcp_profit_a()).to.be.equal(1000000000000000000n);
      expect(await pool.virtual_price()).to.be.equal(1001168132261547627n);
      expect(await pool.D()).to.be.equal(18964038331684244298722n);

      await pool.connect(alice).add_liquidity([0, 7n * ETH_PRECISION], 0n);

      expect(await lpCoin.totalSupply()).to.be.equal(388129423446248101851n);
      expect(await pool.balances(0n)).to.be.equal(13000000000n);
      expect(await pool.balances(1n)).to.be.equal(11567622127595462231n);
      expect(await pool.last_prices()).to.be.equal(1767841266387619535092n);
      expect(await pool.price_scale()).to.be.equal(1500000000000000000000n);
      expect(await pool.price_oracle()).to.be.equal(1500346639262541994318n);
      expect(await pool.xcp_profit()).to.be.equal(1001695159717659519n);
      expect(await pool.xcp_profit_a()).to.be.equal(1000000000000000000n);
      expect(await pool.virtual_price()).to.be.equal(1001695159717659519n);
      expect(await pool.D()).to.be.equal(30115339782508672015786n);
    });
  });
});
