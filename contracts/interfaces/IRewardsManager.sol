// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

struct Pool {
    uint256 pid;
    bool active;
}

struct UserInfo {
        uint256 amount;
        uint256 rewardTokenDebt;
        uint256 sushiRewardDebt;
    }

interface IRewardsManager {
    function deposit(uint256 pid, uint256 amount) external;
    function depositWithPermit(uint256 pid, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function depositOnBehalfOf(address depositor, uint256 pid, uint256 amount) external;
    function withdraw(uint256 pid, uint256 amount) external;
    function withdrawOnBehalfOf(address withdrawer, uint256 pid, uint256 amount) external;
    function emergencyWithdraw(uint256 pid) external;
    function rewardToken() external view returns (IERC20);
    function tokenPools(address token) external view returns (Pool memory);
    function userInfo(uint256 pid, address user) external view returns (UserInfo memory);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

}