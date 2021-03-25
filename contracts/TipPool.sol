// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./lib/AccessControl.sol";
import "./lib/SafeMath.sol";

/**
 * @title TipPool
 * @dev Allows suppliers to create a tip that gets distributed to miners + the network
 */
contract TipPool is AccessControl {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev Record of all known miners
    EnumerableSet.AddressSet private knownMinersSet;

    /// @notice TipPool Admin role
    bytes32 public constant TIP_POOL_ADMIN_ROLE = keccak256("TIP_POOL_ADMIN_ROLE");

    /// @notice Miner manager role
    bytes32 public constant MINER_MANAGER_ROLE = keccak256("MINER_MANAGER_ROLE");

    /// @notice Fee setter role
    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");

    /// @notice Network fee (measured in bips: 10,000 bips = 1% of contract balance)
    uint32 public networkFee;

    /// @notice Network fee output address
    address public networkFeeCollector;

    /// @notice Accountant address
    address public accountant;

    /// @notice Add known miner event
    event KnownMinerAdded(address indexed miner);

    /// @notice Remove known miner event
    event KnownMinerRemoved(address indexed miner);

    /// @notice Accountant set event
    event AccountantSet(address indexed newAccountant, address indexed oldAccountant);

    /// @notice Fee set event
    event FeeSet(uint32 indexed newFee, uint32 indexed oldFee);

    /// @notice Fee collector set event
    event FeeCollectorSet(address indexed newCollector, address indexed oldCollector);

    /// @notice Collection event
    event Collection(address indexed receiver, address indexed feeCollector, uint256 amount, uint256 fee);

    /// @notice modifier to restrict functions to admins
    modifier onlyAdmin() {
        require(hasRole(TIP_POOL_ADMIN_ROLE, msg.sender), "Caller must have TIP_POOL_ADMIN_ROLE role");
        _;
    }

    /// @notice modifier to restrict functions to miner managers
    modifier onlyMinerManager() {
        require(hasRole(MINER_MANAGER_ROLE, msg.sender), "Caller must have MINER_MANAGER_ROLE role");
        _;
    }

    /// @notice modifier to restrict functions to fee setters
    modifier onlyFeeSetter() {
        require(hasRole(FEE_SETTER_ROLE, msg.sender), "Caller must have FEE_SETTER_ROLE role");
        _;
    }

    /// @notice Initializes contract, setting admin roles + network fee
    /// @param _roleAdmin admin in control of roles
    /// @param _tipPoolAdmin admin of tip pool
    /// @param _minerManager miner manager address
    /// @param _feeSetter fee setter address
    /// @param _networkFeeCollector address that collects network fees
    /// @param _networkFee % of fee collected by the network
    /// @param _accountant accountant address
    /// @param _knownMiners known miner addresses
    constructor(
        address _roleAdmin,
        address _tipPoolAdmin,
        address _minerManager,
        address _feeSetter,
        address _networkFeeCollector,
        uint32 _networkFee,
        address _accountant,
        address[] memory _knownMiners
    ) {
        _setupRole(TIP_POOL_ADMIN_ROLE, _tipPoolAdmin);
        _setupRole(MINER_MANAGER_ROLE, _minerManager);
        _setupRole(FEE_SETTER_ROLE, _feeSetter);
        _setupRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
        networkFeeCollector = _networkFeeCollector;
        emit FeeCollectorSet(_networkFeeCollector, address(0));
        networkFee = _networkFee;
        emit FeeSet(_networkFee, 0);
        accountant = _accountant;
        emit AccountantSet(_accountant, address(0));
        for(uint i = 0; i < _knownMiners.length; i++) {
            knownMinersSet.add(_knownMiners[i]);
        }
    }

    /// @notice Receive function to allow contract to accept ETH
    receive() external payable {}

    /**
     * @notice Distributes any ETH in contract to relevant parties
     */
    function collect() external {
        address receiver;
        uint256 fee;
        if (networkFee > 0) {
            fee = address(this).balance.mul(networkFee).div(1000000);
            (bool feeSuccess, ) = networkFeeCollector.call{value: fee}("");
            require(feeSuccess, "Could not collect fee");
        }

        if(knownMinersSet.contains(block.coinbase)) {
            receiver = accountant;
        } else {
            receiver = block.coinbase;
        }
        uint256 amount = address(this).balance;
        (bool success, ) = receiver.call{value: amount}("");
        require(success, "Could not collect ETH");
        emit Collection(receiver, networkFeeCollector, amount, fee);
    }

    /**
     * @notice Return list of known miner addresses
     * @return Array of miner addresses
     */
    function knownMiners() external view returns (address[] memory) {
        uint256 minersLength = knownMinersSet.length();
        address[] memory minersArray = new address[](minersLength);
        for(uint i = 0; i < minersLength; i++) {
            minersArray[i] = knownMinersSet.at(i);
        }
        return minersArray;
    }

    /**
     * @notice Returns the number of known miners
     * @return number of miners
     */
    function numKnownMiners() external view returns (uint256) {
        return knownMinersSet.length();
    }

    /**
     * @notice Determine whether a given address is a known miner
     * @param miner Miner address
     * @return true if miner is known 
     */
    function isKnownMiner(address miner) external view returns (bool) {
        return knownMinersSet.contains(miner);
    }

    /**
     * @notice Admin function to add miners to known miners set
     * @param miners Array of miner addresses
     */
    function addKnownMiners(address[] memory miners) external onlyMinerManager {
        for(uint i = 0; i < miners.length; i++) {
            knownMinersSet.add(miners[i]);
            emit KnownMinerAdded(miners[i]);
        }   
    }

    /**
     * @notice Admin function to remove miners from known miners set
     * @param miners Array of miner addresses
     */
    function removeKnownMiners(address[] memory miners) external onlyMinerManager {
        for(uint i = 0; i < miners.length; i++) {
            knownMinersSet.remove(miners[i]);
            emit KnownMinerRemoved(miners[i]);
        }   
    }

    /**
     * @notice Admin function to set accountant address
     * @param newAccountant new accountant address
     */
    function setAccountant(address newAccountant) external onlyAdmin {
        emit AccountantSet(newAccountant, accountant);
        accountant = newAccountant;
    }

    /**
     * @notice Admin function to set network fee
     * @param newFee new fee
     */
    function setFee(uint32 newFee) external onlyFeeSetter {
        emit FeeSet(newFee, networkFee);
        networkFee = newFee;
    }

    /**
     * @notice Admin function to set fee collector address
     * @param newCollector new fee collector address
     */
    function setFeeCollector(address newCollector) external onlyAdmin {
        emit FeeCollectorSet(newCollector, networkFeeCollector);
        networkFeeCollector = newCollector;
    }
}