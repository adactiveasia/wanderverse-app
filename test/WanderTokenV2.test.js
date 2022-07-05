const { expect } = require('chai');
const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const WanderTokenPol = artifacts.require('./WanderTokenPol.sol');
const WanderTokenPolV2 = artifacts.require('./WanderTokenPolV2.sol');

require('chai')
    .use(require('chai-as-promised'))
    .should()

contract('Wander Token V2', (accounts) => {
    
    beforeEach(async function() {
        /*  
         *  @dev To conduct the test, make sure that the param of admins[] of the contract's deployment 
         *  in the migration file is also given the [accounts[0],accounts[1],accounts[2],accounts[3]] 
         *  addresses as its input. To check the value of accounts, simply enter truffle develop into
         *  your terminal.
         */
        this.wanderTokenPol = await deployProxy(WanderTokenPol, [[accounts[0],accounts[1],accounts[2],accounts[3]],3], 
            {initializer: 'initialize'});
        this.wanderTokenPolV2 = await upgradeProxy(this.wanderTokenPol.address, WanderTokenPolV2);
        
    })

    it('does it have 4 addresses with administrator role', async function () {
        expect((await this.wanderTokenPolV2.getTotalAdmins()).toString()).to.equal("4");
    });
})
