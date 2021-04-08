// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITimelockController {
    function TIMELOCK_ADMIN_ROLE() external view returns (bytes32);
    function PROPOSER_ROLE() external view returns (bytes32);
    function EXECUTOR_ROLE() external view returns (bytes32);
    function _DONE_TIMESTAMP() external view returns (uint256);
    receive() external payable;
    function isOperation(bytes32 id) external view returns (bool pending);
    function isOperationPending(bytes32 id) external view returns (bool pending);
    function isOperationReady(bytes32 id) external view returns (bool ready);
    function isOperationDone(bytes32 id) external view returns (bool done);
    function getTimestamp(bytes32 id) external view returns (uint256 timestamp);
    function getMinDelay() external view returns (uint256 duration);
    function hashOperation(address target, uint256 value, bytes calldata data, bytes32 predecessor, bytes32 salt) external pure returns (bytes32 hash);
    function hashOperationBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas, bytes32 predecessor, bytes32 salt) external pure returns (bytes32 hash);
    function schedule(address target, uint256 value, bytes calldata data, bytes32 predecessor, bytes32 salt, uint256 delay) external returns (bytes32 id);
    function scheduleBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas, bytes32 predecessor, bytes32 salt, uint256 delay) external returns (bytes32 id);
    function cancel(bytes32 id) external;
    function execute(address target, uint256 value, bytes calldata data, bytes32 predecessor, bytes32 salt) external payable;
    function executeBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas, bytes32 predecessor, bytes32 salt) external payable;
    function updateDelay(uint256 newDelay) external;
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
    event CallScheduled(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data, bytes32 predecessor, uint256 delay);
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);
    event Cancelled(bytes32 indexed id);
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
}