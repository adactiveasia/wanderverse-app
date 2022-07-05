// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract WanderTokenPol is Initializable, ERC20PresetMinterPauserUpgradeable {
    // Initializing the maximum supply of 1 billion to Wander token 
    uint256 private MAXSUPPLY;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    Request[] public requests;
    address[] public admins;
    uint public numConfirmationsRequired;

     // Events emitted after the execution a request 
    event SubmitRequest(address indexed owner, uint indexed txIndex, address indexed to, uint value, uint method);
    event ExecuteRequest(address indexed owner, uint indexed txIndex, uint method);

    // Required variables
    struct Request{
        address from;
        address to;
        uint value;
        uint method;
        bool executed;
        address[] confirmedAddress;
        uint numConfirmations;
    }

    function _onlyAdmin() private view {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "not admin");
    }
    
    function _reqExistsAndNotExecuted(uint _reqIndex) private view {
        require(_reqIndex < requests.length, "request does not exist");
        require(!requests[_reqIndex].executed, "request is executed");
    }

    function _fullyConfirmed(uint _reqIndex) private view {
        require(requests[_reqIndex].numConfirmations >= numConfirmationsRequired, "lack the required num of confirmations");
    }

    // Required Modifiers and Involving Function Acting as Modifiers
    function callerConfirmed(uint _reqIndex) public view virtual returns(uint){
        _onlyAdmin();
        uint index = 100;   // Error counter, if it returns 100, then the address has not confirmed
        for (uint i; i< requests[_reqIndex].confirmedAddress.length;i++){
          if (requests[_reqIndex].confirmedAddress[i] == msg.sender){
              index = i;
              break;
          }
        }
        return index;   // Return the index of the caller's address in the requests' array of confirm addresses
    }

    // // Replacement to Constructor
    function initialize(address[] memory _admins, uint _numConfirmationsRequired) public initializer {
        __ERC20_init("WANDER", "pWANDER");
        MAXSUPPLY = 1000000000 * 10 ** 18;
        require(_admins.length > 0, "more than 1 owner is required");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _admins.length, "invalid number of confirmations");
        for (uint i = 0; i < _admins.length; i++){
            require(_admins[i] != address(0), "owner can't be the 0 address");
            require(!hasRole(DEFAULT_ADMIN_ROLE, _admins[i]), "address has administrator role");

            _setupRole(DEFAULT_ADMIN_ROLE, _admins[i]);
            _setupRole(MINTER_ROLE, _admins[i]);
            _setupRole(PAUSER_ROLE, _admins[i]);
            admins.push(_admins[i]);
        }
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    function mint(address to, uint256 amount) public override virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        require(ERC20Upgradeable.totalSupply() + amount <= MAXSUPPLY, "ERC20Capped: cap exceeded");
        require(amount < 1000000 * 10 ** 18, "Use the submit transaction function");
        _mint(to, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(!(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && amount >= 1000000 * 10 * 18), "Use the submit transaction function");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

     // Required Getter Methods
    function getTotalRequests() public view virtual returns (uint256) {
        _onlyAdmin();
        return requests.length;
    }
    function requestDetails(uint256 _reqIndex) public view virtual returns (address, address, uint, uint, uint, bool) {
        _onlyAdmin();
        return(requests[_reqIndex].from,
        requests[_reqIndex].to,
        requests[_reqIndex].value, 
        requests[_reqIndex].method, 
        requests[_reqIndex].numConfirmations, 
        requests[_reqIndex].executed);
    }

    // Functions involved in the execution process of request
    function submitRequest(address _to, uint _value, uint _method) public {
        _onlyAdmin();
        require(!(_value < 1000000 * 10 * 18 && ((_method == 2) || (_method == 3))), "use the regular mint or transfer method");
        require((requests.length < 10 || _method == 6), "clear the pool before submitting a new one");
        Request storage newRequest = requests.push();
        newRequest.from = msg.sender; 
        newRequest.to = _to; 
        newRequest.value = _value;
        newRequest.method = _method;
        newRequest.executed = false;
        newRequest.confirmedAddress.push(msg.sender);
        newRequest.numConfirmations = 1;
        emit SubmitRequest(msg.sender, requests.length, _to, _value, _method);
    }
    function confirmRequest(uint _reqIndex) public {
        _onlyAdmin();
        _reqExistsAndNotExecuted(_reqIndex);
        require((callerConfirmed(_reqIndex) == 100), "req is confirmed");
        requests[_reqIndex].confirmedAddress.push(msg.sender);
        requests[_reqIndex].numConfirmations += 1;
    }
    function revokeConfirmRequest(uint _reqIndex) public {
        _onlyAdmin();
        _reqExistsAndNotExecuted(_reqIndex);
        uint index = callerConfirmed(_reqIndex);
        require((index != 100), "req not confirmed");
        Request storage request = requests[_reqIndex];
        request.confirmedAddress[index] = request.confirmedAddress[request.confirmedAddress.length-1];
        request.confirmedAddress.pop();
        request.numConfirmations -= 1;
    }
    function executeRequest(uint _reqIndex) public virtual {
        _onlyAdmin();
        _reqExistsAndNotExecuted(_reqIndex);
        _fullyConfirmed(_reqIndex);
        Request storage request = requests[_reqIndex];
        if (request.method == 0) {
            require(!hasRole(DEFAULT_ADMIN_ROLE, request.to), "address has administrator role");
            admins.push(request.to);
            _setupRole(DEFAULT_ADMIN_ROLE, request.to);
            _setupRole(MINTER_ROLE, request.to);
            _setupRole(PAUSER_ROLE, request.to);
        }
        if (request.method == 1) {
            require(admins.length >= numConfirmationsRequired, "minimum of number of admins are not met");
            for (uint i = 0; i <= admins.length; i++){
                if (admins[i] == request.to){
                    admins[i] = admins[admins.length-1];
                    admins.pop();
                    break;
                }
            }
            _revokeRole(DEFAULT_ADMIN_ROLE, request.to);
            _revokeRole(MINTER_ROLE, request.to);
            _revokeRole(PAUSER_ROLE, request.to);
        }
        if (request.method == 2) {
            _transfer(request.from, request.to, request.value);
        }
        if (request.method == 3) {
            _mint(request.to,request.value);
        }
        if (request.method == 4) {
            _pause();
        }
        if (request.method == 5) {
            _unpause();
        }
        request.executed = true;
        emit ExecuteRequest(msg.sender, _reqIndex, request.method);
        if (request.method == 6) {
            delete requests;  
        }
    }
    
}
