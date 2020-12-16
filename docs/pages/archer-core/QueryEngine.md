## `QueryEngine`

# Functions:

- [`getPrice(address contractAddress, bytes data)`](#QueryEngine-getPrice-address-bytes-)

- [`queryAllPrices(bytes script, uint256[] inputLocations)`](#QueryEngine-queryAllPrices-bytes-uint256---)

- [`query(bytes script, uint256[] inputLocations)`](#QueryEngine-query-bytes-uint256---)

# Function `getPrice(address contractAddress, bytes data) → bytes` {#QueryEngine-getPrice-address-bytes-}

Calls the price function specified by data at contractAddress, returning the price as bytes

## Parameters:

- `contractAddress`: contract to query

- `data`: the bytecode for the contract call

## Return Values:

- price in bytes

# Function `queryAllPrices(bytes script, uint256[] inputLocations) → bytes` {#QueryEngine-queryAllPrices-bytes-uint256---}

Makes a series of queries at once, returning all the prices as bytes

## Parameters:

- `script`: the compiled bytecode for the series of function calls to get the final price

- `inputLocations`: index locations within the script to insert input amounts dynamically

## Return Values:

- all prices as bytes

# Function `query(bytes script, uint256[] inputLocations) → uint256` {#QueryEngine-query-bytes-uint256---}

Makes a series of queries at once, returning the final price as a uint

## Parameters:

- `script`: the compiled bytecode for the series of function calls to get the final price

- `inputLocations`: index locations within the script to insert input amounts dynamically

## Return Values:

- last price as uint
