// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./interfaces/IERC20.sol";
import "./lib/SafeMath.sol";
import "./lib/BytesLib.sol";
import "./lib/SafeERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Dispatcher is Ownable, AccessControl {
    
    // Allows easy manipulation on bytes
    using BytesLib for bytes;

    // use safe ERC20 interface to gracefully handle non-complient tokens
    using SafeERC20 for IERC20;

    // set up admin role to restrict functions to set list of admins
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice modifier to restrict functions to only users that have been added as an admin
    modifier onlyAdmins() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller must be admin");
        _;
    }

    /// @notice initializes contract, adding the owner as an admin
    constructor() public {
        addAdmin(msg.sender);
    }

    /// @notice Receive function to allow contract to accept ETH
    receive() external payable {}
    
    /// @notice Fallback function in case receive function is not matched
    fallback() external payable {}

    /// @notice Returns true if given address is on the list of admins
    /// @param _adminAddress the address to check
    /// @return addressIsAdmin true if address is admin
    function isAdmin(address _adminAddress) external view returns(bool addressIsAdmin) {
        addressIsAdmin = hasRole(ADMIN_ROLE, _adminAddress);
    }

    /// @notice add admin to the list of admins
    /// @param _adminAddress the address of the admin to add
    function addAdmin(address _adminAddress) public onlyOwner {
        _setupRole(ADMIN_ROLE, _adminAddress);
    }

    /// @notice Set approvals for exchange to use Dispatcher contract tokens
    /// @dev may want to set allowance to specific amounts in the future
    /// @dev may want to allow for setting approvals for array of tokens at once
    /// @param _token the token to approve
    /// @param _spender the address to allow spending of token
    function tokenAllowAll(address _token, address _spender) external onlyAdmins {
        IERC20 token = IERC20(_token);
        if (token.allowance(address(this), _spender) != uint256(-1)) {
            token.safeApprove(_spender, uint256(-1));
        }
    }

    /// @notice deposit tokens to the smart contract
    /// @param _tokens the tokens to deposit
    /// @param _amount the amount of each token to deposit.  If zero, deposits the maximum allowed amount for each token
    function depositTokens(address[] calldata _tokens, uint256 _amount) external onlyAdmins {
        for (uint i = 0; i < _tokens.length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            uint256 amount;
            uint256 tokenBalance = token.balanceOf(msg.sender);
            uint256 tokenAllowance = token.allowance(msg.sender, address(this));
            if (_amount == 0) {
                if (tokenBalance > tokenAllowance) {
                    amount = tokenAllowance;
                } else {
                    amount = tokenBalance;
                }
            } else {
                require(tokenBalance >= _amount, "User balance too low");
                require(tokenAllowance >= _amount, "Increase token allowance");
                amount = _amount;
            }
            require(token.transferFrom(msg.sender, address(this), amount), "Could not deposit funds");
        }
    }

    /// @notice withdraw tokens from the smart contract
    /// @param _tokens the tokens to withdraw
    /// @param _amount the amount of each token to withdraw.  If zero, withdraws the maximum allowed amount for each token
    function withdrawTokens(address[] calldata _tokens, uint256 _amount) external onlyAdmins {
        for (uint i = 0; i < _tokens.length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            uint256 amount;
            uint256 tokenBalance = token.balanceOf(address(this));
            uint256 tokenAllowance = token.allowance(address(this), msg.sender);
            if (_amount == 0) {
                if (tokenBalance > tokenAllowance) {
                    amount = tokenAllowance;
                } else {
                    amount = tokenBalance;
                }
            } else {
                require(tokenBalance >= _amount, "Contract balance too low");
                require(tokenAllowance >= _amount, "Increase token allowance");
                amount = _amount;
            }
            require(token.transferFrom(address(this), msg.sender, amount), "Could not withdraw funds");
        }
    }

    /// @notice withdraw ETH from the smart contract
    /// @param _amount the amount of ETH to withdraw.  If zero, withdraws the maximum allowed amount.
    function withdrawEth(uint256 _amount) external onlyAdmins {
        uint256 amount;
        uint256 contractBalance = address(this).balance;
        if (_amount == 0) {
            amount = contractBalance;
        } else {
            require(contractBalance >= _amount, "_amount exceeds contract balance");
            amount = _amount;
        }
        (bool success, ) = msg.sender.call.value(amount)("");
        require(success, "Could not withdraw ETH");
    }

    /// @notice calls the price function specified by _calldata at _contractAddress, returning the price as bytes
    /// @param _contractAddress contract to query
    /// @param _calldata the bytecode for the contract call
    /// @return price in bytes
    function getPrice(address _contractAddress, bytes memory _calldata) public view returns (bytes memory) {
        (bool success, bytes memory returnData) = _contractAddress.staticcall(_calldata);
        require(success, "Could not fetch price");
        return returnData.slice(0, 32);
    }

    /// @notice makes a series of trades as single transaction if profitable
    /// @param _queryScript the compiled bytecode for the series of function calls to get the final price
    /// @param _queryInputLocations index locations within the _queryScript to insert input amounts dynamically
    /// @param _executeScript the compiled bytecode for the series of function calls to execute the trade
    /// @param _executeInputLocations index locations within the _executeScript to insert input amounts dynamically
    /// @param _targetPrice profit target for this trade, if ETH>ETH, this should be _ethValue + gas estimate * gas price
    /// @param _ethValue the amount of ETH to send with initial contract call
    function makeTrade(
        bytes memory _queryScript,
        uint256[] memory _queryInputLocations,
        bytes memory _executeScript,
        uint256[] memory _executeInputLocations,
        uint256 _targetPrice,
        uint256 _ethValue
    ) public {
        bytes memory prices = queryAllPrices(_queryScript, _queryInputLocations);
        require(prices.toUint256(prices.length - 32) > _targetPrice, "Not profitable");
        for(uint i = 0; i < _executeInputLocations.length; i++) {
            replaceDataAt(_executeScript, prices.slice(i*32, (i+1)*32), _executeInputLocations[i]);
        }
        execute(_executeScript, _ethValue);
    }

    /// @notice a non-view function to help estimate the cost of a given query in practice
    /// @param _script the compiled bytecode for the series of function calls to get the final price
    /// @param _inputLocations index locations within the _script to insert input amounts dynamically
    function estimateQueryCost(bytes memory _script, uint256[] memory _inputLocations) public {
        queryAllPrices(_script, _inputLocations);
    }

    /// @notice makes a series of queries at once, returning all the prices as bytes
    /// @param _script the compiled bytecode for the series of function calls to get the final price
    /// @param _inputLocations index locations within the _script to insert input amounts dynamically
    /// @return all prices as bytes
    function queryAllPrices(bytes memory _script, uint256[] memory _inputLocations) public view returns (bytes memory) {
        uint256 location = 0;
        bytes memory prices;
        bytes memory lastPrice;
        bytes memory callData;
        uint256 inputsLength = _inputLocations.length;
        uint256 inputsIndex = 0;
        while (location < _script.length) {
            address contractAddress = addressAt(_script, location);
            uint256 calldataLength = uint256At(_script, location + 0x14);
            uint256 calldataStart = location + 0x14 + 0x20;
            if (location != 0 && inputsLength > inputsIndex) {
                uint256 insertLocation = _inputLocations[inputsIndex];
                replaceDataAt(_script, lastPrice, insertLocation);
                inputsIndex++;
            }
            callData = _script.slice(calldataStart, calldataLength);
            lastPrice = getPrice(contractAddress, callData);
            prices = prices.concat(lastPrice);
            location += (0x14 + 0x20 + calldataLength);
        }
        return prices;
    }

    /// @notice makes a series of queries at once, returning the final price as a uint
    /// @param _script the compiled bytecode for the series of function calls to get the final price
    /// @param _inputLocations index locations within the _script to insert input amounts dynamically
    /// @return last price as uint
    function query(bytes memory _script, uint256[] memory _inputLocations) public view returns (uint256) {
        uint256 location = 0;
        bytes memory lastPrice;
        bytes memory callData;
        uint256 inputsLength = _inputLocations.length;
        uint256 inputsIndex = 0;
        while (location < _script.length) {
            address contractAddress = addressAt(_script, location);
            uint256 calldataLength = uint256At(_script, location + 0x14);
            uint256 calldataStart = location + 0x14 + 0x20;
            if (location != 0 && inputsLength > inputsIndex) {
                uint256 insertLocation = _inputLocations[inputsIndex];
                replaceDataAt(_script, lastPrice, insertLocation);
                inputsIndex++;
            }
            callData = _script.slice(calldataStart, calldataLength);
            lastPrice = getPrice(contractAddress, callData);
            location += (0x14 + 0x20 + calldataLength);
        }
        return lastPrice.toUint256(0);
    }

    /// @notice executes series of function calls as single transaction
    /// @param _script the compiled bytecode for the series of function calls to invoke
    /// @param _ethValue the amount of ETH to send with initial contract call
    function execute(bytes memory _script, uint256 _ethValue) public onlyAdmins {
        require(address(this).balance >= _ethValue, "Not enough ETH in contract");
        // sequentially call contract methods
        uint256 location = 0;
        while (location < _script.length) {
            address contractAddress = addressAt(_script, location);
            uint256 calldataLength = uint256At(_script, location + 0x14);
            uint256 calldataStart = location + 0x14 + 0x20;
            bytes memory callData = _script.slice(calldataStart, calldataLength);
            if(location == 0) {
                callMethod(contractAddress, callData, _ethValue);
            }
            else {
                callMethod(contractAddress, callData, 0);
            }
            location += (0x14 + 0x20 + calldataLength);
        }
    }

    /// @notice calls the supplied calldata using the supplied contract address
    /// @param _contractAddress the contract to call
    /// @param _calldata the call data to execute
    /// @param _ethValue the amount of ETH to send with initial contract call
    function callMethod(address _contractAddress, bytes memory _calldata, uint256 _ethValue) internal {
        bool success;
        bytes memory returnData;
        address payable contractAddress = payable(_contractAddress);
        if(_ethValue > 0) {
            (success, returnData) = contractAddress.call.value(_ethValue)(_calldata);
        } else {
            (success, returnData) = contractAddress.call(_calldata);
        }
        if (!success) {
            string memory revertMsg = getRevertMsg(returnData);
            revert(revertMsg);
        }
    }

    /// @notice Returns uint from chunk of the bytecode
    /// @param _data the compiled bytecode for the series of function calls
    /// @param _location the current 'cursor' location within the bytecode
    /// @return result uint
    function uint256At(bytes memory _data, uint256 _location) pure internal returns (uint256 result) {
        assembly {
            result := mload(add(_data, add(0x20, _location)))
        }
    }

    /// @notice Returns address from chunk of the bytecode
    /// @param _data the compiled bytecode for the series of function calls
    /// @param _location the current 'cursor' location within the bytecode
    /// @return result address
    function addressAt(bytes memory _data, uint256 _location) pure internal returns (address result) {
        uint256 word = uint256At(_data, _location);
        assembly {
            result := div(and(word, 0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000),
                          0x1000000000000000000000000)
        }
    }

    /// @notice Returns the start of the calldata within a chunk of the bytecode
    /// @param _data the compiled bytecode for the series of function calls
    /// @param _location the current 'cursor' location within the bytecode
    /// @return result pointer to start of calldata
    function locationOf(bytes memory _data, uint256 _location) pure internal returns (uint256 result) {
        assembly {
            result := add(_data, add(0x20, _location))
        }
    }
    
    /// @notice Replace the bytes at the index _location in _original with _new bytes
    /// @param _original original bytes
    /// @param _new new bytes to replace in _original
    /// @param _location the index within the _original bytes where to make the replacement
    function replaceDataAt(bytes memory _original, bytes memory _new, uint256 _location) pure internal {
        assembly {
            mstore(add(add(_original, _location), 0x20), mload(add(_new, 0x20)))
        }
    }

    /// @dev Get the revert message from a call
    /// @notice This is needed in order to get the human-readable revert message from a call
    /// @param _res Response of the call
    /// @return Revert message string
    function getRevertMsg(bytes memory _res) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_res.length < 68) return 'Call failed for unknown reason';
        bytes memory revertData = _res.slice(4, _res.length - 4); // Remove the selector which is the first 4 bytes
        return abi.decode(revertData, (string)); // All that remains is the revert string
    }
}