const { assert } = require('chai');
const WanderTokenPolV2 = artifacts.require('./WanderTokenPolV2.sol');

require('chai')
    .use(require('chai-as-promised'))
    .should()

contract('Wander Token V2 Creation', (accounts) => {
    let contract;
    
    before(async() => {
        /*  
         *  @dev To conduct the test, make sure that the param of admins[] of the contract's deployment 
         *  in the migration file is also given the [accounts[0],accounts[1],accounts[2],accounts[3]] 
         *  addresses as its input. To check the value of accounts, simply enter truffle develop into
         *  your terminal.
         */
        contract = await WanderTokenPolV2.deployed([accounts[0],accounts[1],accounts[2],accounts[3]],3, {from: accounts[0]})
    })

    describe('deployment', async() => {
        // Testing if the smart contract is successfully deployed.
        it('deploys successfully', async () => {
            const address = contract.address
            console.log(address);
            console.log(accounts[0]);
            console.log(accounts[1]);
            console.log(accounts[2]);
            console.log(accounts[3]);
            assert.notEqual(address, 0x0)
            assert.notEqual(address, '')
            assert.notEqual(address, null)
            assert.notEqual(address, undefined)
          })

        // Testing if the smart contract has a token name.
        it('has a name', async () => {
            const name = await contract.name()
            assert.equal(name, 'Wander ETH Token')
        })

        // Testing if the smart contract has a token symbol.
        it('has a symbol', async () => {
            const symbol = await contract.symbol()
            assert.equal(symbol, 'eWander')
        })

        // Testing if the deployer of the contract has adminstrator role.
        it('has role', async () => {
            const hasRole = await contract.hasRole("0x00", accounts[0])
            assert.equal(hasRole, true);
        })

        // Testing if the revoke confirmation request worked properly.
        it('revoke confirmation request', async () => {
            await contract.submitRequest(accounts[1], web3.utils.toBN("100000000000000000000000000"), 1, {from: accounts[0]});
            let txId = await contract.getTotalRequests();
            txId = txId-1;
            await contract.confirmRequest(txId, {from: accounts[3]});
            await contract.confirmRequest(txId, {from: accounts[1]});
            await contract.revokeConfirmRequest(txId, {from: accounts[1]});
            await contract.revokeConfirmRequest(txId, {from: accounts[3]});
            // Should fail
            await contract.executeRequest(txId, {from: accounts[1]});
        })
        
        // Testing if the submission request to delete an existing admin worked properly.
        it('submit request delete admin', async () => {
            let txId = await contract.getTotalRequests();
            txId = txId-1;
            await contract.confirmRequest(txId, {from: accounts[1]});
            await contract.confirmRequest(txId, {from: accounts[3]});
            await contract.executeRequest(txId, {from: accounts[1]});

            // Checking if the removed administrator still has the admin role
            const hasRole = await contract.hasRole("0x00", accounts[1]);
            assert.equal(hasRole, false);
        })

        // Testing if the submission request to add a new admin worked properly.
        it('submit request add admin', async () => {
            await contract.submitRequest(accounts[1], 0, 0);
            let txId = await contract.getTotalRequests();
            txId = txId-1;
            await contract.confirmRequest(txId, {from: accounts[2]});
            await contract.confirmRequest(txId, {from: accounts[3]});
            await contract.executeRequest(txId);

            // Chacking if the new address was granted the admin role
            const result = await contract.hasRole("0x00", accounts[1])
            assert.equal(result, true);
        })

        /*
         * Testing if transferring more than the token threshold worked properly using
         * the submit request function.
         */
        it('submit request transfer equal or more than threshold', async () => {
            await contract.submitRequest(accounts[1], web3.utils.toBN("100000000000000000000000000"), 2);
        })

         /*
         * Testing if minting more than the token threshold worked properly using
         * the submit request function.
         */
        it('submit Request mint equal or more than threshold', async () => {
            await contract.submitRequest(accounts[0], web3.utils.toBN("100000000000000000000000000"), 3);
        })

        /*
         * Testing if transferring less than the token threshold does not work properly
         * using the submit request function (Does not pass the modifier).
         */
        it('submit request transfer smaller than threshold', async () => {
            // Should fail
            await contract.submitRequest(accounts[1], 100, 2);
        })

        /*
         * Testing if minting less than the token threshold does not work properly
         * using the submit request function (Does not pass the modifier).
         */
        it('submit Request mint smaller than threshold', async () => {
            // Should fail
            await contract.submitRequest(accounts[0], 100, 3);
        })

        /*
         * Testing if minting less than the token threshold worked properly using
         * the regular ERC-20 mint function.
         */
        it('mint smaller than threshold', async () => {
            await contract.mint(accounts[0], 100);
        })
        
        /*
         * Testing if transferring less than the token threshold does not work properly
         * using the regular ERC-20 transfer function (Does not pass the modifier).
         */
        it('transfer smaller than threshold', async () => {
            await contract.mint(accounts[0], 100);
            await contract.transfer(accounts[1], 100);
        })

        /*
         * Testing if minting less than the token threshold does not work properly
         * using the regular ERC-20 mint function (Does not pass the modifier).
         */
        it('mint equal or more than threshold', async () => {
            // Should fail
            await contract.mint(accounts[0], web3.utils.toBN("100000000000000000000000000"));
        })

        it('transfer equal or more than threshold', async () => {
            await contract.submitRequest(accounts[0], web3.utils.toBN("100000000000000000000000000"), 3);
            let txId = await contract.getTotalRequests();
            txId = txId-1;
            await contract.confirmRequest(txId, {from: accounts[1]});
            await contract.confirmRequest(txId, {from: accounts[2]});
            await contract.executeRequest(txId);
             // Should fail
            await contract.transfer(accounts[1], web3.utils.toBN("100000000000000000000000000"));
        })

        /*
         * Testing that submitting a request beyond the limit of the request 
         * pool should not work. 
         */
        it('exceeds Request pool', async() => {
            // Should fail
            await contract.submitRequest(accounts[1], web3.utils.toBN("100000000000000000000000000"), 3);
            await contract.submitRequest(accounts[0], web3.utils.toBN("200000000000000000000000000"), 3);
            await contract.submitRequest(accounts[2], web3.utils.toBN("300000000000000000000000000"), 3);
            await contract.submitRequest(accounts[1], web3.utils.toBN("400000000000000000000000000"), 3);
            await contract.submitRequest(accounts[1], web3.utils.toBN("600000000000000000000000000"), 3);
            await contract.submitRequest(accounts[0], web3.utils.toBN("600000000000000000000000000"), 3);
        })

        /*
         * Testing that submitting a request to clear the request pool (even if
         * the request pool is at its limit) should be working properly. 
         */
        it('clear request pool', async() => {
            await contract.submitRequest(accounts[0], 0, 6);
            let txId = await contract.getTotalRequests();
            txId = txId-1;
            await contract.confirmRequest(txId, {from: accounts[1]});
            await contract.confirmRequest(txId, {from: accounts[2]});
            await contract.executeRequest(txId, {from: accounts[1]});

            let requestInPool = await contract.getTotalRequests();
            assert.equal(requestInPool, 0);
        })

        /*
         * Testing that submitting and confirming a request after the 
         * request pool is cleared should be working properly. 
         */
        it('confirm a request after request pool is cleared', async() => {
            await contract.submitRequest(accounts[0], web3.utils.toBN("100000000000000000000000000"), 3);
            await contract.confirmRequest(0, {from : accounts[1]});
            await contract.confirmRequest(0, {from: accounts[2]});
        })
    })
})
