<br/>
<div align="center">
  <img src="public/walk-logo-color.png" width="200"></img>
</div>
<h1 align="center">Wander Token</h1>
<h4 align="center">The native token used in Wanderverse mobile application system</h4>
<div align="center">
  <img src="https://img.shields.io/badge/npm-v8.5.5-orange"></img>
  <img src="https://img.shields.io/badge/solidity-0.8.0-blue"></img>
  <img src="https://img.shields.io/badge/passed%20tests-18-brightgreen"></img>
</div>
<br/>
<div align="center">
  <img src="public/gitHub_images/Screenshot_Walk_1.png" width="170"></img>
  <img src="public/gitHub_images/Screenshot_Walk_2.png" width="170"></img>
  <img src="public/gitHub_images/Screenshot_Walk_3.png" width="170"></img>
  <img src="public/gitHub_images/Screenshot_Walk_4.png" width="170"></img>
</div>

## Token technical overview
Wanderverse will utilize the infamous Polygon (MATIC) blockchain to create the $WANDER token.

The token is to also incorporate OpenZeppelin's Upgradable ERC20 features, allowing the smart contract and essentialy the $WANDER token to be upgradable. This is done as a precaution towards any potential bugs/cyber attacks that can cause harm to the existing smart contract. Upgrading the token will only be done in emergency measures.

## Smart contract code overview
The nature of $WANDER token's smart contract is imported from existing templates (OpenZeppelin's ERC20UpgradablePresetMinterPauser and Initializable).

## Packages required to be installed
To run the code, users are required to install couple of packages. The list of packages to be downloaded (and the process of how to install) goes by the following:
- npm (enter "npm install" in your terminal)
- truffle (enter "npm install truffle" in your terminal)
- @openzeppelin (enter "npm install @openzeppelin/contracts" in your terminal)
- hdwallet-provider: Used to deploy/migrate the smart contract into the blockchain. Not compulsary for truffle testing sake (enter "npm install @truffle/hdwallet-provider in your terminal)
- chai: Used for truffle testing (enter "npm install chai")
- chai-as-promised: Used for truffle testing (enter "npm install chai-as-promised"