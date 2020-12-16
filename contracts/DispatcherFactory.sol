// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./lib/AccessControl.sol";
import "./Dispatcher.sol";

contract DispatcherFactory is AccessControl {
    /// @notice Version number of Dispatcher Factory
    uint8 public version = 1;

    /// @notice Admin role to create new Dispatchers
    bytes32 public constant DISPATCHER_ADMIN_ROLE = keccak256("DISPATCHER_ADMIN_ROLE");

    /// @notice Create new Dispatcher event
    event DispatcherCreated(
        address indexed dispatcher,
        uint8 indexed version, 
        address queryEngine,
        address roleManager,
        address lpManager,
        address withdrawer,
        address trader,
        address approver,
        uint256 initialMaxLiquidity,
        bool lpWhitelist
    );

    /// @notice modifier to restrict createNewDispatcher function
    modifier onlyAdmin() {
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
    /// @param queryEngine Address of query engine contract
    /// @param roleManager Address allowed to manage contract roles
    /// @param lpManager Address allowed to manage LP whitelist
    /// @param withdrawer Address allowed to withdraw profit from contract
    /// @param trader Address allowed to make trades via this contract
    /// @param approver Address allowed to make approvals on contract
    /// @param initialMaxLiquidity Initial max liquidity allowed in contract
    /// @param lpWhitelist list of addresses that are allowed to provide liquidity to this contract
    /// @return dispatcher Address of new Dispatcher contract
    function createNewDispatcher(
        address queryEngine,
        address roleManager,
        address lpManager,
        address withdrawer,
        address trader,
        address approver,
        uint256 initialMaxLiquidity,
        address[] memory lpWhitelist
    ) external onlyAdmin returns (
        address dispatcher
    ) {
        Dispatcher newDispatcher = new Dispatcher(
            version,
            queryEngine,
            roleManager,
            lpManager,
            withdrawer,
            trader,
            approver,
            initialMaxLiquidity,
            lpWhitelist
        );

        dispatcher = address(newDispatcher);

        emit DispatcherCreated(
            dispatcher,
            version,
            queryEngine,
            roleManager,
            lpManager,
            withdrawer,
            trader,
            approver,
            initialMaxLiquidity,
            lpWhitelist.length > 0 ? true : false
        );
    }
}