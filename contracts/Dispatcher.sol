// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IERC20.sol";
import "./interfaces/IQueryEngine.sol";

import "./lib/SafeMath.sol";
import "./lib/SafeERC20.sol";
import "./lib/AccessControl.sol";
import "./lib/Trader.sol";

contract Dispatcher is AccessControl, Trader {
    // Allows easy manipulation on bytes
    using BytesLib for bytes;

    // use safe ERC20 interface to gracefully handle non-compliant tokens
    using SafeERC20 for IERC20;

    /// @notice Admin role to restrict withdrawal of funds from contract
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    /// @notice Caller role to restrict functions to set list of approved callers
    bytes32 public constant CALLER_ROLE = keccak256("CALLER_ROLE");

    /// @notice modifier to restrict functions to only users that have been added as a withdrawer
    modifier onlyWithdrawer() {
        require(hasRole(WITHDRAW_ROLE, msg.sender), "Caller must have WITHDRAW role");
        _;
    }

     /// @notice modifier to restrict functions to only users that have been added as a caller
    modifier onlyCaller() {
        require(hasRole(CALLER_ROLE, msg.sender), "Caller must have CALLER role");
        _;
    }

    /// @notice Initializes contract, adding msg.sender as the admin
    /// @param _queryEngine Address of query engine contract
    constructor(address _queryEngine) {
        queryEngine = IQueryEngine(_queryEngine);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Receive function to allow contract to accept ETH
    receive() external payable {}
    
    /// @notice Fallback function in case receive function is not matched
    fallback() external payable {}

    /// @notice Returns true if given address is on the list of approved callers
    /// @param addressToCheck the address to check
    /// @return true if address is caller
    function isCaller(address addressToCheck) external view returns(bool) {
        return hasRole(CALLER_ROLE, addressToCheck);
    }

    /// @notice Returns true if given address is on the list of approved withdrawers
    /// @param addressToCheck the address to check
    /// @return true if address is withdrawer
    function isWithdrawer(address addressToCheck) external view returns(bool) {
        return hasRole(WITHDRAW_ROLE, addressToCheck);
    }

    /// @notice Set approvals for external addresses to use Dispatcher contract tokens
    /// @param tokensToApprove the tokens to approve
    /// @param spender the address to allow spending of token
    function tokenAllowAll(
        address[] memory tokensToApprove, 
        address spender
    ) external onlyCaller {
        for(uint i = 0; i < tokensToApprove.length; i++) {
            IERC20 token = IERC20(tokensToApprove[i]);
            if (token.allowance(address(this), spender) != uint256(-1)) {
                token.safeApprove(spender, uint256(-1));
            }
        }
    }

    /// @notice Set approvals for external addresses to use Dispatcher contract tokens
    /// @param tokensToApprove the tokens to approve
    /// @param approvalAmounts the token approval amounts
    /// @param spender the address to allow spending of token
    function tokenAllow(
        address[] memory tokensToApprove, 
        uint256[] memory approvalAmounts, 
        address spender
    ) external onlyCaller {
        require(tokensToApprove.length == approvalAmounts.length, "not same length");
        for(uint i = 0; i < tokensToApprove.length; i++) {
            IERC20 token = IERC20(tokensToApprove[i]);
            if (token.allowance(address(this), spender) != uint256(-1)) {
                token.safeApprove(spender, approvalAmounts[i]);
            }
        }
    }

    // /// @notice Deposit tokens to the smart contract
    // /// @param tokens the tokens to deposit
    // /// @param amount the amount of each token to deposit.  If zero, deposits the maximum allowed amount for each token
    // function depositTokens(address[] calldata tokens, uint256 amount) external {
    //     for (uint i = 0; i < tokens.length; i++) {
    //         IERC20 token = IERC20(tokens[i]);
    //         uint256 depositAmount;
    //         uint256 tokenBalance = token.balanceOf(msg.sender);
    //         uint256 tokenAllowance = token.allowance(msg.sender, address(this));
    //         if (amount == 0) {
    //             if (tokenBalance > tokenAllowance) {
    //                 depositAmount = tokenAllowance;
    //             } else {
    //                 depositAmount = tokenBalance;
    //             }
    //         } else {
    //             require(tokenBalance >= amount, "User balance too low");
    //             require(tokenAllowance >= amount, "Increase token allowance");
    //             depositAmount = amount;
    //         }
    //         require(token.transferFrom(msg.sender, address(this), depositAmount), "Could not deposit funds");
    //     }
    // }

    /// @notice Withdraw tokens from the smart contract
    /// @param tokens the tokens to withdraw
    /// @param amount the amount of each token to withdraw.  If zero, withdraws the maximum allowed amount for each token
    function withdrawTokens(address[] calldata tokens, uint256 amount) external onlyWithdrawer {
        for (uint i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            uint256 withdrawalAmount;
            uint256 tokenBalance = token.balanceOf(address(this));
            uint256 tokenAllowance = token.allowance(address(this), msg.sender);
            if (amount == 0) {
                if (tokenBalance > tokenAllowance) {
                    withdrawalAmount = tokenAllowance;
                } else {
                    withdrawalAmount = tokenBalance;
                }
            } else {
                require(tokenBalance >= amount, "Contract balance too low");
                require(tokenAllowance >= amount, "Increase token allowance");
                withdrawalAmount = amount;
            }
            require(token.transferFrom(address(this), msg.sender, withdrawalAmount), "Could not withdraw funds");
        }
    }

    /// @notice Withdraw ETH from the smart contract
    /// @param amount the amount of ETH to withdraw.  If zero, withdraws the maximum allowed amount.
    function withdrawEth(uint256 amount) external onlyWithdrawer {
        uint256 withdrawalAmount;
        uint256 contractBalance = address(this).balance;
        if (amount == 0) {
            withdrawalAmount = contractBalance;
        } else {
            require(contractBalance >= amount, "amount exceeds contract balance");
            withdrawalAmount = amount;
        }
        (bool success, ) = msg.sender.call{value: withdrawalAmount}("");
        require(success, "Could not withdraw ETH");
    }

    /// @notice A non-view function to help estimate the cost of a given query in practice
    /// @param script the compiled bytecode for the series of function calls to get the final price
    /// @param inputLocations index locations within the script to insert input amounts dynamically
    function estimateQueryCost(bytes memory script, uint256[] memory inputLocations) public {
        queryEngine.queryAllPrices(script, inputLocations);
    }
}