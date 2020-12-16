## `Dispatcher`

# Functions:

- [`constructor(uint8 _version, address _queryEngine, address _roleManager, address _lpManager, address _withdrawer, address _trader, address _approver, uint256 _initialMaxLiquidity, address[] _lpWhitelist)`](#Dispatcher-constructor-uint8-address-address-address-address-address-address-uint256-address---)

- [`receive()`](#Dispatcher-receive--)

- [`fallback()`](#Dispatcher-fallback--)

- [`isApprover(address addressToCheck)`](#Dispatcher-isApprover-address-)

- [`isWithdrawer(address addressToCheck)`](#Dispatcher-isWithdrawer-address-)

- [`isLPManager(address addressToCheck)`](#Dispatcher-isLPManager-address-)

- [`isWhitelistedLP(address addressToCheck)`](#Dispatcher-isWhitelistedLP-address-)

- [`tokenAllowAll(address[] tokensToApprove, address spender)`](#Dispatcher-tokenAllowAll-address---address-)

- [`tokenAllow(address[] tokensToApprove, uint256[] approvalAmounts, address spender)`](#Dispatcher-tokenAllow-address---uint256---address-)

- [`rescueTokens(address[] tokens, uint256 amount)`](#Dispatcher-rescueTokens-address---uint256-)

- [`setMaxETHLiquidity(uint256 newMax)`](#Dispatcher-setMaxETHLiquidity-uint256-)

- [`provideETHLiquidity()`](#Dispatcher-provideETHLiquidity--)

- [`removeETHLiquidity(uint256 amount)`](#Dispatcher-removeETHLiquidity-uint256-)

- [`withdrawEth(uint256 amount)`](#Dispatcher-withdrawEth-uint256-)

- [`estimateQueryCost(bytes script, uint256[] inputLocations)`](#Dispatcher-estimateQueryCost-bytes-uint256---)

# Events:

- [`MaxLiquidityUpdated(address asset, uint256 newAmount, uint256 oldAmount)`](#Dispatcher-MaxLiquidityUpdated-address-uint256-uint256-)

- [`LiquidityProvided(address asset, address provider, uint256 amount)`](#Dispatcher-LiquidityProvided-address-address-uint256-)

- [`LiquidityRemoved(address asset, address provider, uint256 amount)`](#Dispatcher-LiquidityRemoved-address-address-uint256-)

# Function `constructor(uint8 _version, address _queryEngine, address _roleManager, address _lpManager, address _withdrawer, address _trader, address _approver, uint256 _initialMaxLiquidity, address[] _lpWhitelist)` {#Dispatcher-constructor-uint8-address-address-address-address-address-address-uint256-address---}

Initializes contract, setting up initial contract permissions

## Parameters:

- `_version`: Version number of Dispatcher

- `_queryEngine`: Address of query engine contract

- `_roleManager`: Address allowed to manage contract roles

- `_lpManager`: Address allowed to manage LP whitelist

- `_withdrawer`: Address allowed to withdraw profit from contract

- `_trader`: Address allowed to make trades via this contract

- `_approver`: Address allowed to make approvals via this contract

- `_initialMaxLiquidity`: Initial max liquidity allowed in contract

- `_lpWhitelist`: list of addresses that are allowed to provide liquidity to this contract

# Function `receive()` {#Dispatcher-receive--}

Receive function to allow contract to accept ETH

# Function `fallback()` {#Dispatcher-fallback--}

Fallback function in case receive function is not matched

# Function `isApprover(address addressToCheck) → bool` {#Dispatcher-isApprover-address-}

Returns true if given address is on the list of approvers

## Parameters:

- `addressToCheck`: the address to check

## Return Values:

- true if address is approver

# Function `isWithdrawer(address addressToCheck) → bool` {#Dispatcher-isWithdrawer-address-}

Returns true if given address is on the list of approved withdrawers

## Parameters:

- `addressToCheck`: the address to check

## Return Values:

- true if address is withdrawer

# Function `isLPManager(address addressToCheck) → bool` {#Dispatcher-isLPManager-address-}

Returns true if given address is on the list of LP managers

## Parameters:

- `addressToCheck`: the address to check

## Return Values:

- true if address is LP manager

# Function `isWhitelistedLP(address addressToCheck) → bool` {#Dispatcher-isWhitelistedLP-address-}

Returns true if given address is on the list of whitelisted LPs

## Parameters:

- `addressToCheck`: the address to check

## Return Values:

- true if address is whitelisted

# Function `tokenAllowAll(address[] tokensToApprove, address spender)` {#Dispatcher-tokenAllowAll-address---address-}

Set approvals for external addresses to use Dispatcher contract tokens

## Parameters:

- `tokensToApprove`: the tokens to approve

- `spender`: the address to allow spending of token

# Function `tokenAllow(address[] tokensToApprove, uint256[] approvalAmounts, address spender)` {#Dispatcher-tokenAllow-address---uint256---address-}

Set approvals for external addresses to use Dispatcher contract tokens

## Parameters:

- `tokensToApprove`: the tokens to approve

- `approvalAmounts`: the token approval amounts

- `spender`: the address to allow spending of token

# Function `rescueTokens(address[] tokens, uint256 amount)` {#Dispatcher-rescueTokens-address---uint256-}

Rescue (withdraw) tokens from the smart contract

## Parameters:

- `tokens`: the tokens to withdraw

- `amount`: the amount of each token to withdraw.  If zero, withdraws the maximum allowed amount for each token

# Function `setMaxETHLiquidity(uint256 newMax)` {#Dispatcher-setMaxETHLiquidity-uint256-}

Set max ETH liquidity to accept for this contract

## Parameters:

- `newMax`: new max ETH liquidity

# Function `provideETHLiquidity()` {#Dispatcher-provideETHLiquidity--}

Provide ETH liquidity to Dispatcher

# Function `removeETHLiquidity(uint256 amount)` {#Dispatcher-removeETHLiquidity-uint256-}

Remove ETH liquidity from Dispatcher

## Parameters:

- `amount`: amount of liquidity to remove

# Function `withdrawEth(uint256 amount)` {#Dispatcher-withdrawEth-uint256-}

Withdraw ETH from the smart contract

## Parameters:

- `amount`: the amount of ETH to withdraw.  If zero, withdraws the maximum allowed amount.

# Function `estimateQueryCost(bytes script, uint256[] inputLocations)` {#Dispatcher-estimateQueryCost-bytes-uint256---}

A non-view function to help estimate the cost of a given query in practice

## Parameters:

- `script`: the compiled bytecode for the series of function calls to get the final price

- `inputLocations`: index locations within the script to insert input amounts dynamically

# Event `MaxLiquidityUpdated(address asset, uint256 newAmount, uint256 oldAmount)` {#Dispatcher-MaxLiquidityUpdated-address-uint256-uint256-}

Max liquidity updated event

# Event `LiquidityProvided(address asset, address provider, uint256 amount)` {#Dispatcher-LiquidityProvided-address-address-uint256-}

Liquidity Provided event

# Event `LiquidityRemoved(address asset, address provider, uint256 amount)` {#Dispatcher-LiquidityRemoved-address-address-uint256-}

Liquidity removed event
