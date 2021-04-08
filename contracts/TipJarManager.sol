// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
  Copyright 2021 Archer DAO: Chris Piatt (chris@archerdao.io).
*/

import "./interfaces/ITimelockController.sol";
import "./lib/0.8/Initializable.sol";

/**
 * @title TipJarManager
 * @dev Responsible for enacting decisions related to sensitive TipJar parameters
 * Decisions are made via a timelock contract
 */
contract TipJarManager is Initializable {

    /// @notice TipJarManager admin
    address public admin;

    /// @notice Delay for critical changes
    uint256 public criticalDelay;

    /// @notice Delay for non-critical changes
    uint256 public regularDelay;

    /// @notice TipJarProxy address
    address public tipJar;

    /// @notice Timelock contract
    ITimelockController public timelock;

    /// @notice Admin modifier
    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    /// @notice Timelock modifier
    modifier onlyTimelock() {
        require(msg.sender == address(timelock), "not timelock");
        _;
    }

    /// @notice Miner Split Proposal event
    event MinerSplitProposal(address indexed proposer, address indexed miner, address indexed splitTo, uint32 splitPct, uint256 eta, bytes32 proposalID, bytes32 salt);

    /// @notice Miner Split Approval event
    event MinerSplitApproval(address indexed approver, address indexed miner, address indexed splitTo, uint32 splitPct);

    /// @notice Fee Proposal event
    event FeeProposal(address indexed proposer, uint32 newFee, uint256 eta, bytes32 proposalID, bytes32 salt);

    /// @notice Fee Approval event
    event FeeApproval(address indexed approver, uint32 newFee);

    /// @notice Fee Collector Proposal event
    event FeeCollectorProposal(address indexed proposer, address indexed newCollector, uint256 eta, bytes32 proposalID, bytes32 salt);

    /// @notice Fee Collector Approval event
    event FeeCollectorApproval(address indexed approver, address indexed newCollector);

    /// @notice New admin event
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    /// @notice New delay event
    event DelayChanged(string indexed delayType, uint256 indexed oldDelay, uint256 indexed newDelay);

    /// @notice New timelock event
    event TimelockChanged(address indexed oldTimelock, address indexed newTimelock);

    /// @notice New tip jar event
    event TipJarChanged(address indexed oldTipJar, address indexed newTipJar);

    /// @notice Receive function to allow contract to accept ETH
    receive() external payable {}

    /// @notice Fallback function to allow contract to accept ETH
    fallback() external payable {}

    /**
     * @notice Construct new TipJarManager contract, setting msg.sender as admin
     */
    constructor() {
        admin = msg.sender;
        emit AdminChanged(address(0), msg.sender);
    }

    /**
     * @notice Initialize contract
     * @param _tipJar TipJar proxy contract address
     * @param _admin Admin address
     * @param _timelock TimelockController contract address
     */
    function initialize(
        address _tipJar,
        address _admin,
        address payable _timelock,
        uint256 _criticalDelay,
        uint256 _regularDelay
    ) external initializer onlyAdmin {
        emit AdminChanged(admin, _admin);
        admin = _admin;

        tipJar = _tipJar;
        emit TipJarChanged(address(0), _tipJar);
        
        timelock = ITimelockController(_timelock);
        emit TimelockChanged(address(0), _timelock);

        criticalDelay = _criticalDelay;
        emit DelayChanged("critical", 0, _criticalDelay);

        regularDelay = _regularDelay;
        emit DelayChanged("regular", 0, _regularDelay);
    }

    /**
     * @notice Propose a new miner split
     * @param minerAddress Address of miner
     * @param splitTo Address that receives split
     * @param splitPct % of tip that splitTo receives
     * @param salt salt
     */
    function proposeNewMinerSplit(
        address minerAddress,
        address splitTo,
        uint32 splitPct,
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("updateMinerSplit(address,address,uint32)")) = 0x8d916340
        bytes32 id = _schedule(tipJar, 0, abi.encodeWithSelector(hex"8d916340", minerAddress, splitTo, splitPct), bytes32(0), salt, regularDelay);
        emit MinerSplitProposal(msg.sender, minerAddress, splitTo, splitPct, block.timestamp + regularDelay, id, salt);
    }

    /**
     * @notice Approve a new miner split
     * @param minerAddress Address of miner
     * @param splitTo Address that receives split
     * @param splitPct % of tip that splitTo receives
     * @param salt salt
     */
    function approveNewMinerSplit(
        address minerAddress,
        address splitTo,
        uint32 splitPct,
        bytes32 salt
    ) external {
        // bytes4(keccak256("updateMinerSplit(address,address,uint32)")) = 0x8d916340
        _execute(tipJar, 0, abi.encodeWithSelector(hex"8d916340", minerAddress, splitTo, splitPct), bytes32(0), salt);
        emit MinerSplitApproval(msg.sender, minerAddress, splitTo, splitPct);
    }

    /**
     * @notice Propose a new network fee
     * @param newFee New fee
     * @param salt salt
     */
    function proposeNewFee(
        uint32 newFee, 
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("setFee(uint32)")) = 0x1ab971ab
        bytes32 id = _schedule(tipJar, 0, abi.encodeWithSelector(hex"1ab971ab", newFee), bytes32(0), salt, criticalDelay);
        emit FeeProposal(msg.sender, newFee, block.timestamp + regularDelay, id, salt);
    }

    /**
     * @notice Approve a new network fee
     * @param newFee New fee
     * @param salt salt
     */
    function approveNewFee(
        uint32 newFee, 
        bytes32 salt
    ) external {
        // bytes4(keccak256("setFee(uint32)")) = 0x1ab971ab
        _execute(tipJar, 0, abi.encodeWithSelector(hex"1ab971ab", newFee), bytes32(0), salt);
        emit FeeApproval(msg.sender, newFee);
    }

    /**
     * @notice Propose a new fee collector
     * @param newFeeCollector New fee collector
     * @param salt salt
     */
    function proposeNewFeeCollector(
        address newFeeCollector, 
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("setFeeCollector(address)")) = 0xa42dce80
        bytes32 id = _schedule(tipJar, 0, abi.encodeWithSelector(hex"a42dce80", newFeeCollector), bytes32(0), salt, criticalDelay);
        emit FeeCollectorProposal(msg.sender, newFeeCollector, block.timestamp + regularDelay, id, salt);
    }

    /**
     * @notice Approve a new fee collector
     * @param newFeeCollector New fee collector
     * @param salt salt
     */
    function approveNewFeeCollector(
        address newFeeCollector, 
        bytes32 salt
    ) external {
        // bytes4(keccak256("setFeeCollector(address)")) = 0xa42dce80
        _execute(tipJar, 0, abi.encodeWithSelector(hex"a42dce80", newFeeCollector), bytes32(0), salt);
        emit FeeCollectorApproval(msg.sender, newFeeCollector);
    }

    /**
     * @notice Propose new admin for this contract
     * @param newAdmin new admin address
     * @param salt salt
     */
    function proposeNewAdmin(
        address newAdmin,
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("setAdmin(address)")) = 0x704b6c02
        _schedule(address(this), 0, abi.encodeWithSelector(hex"704b6c02", newAdmin), bytes32(0), salt, criticalDelay);
    }

    /**
     * @notice Approve new admin for this contract
     * @param newAdmin new admin address
     * @param salt salt
     */
    function approveNewAdmin(
        address newAdmin,
        bytes32 salt
    ) external {
        // bytes4(keccak256("setAdmin(address)")) = 0x704b6c02
        _execute(address(this), 0, abi.encodeWithSelector(hex"704b6c02", newAdmin), bytes32(0), salt);
    }

    /**
     * @notice Set new admin for this contract
     * @dev Can only be executed by Timelock contract
     * @param newAdmin new admin address
     */
    function setAdmin(
        address newAdmin
    ) external onlyTimelock {
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    /**
     * @notice Propose new critical delay for this contract
     * @param newDelay new delay time
     * @param salt salt
     */
    function proposeNewCriticalDelay(
        uint256 newDelay,
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("setCriticalDelay(uint256)")) = 0xdad8a096
        _schedule(address(this), 0, abi.encodeWithSelector(hex"dad8a096", newDelay), bytes32(0), salt, criticalDelay);
    }

    /**
     * @notice Approve new critical delay for this contract
     * @param newDelay new delay time
     * @param salt salt
     */
    function approveNewCriticalDelay(
        uint256 newDelay,
        bytes32 salt
    ) external {
        // bytes4(keccak256("setCriticalDelay(uint256)")) = 0xdad8a096
        _execute(address(this), 0, abi.encodeWithSelector(hex"dad8a096", newDelay), bytes32(0), salt);
    }

    /**
     * @notice Set new critical delay for this contract
     * @dev Can only be executed by Timelock contract
     * @param newDelay new delay time
     */
    function setCriticalDelay(
        uint256 newDelay
    ) external onlyTimelock {
        emit DelayChanged("critical", criticalDelay, newDelay);
        criticalDelay = newDelay;
    }

    /**
     * @notice Propose new regular delay for this contract
     * @param newDelay new delay time
     * @param salt salt
     */
    function proposeNewRegularDelay(
        uint256 newDelay,
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("setRegularDelay(uint256)")) = 0x8023dc81
        _schedule(address(this), 0, abi.encodeWithSelector(hex"8023dc81", newDelay), bytes32(0), salt, criticalDelay);
    }

    /**
     * @notice Approve new regular delay for this contract
     * @param newDelay new delay time
     * @param salt salt
     */
    function approveNewRegularDelay(
        uint256 newDelay,
        bytes32 salt
    ) external {
        // bytes4(keccak256("setRegularDelay(uint256)")) = 0x8023dc81
        _execute(address(this), 0, abi.encodeWithSelector(hex"8023dc81", newDelay), bytes32(0), salt);
    }

    /**
     * @notice Set new regular delay for this contract
     * @dev Can only be executed by Timelock contract
     * @param newDelay new delay time
     */
    function setRegularDelay(
        uint256 newDelay
    ) external onlyTimelock {
        emit DelayChanged("regular", regularDelay, newDelay);
        regularDelay = newDelay;
    }

    /**
     * @notice Propose new tip jar contract
     * @param newTipJar new tip jar address
     * @param salt salt
     */
    function proposeNewTipJar(
        address newTipJar,
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("setTipJar(address)")) = 0x5c66e3da
        _schedule(address(this), 0, abi.encodeWithSelector(hex"5c66e3da", newTipJar), bytes32(0), salt, criticalDelay);
    }

    /**
     * @notice Approve new tip jar contract
     * @param newTipJar new tip jar address
     * @param salt salt
     */
    function approveNewTipJar(
        address newTipJar,
        bytes32 salt
    ) external {
        // bytes4(keccak256("setTipJar(address)")) = 0x5c66e3da
        _execute(address(this), 0, abi.encodeWithSelector(hex"5c66e3da", newTipJar), bytes32(0), salt);
    }

    /**
     * @notice Set new tip jar contract
     * @dev Can only be executed by Timelock contract
     * @param newTipJar new tip jar address
     */
    function setTipJar(
        address newTipJar
    ) external onlyTimelock {
        emit TipJarChanged(tipJar, newTipJar);
        tipJar = newTipJar;
    }

    /**
     * @notice Propose new timelock contract
     * @param newTimelock new timelock address
     * @param salt salt
     */
    function proposeNewTimelock(
        address newTimelock,
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("setTimelock(address)")) = 0xbdacb303
        _schedule(address(this), 0, abi.encodeWithSelector(hex"bdacb303", newTimelock), bytes32(0), salt, criticalDelay);
    }

    /**
     * @notice Approve new timelock contract
     * @param newTimelock new timelock address
     * @param salt salt
     */
    function approveNewTimelock(
        address newTimelock,
        bytes32 salt
    ) external {
        // bytes4(keccak256("setTimelock(address)")) = 0xbdacb303
        _execute(address(this), 0, abi.encodeWithSelector(hex"bdacb303", newTimelock), bytes32(0), salt);
    }

    /**
     * @notice Set new timelock contract
     * @dev Can only be executed by Timelock contract or anyone if timelock has not yet been set
     * @param newTimelock new timelock address
     */
    function setTimelock(
        address payable newTimelock
    ) external onlyTimelock {
        emit TimelockChanged(address(timelock), newTimelock);
        timelock = ITimelockController(newTimelock);
    }

    /**
     * @notice Public getter for TipJar Proxy implementation contract address
     */
    function getProxyImplementation() public view returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = tipJar.staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @notice Public getter for TipJar Proxy admin address
     */
    function getProxyAdmin() public view returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = tipJar.staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @notice Propose new admin for TipJar proxy contract
     * @param newAdmin new admin address
     * @param salt salt
     */
    function proposeNewProxyAdmin(
        address newAdmin,
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("changeAdmin(address)")) = 0x8f283970
        _schedule(tipJar, 0, abi.encodeWithSelector(hex"8f283970", newAdmin), bytes32(0), salt, criticalDelay);
    }

    /**
     * @notice Approve new admin for TipJar proxy contract
     * @param newAdmin new admin address
     * @param salt salt
     */
    function approveNewProxyAdmin(
        address newAdmin,
        bytes32 salt
    ) external {
        // bytes4(keccak256("changeAdmin(address)")) = 0x8f283970
        _execute(tipJar, 0, abi.encodeWithSelector(hex"8f283970", newAdmin), bytes32(0), salt);
    }

    /**
     * @notice Propose new implementation for TipJar proxy contract
     * @param newImplementation new implementation address
     * @param salt salt
     */
    function proposeUpgrade(
        address newImplementation,
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("upgradeTo(address)")) = 0x3659cfe6
        _schedule(tipJar, 0, abi.encodeWithSelector(hex"3659cfe6", newImplementation), bytes32(0), salt, criticalDelay);
    }

    /**
     * @notice Approve new implementation for TipJar proxy
     * @param newImplementation new implementation address
     * @param salt salt
     */
    function approveUpgrade(
        address newImplementation,
        bytes32 salt
    ) external {
        // bytes4(keccak256("upgradeTo(address)")) = 0x3659cfe6
        _execute(tipJar, 0, abi.encodeWithSelector(hex"3659cfe6", newImplementation), bytes32(0), salt);
    }

    /**
     * @notice Propose new implementation for TipJar proxy contract + call function after
     * @param newImplementation new implementation address
     * @param data Bytes-encoded function to call
     * @param value Amount of ETH to send on call
     * @param salt salt
     */
    function proposeUpgradeAndCall(
        address newImplementation,
        bytes memory data,
        uint256 value,
        bytes32 salt
    ) external onlyAdmin {
        // bytes4(keccak256("upgradeToAndCall(address,bytes)")) = 0x4f1ef286
        _schedule(tipJar, value, abi.encodeWithSelector(hex"4f1ef286", newImplementation, data), bytes32(0), salt, criticalDelay);
    }

    /**
     * @notice Approve new implementation for TipJar proxy + call function after
     * @param newImplementation new implementation address
     * @param data Bytes-encoded function to call
     * @param value Amount of ETH to send on call
     * @param salt salt
     */
    function approveUpgradeAndCall(
        address newImplementation,
        bytes memory data,
        uint256 value,
        bytes32 salt
    ) external payable {
        // bytes4(keccak256("upgradeToAndCall(address,bytes)")) = 0x4f1ef286
        _execute(tipJar, value, abi.encodeWithSelector(hex"4f1ef286", newImplementation, data), bytes32(0), salt);
    }

    /**
     * @notice Create proposal
     * @param target target address
     * @param value ETH value
     * @param data function call bytes
     * @param predecessor predecessor function call
     * @param salt salt used in proposal
     */
    function createProposal(
        address target, 
        uint256 value, 
        bytes memory data, 
        bytes32 predecessor, 
        bytes32 salt
    ) external onlyAdmin {
        _schedule(target, value, data, predecessor, salt, criticalDelay);
    }

    /**
     * @notice Create batch proposal
     * @param targets target address
     * @param values ETH value
     * @param datas function call bytes
     * @param predecessor predecessor function call
     * @param salt salt used in proposal
     */
    function createProposalBatch(
        address[] calldata targets, 
        uint256[] calldata values, 
        bytes[] calldata datas, 
        bytes32 predecessor, 
        bytes32 salt
    ) external onlyAdmin {
        timelock.scheduleBatch(targets, values, datas, predecessor, salt, criticalDelay);
    }

    /**
     * @notice Execute proposal
     * @param target target address
     * @param value ETH value
     * @param data function call bytes
     * @param predecessor predecessor function call
     * @param salt salt used in proposal
     */
    function executeProposal(
        address target, 
        uint256 value, 
        bytes memory data, 
        bytes32 predecessor, 
        bytes32 salt
    ) external payable onlyAdmin {
        _execute(target, value, data, predecessor, salt);
    }

    /**
     * @notice Execute batch proposal
     * @param targets target address
     * @param values ETH value
     * @param datas function call bytes
     * @param predecessor predecessor function call
     * @param salt salt used in proposal
     */
    function executeProposalBatch(
        address[] calldata targets, 
        uint256[] calldata values, 
        bytes[] calldata datas, 
        bytes32 predecessor, 
        bytes32 salt
    ) external payable onlyAdmin {
        timelock.executeBatch{value: msg.value}(targets, values, datas, predecessor, salt);
    }

    /**
     * @notice Cancel proposal
     * @param id ID of proposal
     */
    function cancelProposal(bytes32 id) external onlyAdmin {
        timelock.cancel(id);
    }

    function _schedule(
        address target, 
        uint256 value, 
        bytes memory data, 
        bytes32 predecessor, 
        bytes32 salt, 
        uint256 delay
    ) private returns (bytes32 id) {
        return timelock.schedule(target, value, data, predecessor, salt, delay);
    }

    function _execute(
        address target, 
        uint256 value, 
        bytes memory data, 
        bytes32 predecessor, 
        bytes32 salt
    ) private {
        timelock.execute{value: value}(target, value, data, predecessor, salt);
    }
}
