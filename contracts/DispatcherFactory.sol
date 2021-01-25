// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./lib/AccessControl.sol";
import "./Dispatcher.sol";

/**
 * @title DispatcherFactory
 * @dev Creates and keeps track of Dispatchers on the network
 */
contract DispatcherFactory is AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Version number of Dispatcher Factory
    uint8 public version = 2;

    /// @notice Admin role to create new Dispatchers
    bytes32 public constant DISPATCHER_ADMIN_ROLE = keccak256("DISPATCHER_ADMIN_ROLE");

    /// @dev Record of all Dispatchers
    EnumerableSet.AddressSet private dispatchersSet;

    /// @notice Create new Dispatcher event
    event DispatcherCreated(
        address indexed dispatcher,
        uint8 indexed version, 
        address queryEngine,
        address roleManager,
        address lpManager,
        address withdrawer,
        address trader,
        address supplier,
        uint256 initialMaxLiquidity,
        bool lpWhitelist
    );

    /// @notice Add existing Dispatcher event
    event DispatcherAdded(address indexed dispatcher);

    /// @notice Remove existing Dispatcher event
    event DispatcherRemoved(address indexed dispatcher);

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
    /// @param supplier Address allowed to supply opportunities to contract
    /// @param initialMaxLiquidity Initial max liquidity allowed in contract
    /// @param lpWhitelist List of addresses that are allowed to provide liquidity to this contract
    /// @return dispatcher Address of new Dispatcher contract
    function createNewDispatcher(
        address queryEngine,
        address roleManager,
        address lpManager,
        address withdrawer,
        address trader,
        address supplier,
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
            supplier,
            initialMaxLiquidity,
            lpWhitelist
        );

        dispatcher = address(newDispatcher);
        dispatchersSet.add(dispatcher);

        emit DispatcherCreated(
            dispatcher,
            version,
            queryEngine,
            roleManager,
            lpManager,
            withdrawer,
            trader,
            supplier,
            initialMaxLiquidity,
            lpWhitelist.length > 0 ? true : false
        );
    }

    /**
     * @notice Admin function to allow addition of dispatchers created via other Dispatcher Factories
     * @param dispatcherContracts Array of dispatcher contract addresses
     */
    function addDispatchers(address[] memory dispatcherContracts) external onlyAdmin {
        for(uint i = 0; i < dispatcherContracts.length; i++) {
            dispatchersSet.add(dispatcherContracts[i]);
            emit DispatcherAdded(dispatcherContracts[i]);
        }
    }

    /**
     * @notice Admin function to allow removal of dispatchers from Dispatcher set
     * @param dispatcherContracts Dispatcher contract addresses
     */
    function removeDispatchers(address[] memory dispatcherContracts) external onlyAdmin {
        for(uint i = 0; i < dispatcherContracts.length; i++) {
            dispatchersSet.remove(dispatcherContracts[i]);
            emit DispatcherRemoved(dispatcherContracts[i]);
        }
    }

    /**
     * @notice Return list of Dispatcher contracts this factory indexes
     * @return Array of Dispatcher addresses
     */
    function dispatchers() external view returns (address[] memory) {
        uint256 dispatchersLength = dispatchersSet.length();
        address[] memory dispatchersArray = new address[](dispatchersLength);
        for(uint i = 0; i < dispatchersLength; i++) {
            dispatchersArray[i] = dispatchersSet.at(i);
        }
        return dispatchersArray;
    }

    /**
     * @notice Determine whether this factory is indexing a Dispatcher at the provided address
     * @param dispatcherContract Dispatcher address
     * @return true if Dispatcher is indexed 
     */
    function exists(address dispatcherContract) external view returns (bool) {
        return dispatchersSet.contains(dispatcherContract);
    }

    /**
     * @notice Returns the number of Dispatchers indexed by this factory
     * @return number of Dispatchers indexed 
     */
    function numDispatchers() external view returns (uint256) {
        return dispatchersSet.length();
    }
}