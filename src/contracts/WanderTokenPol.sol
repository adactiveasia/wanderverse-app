// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.12 < 0.9.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Wanderverse's ERC20Upgradable ($WANDER) token
 * @author Adactive Asia
 * @dev The ERC20 token is upgradable by the use of OpenZeppelin's proxy smart
 * contract. It is also incorporated with a multi-signature function for crucial
 * administrator functions. 
 */
contract WanderTokenPol is Initializable, ERC20PresetMinterPauserUpgradeable {
    /**
     * @dev placement of variable ordering is crucial and should not be tampered.
     * When new variables are needed in the next implementation contract, place 
     * them below the current existing variables. 
     */
    uint256 private constant MAXSUPPLY = 1000000000*10**18;
    uint256 private constant MAXADMINS = 10;
    uint256 private constant MAXREQUESTS = 10;
    uint256 private constant THRESHOLD = 1000000*10**18;
    /**
     * @dev used as an error encounter to find the caller's confirmation's 
     * index within a request's array of confirmations.
     */
    uint256 private constant ERRORCOUNTERCALLERCONFIRM = 100;
    /**
     * @dev index used to identify which of the admin functions that the
     * request wishes to execute.
     */
    uint256 private constant METHOD_ID_ADD_ADMIN = 0;
    uint256 private constant METHOD_ID_REMOVE_ADMIN = 1;
    uint256 private constant METHOD_ID_TRANSFER_EQU_MORE_THRES = 2;
    uint256 private constant METHOD_ID_MINT = 3;
    uint256 private constant METHOD_ID_PAUSE = 4;
    uint256 private constant METHOD_ID_UNPAUSE = 5;
    uint256 private constant METHOD_ID_CLEAR_POOL = 6;
    uint256 private numConfirmsRequired;
    Request[] public requests;
    address[] public admins;

    /// Event emitted after the submission of a request.
    event SubmitRequest(
        address indexed owner, 
        uint indexed txIndex, 
        address indexed to, 
        uint value, 
        uint method
    );

    // Event emitted after the execution of a request. 
    event ExecuteRequest(
        address indexed owner,
        uint indexed txIndex, 
        uint method
    );

    /// Structure used to store all of the request's information 
    struct Request {
        address from;
        address to;
        uint value;
        uint method;
        bool executed;
        address[] confirmedAddress;
        uint numConfirmations;
    }

    /**
     * @dev Used as a replacement of constructor based on the
     * requirements for upgradable smart contract.
     */
    function initialize(
        address[] memory _admins, 
        uint _numConfirmsRequired
    )
        public initializer 
    {
        /// Input the required parameters for general ERC20 tokens
        __ERC20_init("Wanderverse Token", "WANDER");
        require(
            _admins.length > 0 && 
            _admins.length <= MAXADMINS,
            "# of addresses should be > 0 and <= than 10"
        );
        require(
            _numConfirmsRequired > 0 && 
            _numConfirmsRequired <= _admins.length, 
            "invalid number of confirmations"
        );
        /**
         * @dev make sure there are no address(0) present and all address 
         * should be unique in the array of addresses given as the parameter.
         */
        for (uint i = 0; i < _admins.length; i++) {
            require(
                _admins[i] != address(0), 
                "owner can't be the 0 address"
            );
            require(
                !hasRole(DEFAULT_ADMIN_ROLE, _admins[i]),
                "duplicate address in _admins parameter"
            );
            _grantRole(DEFAULT_ADMIN_ROLE, _admins[i]);
            _grantRole(MINTER_ROLE, _admins[i]);
            _grantRole(PAUSER_ROLE, _admins[i]);
            admins.push(_admins[i]);
        }
        numConfirmsRequired = _numConfirmsRequired;
    }

    /**
     * @dev if the administrator wishes to transfer equal or more 
     * than 1,000,000 $WANDER tokens owned by the administrator in
     * a single transaction, the admin needs to submit a request. 
     * If the administrator wishes to transfer less than 
     * 1,000,000 $WANDER tokens, he/she can simply use the regular
     * transfer function.
     * Non-administrator users can use this function freely without 
     * any restrictions.
     */
    function transfer(address recipient, uint256 amount) 
        public 
        virtual 
        override
        returns (bool) 
    {
        require(
            !(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) && 
            amount >= THRESHOLD), 
            "Use the submit request function"
        );
        _transfer(_msgSender(), recipient, amount);
        return true;    
    }

    /**
     * @dev used to submit the ability to execute crucial administrator functions 
     * that requires multi-signature approvals before being able to execute.
     * To be able to execute these functions, an admin has to submit a request
     * and the request needs the approval of other admins as many as the minimum
     * number of confirmations.
     *
     * @param _to is the address of the function (Please enter any real address 
     * for method value: 4, 5, 6)
     * @param _value the value involving in the function (Please enter any +
     * integers for method value: 0, 1, 4, 5, 6)
     * @param _method the method/function's index number to be executed. Each 
     * of these crucial functions is assigned with its own index number, which 
     * goes by the following: 
     * - 0: Add a new admin
     * - 1: Remove an existing admin
     * - 2: Transfer a quantity of $WANDER tokens owned by an administrator 
            greater or equal than the given threshold (1,000,000 $WANDER) to a 
            given recipient address within a single transaction
     * - 3: Minting any quantity of $WANDER tokens to a given address
     * - 4: Pausing the smart contract (state should be unpaused)
     * - 5: Unpausing the smart contract (state should be paused)
     * - 6: Clearing the request pool
     * Please enter the appropriate index number according to the desired 
     * administrator function to be executed.
     */
    function submitRequest(
        address _to, 
        uint _value, 
        uint _method
    ) 
        public 
    {
        _onlyAdmin();
        /**
         * @dev There can only be a maximum of 10 requests in the request
         * pool. The submission of additional request (OTHER THAN the
         * request to clear the request pool) will not be allowed until the
         * request pool has some empty space.
         */
        require(
            (requests.length < MAXREQUESTS || _method == METHOD_ID_CLEAR_POOL), 
            "clear the pool before submitting a new one"
        );
        /**
         * @dev Admins should be entering a value only between 0 to 6 in
         * method's parameter, as there are no methods with an index less
         * than 0 nor greater than 6.
         */
        require(
            (_method >= METHOD_ID_ADD_ADMIN && _method <= METHOD_ID_CLEAR_POOL),
            "invalid method index entered"
        );
        /**
         * @dev If the administrator wishes to mint more tokens that will
         * exceed the maximum total supply of $WANDER token, revert the
         * execution and return the administrator with an error.
         */
        if (
            (_method == METHOD_ID_MINT) && 
            ((ERC20Upgradeable.totalSupply() + _value) > MAXSUPPLY)
        ) {
            revert("ERC20Capped: cap exceeded");
        } else if (
            (_method == METHOD_ID_TRANSFER_EQU_MORE_THRES) && 
            (_value < THRESHOLD)
        ) {
            /**
             * @dev notify the admin to use the regular transfer function
             * if he/she wishes to transfer less than 1,000,000 $WANDER tokens.
             */
            revert("use the regular transfer method");
        } else {
            Request storage newRequest = requests.push();
            /// Creates a new structure to store all the request's info
            newRequest.from = _msgSender(); 
            newRequest.to = _to; 
            newRequest.value = _value;
            newRequest.method = _method;
            newRequest.executed = false;
            newRequest.confirmedAddress.push(_msgSender());
            /// @dev adds the requester's confirmation into the request
            newRequest.numConfirmations = 1;
            emit SubmitRequest(msg.sender, requests.length, _to, _value, _method);
        }
    }

    /**
     * @dev allows admin to confirm a request. The caller of the
     * function should be an admin and has not yet confirm the request.
     * 
     * @param _reqIndex the index of the request to be confirmed.
     */
    function confirmRequest(uint _reqIndex) public {
        _onlyAdmin();
        _reqExistsAndNotExecuted(_reqIndex);
        require(
            (callerConfirmed(_reqIndex) == ERRORCOUNTERCALLERCONFIRM), 
            "req is confirmed"
        );
        requests[_reqIndex].confirmedAddress.push(_msgSender());
        requests[_reqIndex].numConfirmations += 1;
    }

    /**
     * @dev allows admin to revoke his/her confirmation of a request. 
     * The caller of the function should be an admin and has given a
     * confirmation to the request.
     * 
     * @param _reqIndex the index of the request that will receive a 
     * revoke on its confirmation.
     */
    function revokeConfirmRequest(uint _reqIndex) public {
        _onlyAdmin();
        _reqExistsAndNotExecuted(_reqIndex);
        uint confirmIndex = callerConfirmed(_reqIndex);
        require((confirmIndex != ERRORCOUNTERCALLERCONFIRM), "req not confirmed");
        Request storage request = requests[_reqIndex];
        uint reqConfAddSize = requests[_reqIndex].confirmedAddress.length;
        request.confirmedAddress[confirmIndex] = request.confirmedAddress[reqConfAddSize-1];
        request.confirmedAddress.pop();
        request.numConfirmations -= 1;
    }

    /**
     * @dev allows any admin to execute the administrator function
     * inside of a request, given that the request has met its minimum
     * number of confirmations requirement.
     * 
     * @param _reqIndex the index of the request to be executed.
     */
    function executeRequest(uint _reqIndex) public virtual {
        _onlyAdmin();
        _reqExistsAndNotExecuted(_reqIndex);
        _fullyConfirmed(_reqIndex);
        Request storage request = requests[_reqIndex];
        if (request.method == METHOD_ID_ADD_ADMIN) {
            /// Prohibits the number of admins to exceed the maximum 
            /// number of admins
            require(
                admins.length + 1 <= MAXADMINS, 
                "maximum # of admins is reached"
            );
            /// The address to be added should not have any admin role
            require(
                !hasRole(DEFAULT_ADMIN_ROLE, request.to), 
                "recipient address has administrator role"
            );
            admins.push(request.to);
            _grantRole(DEFAULT_ADMIN_ROLE, request.to);
            _grantRole(MINTER_ROLE, request.to);
            _grantRole(PAUSER_ROLE, request.to);
        }
        if (request.method == METHOD_ID_REMOVE_ADMIN) {
            /// Prohibits the number of admins to fall behind the minimum 
            /// number of confirmations
            require(
                admins.length - 1 >= numConfirmsRequired, 
                "minimum # of admins is not met"
            );
            /// The admin address to be removed should have an admin role
            require(
                hasRole(DEFAULT_ADMIN_ROLE, request.to), 
                "recipient address is not an admin"
            );
            /// Removing the address from the admins array
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
        if (request.method == METHOD_ID_TRANSFER_EQU_MORE_THRES) {
            _transfer(request.from, request.to, request.value);
        }
        if (request.method == METHOD_ID_MINT) {
            _mint(request.to, request.value);
        }
        if (request.method == METHOD_ID_PAUSE) {
            _pause();
        }
        if (request.method == METHOD_ID_UNPAUSE) {
            _unpause();
        }
        /// Indicate that the request has been executed
        request.executed = true;
        emit ExecuteRequest(msg.sender, _reqIndex, request.method);
        if (request.method == METHOD_ID_CLEAR_POOL) {
            delete requests;  
        }
    }

    /**
     * @dev overriding AccessControlUpgradable's grantRole function.
     * Depreciating the function, which forces administrator to go through
     * the request procedure to execute the same intended function.
     */
    function grantRole(
        bytes32 role, 
        address account
    ) 
        public 
        virtual 
        override(AccessControlUpgradeable, IAccessControlUpgradeable) 
        onlyRole(getRoleAdmin(role)) 
    {
        _revertError();
    }

    /**
     * @dev overriding ERC20PresetMinterPauserUpgradable's pause function.
     * Depreciating the function, which forces administrator to go through
     * the request procedure to execute the same intended function.
     */
    function pause() public virtual override {
        _revertError();
    }

    /**
     * @dev overriding ERC20PresetMinterPauserUpgradable's unpause function.
     * Depreciating the function, which forces administrator to go through
     * the request procedure to execute the same intended function.
     */
    function unpause() public virtual override {
         _revertError();
    }

    /**
     * @dev overriding ERC20PresetMinterPauserUpgradable's mint function.
     * Depreciating the function, which forces administrator to go through
     * the request procedure to execute the same intended function.
     */
    function mint(address to, uint256 amount) public virtual override {
         _revertError();
    }

    /**
     * @dev finds the index of the admin's confirmation in a request
     */
    function callerConfirmed(uint _reqIndex) public virtual view returns (uint){
        _onlyAdmin();
        // Error counter, if index returns 100, then the address has not confirmed
        uint index = ERRORCOUNTERCALLERCONFIRM;  
        for (uint i = 0; i < requests[_reqIndex].confirmedAddress.length; i++){
          if (requests[_reqIndex].confirmedAddress[i] == _msgSender()){
              index = i;
              break;
          }
        }
        // Return the index of the caller's address in the request's 
        // array of confirmed addresses
        return index;
    }

    function getTotalRequests() public virtual view returns (uint256) {
        _onlyAdmin();
        return requests.length;
    }

    function requestDetails(
        uint256 _reqIndex
    ) 
        public 
        view 
        virtual 
        returns (
            address, 
            address, 
            uint, 
            uint, 
            uint, 
            bool
        ) 
    {
        _onlyAdmin();

        return(
            requests[_reqIndex].from,
            requests[_reqIndex].to,
            requests[_reqIndex].value, 
            requests[_reqIndex].method, 
            requests[_reqIndex].numConfirmations, 
            requests[_reqIndex].executed
        );
    }

    /**
     * @dev Return the version of $WANDER token's 
     * implementation smart contract.
     */
    function version() public virtual pure returns (string memory) {
        return "1.0.0";
    }

    /**
     * @dev function acting as a modifier, which checks whether if
     * the address is an administrator
     */
    function _onlyAdmin() private view {
        require((hasRole(DEFAULT_ADMIN_ROLE, _msgSender())), "caller is not admin");
    }
    
    /**
     * @dev function acting as a modifier, which checks whether if
     * the request exists and it is not yet executed
     */
    function _reqExistsAndNotExecuted(uint _reqIndex) private view {
        require(
            _reqIndex < requests.length &&
            !requests[_reqIndex].executed, 
            "request either does not exist or has been executed"
        );
    }

    /**
     * @dev function acting as a modifier, which checks whether if
     * the request's confirmation has met or exceed the min. 
     * required number of confirmation.
     */
    function _fullyConfirmed(uint _reqIndex) private view {
        require(
            requests[_reqIndex].numConfirmations >= numConfirmsRequired, 
            "lack the required num of confirmations"
        );
    }

    /**
     * @dev function that returns a revert error, notifying the user that
     * the function, which has this _revertError() function, is depreciated.
     */
    function _revertError() private pure {
        revert("Function depreciated");
    }
}