
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IWETH.sol";

/**
 * @title WETH2
 * @dev Wrapped Ether token with add-ons to allow for offchain signing
 * See EIP-712, EIP-2612, and EIP-3009 for details
 */
contract WETH2 {

    /// @notice EIP-20 token name for this token
    string public constant name = "Wrapped Ether v2";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "WETH2";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @dev Allowance amounts on behalf of others
    mapping (address => mapping (address => uint256)) public allowance;

    /// @dev Official record of token balances for each account
    mapping (address => uint256) public balanceOf;

    /// @notice WETH v1
    IWETH public immutable WETH;

    /// @notice The EIP-712 typehash for the contract's domain
    /// keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 public constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    
    /// @notice The EIP-712 version hash
    /// keccak256("1");
    bytes32 public constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    /// @notice The EIP-712 typehash for permit (EIP-2612)
    /// keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice The EIP-712 typehash for transferWithAuthorization (EIP-3009)
    /// keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)");
    bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH = 0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

    /// @notice The EIP-712 typehash for receiveWithAuthorization (EIP-3009)
    /// keccak256("ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    bytes32 public constant RECEIVE_WITH_AUTHORIZATION_TYPEHASH = 0xd099cc98ef71107a616c4f0f941f04c322d8e254fe26b3c6668db87aae413de8;

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @dev authorizer address > nonce > state (true = used / false = unused)
    mapping (address => mapping (bytes32 => bool)) public authorizationState;

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice An event that's emitted whenever an authorized transfer occurs
    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);

    /// @notice Deposit event
    event Deposit(address indexed depositor, address indexed receiver, uint256 amount);

    /// @notice Withdrawal event
    event Withdrawal(address indexed withdrawer, uint256 amount);

    /// @notice Receive function to allow contract to accept ETH deposits directly
    receive() external payable {
        _depositTo(msg.sender, msg.value);
    }

    /// @notice Fallback function to allow contract to accept ETH deposits directly
    fallback() external payable {
        _depositTo(msg.sender, msg.value);
    }

    /**
     * @notice Create WETH2
     * @param _weth WETH v1 address
     */
    constructor(IWETH _weth) {
        WETH = _weth;
    }

    /**
     * @notice Deposit ETH to contract and receive WETH2 in return
     */
    function deposit() external payable {
        _depositTo(msg.sender, msg.value);
    }

    /**
     * @notice Deposit ETH to contract and send WETH2 to `receiver` in return
     * @param receiver Account to receive WETH2
     */
    function depositTo(address receiver) external payable {
        _depositTo(receiver, msg.value);
    }

    /**
     * @notice Deposit WETH to contract and receive WETH2 in return
     * @param amount Amount of WETH
     */
    function depositWETH(uint256 amount) external {
        WETH.transferFrom(msg.sender, address(this), amount);
        WETH.withdraw(amount);
        _depositTo(msg.sender, amount);
    }

    /**
     * @notice Deposit WETH to contract and send WETH2 to `receiver` in return
     * @param receiver Account to receive WETH2
     * @param amount Amount of WETH
     */
    function depositWETHTo(address receiver, uint256 amount) external {
        WETH.transferFrom(msg.sender, address(this), amount);
        WETH.withdraw(amount);
        _depositTo(receiver, amount);
    }

    /**
     * @notice Withdraw ETH from contract
     * @param amount Amount of WETH2
     */
    function withdraw(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "W2::withdraw: amount > balance");
        balanceOf[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "W2::withdraw: could not withdraw ETH");
        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @notice Total supply of WETH2
     * @return Total supply
     */
    function totalSupply() external view returns (uint256) {
        return address(this).balance;
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
        require(deadline >= block.timestamp, "W2::permit: signature expired");

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

        if (spender != src && spenderAllowance != type(uint256).max) {
            uint256 newAllowance = spenderAllowance - amount;
            allowance[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Transfer tokens with a signed authorization
     * @param from Payer's address (Authorizer)
     * @param to Payee's address
     * @param value Amount to be transferred
     * @param validAfter The time after which this is valid (unix time)
     * @param validBefore The time before which this is valid (unix time)
     * @param nonce Unique nonce
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        require(block.timestamp > validAfter, "W2::transferWithAuth: auth not yet valid");
        require(block.timestamp < validBefore, "W2::transferWithAuth: auth expired");
        require(!authorizationState[from][nonce],  "W2::transferWithAuth: auth already used");

        bytes32 encodeData = keccak256(abi.encode(TRANSFER_WITH_AUTHORIZATION_TYPEHASH, from, to, value, validAfter, validBefore, nonce));
        _validateSignedData(from, encodeData, v, r, s);

        authorizationState[from][nonce] = true;
        emit AuthorizationUsed(from, nonce);

        _transferTokens(from, to, value);
    }

    /**
     * @notice Receive a transfer with a signed authorization from the payer
     * @dev This has an additional check to ensure that the payee's address matches
     * the caller of this function to prevent front-running attacks.
     * @param from Payer's address (Authorizer)
     * @param to Payee's address
     * @param value Amount to be transferred
     * @param validAfter The time after which this is valid (unix time)
     * @param validBefore The time before which this is valid (unix time)
     * @param nonce Unique nonce
     * @param v v of the signature
     * @param r r of the signature
     * @param s s of the signature
     */
    function receiveWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(to == msg.sender, "W2::receiveWithAuth: caller must be the payee");
        require(block.timestamp > validAfter, "W2::receiveWithAuth: auth not yet valid");
        require(block.timestamp < validBefore, "W2::receiveWithAuth: auth expired");
        require(!authorizationState[from][nonce],  "W2::receiveWithAuth: auth already used");

        bytes32 encodeData = keccak256(abi.encode(RECEIVE_WITH_AUTHORIZATION_TYPEHASH, from, to, value, validAfter, validBefore, nonce));
        _validateSignedData(from, encodeData, v, r, s);

        authorizationState[from][nonce] = true;
        emit AuthorizationUsed(from, nonce);

        _transferTokens(from, to, value);
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
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @notice Internal implementation of deposit
     * @param receiver Address of receiver
     * @param amount Amount to deposit
     */
    function _depositTo(address receiver, uint256 amount) internal {
        balanceOf[receiver] += amount;
        emit Deposit(msg.sender, receiver, amount);
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
        require(recoveredAddress != address(0) && recoveredAddress == signer, "W2::validateSig: invalid signature");
    }

    /**
     * @notice Approval implementation
     * @param owner The address of the account which owns tokens
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _increaseAllowance(
        address owner,
        address spender,
        uint256 addedValue
    ) internal {
        _approve(owner, spender, allowance[owner][spender] + addedValue);
    }

    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 subtractedValue
    ) internal {
        _approve(
            owner,
            spender,
            allowance[owner][spender] - subtractedValue
        );
    }

    /**
     * @notice Transfer implementation
     * @param from The address of the account which owns tokens
     * @param to The address of the account which is receiving tokens
     * @param value The number of tokens that are being transferred
     */
    function _transferTokens(address from, address to, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }
}