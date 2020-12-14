// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./lib/AccessControl.sol";
import "./Dispatcher.sol";

contract DispatcherFactory is AccessControl {
    /// @notice Admin role to create new Dispatchers
    bytes32 public constant DISPATCHER_ADMIN_ROLE = keccak256("DISPATCHER_ADMIN_ROLE");

    /// @notice Create new Dispatcher event
    event DispatcherCreated(
        address indexed dispatcher, 
        address queryEngine,
        address roleManager,
        address lpManager,
        address withdrawer,
        address trader,
        uint256 initialMaxLiquidity,
        bool lpWhitelist
    );

    /// @notice modifier to restrict createNewDispatcher function
    modifier onlyCreator() {
        require(hasRole(DISPATCHER_ADMIN_ROLE, msg.sender), "Caller must have DISPATCHER_ADMIN role");
        _;
    }

    /// @notice Initializes contract, setting admin
    /// @param _roleAdmin admin in control of roles
    /// @param _dispatcherAdmin admin that can create new Dispatchers
    constructor(
        address _roleAdmin,
        address _dispatcherAdmin
    ) {
        _setupRole(DISPATCHER_ADMIN_ROLE, _dispatcherAdmin);
        _setupRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
    }

    /// @notice Create new Dispatcher contract
    /// @param _queryEngine Address of query engine contract
    /// @param _roleManager Address allowed to manage contract roles
    /// @param _lpManager Address allowed to manage LP whitelist
    /// @param _withdrawer Address allowed to withdraw profit from contract
    /// @param _trader Address allowed to make trades via this contract
    /// @param _initialMaxLiquidity Initial max liquidity allowed in contract
    /// @param _lpWhitelist list of addresses that are allowed to provide liquidity to this contract
    function createNewDispatcher(
        address _queryEngine,
        address _roleManager,
        address _lpManager,
        address _withdrawer,
        address _trader,
        uint256 _initialMaxLiquidity,
        address[] memory _lpWhitelist
    ) external onlyCreator returns (
        address dispatcher
    ) {
        Dispatcher newDispatcher = new Dispatcher(
            _queryEngine,
            _roleManager,
            _lpManager,
            _withdrawer,
            _trader,
            _initialMaxLiquidity,
            _lpWhitelist
        );

        dispatcher = address(newDispatcher);

        emit DispatcherCreated(
            dispatcher,
            _queryEngine,
            _roleManager,
            _lpManager,
            _withdrawer,
            _trader,
            _initialMaxLiquidity,
            _lpWhitelist.length > 0 ? true : false
        );
    }
}