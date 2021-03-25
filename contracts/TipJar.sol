// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./interfaces/ITipPool.sol";
import "./lib/AccessControl.sol";

/**
 * @title TipJar
 * @dev Deposits tips into tip pool
 */
contract TipJar is AccessControl {

    /// @notice TipJar Admin role
    bytes32 public constant TIPJAR_ADMIN_ROLE = keccak256("TIPJAR_ADMIN_ROLE");

    /// @notice TipPool address
    ITipPool public tipPool;

    /// @notice modifier to restrict functions to admins
    modifier onlyAdmin() {
        require(hasRole(TIPJAR_ADMIN_ROLE, msg.sender), "Caller must have TIPJAR_ADMIN_ROLE role");
        _;
    }

    /// @notice Initializes contract, setting admin roles + network fee
    /// @param _roleAdmin admin in control of roles
    /// @param _tipJarAdmin admin of tipJar
    /// @param _tipPool tip pool address
    constructor(
        address _roleAdmin,
        address _tipJarAdmin,
        address _tipPool
    ) {
        _setupRole(TIPJAR_ADMIN_ROLE, _tipJarAdmin);
        _setupRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
        tipPool = ITipPool(_tipPool);
    }

    /// @notice Receive function to allow contract to accept ETH
    receive() external payable {
        tip();
    }

    /// @notice Fallback function
    fallback() external payable {
        tip();
    }

    /**
     * @notice Collect tips from tip pool
     */
    function collect() public {
        tipPool.collect();
    }

    /**
     * @notice Check that pool is not empty, then collect
     */
    function checkBalanceThenCollect() external {
        if(checkBalance(address(tipPool), 1)) {
            collect();
        }
    }

    /// @notice Send ETH as tip to tip jar
    function tip() public payable {
        (bool success, ) = address(tipPool).call{value: msg.value}("");
        require(success, "Could not send tip");
    }

    /**
     * @notice Check that address meets minimum balance requirement before sending tip
     * @param addressToCheck address to check
     * @param minBalance minimum balance
     */
    function checkBalanceThenTip(address addressToCheck, uint256 minBalance) external payable {
        require(checkBalance(addressToCheck, minBalance), "address balance < minimum");
        tip();
    }

    /**
     * @notice Check that address balance >= minimum specified
     * @param addressToCheck address to check
     * @param minBalance minimum balance
     */
    function checkBalance(address addressToCheck, uint256 minBalance) public view returns (bool) {
        return addressToCheck.balance >= minBalance;
    }

    /**
     * @notice Admin function to set tip pool address
     * @param newTipPool new tip pool address
     */
    function setTipPool(address newTipPool) external onlyAdmin {
        tipPool = ITipPool(newTipPool);
    }
}