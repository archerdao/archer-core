// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IVotingPower.sol";
import "./interfaces/IDispatcherFactory.sol";
import "./interfaces/IDispatcher.sol";
import "./lib/AccessControl.sol";
import "./lib/ReentrancyGuard.sol";
import "./lib/SafeMath.sol";
import "./BankrollToken.sol";

/**
 * @title Bouncer
 * @dev Used as an interface to provide bankroll to Dispatchers on the Archer network
 */
contract Bouncer is AccessControl, ReentrancyGuard {
    using SafeMath for uint256;

    /// @notice Dispatcher Factory
    IDispatcherFactory public dispatcherFactory;

    /// @notice Voting Power Contract
    IVotingPower public votingPowerContract;

    /// @notice Global cap on % of network bankroll any one entity can provide (measured in bips: 10,000 bips = 1% of bankroll requested by the network)
    uint32 public globalMaxContributionPct;

    /// @notice Per Dispatcher cap on % of bankroll any one entity can provide (measured in bips: 10,000 bips = 1% of bankroll requested by the Dispatcher)
    uint32 public dispatcherMaxContributionPct;

    /// @notice Amount of voting power required to bankroll on the network
    uint256 public requiredVotingPower;

    /// @notice Total amount of bankroll provided to the network via this contract
    uint256 public totalAmountDeposited;

    /// @notice Mapping of bankroll Dispatcher > asset > bankroll token
    mapping(address => mapping(address => BankrollToken)) public bankrollTokens;

    /// @notice Mapping of Dispatcher address > bankroll provided
    mapping(address => uint256) public amountDeposited;

    /// @notice Admin role to manage Bouncer
    bytes32 public constant BOUNCER_ADMIN_ROLE = keccak256("BOUNCER_ADMIN_ROLE");

     /// @notice Modifier to restrict functions to only users that have been added as Bouncer admin
    modifier onlyAdmin() {
        require(hasRole(BOUNCER_ADMIN_ROLE, msg.sender), "Caller must have BOUNCER_ADMIN_ROLE role");
        _;
    }

    /// @notice Event emitted when Dispatcher Factory contract address is changed
    event DispatcherFactoryChanged(address indexed oldAddress, address indexed newAddress);
    
    /// @notice Event emitted when Voting Power contract address is changed
    event VotingPowerChanged(address indexed oldAddress, address indexed newAddress);
    
    /// @notice Event emitted when required voting power to bankroll network is changed
    event RequiredVotingPowerChanged(uint256 oldVotingPower, uint256 newVotingPower);
    
    /// @notice Event emitted when global cap is changed
    event GlobalMaxChanged(uint32 oldPct, uint32 newPct);

    /// @notice Event emitted when per dispatcher cap is changed
    event DispatcherMaxChanged(uint32 oldPct, uint32 newPct);

    /// @notice Event emitted when a new Dispatcher/asset is added to the bankroll program
    event BankrollTokenCreated(address indexed tokenAddress, address indexed asset, address dispatcher);

    /// @notice Event emitted when bankroll is provided to a dispatcher
    event BankrollProvided(address indexed dispatcher, address indexed sender, address indexed account, address asset, uint256 amount);
    
    /// @notice Event emitted when bankroll is removed from a dispatcher
    event BankrollRemoved(address indexed dispatcher, address indexed sender, address indexed account, address asset, uint256 amount);

    /**
     * @notice Construct a new Bouncer contract
     * @param _dispatcherFactory Dispatcher Factory address
     * @param _votingPower VotingPower address
     * @param _globalMaxContributionPct Global cap on % of bankroll any one account can provide
     * @param _dispatcherMaxContributionPct Per Dispatcher cap on % of bankroll any one account can provide
     * @param _requiredVotingPower Amount of voting power required for account to provide bankroll
     * @param _bouncerAdmin Admin of Bouncer contract
     * @param _roleAdmin Admin of Bouncer admin role
     */
    constructor(
        address _dispatcherFactory,
        address _votingPower,
        uint32 _globalMaxContributionPct,
        uint32 _dispatcherMaxContributionPct,
        uint256 _requiredVotingPower,
        address _bouncerAdmin,
        address _roleAdmin
    ) {
        dispatcherFactory = IDispatcherFactory(_dispatcherFactory);
        votingPowerContract = IVotingPower(_votingPower);
        globalMaxContributionPct = _globalMaxContributionPct;
        dispatcherMaxContributionPct = _dispatcherMaxContributionPct;
        requiredVotingPower = _requiredVotingPower;
        _setupRole(BOUNCER_ADMIN_ROLE, _bouncerAdmin);
        _setupRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
    }

    /// @notice Receive function to allow contract to accept ETH
    receive() external payable {}
    
    /// @notice Fallback function in case receive function is not matched
    fallback() external payable {}

    /**
     * @notice Amount of voting power a given account has currently
     * @param account Address of account
     * @return amount Amount of voting power
     */
    function votingPower(address account) public view returns (uint256 amount) {
        return votingPowerContract.balanceOf(account);
    }

    /**
     * @notice Maximum amount of bankroll any one account can provide to the network as a whole
     * @return amount Max deposit amount
     */
    function maxDepositPerAccount() public view returns(uint256 amount) {
        return totalBankrollRequested().mul(globalMaxContributionPct).div(1000000);
    }

    /**
     * @notice Total amount of bankroll requested by all of the Dispatchers on the network
     * @return amount Total bankroll requested
     */
    function totalBankrollRequested() public view returns (uint256 amount) {
        address[] memory allDispatchers = dispatcherFactory.dispatchers();
        for(uint i = 0; i < allDispatchers.length; i++) {
            IDispatcher dispatcher = IDispatcher(allDispatchers[i]);
            if (dispatcher.isWhitelistedLP(address(this)) && bankrollTokens[allDispatchers[i]][address(0)] != BankrollToken(0)) {
                amount = amount + bankrollRequested(dispatcher);
            }
        }
    }

    /**
     * @notice Total amount of bankroll requested by all of the Dispatchers on the network that has not yet been provided
     * @return amount Total bankroll available for deposit
     */
    function totalBankrollAvailable() public view returns (uint256 amount) {
        address[] memory allDispatchers = dispatcherFactory.dispatchers();
        for(uint i = 0; i < allDispatchers.length; i++) {
            IDispatcher dispatcher = IDispatcher(allDispatchers[i]);
            amount = amount + bankrollAvailable(dispatcher);
        }
    }

    /**
     * @notice All of the Dispatchers on the network that have bankroll available that has not yet been provided
     * @return dispatchers Array of dispatchers that have bankroll requests available
     */
    function dispatchersWithBankrollAvailable() public view returns (address[] memory dispatchers) {
        address[] memory allDispatchers = dispatcherFactory.dispatchers();
        address[] memory filteredDispatchers = new address[](allDispatchers.length);
        uint numAvailable = 0;
        for(uint i = 0; i < allDispatchers.length; i++) {
            IDispatcher dispatcher = IDispatcher(allDispatchers[i]);
            if(bankrollAvailable(dispatcher) > 0) {
                filteredDispatchers[numAvailable] = allDispatchers[i];
                numAvailable++;
            }
        }
        dispatchers = new address[](numAvailable);
        for(uint i = 0; i < numAvailable; i++) {
            dispatchers[i] = filteredDispatchers[i];
        }
        return dispatchers;
    }

    /**
     * @notice Total amount of bankroll requested by the given Dispatcher
     * @return amount Bankroll requested by Dispatcher
     */
    function bankrollRequested(IDispatcher dispatcher) public view returns (uint256 amount) {
        return dispatcher.MAX_LIQUIDITY();
    }

   /**
     * @notice Amount of bankroll provided to given Dispatcher
     * @return amount Bankroll provided to Dispatcher
     */
    function bankrollProvided(IDispatcher dispatcher) public view returns (uint256 amount) {
        return dispatcher.totalLiquidity();
    }
    
    /**
     * @notice Amount of bankroll available to provide to given Dispatcher
     * @return amount Bankroll available for Dispatcher
     */
    function bankrollAvailable(IDispatcher dispatcher) public view returns (uint256 amount) {
        if (!dispatcher.isWhitelistedLP(address(this))) {
            return 0;
        }
        if (bankrollTokens[address(dispatcher)][address(0)] == BankrollToken(0)) {
            return 0;
        }

        return bankrollRequested(dispatcher).sub(bankrollProvided(dispatcher));
    }

    /**
     * @notice Max amount of bankroll any one account can provide to given Dispatcher
     * @return amount Max bankroll per account
     */
    function maxBankrollPerAccount(IDispatcher dispatcher) public view returns (uint256 amount) {
        return bankrollRequested(dispatcher).mul(dispatcherMaxContributionPct).div(1000000);
    }

    /**
     * @notice Total amount of remaining bankroll account can provide to network
     * @return amount Bankroll available to account
     */
    function amountAvailableToDeposit(address account) public view returns (uint256 amount) {
        if (votingPower(account) < requiredVotingPower) {
            return 0;
        }

        uint256 existingDeposit = amountDeposited[account];
        uint256 maxDeposit = maxDepositPerAccount();
        if(maxDeposit <= existingDeposit) {
            return 0;
        }
        return maxDeposit.sub(existingDeposit);
    }

    /**
     * @notice Amount of remaining bankroll account can provide to given Dispatcher
     * @return amount Bankroll available to account for given Dispatcher
     */
    function amountAvailableToBankroll(address account, address dispatcher) public view returns (uint256 amount) {
        if (dispatcherFactory.exists(account)) {
            return 0;
        }

        if (votingPower(account) < requiredVotingPower) {
            return 0;
        }

        uint256 availableDeposit = amountAvailableToDeposit(account);
        if (availableDeposit == 0) {
            return 0;
        }
        uint256 dispatcherBankrollAvailable = bankrollAvailable(IDispatcher(dispatcher));
        if (dispatcherBankrollAvailable == 0) {
            return 0;
        }

        uint256 maxBankroll = maxBankrollPerAccount(IDispatcher(dispatcher));
        BankrollToken bToken = bankrollTokens[dispatcher][address(0)];
        uint256 existingBankroll = bToken.balanceOf(account);

        if (maxBankroll <= existingBankroll) {
            return 0;
        }
        uint256 availableBankroll = maxBankroll.sub(existingBankroll);

        if (availableDeposit >= dispatcherBankrollAvailable) {
            return availableBankroll <= dispatcherBankrollAvailable ? availableBankroll : dispatcherBankrollAvailable;
        } else {
            return availableBankroll <= availableDeposit ? availableBankroll : availableDeposit;
        }
    }

    /**
     * @notice Gets all balances relevant to determining whether a given user can bankroll a dispatcher
     * @return balances 
     * 1) dispatcher bankroll available 
     * 2) min voting power 
     * 3) user voting power 
     * 4) network deposit max 
     * 5) account amount deposited 
     * 6) max bankroll per account for dispatcher 
     * 7) bankroll already provided by user to this dispatcher
     */
    function bankrollBalances(address account, address dispatcher) external view returns (uint256[7] memory balances) {
        BankrollToken bToken = bankrollTokens[dispatcher][address(0)];
        balances[0] = bankrollAvailable(IDispatcher(dispatcher));
        balances[1] = requiredVotingPower;
        balances[2] = votingPower(account);
        balances[3] = maxDepositPerAccount();
        balances[4] = amountDeposited[account];
        balances[5] = maxBankrollPerAccount(IDispatcher(dispatcher));
        balances[6] = bToken.balanceOf(account);
    }

    /**
     * @notice Function to allow a dispatcher to join the bankroll program
     * @param dispatcher Dispatcher address
     */
    function join(address dispatcher) external {
        if(bankrollTokens[dispatcher][address(0)] == BankrollToken(0)) {
            BankrollToken bToken = new BankrollToken(address(0), dispatcher, address(this));
            bankrollTokens[dispatcher][address(0)] = bToken;
            emit BankrollTokenCreated(address(bToken), address(0), dispatcher);
        }
    }

    /**
     * @notice Admin function to migrate token to new Bouncer
     * @param token the token
     * @param newBouncer Bouncer address
     */
    function migrate(BankrollToken token, address newBouncer) external onlyAdmin {
        require(newBouncer != address(0), "cannot migrate to zero");
        token.setSupplyManager(newBouncer);
    }

    /**
     * @notice Provide ETH bankroll to Dispatcher
     * @param dispatcher Dispatcher address
     */
    function provideETHBankroll(address dispatcher) external payable nonReentrant {
        require(bankrollTokens[dispatcher][address(0)] != BankrollToken(0), "create bankroll token first");
        require(amountAvailableToBankroll(tx.origin, dispatcher) >= msg.value, "amount exceeds max");
        require(!dispatcherFactory.exists(msg.sender), "dispatchers cannot provide bankroll");
        amountDeposited[tx.origin] = amountDeposited[tx.origin].add(msg.value);
        totalAmountDeposited = totalAmountDeposited.add(msg.value);
        IDispatcher(dispatcher).provideETHLiquidity{value:msg.value}();
        BankrollToken bToken = bankrollTokens[dispatcher][address(0)];
        bToken.mint(tx.origin, msg.value);
        emit BankrollProvided(dispatcher, msg.sender, tx.origin, address(0), msg.value);
    }

    /**
     * @notice Remove ETH bankroll from Dispatcher
     * @param dispatcher Dispatcher address
     * @param amount Amount of bankroll to remove
     */
    function removeETHBankroll(address dispatcher, uint256 amount) external nonReentrant {
        require(bankrollTokens[dispatcher][address(0)] != BankrollToken(0), "create bankroll token first");
        BankrollToken bToken = bankrollTokens[dispatcher][address(0)];
        require(bToken.balanceOf(tx.origin) >= amount, "not enough bankroll tokens");
        require(amountDeposited[tx.origin] >= amount, "amount exceeds deposit");
        require(totalAmountDeposited >= amount, "amount exceeds total");
        amountDeposited[tx.origin] = amountDeposited[tx.origin].sub(amount);
        totalAmountDeposited = totalAmountDeposited.sub(amount);
        IDispatcher(dispatcher).removeETHLiquidity(amount);
        bToken.burn(tx.origin, amount);
        (bool success, ) = msg.sender.call{value:amount}("");
        require(success, "Transfer failed");
        emit BankrollRemoved(dispatcher, msg.sender, tx.origin, address(0), amount);
    }

    /**
     * @notice Set Dispatcher Factory address
     * @dev Only Bouncer admin can call
     * @param factoryAddress Dispatcher Factory address
     */
    function setDispatcherFactory(address factoryAddress) external onlyAdmin {
        emit DispatcherFactoryChanged(address(dispatcherFactory), factoryAddress);
        dispatcherFactory = IDispatcherFactory(factoryAddress);
    }

    /**
     * @notice Set VotingPower address
     * @dev Only Bouncer admin can call
     * @param votingPowerAddress VotingPower address
     */
    function setVotingPower(address votingPowerAddress) external onlyAdmin {
        emit VotingPowerChanged(address(votingPowerContract), votingPowerAddress);
        votingPowerContract = IVotingPower(votingPowerAddress);
    }

    /**
     * @notice Set voting power required by users to provide bankroll
     * @dev Only Bouncer admin can call
     * @param newVotingPower minimum voting power
     */
    function setRequiredVotingPower(uint256 newVotingPower) external onlyAdmin {
        emit RequiredVotingPowerChanged(requiredVotingPower, newVotingPower);
        requiredVotingPower = newVotingPower;
    }

    /**
     * @notice Set global max % of network bankroll any one account can provide
     * @dev Only Bouncer admin can call
     * @param newPct new global cap %
     */
    function setGlobalMaxContributionPct(uint32 newPct) external onlyAdmin {
        emit GlobalMaxChanged(globalMaxContributionPct, newPct);
        globalMaxContributionPct = newPct;
    }

    /**
     * @notice Set per Dispatcher max % of bankroll any one account can provide
     * @dev Only Bouncer admin can call
     * @param newPct new per Dispatcher cap %
     */
    function setDispatcherMaxContributionPct(uint32 newPct) external onlyAdmin {
        emit DispatcherMaxChanged(dispatcherMaxContributionPct, newPct);
        dispatcherMaxContributionPct = newPct;
    }
}