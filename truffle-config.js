require('babel-register');
require('babel-polyfill');

require("dotenv").config();
const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  networks: {
    ethTestnet: {
      provider: () => new HDWalletProvider([process.env.PRIVATE_KEYS1], "wss://rinkeby.infura.io/ws/v3/"+process.env.INFURA_PROJECT_ETHEREUM_ID, 0, 1),
      network_id: 4, //rinkeby
      skipDryRun: true
    },
    bscTestnet: {
      provider: () => new HDWalletProvider([process.env.PRIVATE_KEYS1], "https://data-seed-prebsc-1-s1.binance.org:8545", 0, 1),
      network_id: 97,
      skipDryRun: true
    },
    maticTestnet: {
      provider: () => new HDWalletProvider([process.env.PRIVATE_KEYS1], "https://polygon-mumbai.infura.io/v3/"+process.env.INFURA_PROJECT_POLYGON_ID, 0, 1),
      network_id: 80001,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 7545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
    },
  },
  contracts_directory: './src/contracts/',
  contracts_build_directory: './src/abis/',
  compilers: {
    solc: {
      version: "0.8.2",    // Fetch exact version from solc-bin (default: truffle's version)
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    // Etherscan API key made by using personal account
    etherscan: process.env.ETHERSCAN_API_KEY,
    polygonscan: ''
  }
}
