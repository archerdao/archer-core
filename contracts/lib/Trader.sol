// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../interfaces/IQueryEngine.sol";

import "./BytesLib.sol";
import "./CalldataEditor.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";

abstract contract Trader is ReentrancyGuard, AccessControl, CalldataEditor {
    using BytesLib for bytes;

    /// @notice Query contract
    IQueryEngine public queryEngine;

    /// @notice Trader role to restrict functions to set list of approved traders
    bytes32 public constant TRADER_ROLE = keccak256("TRADER_ROLE");

    /// @notice modifier to restrict functions to only users that have been added as a trader
    modifier onlyTrader() {
        require(hasRole(TRADER_ROLE, msg.sender), "Trader must have TRADER role");
        _;
    }

    /// @notice All trades must be profitable
    modifier mustBeProfitable(uint256 ethRequested) {
        uint256 contractBalanceBefore = address(this).balance;
        require(contractBalanceBefore >= ethRequested, "Not enough ETH in contract");
        _;
        require(address(this).balance >= contractBalanceBefore, "missing ETH");
    }

    /// @notice Trades must not be expired
    modifier notExpired(uint256 deadlineBlock) {
        require(deadlineBlock >= block.number, "trade expired");
        _;
    }

    /// @notice Trades must be executed within time window
    modifier onTime(uint256 minTimestamp, uint256 maxTimestamp) {
        require(maxTimestamp >= block.timestamp, "trade too late");
        require(minTimestamp <= block.timestamp, "trade too early");
        _;
    }

    /// @notice Returns true if given address is on the list of approved traders
    /// @param addressToCheck the address to check
    /// @return true if address is trader
    function isTrader(address addressToCheck) external view returns (bool) {
        return hasRole(TRADER_ROLE, addressToCheck);
    }

    /// @notice Makes a series of trades as single transaction if profitable without query
    /// @param executeScript the compiled bytecode for the series of function calls to execute the trade
    /// @param ethValue the amount of ETH to send with initial contract call
    function makeTrade(
        bytes memory executeScript,
        uint256 ethValue
    ) public onlyTrader nonReentrant mustBeProfitable(ethValue) {
        execute(executeScript, ethValue);
    }

    /// @notice Makes a series of trades as single transaction if profitable without query + block deadline
    /// @param executeScript the compiled bytecode for the series of function calls to execute the trade
    /// @param ethValue the amount of ETH to send with initial contract call
    /// @param blockDeadline block number when trade expires
    function makeTrade(
        bytes memory executeScript,
        uint256 ethValue,
        uint256 blockDeadline
    ) public onlyTrader nonReentrant notExpired(blockDeadline) mustBeProfitable(ethValue) {
        execute(executeScript, ethValue);
    }

    /// @notice Makes a series of trades as single transaction if profitable without query + within time window specified
    /// @param executeScript the compiled bytecode for the series of function calls to execute the trade
    /// @param ethValue the amount of ETH to send with initial contract call
    /// @param minTimestamp minimum block timestamp to execute trade
    /// @param maxTimestamp maximum timestamp to execute trade
    function makeTrade(
        bytes memory executeScript,
        uint256 ethValue,
        uint256 minTimestamp,
        uint256 maxTimestamp
    ) public onlyTrader nonReentrant onTime(minTimestamp, maxTimestamp) mustBeProfitable(ethValue) {
        execute(executeScript, ethValue);
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
    ) public onlyTrader nonReentrant mustBeProfitable(ethValue) {
        bytes memory prices = queryEngine.queryAllPrices(queryScript, queryInputLocations);
        require(prices.toUint256(prices.length - 32) >= targetPrice, "Not profitable");
        for(uint i = 0; i < executeInputLocations.length; i++) {
            replaceDataAt(executeScript, prices.slice(i*32, 32), executeInputLocations[i]);
        }
        execute(executeScript, ethValue);
    }

    /// @notice Makes a series of trades as single transaction if profitable + block deadline
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
    ) public onlyTrader nonReentrant notExpired(blockDeadline) mustBeProfitable(ethValue) {
        bytes memory prices = queryEngine.queryAllPrices(queryScript, queryInputLocations);
        require(prices.toUint256(prices.length - 32) >= targetPrice, "Not profitable");
        for(uint i = 0; i < executeInputLocations.length; i++) {
            replaceDataAt(executeScript, prices.slice(i*32, 32), executeInputLocations[i]);
        }
        execute(executeScript, ethValue);
    }

    /// @notice Makes a series of trades as single transaction if profitable + within time window specified
    /// @param queryScript the compiled bytecode for the series of function calls to get the final price
    /// @param queryInputLocations index locations within the queryScript to insert input amounts dynamically
    /// @param executeScript the compiled bytecode for the series of function calls to execute the trade
    /// @param executeInputLocations index locations within the executeScript to insert input amounts dynamically
    /// @param targetPrice profit target for this trade, if ETH>ETH, this should be ethValue + gas estimate * gas price
    /// @param ethValue the amount of ETH to send with initial contract call
    /// @param minTimestamp minimum block timestamp to execute trade
    /// @param maxTimestamp maximum timestamp to execute trade
    function makeTrade(
        bytes memory queryScript,
        uint256[] memory queryInputLocations,
        bytes memory executeScript,
        uint256[] memory executeInputLocations,
        uint256 targetPrice,
        uint256 ethValue,
        uint256 minTimestamp,
        uint256 maxTimestamp
    ) public onlyTrader nonReentrant onTime(minTimestamp, maxTimestamp) mustBeProfitable(ethValue) {
        bytes memory prices = queryEngine.queryAllPrices(queryScript, queryInputLocations);
        require(prices.toUint256(prices.length - 32) >= targetPrice, "Not profitable");
        for(uint i = 0; i < executeInputLocations.length; i++) {
            replaceDataAt(executeScript, prices.slice(i*32, 32), executeInputLocations[i]);
        }
        execute(executeScript, ethValue);
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