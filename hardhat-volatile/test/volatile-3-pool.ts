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
const BTC_PRECISION = 1_000_000_000_000_000_000n;
const USDC_PRECISION = 1_000_000n;
const MID_FEE = '4000000';
const OUT_FEE = '40000000';
const ALLOWED_EXTRA_PROFIT = '2000000000000';
const FEE_GAMMA = '10000000000000000';
const ADJUSTMENT_STEP = '1500000000000000';
const ADMIN_FEE = '2000000000';
const MA_HALF_TIME = '600000';
const ETH_INITIAL_PRICE = 1500n * ETH_PRECISION;
const BTC_INITIAL_PRICE = 47500n * BTC_PRECISION;

const MAX_U256 =
  '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

describe('Volatile 3 Pool', function () {
  async function deploy3PoolFixture() {
    const [owner, bob, alice] = await hre.ethers.getSigners();

    const weth = await hre.ethers.deployContract('ETH');

    const lpCoin = await hre.ethers.deployContract('LpCoin');
    const usdc = await hre.ethers.deployContract('USDC');
    const eth = await hre.ethers.deployContract('ETH');
    const btc = await hre.ethers.deployContract('BTC');

    const math = await hre.ethers.deployContract('math');

    const lpCoinAddress = await lpCoin.getAddress();
    const usdcAddress = await usdc.getAddress();
    const ethAddress = await eth.getAddress();
    const btcAddress = await btc.getAddress();
    const mathAddress = await math.getAddress();

    const view = await hre.ethers.deployContract('view', [mathAddress]);

    const viewAddress = await view.getAddress();

    const pool = (await hre.ethers.deployContract('3-pool', [
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
      [BTC_INITIAL_PRICE, ETH_INITIAL_PRICE],
      mathAddress,
      viewAddress,
      lpCoinAddress,
      [usdcAddress, btcAddress, ethAddress],
    ])) as any;

    await pool.waitForDeployment();

    const poolAddress = (await pool.getAddress()) as `0x${string}`;

    // Approve
    await Promise.all([
      usdc.connect(alice).approve(poolAddress, BigInt(MAX_U256)),
      usdc.connect(bob).approve(poolAddress, BigInt(MAX_U256)),
      btc.connect(alice).approve(poolAddress, BigInt(MAX_U256)),
      btc.connect(bob).approve(poolAddress, BigInt(MAX_U256)),
      eth.connect(alice).approve(poolAddress, BigInt(MAX_U256)),
      eth.connect(bob).approve(poolAddress, BigInt(MAX_U256)),
    ]);

    // Mint Coins
    await Promise.all([
      usdc.connect(alice).mint(alice.address, 10_000_000_000n * USDC_PRECISION),
      usdc.connect(bob).mint(bob.address, 10_000_000n * USDC_PRECISION),
      btc.connect(alice).mint(alice.address, 10_000_000_000n * BTC_PRECISION),
      btc.connect(alice).mint(bob.address, 10_000_000n * BTC_PRECISION),
      eth.connect(alice).mint(alice.address, 10_000_000_000n * ETH_PRECISION),
      eth.connect(alice).mint(bob.address, 10_000_000n * ETH_PRECISION),
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
        deploy3PoolFixture
      );

      expect(await lpCoin.totalSupply()).to.be.equal(0n);
      expect(await pool.balances(0n)).to.be.equal(0n);
      expect(await pool.balances(1n)).to.be.equal(0n);

      await pool
        .connect(alice)
        .add_liquidity(
          [150_000n * USDC_PRECISION, 3n * BTC_PRECISION, 100n * ETH_PRECISION],
          0n
        );

      expect(await lpCoin.totalSupply()).to.be.equal(355781584449860319361n);

      expect(await lpCoin.balanceOf(alice.address)).to.be.equal(
        355781584449860319361n
      );

      expect(await pool.balances(0n)).to.be.equal(150000000000n);
      expect(await pool.balances(1n)).to.be.equal(3000000000000000000n);
      expect(await pool.balances(2n)).to.be.equal(100000000000000000000n);

      expect(await pool.last_prices(0)).to.be.equal(47500000000000000000000n);
      expect(await pool.last_prices(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.price_scale(0)).to.be.equal(47500000000000000000000n);
      expect(await pool.price_scale(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.price_oracle(0)).to.be.equal(47500000000000000000000n);
      expect(await pool.price_oracle(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.xcp_profit()).to.be.equal(1000000000000000000n);
      expect(await pool.xcp_profit_a()).to.be.equal(1000000000000000000n);
      expect(await pool.virtual_price()).to.be.equal(1000000000000000000n);
      expect(await pool.D()).to.be.equal(442486144074400445244930n);

      await pool
        .connect(bob)
        .add_liquidity(
          [60_000n * USDC_PRECISION, 2n * BTC_PRECISION, 5n * ETH_PRECISION],
          0n
        );

      expect(await lpCoin.totalSupply()).to.be.equal(480377433110497362876n);
      expect(await pool.balances(0n)).to.be.equal(210000000000n);
      expect(await pool.balances(1n)).to.be.equal(5000000000000000000n);
      expect(await pool.balances(2n)).to.be.equal(105000000000000000000n);

      expect(await pool.last_prices(0)).to.be.equal(42297153987631797536005n);
      expect(await pool.last_prices(1)).to.be.equal(1972991592365437383014n);

      expect(await pool.price_scale(0)).to.be.equal(47500000000000000000000n);
      expect(await pool.price_scale(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.price_oracle(0)).to.be.equal(47500000000000000000000n);
      expect(await pool.price_oracle(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.xcp_profit()).to.be.equal(1000187682358106076n);
      expect(await pool.xcp_profit_a()).to.be.equal(1000000000000000000n);
      expect(await pool.virtual_price()).to.be.equal(1000187682358106076n);
      expect(await pool.D()).to.be.equal(597558336908883561483801n);

      await pool
        .connect(bob)
        .add_liquidity([300_555n * USDC_PRECISION, 0, 0], 0n);

      expect(await pool.balances(0n)).to.be.equal(510555000000n);
      expect(await pool.balances(1n)).to.be.equal(5000000000000000000n);
      expect(await pool.balances(2n)).to.be.equal(105000000000000000000n);

      expect(await pool.last_prices(0)).to.be.equal(66264310352904091732493n);
      expect(await pool.last_prices(1)).to.be.equal(3090962745115272648685n);

      expect(await pool.price_scale(0)).to.be.equal(47500000000000000000000n);
      expect(await pool.price_scale(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.price_oracle(0)).to.be.equal(47499994006794493076617n);
      expect(await pool.price_oracle(1)).to.be.equal(1500000544843304867041n);

      expect(await pool.xcp_profit()).to.be.equal(1000691985308738478n);
      expect(await pool.xcp_profit_a()).to.be.equal(1000000000000000000n);
      expect(await pool.virtual_price()).to.be.equal(1000691985308738478n);
      expect(await pool.D()).to.be.equal(805384032226452839704013n);

      await pool.connect(bob).add_liquidity([0n, 1n * BTC_PRECISION, 0n], 0n);

      expect(await pool.balances(0n)).to.be.equal(510555000000n);
      expect(await pool.balances(1n)).to.be.equal(6000000000000000000n);
      expect(await pool.balances(2n)).to.be.equal(105000000000000000000n);

      expect(await pool.last_prices(0)).to.be.equal(75742558267016538159185n);
      expect(await pool.last_prices(1)).to.be.equal(3090962745115272648685n);

      expect(await pool.price_scale(0)).to.be.equal(47500000000000000000000n);
      expect(await pool.price_scale(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.price_oracle(0)).to.be.equal(47500015621580668147039n);
      expect(await pool.price_oracle(1)).to.be.equal(1500002377487092000158n);

      expect(await pool.xcp_profit()).to.be.equal(1000806764556673796n);
      expect(await pool.xcp_profit_a()).to.be.equal(1000000000000000000n);
      expect(await pool.virtual_price()).to.be.equal(1000806764556673796n);
      expect(await pool.D()).to.be.equal(855738310293549946471340n);

      await pool.connect(bob).add_liquidity([0n, 0n, 27n * ETH_PRECISION], 0n);

      expect(await pool.balances(0n)).to.be.equal(510555000000n);
      expect(await pool.balances(1n)).to.be.equal(6000000000000000000n);
      expect(await pool.balances(2n)).to.be.equal(132000000000000000000n);

      expect(await pool.last_prices(0)).to.be.equal(75742558267016538159185n);
      expect(await pool.last_prices(1)).to.be.equal(4041883988841056305152n);

      expect(await pool.price_scale(0)).to.be.equal(47500000000000000000000n);
      expect(await pool.price_scale(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.price_oracle(0)).to.be.equal(47500048154421676658914n);
      expect(await pool.price_oracle(1)).to.be.equal(1500004210128768094276n);

      expect(await pool.xcp_profit()).to.be.equal(1000947482668888938n);
      expect(await pool.xcp_profit_a()).to.be.equal(1000000000000000000n);
      expect(await pool.virtual_price()).to.be.equal(1000947482668888938n);
      expect(await pool.D()).to.be.equal(923081926000246540413964n);
    });

    it('mints correctly lp coin amount after swaps', async () => {
      const { pool, alice, bob, lpCoin } = await loadFixture(
        deploy3PoolFixture
      );

      await pool
        .connect(alice)
        .add_liquidity(
          [150_000n * USDC_PRECISION, 3n * BTC_PRECISION, 100n * ETH_PRECISION],
          0n
        );

      // Nuke the pool in one direction
      await pool.connect(bob).exchange(0, 1, 20_000n * USDC_PRECISION, 0);
      await pool.connect(bob).exchange(0, 1, 20_000n * USDC_PRECISION, 0);
      await pool.connect(bob).exchange(0, 1, 20_000n * USDC_PRECISION, 0);
      await pool.connect(bob).exchange(0, 1, 20_000n * USDC_PRECISION, 0);
      await pool.connect(bob).exchange(0, 1, 20_000n * USDC_PRECISION, 0);
      await pool.connect(bob).exchange(0, 1, 20_000n * USDC_PRECISION, 0);
      await pool.connect(bob).exchange(0, 1, 20_000n * USDC_PRECISION, 0);

      await pool
        .connect(alice)
        .add_liquidity([150_000n * USDC_PRECISION, 3n * BTC_PRECISION, 0n], 0n);

      expect(await lpCoin.totalSupply()).to.be.equal(586029756410238804934n);

      expect(await pool.balances(0n)).to.be.equal(440000000000n);
      expect(await pool.balances(1n)).to.be.equal(4535024703268191759n);
      expect(await pool.balances(2n)).to.be.equal(100000000000000000000n);

      expect(await pool.last_prices(0)).to.be.equal(95866830069307439719678n);
      expect(await pool.last_prices(1)).to.be.equal(4332316479302974128020n);

      expect(await pool.price_scale(0)).to.be.equal(47500000000000000000000n);
      expect(await pool.price_scale(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.price_oracle(0)).to.be.equal(47500506106873931050560n);
      expect(await pool.price_oracle(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.xcp_profit()).to.be.equal(1001226700479424662n);
      expect(await pool.xcp_profit_a()).to.be.equal(1000000000000000000n);
      expect(await pool.virtual_price()).to.be.equal(1001226700479424662n);
      expect(await pool.D()).to.be.equal(729740251698351883505844n);

      await pool.connect(alice).add_liquidity([0n, 3n * BTC_PRECISION, 0n], 0n);

      expect(await lpCoin.totalSupply()).to.be.equal(693824797696987945622n);

      expect(await pool.balances(0n)).to.be.equal(440000000000n);
      expect(await pool.balances(1n)).to.be.equal(7535024703268191759n);
      expect(await pool.balances(2n)).to.be.equal(100000000000000000000n);

      expect(await pool.last_prices(0)).to.be.equal(74162751893595805161471n);
      expect(await pool.last_prices(1)).to.be.equal(4332316479302974128020n);

      expect(await pool.price_scale(0)).to.be.equal(47500000000000000000000n);
      expect(await pool.price_scale(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.price_oracle(0)).to.be.equal(47500561820481143760623n);
      expect(await pool.price_oracle(1)).to.be.equal(1500003262571039149783n);

      expect(await pool.xcp_profit()).to.be.equal(1001529230755982137n);
      expect(await pool.xcp_profit_a()).to.be.equal(1000000000000000000n);
      expect(await pool.virtual_price()).to.be.equal(1001529230755982137n);
      expect(await pool.D()).to.be.equal(864230636705116526806970n);
    });

    it('mints the correct lp coin amount after swaps with a time delay', async function () {
      const { pool, alice, bob, lpCoin } = await loadFixture(
        deploy3PoolFixture
      );

      await pool
        .connect(alice)
        .add_liquidity(
          [150_000n * USDC_PRECISION, 3n * BTC_PRECISION, 100n * ETH_PRECISION],
          0n
        );

      // Nuke the pool in one direction
      await pool.connect(bob).exchange(0, 1, 20_000n * USDC_PRECISION, 0);
      await time.increase(20);
      await mine();

      await pool.connect(bob).exchange(0, 1, 20_000n * USDC_PRECISION, 0);
      await time.increase(20);
      await mine();

      await pool.connect(bob).exchange(0, 1, 20_000n * USDC_PRECISION, 0);
      await time.increase(20);
      await mine();

      await pool.connect(bob).exchange(0, 1, 20_000n * USDC_PRECISION, 0);
      await time.increase(20);
      await mine();

      await pool.connect(bob).exchange(0, 1, 20_000n * USDC_PRECISION, 0);
      await time.increase(20);
      await mine();

      await pool.connect(bob).exchange(0, 1, 20_000n * USDC_PRECISION, 0);
      await time.increase(20);
      await mine();

      await pool.connect(bob).exchange(0, 1, 20_000n * USDC_PRECISION, 0);
      await time.increase(20);
      await mine();

      await pool.connect(alice).add_liquidity([0, 3n * BTC_PRECISION, 0], 0n);

      expect(await pool.balances(0n)).to.be.equal(290000000000n);
      expect(await pool.balances(1n)).to.be.equal(4535024703268191759n);
      expect(await pool.balances(2n)).to.be.equal(100000000000000000000n);

      expect(await pool.last_prices(0)).to.be.equal(81184196219695362378793n);
      expect(await pool.last_prices(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.price_scale(0)).to.be.equal(47500000000000000000000n);
      expect(await pool.price_scale(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.price_oracle(0)).to.be.equal(47511163087024737258827n);
      expect(await pool.price_oracle(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.xcp_profit()).to.be.equal(1001400555958757938n);
      expect(await pool.xcp_profit_a()).to.be.equal(1000000000000000000n);
      expect(await pool.virtual_price()).to.be.equal(1001400555958757938n);
      expect(await pool.D()).to.be.equal(634242617991253887928774n);

      await time.increase(20);
      await mine();

      await pool.connect(alice).add_liquidity([0, 0, 55n * ETH_PRECISION], 0n);

      expect(await pool.balances(0n)).to.be.equal(290000000000n);
      expect(await pool.balances(1n)).to.be.equal(4535024703268191759n);
      expect(await pool.balances(2n)).to.be.equal(155000000000000000000n);

      expect(await pool.last_prices(0)).to.be.equal(81184196219695362378793n);
      expect(await pool.last_prices(1)).to.be.equal(2598919272026284123336n);

      expect(await pool.price_scale(0)).to.be.equal(47500000000000000000000n);
      expect(await pool.price_scale(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.price_oracle(0)).to.be.equal(47512018667447449046418n);
      expect(await pool.price_oracle(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.xcp_profit()).to.be.equal(1001600639367002693n);
      expect(await pool.xcp_profit_a()).to.be.equal(1000000000000000000n);
      expect(await pool.virtual_price()).to.be.equal(1001600639367002693n);
      expect(await pool.D()).to.be.equal(733139234906431020032474n);
    });
  });

  // We did this one by mistake
  describe('Swap', () => {
    it('do extreme usdc swaps', async function () {
      const { pool, alice, lpCoin } = await loadFixture(deploy3PoolFixture);

      await pool
        .connect(alice)
        .add_liquidity(
          [150_000n * USDC_PRECISION, 3n * BTC_PRECISION, 100n * ETH_PRECISION],
          0n
        );

      // Nuke the pool in one direction
      await pool.connect(alice).exchange(0, 1, 40_000n * USDC_PRECISION, 0);
      await time.increase(20);
      await mine();

      // Nuke the pool in one direction
      await pool.connect(alice).exchange(0, 1, 40_000n * USDC_PRECISION, 0);
      await time.increase(20);
      await mine();

      // Nuke the pool in one direction
      await pool.connect(alice).exchange(0, 1, 40_000n * USDC_PRECISION, 0);
      await time.increase(20);
      await mine();

      // Nuke the pool in one direction
      await pool.connect(alice).exchange(0, 1, 40_000n * USDC_PRECISION, 0);
      await time.increase(20);
      await mine();

      // Nuke the pool in one direction
      await pool.connect(alice).exchange(0, 1, 40_000n * USDC_PRECISION, 0);
      await time.increase(20);
      await mine();

      expect(await pool.balances(0n)).to.be.equal(350000000000n);
      expect(await pool.balances(1n)).to.be.equal(1269800855063115831n);
      expect(await pool.balances(2n)).to.be.equal(100000000000000000000n);

      expect(await pool.last_prices(0)).to.be.equal(241613396579540753549299n);
      expect(await pool.last_prices(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.price_scale(0)).to.be.equal(47500000000000000000000n);
      expect(await pool.price_scale(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.price_oracle(0)).to.be.equal(47507425267449372140237n);
      expect(await pool.price_oracle(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.xcp_profit()).to.be.equal(1001184991174582564n);
      expect(await pool.xcp_profit_a()).to.be.equal(1000000000000000000n);
      expect(await pool.virtual_price()).to.be.equal(1001184991174582564n);
      expect(await pool.D()).to.be.equal(443010486250003678766705n);
    });

    it('do extreme btc swaps', async function () {
      const { pool, alice, lpCoin } = await loadFixture(deploy3PoolFixture);

      await pool
        .connect(alice)
        .add_liquidity(
          [150_000n * USDC_PRECISION, 3n * BTC_PRECISION, 100n * ETH_PRECISION],
          0n
        );

      // Nuke the pool in one direction
      await pool.connect(alice).exchange(1, 2, (5n * BTC_PRECISION) / 10n, 0);
      await time.increase(20);
      await mine();

      // Nuke the pool in one direction
      await pool.connect(alice).exchange(1, 2, (5n * BTC_PRECISION) / 10n, 0);
      await time.increase(20);
      await mine();

      // Nuke the pool in one direction
      await pool.connect(alice).exchange(1, 2, (5n * BTC_PRECISION) / 10n, 0);
      await time.increase(20);
      await mine();

      // Nuke the pool in one direction
      await pool.connect(alice).exchange(1, 2, (5n * BTC_PRECISION) / 10n, 0);
      await time.increase(20);
      await mine();

      // Nuke the pool in one direction
      await pool.connect(alice).exchange(1, 2, (5n * BTC_PRECISION) / 10n, 0);
      await time.increase(20);
      await mine();

      expect(await pool.balances(0n)).to.be.equal(150000000000n);
      expect(await pool.balances(1n)).to.be.equal(5500000000000000000n);
      expect(await pool.balances(2n)).to.be.equal(54027773845506102414n);

      expect(await pool.last_prices(0)).to.be.equal(47500000000000000000000n);
      expect(await pool.last_prices(1)).to.be.equal(4343512371979121649547n);

      expect(await pool.price_scale(0)).to.be.equal(47500000000000000000000n);
      expect(await pool.price_scale(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.price_oracle(0)).to.be.equal(47500000000000000000000n);
      expect(await pool.price_oracle(1)).to.be.equal(1500106516255014532491n);

      expect(await pool.xcp_profit()).to.be.equal(1000751898359023368n);
      expect(await pool.xcp_profit_a()).to.be.equal(1000000000000000000n);
      expect(await pool.virtual_price()).to.be.equal(1000751898359023368n);
      expect(await pool.D()).to.be.equal(442818848680020564855580n);
    });

    it('do extreme eth swaps', async function () {
      const { pool, alice, lpCoin } = await loadFixture(deploy3PoolFixture);

      await pool
        .connect(alice)
        .add_liquidity(
          [150_000n * USDC_PRECISION, 3n * BTC_PRECISION, 100n * ETH_PRECISION],
          0n
        );

      // Nuke the pool in one direction
      await pool.connect(alice).exchange(2, 0, 40n * ETH_PRECISION, 0);
      await time.increase(21);
      await mine();

      // Nuke the pool in one direction
      await pool.connect(alice).exchange(2, 0, 40n * ETH_PRECISION, 0);
      await time.increase(21);
      await mine();

      // Nuke the pool in one direction
      await pool.connect(alice).exchange(2, 0, 40n * ETH_PRECISION, 0);
      await time.increase(21);
      await mine();

      // Nuke the pool in one direction
      await pool.connect(alice).exchange(2, 0, 40n * ETH_PRECISION, 0);
      await time.increase(21);
      await mine();

      // Nuke the pool in one direction
      await pool.connect(alice).exchange(2, 0, 40n * ETH_PRECISION, 0);
      await time.increase(21);
      await mine();

      expect(await pool.balances(0n)).to.be.equal(49285237353n);
      expect(await pool.balances(1n)).to.be.equal(3000000000000000000n);
      expect(await pool.balances(2n)).to.be.equal(300000000000000000000n);

      expect(await pool.last_prices(0)).to.be.equal(47500000000000000000000n);
      expect(await pool.last_prices(1)).to.be.equal(191456323300000000000n);

      expect(await pool.price_scale(0)).to.be.equal(47500000000000000000000n);
      expect(await pool.price_scale(1)).to.be.equal(1500000000000000000000n);

      expect(await pool.price_oracle(0)).to.be.equal(47500000000000000000000n);
      expect(await pool.price_oracle(1)).to.be.equal(1499902420003103587512n);

      expect(await pool.xcp_profit()).to.be.equal(1001616388226721678n);
      expect(await pool.xcp_profit_a()).to.be.equal(1000000000000000000n);
      expect(await pool.virtual_price()).to.be.equal(1001616388226721678n);
      expect(await pool.D()).to.be.equal(443201373468169778504920n);
    });

    it.skip('do 1000 swing swaps', async function () {
      const { pool, alice, lpCoin } = await loadFixture(deploy3PoolFixture);

      await pool
        .connect(alice)
        .add_liquidity(
          [150_000n * USDC_PRECISION, 3n * BTC_PRECISION, 100n * ETH_PRECISION],
          0n
        );

      const arr = Array(1000)
        .fill(0)
        .map((_, index) => index);

      for await (const _ of arr) {
        // Nuke the pool in one direction
        await pool.connect(alice).exchange(2, 0, 75n * ETH_PRECISION, 0);

        // Nuke the pool in one direction
        await pool.connect(alice).exchange(1, 2, 2n * BTC_PRECISION, 0);

        // Nuke the pool in one direction
        await pool.connect(alice).exchange(0, 1, 100_000n * USDC_PRECISION, 0);

        // Nuke the pool in one direction
        await pool
          .connect(alice)
          .exchange(1, 2, 15n * (BTC_PRECISION / 10n), 0);
        await time.increase(20);
        await mine();
      }

      await pool.claim_admin_fees();

      expect(await lpCoin.totalSupply()).to.be.equal(385241469606775583374n);

      expect(await pool.balances(0n)).to.be.equal(150000000000n);
      expect(await pool.balances(1n)).to.be.equal(3000000000000000000n);
      expect(await pool.balances(2n)).to.be.equal(75100000000000000000000n);

      expect(await pool.last_prices(0)).to.be.equal(28680336310352529203817n);
      expect(await pool.last_prices(1)).to.be.equal(1339192935926189875722n);

      expect(await pool.price_scale(0)).to.be.equal(47020670825017530067032n);
      expect(await pool.price_scale(1)).to.be.equal(1495888697711251099772n);

      expect(await pool.price_oracle(0)).to.be.equal(46965479070309829523535n);
      expect(await pool.price_oracle(1)).to.be.equal(1495417295563756912037n);

      expect(await pool.xcp_profit()).to.be.equal(3599777285496751557n);
      expect(await pool.xcp_profit_a()).to.be.equal(3599777285496751557n);
      expect(await pool.virtual_price()).to.be.equal(8615714491009094114n);
      expect(await pool.D()).to.be.equal(4110313539653823619161751n);
    }).timeout(1000000);
  });
});
