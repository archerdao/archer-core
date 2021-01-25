// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IVotingPower {
    function balanceOf(address account) external view returns (uint256);
    function balanceOfAt(address account, uint256 blockNumber) external view returns (uint256);
}