import { loadFixture } from '@nomicfoundation/hardhat-toolbox-viem/network-helpers';
import { expect } from 'chai';
import hre from 'hardhat';

describe('BTC', function () {
  async function deployBTCFixture() {
    const [owner, otherAccount] = await hre.viem.getWalletClients();

    const btc = await hre.viem.deployContract('BTC');

    const publicClient = await hre.viem.getPublicClient();

    return {
      btc,
      owner,
      otherAccount,
      publicClient,
    };
  }

  describe('Deployment', function () {
    it('Has the correct metadata', async function () {
      const { btc } = await loadFixture(deployBTCFixture);
      expect(await btc.read.decimals()).to.equal(18);
      expect(await btc.read.name()).to.equal('Bitcoin');
      expect(await btc.read.symbol()).to.equal('BTC');
    });
  });
});
