const { expect } = require('chai');
const { deployProxy } = require('@openzeppelin/truffle-upgrades');
const WanderTokenPol = artifacts.require('./WanderTokenPol.sol');
const Request = artifacts.require('./Request.sol');

require('chai')
    .use(require('chai-as-promised'))
    .should()

contract('Wander Token', (accounts) => {
    
    beforeEach(async function() {
        /*  
         *  @dev To conduct the test, make sure that the param of admins[] of the contract's deployment 
         *  in the migration file is also given the [accounts[0],accounts[1],accounts[2],accounts[3]] 
         *  addresses as its input. To check the value of accounts, simply enter truffle develop into
         *  your terminal.
         */
        this.wanderTokenPol = await deployProxy(WanderTokenPol, [[accounts[0],accounts[1],accounts[2],accounts[3]],3], 
            {initializer: 'initialize'});
    })

    it('retrieve the initial variable of number of requests', async function () {
        // Test if the returned value is the same one
        // Note that we need to use strings to compare the 256 bit integers
        expect((await this.wanderTokenPol.getTotalRequests()).toString()).to.equal('0');
    });

    it('does account 0 has an administrator role', async function () {
        expect(await this.wanderTokenPol.hasRole("0x00", accounts[0])).to.equal(true);
    });

    it('revoke confirmation request', async function () {
        await this.wanderTokenPol.submitRequest(accounts[1], web3.utils.toBN("100000000000000000000000000"), 1, {from: accounts[0]});
        let txId = await this.wanderTokenPol.getTotalRequests();
        txId = txId-1;
        await this.wanderTokenPol.confirmRequest(txId, {from: accounts[3]});
        await this.wanderTokenPol.confirmRequest(txId, {from: accounts[1]});
        await this.wanderTokenPol.revokeConfirmRequest(txId, {from: accounts[1]});
        await this.wanderTokenPol.revokeConfirmRequest(txId, {from: accounts[3]});
        // Should fail
        await this.wanderTokenPol.executeRequest(txId, {from: accounts[1]});
    });

    // Testing if the submission request to delete an existing admin worked properly.
    it('submit request delete admin', async function () {
        await this.wanderTokenPol.submitRequest(accounts[1], web3.utils.toBN("100000000000000000000000000"), 1, {from: accounts[0]});
        let txId = await this.wanderTokenPol.getTotalRequests();
        txId = txId-1;
        await this.wanderTokenPol.confirmRequest(txId, {from: accounts[1]});
        await this.wanderTokenPol.confirmRequest(txId, {from: accounts[3]});
        await this.wanderTokenPol.executeRequest(txId, {from: accounts[1]});

        // Checking if the removed administrator still has the admin role
        expect(await this.wanderTokenPol.hasRole("0x00", accounts[1])).to.equal(false);
    });
    
    // Testing if the submission request to add a new admin worked properly.
    it('submit request add admin', async function () {
        await this.wanderTokenPol.submitRequest(accounts[1], web3.utils.toBN("100000000000000000000000000"), 1, {from: accounts[0]});
        let txId = await this.wanderTokenPol.getTotalRequests();
        txId = txId-1;
        await this.wanderTokenPol.confirmRequest(txId, {from: accounts[1]});
        await this.wanderTokenPol.confirmRequest(txId, {from: accounts[3]});
        await this.wanderTokenPol.executeRequest(txId, {from: accounts[1]});

        await this.wanderTokenPol.submitRequest(accounts[1], 0, 0);
        txId = await this.wanderTokenPol.getTotalRequests();
        txId = txId-1;
        await this.wanderTokenPol.confirmRequest(txId, {from: accounts[2]});
        await this.wanderTokenPol.confirmRequest(txId, {from: accounts[3]});
        await this.wanderTokenPol.executeRequest(txId);

        // Chacking if the new address was granted the admin role
        expect(await this.wanderTokenPol.hasRole("0x00", accounts[1])).to.equal(true);
    });

    /*
    * Testing if transferring more than the token threshold worked properly using
    * the submit request function.
    */
    it('submit request transfer equal or more than threshold', async function () {
        await this.wanderTokenPol.submitRequest(accounts[1], web3.utils.toBN("100000000000000000000000000"), 2);
        expect((await this.wanderTokenPol.getTotalRequests()).toString()).to.equal('1');
    });

    /*
    * Testing if minting more than the token threshold worked properly using
    * the submit request function.
    */
    it('submit Request mint equal or more than threshold', async function () {
        await this.wanderTokenPol.submitRequest(accounts[0], web3.utils.toBN("100000000000000000000000000"), 3);
        expect((await this.wanderTokenPol.getTotalRequests()).toString()).to.equal('1');
    });

    /*
    * Testing if transferring less than the token threshold does not work properly
    * using the submit request function (Does not pass the modifier).
    */
    it('submit request transfer smaller than threshold', async function () {
        // Should fail
        await this.wanderTokenPol.submitRequest(accounts[1], 100, 2);
        expect(await this.wanderTokenPol.getTotalRequests().toString()).to.equal('1');
    });

    /*
    * Testing if minting less than the token threshold does not work properly
    * using the submit request function (Does not pass the modifier).
    */
    it('submit Request mint smaller than threshold', async function () {
        // Should fail
        await this.wanderTokenPol.submitRequest(accounts[0], 100, 3);
        expect(await this.wanderTokenPol.getTotalRequests().toString()).to.equal('1');
    });

    /*
    * Testing if minting less than the token threshold worked properly using
    * the regular ERC-20 mint function.
    */
    it('mint smaller than threshold', async function () {
        await this.wanderTokenPol.mint(accounts[0], 100);
        await this.wanderTokenPol.balanceOf.call(accounts[0]).then(function(result){
            let tokenBalance = result.toString();
            expect(tokenBalance).to.equal('100');
        })
    });

    /*
    * Testing if transferring less than the token threshold does not work properly
    * using the regular ERC-20 transfer function (Does not pass the modifier).
    */
    it('transfer smaller than threshold', async function () {
        await this.wanderTokenPol.mint(accounts[0], 100);
        await this.wanderTokenPol.transfer(accounts[1], 100);
        await this.wanderTokenPol.balanceOf.call(accounts[1]).then(function(result){
            let tokenBalance = result.toString();
            expect(tokenBalance).to.equal('100');
        })
    })

    /*
    * Testing if minting less than the token threshold does not work properly
    * using the regular ERC-20 mint function (Does not pass the modifier).
    */
    it('mint equal or more than threshold', async function () {
        // Should fail
        await this.wanderTokenPol.mint(accounts[0], web3.utils.toBN("100000000000000000000000000"));
        await this.wanderTokenPol.balanceOf.call(accounts[0]).then(function(result){
            let tokenBalance = result.toString();
            expect(tokenBalance).to.equal('100000000000000000000000000');
        })
    })

    it('transfer equal or more than threshold', async function () {
        await this.wanderTokenPol.submitRequest(accounts[0], web3.utils.toBN("100000000000000000000000000"), 3);
        let txId = await this.wanderTokenPol.getTotalRequests();
        txId = txId-1;
        await this.wanderTokenPol.confirmRequest(txId, {from: accounts[1]});
        await this.wanderTokenPol.confirmRequest(txId, {from: accounts[2]});
        await this.wanderTokenPol.executeRequest(txId);
            // Should fail
        await this.wanderTokenPol.transfer(accounts[1], web3.utils.toBN("100000000000000000000000000"));
        await this.wanderTokenPol.balanceOf.call(accounts[1]).then(function(result){
            let tokenBalance = result.toString();
            expect(tokenBalance).to.equal('100000000000000000000000000');
        })
    })

    /*
    * Testing that submitting a request beyond the limit of the request 
    * pool should not work. 
    */
    it('exceeds Request pool', async function () {
        // Should fail
        await this.wanderTokenPol.submitRequest(accounts[1], web3.utils.toBN("100000000000000000000000000"), 3);
        await this.wanderTokenPol.submitRequest(accounts[0], web3.utils.toBN("200000000000000000000000000"), 3);
        await this.wanderTokenPol.submitRequest(accounts[2], web3.utils.toBN("300000000000000000000000000"), 3);
        await this.wanderTokenPol.submitRequest(accounts[1], web3.utils.toBN("400000000000000000000000000"), 3);
        await this.wanderTokenPol.submitRequest(accounts[1], web3.utils.toBN("600000000000000000000000000"), 3);
        await this.wanderTokenPol.submitRequest(accounts[0], web3.utils.toBN("600000000000000000000000000"), 3);
        await this.wanderTokenPol.submitRequest(accounts[1], web3.utils.toBN("100000000000000000000000000"), 3);
        await this.wanderTokenPol.submitRequest(accounts[1], web3.utils.toBN("100000000000000000000000000"), 3);
        await this.wanderTokenPol.submitRequest(accounts[1], web3.utils.toBN("100000000000000000000000000"), 3);
        await this.wanderTokenPol.submitRequest(accounts[1], web3.utils.toBN("100000000000000000000000000"), 3);
        await this.wanderTokenPol.submitRequest(accounts[1], web3.utils.toBN("100000000000000000000000000"), 3);
    })

    /*
    * Testing that submitting a request to clear the request pool (even if
    * the request pool is at its limit) should be working properly. 
    */
    it('clear request pool', async function () {
        await this.wanderTokenPol.submitRequest(accounts[1], web3.utils.toBN("100000000000000000000000000"), 3);
        await this.wanderTokenPol.submitRequest(accounts[0], web3.utils.toBN("200000000000000000000000000"), 3);
        await this.wanderTokenPol.submitRequest(accounts[2], web3.utils.toBN("300000000000000000000000000"), 3);
        await this.wanderTokenPol.submitRequest(accounts[1], web3.utils.toBN("400000000000000000000000000"), 3);
        await this.wanderTokenPol.submitRequest(accounts[1], web3.utils.toBN("600000000000000000000000000"), 3);
        await this.wanderTokenPol.submitRequest(accounts[0], web3.utils.toBN("600000000000000000000000000"), 3);
        await this.wanderTokenPol.submitRequest(accounts[1], web3.utils.toBN("100000000000000000000000000"), 3);
        await this.wanderTokenPol.submitRequest(accounts[1], web3.utils.toBN("100000000000000000000000000"), 3);
        await this.wanderTokenPol.submitRequest(accounts[1], web3.utils.toBN("100000000000000000000000000"), 3);
        await this.wanderTokenPol.submitRequest(accounts[1], web3.utils.toBN("100000000000000000000000000"), 3);
        await this.wanderTokenPol.submitRequest(accounts[0], 0, 6);
        let txId = await this.wanderTokenPol.getTotalRequests();
        txId = txId-1;
        await this.wanderTokenPol.confirmRequest(txId, {from: accounts[1]});
        await this.wanderTokenPol.confirmRequest(txId, {from: accounts[2]});
        await this.wanderTokenPol.executeRequest(txId, {from: accounts[1]});

        expect((await this.wanderTokenPol.getTotalRequests()).toString()).to.equal('0');
    })

    /*
    * Testing that submitting and confirming a request after the 
    * request pool is cleared should be working properly. 
    */
    it('confirm a request after request pool is cleared', async function () {
        await this.wanderTokenPol.submitRequest(accounts[0], web3.utils.toBN("100000000000000000000000000"), 3);
        await this.wanderTokenPol.confirmRequest(0, {from : accounts[1]});
        await this.wanderTokenPol.confirmRequest(0, {from: accounts[2]});

        expect((await this.wanderTokenPol.getTotalRequests()).toString()).to.equal('1');
    })
})
