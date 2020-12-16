## `Trader`

# Functions:

- [`isTrader(address addressToCheck)`](#Trader-isTrader-address-)

- [`makeTrade(bytes executeScript, uint256 ethValue)`](#Trader-makeTrade-bytes-uint256-)

- [`makeTrade(bytes executeScript, uint256 ethValue, uint256 blockDeadline)`](#Trader-makeTrade-bytes-uint256-uint256-)

- [`makeTrade(bytes executeScript, uint256 ethValue, uint256 minTimestamp, uint256 maxTimestamp)`](#Trader-makeTrade-bytes-uint256-uint256-uint256-)

- [`makeTrade(bytes queryScript, uint256[] queryInputLocations, bytes executeScript, uint256[] executeInputLocations, uint256 targetPrice, uint256 ethValue)`](#Trader-makeTrade-bytes-uint256---bytes-uint256---uint256-uint256-)

- [`makeTrade(bytes queryScript, uint256[] queryInputLocations, bytes executeScript, uint256[] executeInputLocations, uint256 targetPrice, uint256 ethValue, uint256 blockDeadline)`](#Trader-makeTrade-bytes-uint256---bytes-uint256---uint256-uint256-uint256-)

- [`makeTrade(bytes queryScript, uint256[] queryInputLocations, bytes executeScript, uint256[] executeInputLocations, uint256 targetPrice, uint256 ethValue, uint256 minTimestamp, uint256 maxTimestamp)`](#Trader-makeTrade-bytes-uint256---bytes-uint256---uint256-uint256-uint256-uint256-)

# Function `isTrader(address addressToCheck) → bool` {#Trader-isTrader-address-}

Returns true if given address is on the list of approved traders

## Parameters:

- `addressToCheck`: the address to check

## Return Values:

- true if address is trader

# Function `makeTrade(bytes executeScript, uint256 ethValue)` {#Trader-makeTrade-bytes-uint256-}

Makes a series of trades as single transaction if profitable without query

## Parameters:

- `executeScript`: the compiled bytecode for the series of function calls to execute the trade

- `ethValue`: the amount of ETH to send with initial contract call

# Function `makeTrade(bytes executeScript, uint256 ethValue, uint256 blockDeadline)` {#Trader-makeTrade-bytes-uint256-uint256-}

Makes a series of trades as single transaction if profitable without query + block deadline

## Parameters:

- `executeScript`: the compiled bytecode for the series of function calls to execute the trade

- `ethValue`: the amount of ETH to send with initial contract call

- `blockDeadline`: block number when trade expires

# Function `makeTrade(bytes executeScript, uint256 ethValue, uint256 minTimestamp, uint256 maxTimestamp)` {#Trader-makeTrade-bytes-uint256-uint256-uint256-}

Makes a series of trades as single transaction if profitable without query + within time window specified

## Parameters:

- `executeScript`: the compiled bytecode for the series of function calls to execute the trade

- `ethValue`: the amount of ETH to send with initial contract call

- `minTimestamp`: minimum block timestamp to execute trade

- `maxTimestamp`: maximum timestamp to execute trade

# Function `makeTrade(bytes queryScript, uint256[] queryInputLocations, bytes executeScript, uint256[] executeInputLocations, uint256 targetPrice, uint256 ethValue)` {#Trader-makeTrade-bytes-uint256---bytes-uint256---uint256-uint256-}

Makes a series of trades as single transaction if profitable

## Parameters:

- `queryScript`: the compiled bytecode for the series of function calls to get the final price

- `queryInputLocations`: index locations within the queryScript to insert input amounts dynamically

- `executeScript`: the compiled bytecode for the series of function calls to execute the trade

- `executeInputLocations`: index locations within the executeScript to insert input amounts dynamically

- `targetPrice`: profit target for this trade, if ETH>ETH, this should be ethValue + gas estimate * gas price

- `ethValue`: the amount of ETH to send with initial contract call

# Function `makeTrade(bytes queryScript, uint256[] queryInputLocations, bytes executeScript, uint256[] executeInputLocations, uint256 targetPrice, uint256 ethValue, uint256 blockDeadline)` {#Trader-makeTrade-bytes-uint256---bytes-uint256---uint256-uint256-uint256-}

Makes a series of trades as single transaction if profitable + block deadline

## Parameters:

- `queryScript`: the compiled bytecode for the series of function calls to get the final price

- `queryInputLocations`: index locations within the queryScript to insert input amounts dynamically

- `executeScript`: the compiled bytecode for the series of function calls to execute the trade

- `executeInputLocations`: index locations within the executeScript to insert input amounts dynamically

- `targetPrice`: profit target for this trade, if ETH>ETH, this should be ethValue + gas estimate * gas price

- `ethValue`: the amount of ETH to send with initial contract call

- `blockDeadline`: block number when trade expires

# Function `makeTrade(bytes queryScript, uint256[] queryInputLocations, bytes executeScript, uint256[] executeInputLocations, uint256 targetPrice, uint256 ethValue, uint256 minTimestamp, uint256 maxTimestamp)` {#Trader-makeTrade-bytes-uint256---bytes-uint256---uint256-uint256-uint256-uint256-}

Makes a series of trades as single transaction if profitable + within time window specified

## Parameters:

- `queryScript`: the compiled bytecode for the series of function calls to get the final price

- `queryInputLocations`: index locations within the queryScript to insert input amounts dynamically

- `executeScript`: the compiled bytecode for the series of function calls to execute the trade

- `executeInputLocations`: index locations within the executeScript to insert input amounts dynamically

- `targetPrice`: profit target for this trade, if ETH>ETH, this should be ethValue + gas estimate * gas price

- `ethValue`: the amount of ETH to send with initial contract call

- `minTimestamp`: minimum block timestamp to execute trade

- `maxTimestamp`: maximum timestamp to execute trade
