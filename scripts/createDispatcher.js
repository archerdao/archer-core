const { ethers, deployments, getNamedAccounts } = require("hardhat");

const ROLE_MANAGER_ADDRESS = process.env.ROLE_MANAGER_ADDRESS
const LP_MANAGER_ADDRESS = process.env.LP_MANAGER_ADDRESS
const WITHDRAWER_ADDRESS = process.env.WITHDRAWER_ADDRESS
const TRADER_ADDRESS = process.env.TRADER_ADDRESS
const INITIAL_MAX_LIQUIDITY = process.env.INITIAL_MAX_LIQUIDITY

const LP_WHITELIST = []

async function createDispatcher(
    roleManager,
    lpManager,
    withdrawer,
    trader,
    initialMaxLiquidity,
    lpWhitelist
) {
    const { admin } = await getNamedAccounts()
    const queryEngine = await deployments.get('QueryEngine')
    console.log(`- Creating new Dispatcher`)
    const receipt = await deployments.execute(
        'DispatcherFactory', 
        {from: admin, gasLimit: 6000000 }, 
        'createNewDispatcher',
        queryEngine.address,
        roleManager,
        lpManager,
        withdrawer,
        trader,
        initialMaxLiquidity,
        lpWhitelist
    );

    if(receipt.status) {
        console.log(`- New Dispatcher created`)
        console.log(receipt)
    } else {
        console.log(`- Error creating new Dispatcher:`)
        console.log(receipt)
    }
}

if (require.main === module) {
    createDispatcher(
        ROLE_MANAGER_ADDRESS,
        LP_MANAGER_ADDRESS,
        WITHDRAWER_ADDRESS,
        TRADER_ADDRESS,
        INITIAL_MAX_LIQUIDITY,
        LP_WHITELIST
    )
}

module.exports.createDispatcher = createDispatcher