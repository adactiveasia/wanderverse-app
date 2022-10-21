require('babel-register');
require('babel-polyfill');

require("dotenv").config();
const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  networks: {
    rinkebyTestnet: {
      provider: () => new HDWalletProvider(
        [process.env.PRIVATE_KEY1], 
        PROJECT_RINKEBY_API_URL_KEY, 
        0, 
        1
      ),
      network_id: 4, //rinkeby
      skipDryRun: true
    },
    bscTestnet: {
      provider: () => new HDWalletProvider(
        [process.env.PRIVATE_KEY1], 
        "https://data-seed-prebsc-1-s1.binance.org:8545", 
        0, 
        1
      ),
      network_id: 97,
      skipDryRun: true
    },
    maticTestnet: {
      provider: () => new HDWalletProvider(
        [process.env.PRIVATE_KEY1], 
        process.env.PROJECT_MUMBAI_API_URL_KEY,
        0, 
        1
      ),
      network_id: 80001,
      confirmations: 2,
      timeoutBlocks: 20000,
      gasPrice: 40000000000,
      networkCheckTimeout: 1000000,
      skipDryRun: true
    },
    matic: {
      provider: () => new HDWalletProvider(
        [process.env.PRIVATE_KEY1], 
        process.env.PROJECT_POLYGON_API_URL_KEY,
        0, 
        1
      ),
      network_id: 80001,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 9545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
    },
  },
  contracts_directory: './src/contracts/',
  contracts_build_directory: './src/abis/',
  compilers: {
    solc: {
      version: "0.8.16",    // Fetch exact version from solc-bin (default: truffle's version)
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  plugins: [
    'truffle-plugin-verify',
    'truffle-contract-size',
    'solidity-coverage'
  ],
  api_keys: {
    etherscan: process.env.ETHERSCAN_API_KEY,
    polygonscan: process.env.POLYGONSCAN_API_KEY
  }
}
