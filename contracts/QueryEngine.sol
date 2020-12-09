// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./interfaces/IERC20.sol";
import "./lib/SafeMath.sol";
import "./lib/BytesLib.sol";
import "./lib/CalldataEditor.sol";
import "./lib/SafeERC20.sol";
import "./lib/AccessControl.sol";

contract QueryEngine is AccessControl, CalldataEditor {
    // Allows easy manipulation on bytes
    using BytesLib for bytes;

    /// @notice Calls the price function specified by data at contractAddress, returning the price as bytes
    /// @param contractAddress contract to query
    /// @param data the bytecode for the contract call
    /// @return price in bytes
    function getPrice(address contractAddress, bytes memory data) public view returns (bytes memory) {
        (bool success, bytes memory returnData) = contractAddress.staticcall(data);
        require(success, "Could not fetch price");
        return returnData.slice(0, 32);
    }

    /// @notice Makes a series of queries at once, returning all the prices as bytes
    /// @param script the compiled bytecode for the series of function calls to get the final price
    /// @param inputLocations index locations within the script to insert input amounts dynamically
    /// @return all prices as bytes
    function queryAllPrices(bytes memory script, uint256[] memory inputLocations) public view returns (bytes memory) {
        uint256 location = 0;
        bytes memory prices;
        bytes memory lastPrice;
        bytes memory callData;
        uint256 inputsLength = inputLocations.length;
        uint256 inputsIndex = 0;
        while (location < script.length) {
            address contractAddress = addressAt(script, location);
            uint256 calldataLength = uint256At(script, location + 0x14);
            uint256 calldataStart = location + 0x14 + 0x20;
            if (location != 0 && inputsLength > inputsIndex) {
                uint256 insertLocation = inputLocations[inputsIndex];
                replaceDataAt(script, lastPrice, insertLocation);
                inputsIndex++;
            }
            callData = script.slice(calldataStart, calldataLength);
            lastPrice = getPrice(contractAddress, callData);
            prices = prices.concat(lastPrice);
            location += (0x14 + 0x20 + calldataLength);
        }
        return prices;
    }

    /// @notice Makes a series of queries at once, returning the final price as a uint
    /// @param script the compiled bytecode for the series of function calls to get the final price
    /// @param inputLocations index locations within the script to insert input amounts dynamically
    /// @return last price as uint
    function query(bytes memory script, uint256[] memory inputLocations) public view returns (uint256) {
        uint256 location = 0;
        bytes memory lastPrice;
        bytes memory callData;
        uint256 inputsLength = inputLocations.length;
        uint256 inputsIndex = 0;
        while (location < script.length) {
            address contractAddress = addressAt(script, location);
            uint256 calldataLength = uint256At(script, location + 0x14);
            uint256 calldataStart = location + 0x14 + 0x20;
            if (location != 0 && inputsLength > inputsIndex) {
                uint256 insertLocation = inputLocations[inputsIndex];
                replaceDataAt(script, lastPrice, insertLocation);
                inputsIndex++;
            }
            callData = script.slice(calldataStart, calldataLength);
            lastPrice = getPrice(contractAddress, callData);
            location += (0x14 + 0x20 + calldataLength);
        }
        return lastPrice.toUint256(0);
    }
}