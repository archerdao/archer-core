// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./IQueryEngine.sol";

interface IDispatcher {
    function version() external view returns (uint8);
    function lpBalances(address) external view returns (uint256);
    function totalLiquidity() external view returns (uint256);
    function MAX_LIQUIDITY() external view returns (uint256);
    function tokenAllowAll(address[] memory tokensToApprove, address spender) external;
    function tokenAllow(address[] memory tokensToApprove, uint256[] memory approvalAmounts, address spender) external;
    function rescueTokens(address[] calldata tokens, uint256 amount) external;
    function setMaxETHLiquidity(uint256 newMax) external;
    function provideETHLiquidity() external payable;
    function removeETHLiquidity(uint256 amount) external;
    function withdrawEth(uint256 amount) external;
    function estimateQueryCost(bytes memory script, uint256[] memory inputLocations) external;
    function queryEngine() external view returns (IQueryEngine);
    function isTrader(address addressToCheck) external view returns (bool);
    function makeTrade(bytes memory executeScript, uint256 ethValue) external;
    function makeTrade(bytes memory executeScript, uint256 ethValue, uint256 blockDeadline) external;
    function makeTrade(bytes memory executeScript, uint256 ethValue, uint256 minTimestamp, uint256 maxTimestamp) external;
    function makeTrade(bytes memory queryScript, uint256[] memory queryInputLocations, bytes memory executeScript, uint256[] memory executeInputLocations, uint256 targetPrice, uint256 ethValue) external;
    function makeTrade(bytes memory queryScript, uint256[] memory queryInputLocations, bytes memory executeScript, uint256[] memory executeInputLocations, uint256 targetPrice, uint256 ethValue, uint256 blockDeadline) external;
    function makeTrade(bytes memory queryScript, uint256[] memory queryInputLocations, bytes memory executeScript, uint256[] memory executeInputLocations, uint256 targetPrice, uint256 ethValue, uint256 minTimestamp, uint256 maxTimestamp) external;
    function TRADER_ROLE() external view returns (bytes32);
    function MANAGE_LP_ROLE() external view returns (bytes32);
    function WHITELISTED_LP_ROLE() external view returns (bytes32);
    function APPROVER_ROLE() external view returns (bytes32);
    function WITHDRAW_ROLE() external view returns (bytes32);
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    function isApprover(address addressToCheck) external view returns(bool);
    function isWithdrawer(address addressToCheck) external view returns(bool);
    function isLPManager(address addressToCheck) external view returns(bool);
    function isWhitelistedLP(address addressToCheck) external view returns(bool);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
    event MaxLiquidityUpdated(address indexed asset, uint256 indexed newAmount, uint256 oldAmount);
    event LiquidityProvided(address indexed asset, address indexed provider, uint256 amount);
    event LiquidityRemoved(address indexed asset, address indexed provider, uint256 amount);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
}