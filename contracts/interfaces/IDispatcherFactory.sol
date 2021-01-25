// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IDispatcherFactory {
    function version() external view returns (uint8);
    function dispatchers() external view returns (address[] memory);
    function exists(address dispatcher) external view returns (bool);
    function numDispatchers() external view returns (uint256);
    function createNewDispatcher(address queryEngine, address roleManager, address lpManager, address withdrawer, address trader, address supplier, uint256 initialMaxLiquidity, address[] memory lpWhitelist) external returns (address);
    function addDispatchers(address[] memory dispatcherContracts) external;
    function removeDispatcher(address dispatcherContract) external;
    function DISPATCHER_ADMIN_ROLE() external view returns (bytes32);
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
    event DispatcherCreated(address indexed dispatcher, uint8 indexed version, address queryEngine, address roleManager, address lpManager, address withdrawer, address trader, address supplier, uint256 initialMaxLiquidity, bool lpWhitelist);
    event DispatcherAdded(address indexed dispatcher);
    event DispatcherRemoved(address indexed dispatcher);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
}