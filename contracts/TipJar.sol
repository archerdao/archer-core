// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
  Copyright 2021 Archer DAO: Chris Piatt (chris@archerdao.io).
*/

import "./lib/0.8/AccessControlUpgradeable.sol";
import "./lib/0.8/CheckAndSend.sol";

/**
 * @title TipJar
 * @dev Allows suppliers to create a tip that gets distributed to miners + the network
 */
contract TipJar is AccessControlUpgradeable, CheckAndSend {

    /// @notice TipJar Admin role
    bytes32 public constant TIP_JAR_ADMIN_ROLE = keccak256("TIP_JAR_ADMIN_ROLE");

    /// @notice Miner manager role
    bytes32 public constant MINER_MANAGER_ROLE = keccak256("MINER_MANAGER_ROLE");

    /// @notice Fee setter role
    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");

    /// @notice Network fee (measured in bips: 10,000 bips = 1% of contract balance)
    uint32 public networkFee;

    /// @notice Network fee output address
    address public networkFeeCollector;

    /// @notice Miner split
    struct Split {
        address splitTo;
        uint32 splitPct;
    }

    /// @notice Miner split mapping
    mapping (address => Split) public minerSplits;

    /// @notice Fee set event
    event FeeSet(uint32 indexed newFee, uint32 indexed oldFee);

    /// @notice Fee collector set event
    event FeeCollectorSet(address indexed newCollector, address indexed oldCollector);

    /// @notice Miner split updated event
    event MinerSplitUpdated(address indexed miner, address indexed newSplitTo, address indexed oldSplitTo, uint32 newSplit, uint32 oldSplit);

    /// @notice modifier to restrict functions to admins
    modifier onlyAdmin() {
        require(hasRole(TIP_JAR_ADMIN_ROLE, msg.sender), "Caller must have TIP_JAR_ADMIN_ROLE role");
        _;
    }

    /// @notice modifier to restrict functions to miner managers
    modifier onlyMinerManager(address miner) {
        require(msg.sender == miner || hasRole(MINER_MANAGER_ROLE, msg.sender), "Caller must have MINER_MANAGER_ROLE role");
        _;
    }

    /// @notice modifier to restrict functions to fee setters
    modifier onlyFeeSetter() {
        require(hasRole(FEE_SETTER_ROLE, msg.sender), "Caller must have FEE_SETTER_ROLE role");
        _;
    }

    /// @notice Initializes contract, setting admin roles + network fee
    /// @param _roleAdmin admin in control of roles
    /// @param _tipJarAdmin admin of tip pool
    /// @param _minerManager miner manager address
    /// @param _feeSetter fee setter address
    /// @param _networkFeeCollector address that collects network fees
    /// @param _networkFee % of fee collected by the network
    function initialize(
        address _roleAdmin,
        address _tipJarAdmin,
        address _minerManager,
        address _feeSetter,
        address _networkFeeCollector,
        uint32 _networkFee
    ) public initializer {
        _setupRole(TIP_JAR_ADMIN_ROLE, _tipJarAdmin);
        _setupRole(MINER_MANAGER_ROLE, _minerManager);
        _setupRole(FEE_SETTER_ROLE, _feeSetter);
        _setupRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
        networkFeeCollector = _networkFeeCollector;
        emit FeeCollectorSet(_networkFeeCollector, address(0));
        networkFee = _networkFee;
        emit FeeSet(_networkFee, 0);
    }

    /// @notice Receive function to allow contract to accept ETH
    receive() external payable {}

    /// @notice Fallback function to allow contract to accept ETH
    fallback() external payable {}

    function check32BytesAndSend(
        address _target,
        bytes calldata _payload,
        bytes32 _resultMatch
    ) external payable {
        _check32Bytes(_target, _payload, _resultMatch);
    }

    function check32BytesAndTip(
        address _target,
        bytes calldata _payload,
        bytes32 _resultMatch
    ) external payable {
        _check32Bytes(_target, _payload, _resultMatch);
        tip();
    }

    function check32BytesAndSendMulti(
        address[] calldata _targets,
        bytes[] calldata _payloads,
        bytes32[] calldata _resultMatches
    ) external payable {
        _check32BytesMulti(_targets, _payloads, _resultMatches);
    }

    function check32BytesAndTipMulti(
        address[] calldata _targets,
        bytes[] calldata _payloads,
        bytes32[] calldata _resultMatches
    ) external payable {
        _check32BytesMulti(_targets, _payloads, _resultMatches);
        tip();
    }

    function checkBytesAndSend(
        address _target,
        bytes calldata _payload,
        bytes calldata _resultMatch
    ) external payable {
        _checkBytes(_target, _payload, _resultMatch);
    }

    function checkBytesAndTip(
        address _target,
        bytes calldata _payload,
        bytes calldata _resultMatch
    ) external payable {
        _checkBytes(_target, _payload, _resultMatch);
        tip();
    }

    function checkBytesAndSendMulti(
        address[] calldata _targets,
        bytes[] calldata _payloads,
        bytes[] calldata _resultMatches
    ) external payable {
        _checkBytesMulti(_targets, _payloads, _resultMatches);
    }

    function checkBytesAndTipMulti(
        address[] calldata _targets,
        bytes[] calldata _payloads,
        bytes[] calldata _resultMatches
    ) external payable {
        _checkBytesMulti(_targets, _payloads, _resultMatches);
        tip();
    }

    /**
     * @notice Distributes any ETH in contract to relevant parties
     */
    function tip() public payable {
        if (networkFee > 0) {
            uint256 fee = (address(this).balance * networkFee) / 1000000;
            (bool feeSuccess, ) = networkFeeCollector.call{value: fee}("");
            require(feeSuccess, "Could not collect fee");
        }

        if(minerSplits[block.coinbase].splitPct > 0) {
            uint256 split = (address(this).balance * minerSplits[block.coinbase].splitPct) / 1000000;
            (bool splitSuccess, ) = minerSplits[block.coinbase].splitTo.call{value: split}("");
            require(splitSuccess, "Could not split");
        }

        if (address(this).balance > 0) {
            (bool success, ) = block.coinbase.call{value: address(this).balance}("");
            require(success, "Could not collect ETH");
        }
    }

    /**
     * @notice Admin function to set network fee
     * @param newFee new fee
     */
    function setFee(uint32 newFee) external onlyFeeSetter {
        require(newFee <= 1000000, ">100%");
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

    /**
     * @notice Update split % and split to address for given miner
     * @param minerAddress Address of miner
     * @param splitTo Address that receives split
     * @param splitPct % of tip that splitTo receives
     */
    function updateMinerSplit(
        address minerAddress, 
        address splitTo, 
        uint32 splitPct
    ) external onlyMinerManager(minerAddress) {
        Split memory oldSplit = minerSplits[minerAddress];
        address oldSplitTo = oldSplit.splitTo;
        uint32 oldSplitPct = oldSplit.splitPct;
        minerSplits[minerAddress] = Split({
            splitTo: splitTo,
            splitPct: splitPct
        });
        emit MinerSplitUpdated(minerAddress, splitTo, oldSplitTo, splitPct, oldSplitPct);
    }
}