// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../interfaces/IQueryEngine.sol";

import "./BytesLib.sol";
import "./CalldataEditor.sol";

abstract contract Trader is CalldataEditor {
    using BytesLib for bytes;

    /// @notice Query contract
    IQueryEngine public queryEngine;

    /// @notice Makes a series of trades as single transaction if profitable without query
    /// @param executeScript the compiled bytecode for the series of function calls to execute the trade
    /// @param ethValue the amount of ETH to send with initial contract call
    function makeTrade(
        bytes memory executeScript,
        uint256 ethValue
    ) public {
        uint256 contractBalanceBefore = address(this).balance;
        require(contractBalanceBefore >= ethValue, "Not enough ETH in contract");
        execute(executeScript, ethValue);
        require(address(this).balance >= contractBalanceBefore, "missing ETH");
    }

    /// @notice Makes a series of trades as single transaction if profitable without query + block deadline
    /// @param executeScript the compiled bytecode for the series of function calls to execute the trade
    /// @param ethValue the amount of ETH to send with initial contract call
    /// @param blockDeadline block number when trade expires
    function makeTrade(
        bytes memory executeScript,
        uint256 ethValue,
        uint256 blockDeadline
    ) public {
        require(blockDeadline >= block.number, "trade expired");
        uint256 contractBalanceBefore = address(this).balance;
        require(contractBalanceBefore >= ethValue, "Not enough ETH in contract");
        execute(executeScript, ethValue);
        require(address(this).balance >= contractBalanceBefore, "missing ETH");
    }

    /// @notice Makes a series of trades as single transaction if profitable
    /// @param queryScript the compiled bytecode for the series of function calls to get the final price
    /// @param queryInputLocations index locations within the queryScript to insert input amounts dynamically
    /// @param executeScript the compiled bytecode for the series of function calls to execute the trade
    /// @param executeInputLocations index locations within the executeScript to insert input amounts dynamically
    /// @param targetPrice profit target for this trade, if ETH>ETH, this should be ethValue + gas estimate * gas price
    /// @param ethValue the amount of ETH to send with initial contract call
    function makeTrade(
        bytes memory queryScript,
        uint256[] memory queryInputLocations,
        bytes memory executeScript,
        uint256[] memory executeInputLocations,
        uint256 targetPrice,
        uint256 ethValue
    ) public {
        uint256 contractBalanceBefore = address(this).balance;
        require(contractBalanceBefore >= ethValue, "Not enough ETH in contract");
        bytes memory prices = queryEngine.queryAllPrices(queryScript, queryInputLocations);
        require(prices.toUint256(prices.length - 32) > targetPrice, "Not profitable");
        for(uint i = 0; i < executeInputLocations.length; i++) {
            replaceDataAt(executeScript, prices.slice(i*32, (i+1)*32), executeInputLocations[i]);
        }
        execute(executeScript, ethValue);
        require(address(this).balance >= contractBalanceBefore, "missing ETH");
    }

    /// @notice Makes a series of trades as single transaction if profitable
    /// @param queryScript the compiled bytecode for the series of function calls to get the final price
    /// @param queryInputLocations index locations within the queryScript to insert input amounts dynamically
    /// @param executeScript the compiled bytecode for the series of function calls to execute the trade
    /// @param executeInputLocations index locations within the executeScript to insert input amounts dynamically
    /// @param targetPrice profit target for this trade, if ETH>ETH, this should be ethValue + gas estimate * gas price
    /// @param ethValue the amount of ETH to send with initial contract call
    /// @param blockDeadline block number when trade expires
    function makeTrade(
        bytes memory queryScript,
        uint256[] memory queryInputLocations,
        bytes memory executeScript,
        uint256[] memory executeInputLocations,
        uint256 targetPrice,
        uint256 ethValue,
        uint256 blockDeadline
    ) public {
        require(blockDeadline >= block.number, "trade expired");
        uint256 contractBalanceBefore = address(this).balance;
        require(contractBalanceBefore >= ethValue, "Not enough ETH in contract");
        bytes memory prices = queryEngine.queryAllPrices(queryScript, queryInputLocations);
        require(prices.toUint256(prices.length - 32) > targetPrice, "Not profitable");
        for(uint i = 0; i < executeInputLocations.length; i++) {
            replaceDataAt(executeScript, prices.slice(i*32, (i+1)*32), executeInputLocations[i]);
        }
        execute(executeScript, ethValue);
        require(address(this).balance >= contractBalanceBefore, "missing ETH");
    }

    /// @notice Executes series of function calls as single transaction
    /// @param script the compiled bytecode for the series of function calls to invoke
    /// @param ethValue the amount of ETH to send with initial contract call
    function execute(bytes memory script, uint256 ethValue) internal {
        // sequentially call contract methods
        uint256 location = 0;
        while (location < script.length) {
            address contractAddress = addressAt(script, location);
            uint256 calldataLength = uint256At(script, location + 0x14);
            uint256 calldataStart = location + 0x14 + 0x20;
            bytes memory callData = script.slice(calldataStart, calldataLength);
            if(location == 0) {
                callMethod(contractAddress, callData, ethValue);
            }
            else {
                callMethod(contractAddress, callData, 0);
            }
            location += (0x14 + 0x20 + calldataLength);
        }
    }

    /// @notice Calls the supplied calldata using the supplied contract address
    /// @param contractToCall the contract to call
    /// @param data the call data to execute
    /// @param ethValue the amount of ETH to send with initial contract call
    function callMethod(address contractToCall, bytes memory data, uint256 ethValue) internal {
        bool success;
        bytes memory returnData;
        address payable contractAddress = payable(contractToCall);
        if(ethValue > 0) {
            (success, returnData) = contractAddress.call{value: ethValue}(data);
        } else {
            (success, returnData) = contractAddress.call(data);
        }
        if (!success) {
            string memory revertMsg = getRevertMsg(returnData);
            revert(revertMsg);
        }
    }
}