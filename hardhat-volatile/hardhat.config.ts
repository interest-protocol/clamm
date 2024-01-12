import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import '@nomicfoundation/hardhat-toolbox-viem';
import '@nomiclabs/hardhat-vyper';

const config: HardhatUserConfig = {
  solidity: '0.8.23',
  vyper: {
    version: '0.3.7',
  },
};

export default config;
