// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import './lib/SafeMath.sol';

/**
 * @title BankrollToken
 * @dev Token representing share of bankroll for Archer DAO
 * ERC-20 with add-ons to allow for offchain signing
 * See EIP-712, EIP-2612, and EIP-3009 for details
 */
contract BankrollToken {
    using SafeMath for uint256;

    /// @notice EIP-20 token name for this token
    string public constant name = "Archer Bankroll Token";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "ARCH-B";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint256 public totalSupply;

    /// @notice Underlying asset being bankrolled
    address public asset;

    /// @notice Recipient of bankroll
    address public recipient;

    /// @notice Address which may mint/burn tokens
    address public supplyManager;

    /// @notice Official record of token balances for each account
    mapping(address => uint256) public balanceOf;

    /// @notice Allowance amounts on behalf of others
    mapping(address => mapping(address => uint256)) public allowance;

    /// @notice The version number for this token
    uint8 public constant version = 1;

    /// @notice The EIP-712 version hash
    /// keccak256("1");
    bytes32 public constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    // @notice The EIP-712 typehash for the contract's domain
    /// keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 public constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @notice The EIP-712 typehash for permit (EIP-2612)
    /// keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint256) public nonces;

    /// @notice An event that's emitted when the supplyManager address is changed
    event SupplyManagerChanged(address indexed oldManager, address indexed newManager);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlySupplyManager {
        require(msg.sender == supplyManager, "only supply manager");
        _;
    }

    /**
     * @notice Construct a new Arch bankroll token
     * @param _asset Bankroll asset
     * @param _recipient Address receiving the bankroll
     * @param _supplyManager The address with minting/burning ability
     */
    constructor(
        address _asset,
        address _recipient,
        address _supplyManager
    ) {
        asset = _asset;
        recipient = _recipient;
        supplyManager = _supplyManager;
        emit SupplyManagerChanged(address(0), _supplyManager);
    }

    /**
     * @notice Change the supplyManager address
     * @param newSupplyManager The address of the new supply manager
     * @return true if successful
     */
    function setSupplyManager(address newSupplyManager) external onlySupplyManager returns (bool) {
        emit SupplyManagerChanged(supplyManager, newSupplyManager);
        supplyManager = newSupplyManager;
        return true;
    }

    /**
     * @notice Mint new tokens
     * @param dst The address of the destination account
     * @param amount The number of tokens to be minted
     * @return Boolean indicating success of mint
     */
    function mint(address dst, uint256 amount) external onlySupplyManager returns (bool) {
        require(dst != address(0), "ABT::mint: cannot transfer to the zero address");

        // mint the amount
        _mint(dst, amount);
        return true;
    }

    /**
     * @notice Burn tokens
     * @param src The account that will burn tokens
     * @param amount The number of tokens to be burned
     * @return Boolean indicating success of burn
     */
    function burn(address src, uint256 amount) external onlySupplyManager returns (bool) {
        require(src != address(0), "ABT::burn: cannot transfer from the zero address");
        
        // burn the amount
        _burn(src, amount);
        return true;
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     * and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * It is recommended to use increaseAllowance and decreaseAllowance instead
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Increase the allowance by a given amount
     * @param spender Spender's address
     * @param addedValue Amount of increase in allowance
     * @return True if successful
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _increaseAllowance(msg.sender, spender, addedValue);
        return true;
    }

    /**
     * @notice Decrease the allowance by a given amount
     * @param spender Spender's address
     * @param subtractedValue Amount of decrease in allowance
     * @return True if successful
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        _decreaseAllowance(msg.sender, spender, subtractedValue);
        return true;
    }

    /**
     * @notice Triggers an approval from owner to spender
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param value The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, "ABT::permit: signature expired");

        bytes32 encodeData = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        _validateSignedData(owner, encodeData, v, r, s);

        _approve(owner, spender, value);
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowance[src][spender];

        if (spender != src && spenderAllowance != uint256(-1)) {
            uint256 newAllowance = spenderAllowance.sub(
                amount,
                "ABT::transferFrom: transfer amount exceeds allowance"
            );
            allowance[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice EIP-712 Domain separator
     * @return Separator
     */
    function getDomainSeparator() public view returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                VERSION_HASH,
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @notice Recovers address from signed data and validates the signature
     * @param signer Address that signed the data
     * @param encodeData Data signed by the address
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function _validateSignedData(address signer, bytes32 encodeData, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                getDomainSeparator(),
                encodeData
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        // Explicitly disallow authorizations for address(0) as ecrecover returns address(0) on malformed messages
        require(recoveredAddress != address(0) && recoveredAddress == signer, "ABT::validateSig: invalid signature");
    }

    /**
     * @notice Approval implementation
     * @param owner The address of the account which owns tokens
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ABT::_approve: approve from the zero address");
        require(spender != address(0), "ABT::_approve: approve to the zero address");
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _increaseAllowance(
        address owner,
        address spender,
        uint256 addedValue
    ) internal {
        _approve(owner, spender, allowance[owner][spender].add(addedValue));
    }

    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 subtractedValue
    ) internal {
        _approve(
            owner,
            spender,
            allowance[owner][spender].sub(
                subtractedValue,
                "ABT::_decreaseAllowance: decreased allowance below zero"
            )
        );
    }

    /**
     * @notice Transfer implementation
     * @param from The address of the account which owns tokens
     * @param to The address of the account which is receiving tokens
     * @param value The number of tokens that are being transferred
     */
    function _transferTokens(address from, address to, uint256 value) internal {
        require(to != address(0), "ABT::_transferTokens: cannot transfer to the zero address");

        balanceOf[from] = balanceOf[from].sub(
            value,
            "ABT::_transferTokens: transfer exceeds from balance"
        );
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @notice Mint implementation
     * @param to The address of the account which is receiving tokens
     * @param value The number of tokens that are being minted
     */
    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    /**
     * @notice Burn implementation
     * @param from The address of the account which owns tokens
     * @param value The number of tokens that are being burned
     */
    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(
            value,
            "ABT::_burn: burn amount exceeds from balance"
        );
        totalSupply = totalSupply.sub(
            value,
            "ABT::_burn: burn amount exceeds total supply"
        );
        emit Transfer(from, address(0), value);
    }

    /**
     * @notice Current id of the chain where this contract is deployed
     * @return Chain id
     */
    function _getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}