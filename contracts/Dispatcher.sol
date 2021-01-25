// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IERC20.sol";
import "./interfaces/IQueryEngine.sol";

import "./lib/SafeMath.sol";
import "./lib/SafeERC20.sol";
import "./lib/AccessControl.sol";
import "./lib/Trader.sol";

/**
 * @title Dispatcher
 * @dev Executes trades on behalf of suppliers and maintains bankroll to support supplier strategies
 */
contract Dispatcher is AccessControl, Trader {
    // Allows safe math operations on uint256 values
    using SafeMath for uint256;

    // Allows easy manipulation on bytes
    using BytesLib for bytes;

    // Use safe ERC20 interface to gracefully handle non-compliant tokens
    using SafeERC20 for IERC20;

    /// @notice Version number of Dispatcher
    uint8 public version;

    /// @notice Admin role to manage whitelisted LPs
    bytes32 public constant MANAGE_LP_ROLE = keccak256("MANAGE_LP_ROLE");

    /// @notice Addresses with this role are allowed to provide liquidity to this contract
    /// @dev If no addresses with this role exist, all addresses can provide liquidity
    bytes32 public constant WHITELISTED_LP_ROLE = keccak256("WHITELISTED_LP_ROLE");

    /// @notice Admin role to restrict approval of tokens on dispatcher
    bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE");  

    /// @notice Admin role to restrict withdrawal of funds from contract
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");    

    /// @notice Maximum ETH liquidity allowed in Dispatcher
    uint256 public MAX_LIQUIDITY;

    /// @notice Total current liquidity provided to Dispatcher
    uint256 public totalLiquidity;

    /// @notice Mapping of lp address to liquidity provided
    mapping(address => uint256) public lpBalances;

    /// @notice modifier to restrict functions to only users that have been added as LP manager
    modifier onlyLPManager() {
        require(hasRole(MANAGE_LP_ROLE, msg.sender), "Caller must have MANAGE_LP role");
        _;
    }

    /// @notice modifier to restrict functions to only users that have been added as an approver
    modifier onlyApprover() {
        require(hasRole(APPROVER_ROLE, msg.sender), "Caller must have APPROVER role");
        _;
    }

    /// @notice modifier to restrict functions to only users that have been added as a withdrawer
    modifier onlyWithdrawer() {
        require(hasRole(WITHDRAW_ROLE, msg.sender), "Caller must have WITHDRAW role");
        _;
    }

    /// @notice modifier to restrict functions to only users that have been whitelisted as an LP
    modifier onlyWhitelistedLP() {
        if(getRoleMemberCount(WHITELISTED_LP_ROLE) > 0) {
            require(hasRole(WHITELISTED_LP_ROLE, msg.sender), "Caller must have WHITELISTED_LP role");
        }
        _;
    }

    /// @notice Max liquidity updated event
    event MaxLiquidityUpdated(address indexed asset, uint256 indexed newAmount, uint256 oldAmount);

    /// @notice Liquidity Provided event
    event LiquidityProvided(address indexed asset, address indexed provider, uint256 amount);

    /// @notice Liquidity removed event
    event LiquidityRemoved(address indexed asset, address indexed provider, uint256 amount);

    /// @notice Initializes contract, setting up initial contract permissions
    /// @param _version Version number of Dispatcher
    /// @param _queryEngine Address of query engine contract
    /// @param _roleManager Address allowed to manage contract roles
    /// @param _lpManager Address allowed to manage LP whitelist
    /// @param _withdrawer Address allowed to withdraw profit from contract
    /// @param _trader Address allowed to make trades via this contract
    /// @param _supplier Address allowed to send opportunities to this contract
    /// @param _initialMaxLiquidity Initial max liquidity allowed in contract
    /// @param _lpWhitelist List of addresses that are allowed to provide liquidity to this contract
    constructor(
        uint8 _version,
        address _queryEngine,
        address _roleManager,
        address _lpManager,
        address _withdrawer,
        address _trader,
        address _supplier,
        uint256 _initialMaxLiquidity,
        address[] memory _lpWhitelist
    ) {
        version = _version;
        queryEngine = IQueryEngine(_queryEngine);
        _setupRole(MANAGE_LP_ROLE, _lpManager);
        _setRoleAdmin(WHITELISTED_LP_ROLE, MANAGE_LP_ROLE);
        _setupRole(WITHDRAW_ROLE, _withdrawer);
        _setupRole(TRADER_ROLE, _trader);
        _setupRole(APPROVER_ROLE, _supplier);
        _setupRole(APPROVER_ROLE, _withdrawer);
        _setupRole(DEFAULT_ADMIN_ROLE, _roleManager);
        MAX_LIQUIDITY = _initialMaxLiquidity;
        for(uint i; i < _lpWhitelist.length; i++) {
            _setupRole(WHITELISTED_LP_ROLE, _lpWhitelist[i]);
        }
    }

    /// @notice Receive function to allow contract to accept ETH
    receive() external payable {}
    
    /// @notice Fallback function in case receive function is not matched
    fallback() external payable {}

    /// @notice Returns true if given address is on the list of approvers
    /// @param addressToCheck the address to check
    /// @return true if address is approver
    function isApprover(address addressToCheck) external view returns(bool) {
        return hasRole(APPROVER_ROLE, addressToCheck);
    }

    /// @notice Returns true if given address is on the list of approved withdrawers
    /// @param addressToCheck the address to check
    /// @return true if address is withdrawer
    function isWithdrawer(address addressToCheck) external view returns(bool) {
        return hasRole(WITHDRAW_ROLE, addressToCheck);
    }

    /// @notice Returns true if given address is on the list of LP managers
    /// @param addressToCheck the address to check
    /// @return true if address is LP manager
    function isLPManager(address addressToCheck) external view returns(bool) {
        return hasRole(MANAGE_LP_ROLE, addressToCheck);
    }

    /// @notice Returns true if given address is on the list of whitelisted LPs
    /// @param addressToCheck the address to check
    /// @return true if address is whitelisted
    function isWhitelistedLP(address addressToCheck) external view returns(bool) {
        return hasRole(WHITELISTED_LP_ROLE, addressToCheck);
    }

    /// @notice Set approvals for external addresses to use Dispatcher contract tokens
    /// @param tokensToApprove the tokens to approve
    /// @param spender the address to allow spending of token
    function tokenAllowAll(
        address[] memory tokensToApprove, 
        address spender
    ) external onlyApprover {
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
    ) external onlyApprover {
        require(tokensToApprove.length == approvalAmounts.length, "not same length");
        for(uint i = 0; i < tokensToApprove.length; i++) {
            IERC20 token = IERC20(tokensToApprove[i]);
            if (token.allowance(address(this), spender) != uint256(-1)) {
                token.safeApprove(spender, approvalAmounts[i]);
            }
        }
    }

    /// @notice Rescue (withdraw) tokens from the smart contract
    /// @param tokens the tokens to withdraw
    /// @param amount the amount of each token to withdraw.  If zero, withdraws the maximum allowed amount for each token
    function rescueTokens(address[] calldata tokens, uint256 amount) external onlyWithdrawer {
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
            token.safeTransferFrom(address(this), msg.sender, withdrawalAmount);
        }
    }

    /// @notice Set max ETH liquidity to accept for this contract
    /// @param newMax new max ETH liquidity
    function setMaxETHLiquidity(uint256 newMax) external onlyLPManager {
        emit MaxLiquidityUpdated(address(0), newMax, MAX_LIQUIDITY);
        MAX_LIQUIDITY = newMax;
    }

    /// @notice Provide ETH liquidity to Dispatcher
    function provideETHLiquidity() external payable onlyWhitelistedLP {
        require(totalLiquidity.add(msg.value) <= MAX_LIQUIDITY, "amount exceeds max liquidity");
        totalLiquidity = totalLiquidity.add(msg.value);
        lpBalances[msg.sender] = lpBalances[msg.sender].add(msg.value);
        emit LiquidityProvided(address(0), msg.sender, msg.value);
    }

    /// @notice Remove ETH liquidity from Dispatcher
    /// @param amount amount of liquidity to remove
    function removeETHLiquidity(uint256 amount) external {
        require(lpBalances[msg.sender] >= amount, "amount exceeds liquidity provided");
        require(totalLiquidity.sub(amount) >= 0, "amount exceeds total liquidity");
        require(address(this).balance.sub(amount) >= 0, "amount exceeds contract balance");
        lpBalances[msg.sender] = lpBalances[msg.sender].sub(amount);
        totalLiquidity = totalLiquidity.sub(amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Could not withdraw ETH");
        emit LiquidityRemoved(address(0), msg.sender, amount);
    }

    /// @notice Withdraw ETH from the smart contract
    /// @param amount the amount of ETH to withdraw.  If zero, withdraws the maximum allowed amount.
    function withdrawEth(uint256 amount) external onlyWithdrawer {
        uint256 withdrawalAmount;
        uint256 withdrawableBalance = address(this).balance.sub(totalLiquidity);
        if (amount == 0) {
            withdrawalAmount = withdrawableBalance;
        } else {
            require(withdrawableBalance >= amount, "amount exceeds withdrawable balance");
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