# Archer Core Contracts

Archer Core is a series of smarts contracts that allow for the atomic execution of arbitrage and other opportunities on the Ethereum blockchain, while ensuring the profitability of the resulting transactions.  These contracts are used by the Archer network to execute any transaction sent via the Archer Rest API.

## How it Works
Each supplier that signs up for the Archer network is assigned 3 things:
* An API key used to submit opportunities to the network (unique to each supplier)
* A Bot ID that is used to identify the bot sending each opportunity + distribute rewards to suppliers (each supplier can have multiple)
* A Dispatcher contract that executes transactions sent via API request and, optionally, serves as a liquidity pool the supplier can use to support their strategies

Suppliers send POST requests to the Archer REST API with the payloads necessary to execute their transactions. [See documentation for these requests here.](https://docs.google.com/document/d/178mTvHjqIM0sFx_AM3NpnqCG68WNKvtrgKc3iSMAE2g)

Archer finds the most profitable transactions each block and submits them to the network on behalf of the suppliers.  If a miner within the Archer network mines this transaction before the opportunity expires and places it in priority position (first tx in block), then the resulting profit will be split between the miner, the supplier, and the network (with splits and other incentives to be determined by Archer DAO).

