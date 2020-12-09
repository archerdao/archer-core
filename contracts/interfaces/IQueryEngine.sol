// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IQueryEngine {
    function getPrice(address contractAddress, bytes memory data) external view returns (bytes memory);
    function queryAllPrices(bytes memory script, uint256[] memory inputLocations) external view returns (bytes memory);
    function query(bytes memory script, uint256[] memory inputLocations) external view returns (uint256);
}