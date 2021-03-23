// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./lib/AccessControl.sol";
import "./lib/SafeMath.sol";

/**
 * @title TipJar
 * @dev Allows suppliers to create a tip that gets distributed to miners + the network
 */
contract TipJar is AccessControl {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev Record of all known miners
    EnumerableSet.AddressSet private knownMiners;

    /// @notice TipJar Admin role
    bytes32 public constant TIPJAR_ADMIN_ROLE = keccak256("TIPJAR_ADMIN_ROLE");

    /// @notice Network fee (measured in bips: 10,000 bips = 1% of contract balance)
    uint32 public networkFee;

    /// @notice Network fee output address
    address public networkFeeCollector;

    /// @notice Accountant address
    address public accountant;

    /// @notice modifier to restrict functions to admins
    modifier onlyAdmin() {
        require(hasRole(TIPJAR_ADMIN_ROLE, msg.sender), "Caller must have TIPJAR_ADMIN_ROLE role");
        _;
    }

    /// @notice Initializes contract, setting admin roles + network fee
    /// @param _roleAdmin admin in control of roles
    /// @param _tipJarAdmin admin of tip jar
    /// @param _networkFeeCollector address that collects network fees
    /// @param _networkFee % of fee collected by the network
    /// @param _accountant accountant address
    /// @param _knownMiners known miner addresses
    constructor(
        address _roleAdmin,
        address _tipJarAdmin,
        address _networkFeeCollector,
        uint32 _networkFee,
        address _accountant,
        address[] memory _knownMiners
    ) {
        _setupRole(TIPJAR_ADMIN_ROLE, _tipJarAdmin);
        _setupRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
        networkFeeCollector = _networkFeeCollector;
        networkFee = _networkFee;
        accountant = _accountant;
        for(uint i = 0; i < _knownMiners.length; i++) {
            knownMiners.add(_knownMiners[i]);
        }
    }

    /// @notice Receive function to allow contract to accept ETH
    receive() external payable {}

    /**
     * @notice Distributes any ETH in contract to relevant parties
     */
    function collect() external {
        if (networkFee > 0) {
            uint256 fee = address(this).balance.mul(networkFee).div(1000000);
            (bool success, ) = networkFeeCollector.call{value: fee}("");
            require(success, "Could not collect fee");
        }

        if(knownMiners.contains(block.coinbase)) {
            (bool success, ) = accountant.call{value: address(this).balance}("");
            require(success, "Could not collect ETH");
        } else {
            (bool success, ) = block.coinbase.call{value: address(this).balance}("");
            require(success, "Could not collect ETH");
        }
    }

    // TODO: determine if should make public getter methods + events for miner address set

    /**
     * @notice Admin function to add miners to known miners set
     * @param miners Array of miner addresses
     */
    function addKnownMiners(address[] memory miners) external onlyAdmin {
        for(uint i = 0; i < miners.length; i++) {
            knownMiners.add(miners[i]);
        }   
    }

    /**
     * @notice Admin function to remove miners from known miners set
     * @param miners Array of miner addresses
     */
    function removeKnownMiners(address[] memory miners) external onlyAdmin {
        for(uint i = 0; i < miners.length; i++) {
            knownMiners.remove(miners[i]);
        }   
    }

    /**
     * @notice Determine whether a given address is a known miner
     * @param miner Miner address
     * @return true if miner is known 
     */
    function isKnownMiner(address miner) external view returns (bool) {
        return knownMiners.contains(miner);
    }

    /**
     * @notice Admin function to set network fee
     * @param newFee new fee
     */
    function setFee(uint32 newFee) external onlyAdmin {
        networkFee = newFee;
    }

    /**
     * @notice Admin function to set fee collector address
     * @param newCollector new fee collector address
     */
    function setFeeCollector(address newCollector) external onlyAdmin {
        networkFeeCollector = newCollector;
    }

    /**
     * @notice Admin function to set accountant address
     * @param newAccountant new accountant address
     */
    function setAccountant(address newAccountant) external onlyAdmin {
        accountant = newAccountant;
    }
}