## `DispatcherFactory`

# Functions:

- [`constructor(address _roleAdmin, address _dispatcherAdmin)`](#DispatcherFactory-constructor-address-address-)

- [`createNewDispatcher(address queryEngine, address roleManager, address lpManager, address withdrawer, address trader, address approver, uint256 initialMaxLiquidity, address[] lpWhitelist)`](#DispatcherFactory-createNewDispatcher-address-address-address-address-address-address-uint256-address---)

# Events:

- [`DispatcherCreated(address dispatcher, uint8 version, address queryEngine, address roleManager, address lpManager, address withdrawer, address trader, address approver, uint256 initialMaxLiquidity, bool lpWhitelist)`](#DispatcherFactory-DispatcherCreated-address-uint8-address-address-address-address-address-address-uint256-bool-)

# Function `constructor(address _roleAdmin, address _dispatcherAdmin)` {#DispatcherFactory-constructor-address-address-}

Initializes contract, setting admin

## Parameters:

- `_roleAdmin`: admin in control of roles

- `_dispatcherAdmin`: admin that can create new Dispatchers

# Function `createNewDispatcher(address queryEngine, address roleManager, address lpManager, address withdrawer, address trader, address approver, uint256 initialMaxLiquidity, address[] lpWhitelist) → address dispatcher` {#DispatcherFactory-createNewDispatcher-address-address-address-address-address-address-uint256-address---}

Create new Dispatcher contract

## Parameters:

- `queryEngine`: Address of query engine contract

- `roleManager`: Address allowed to manage contract roles

- `lpManager`: Address allowed to manage LP whitelist

- `withdrawer`: Address allowed to withdraw profit from contract

- `trader`: Address allowed to make trades via this contract

- `approver`: Address allowed to make approvals on contract

- `initialMaxLiquidity`: Initial max liquidity allowed in contract

- `lpWhitelist`: list of addresses that are allowed to provide liquidity to this contract

## Return Values:

- dispatcher Address of new Dispatcher contract

# Event `DispatcherCreated(address dispatcher, uint8 version, address queryEngine, address roleManager, address lpManager, address withdrawer, address trader, address approver, uint256 initialMaxLiquidity, bool lpWhitelist)` {#DispatcherFactory-DispatcherCreated-address-uint8-address-address-address-address-address-address-uint256-bool-}

Create new Dispatcher event
