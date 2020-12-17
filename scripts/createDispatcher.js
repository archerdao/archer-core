const { ethers, deployments, getNamedAccounts } = require("hardhat");

const ROLE_MANAGER_ADDRESS = process.env.ROLE_MANAGER_ADDRESS
const LP_MANAGER_ADDRESS = process.env.LP_MANAGER_ADDRESS
const WITHDRAWER_ADDRESS = process.env.WITHDRAWER_ADDRESS
const TRADER_ADDRESS = process.env.TRADER_ADDRESS
const SUPPLIER_ADDRESS = process.env.SUPPLIER_ADDRESS
const INITIAL_MAX_LIQUIDITY = process.env.INITIAL_MAX_LIQUIDITY

const LP_WHITELIST = [SUPPLIER_ADDRESS]

async function createDispatcher(
    roleManager,
    lpManager,
    withdrawer,
    trader,
    supplier,
    initialMaxLiquidity,
    lpWhitelist
) {
    const { admin } = await getNamedAccounts()
    const queryEngine = await deployments.get('QueryEngine')
    console.log(`- Creating new Dispatcher`)
    const receipt = await deployments.execute(
        'DispatcherFactory', 
        { from: admin, gasLimit: 6000000 }, 
        'createNewDispatcher',
        queryEngine.address,
        roleManager,
        lpManager,
        withdrawer,
        trader,
        supplier,
        initialMaxLiquidity,
        lpWhitelist
    );

    if(receipt.status) {
        for(const event of receipt.events) {
            if(event.event == 'DispatcherCreated') {
                console.log(`- New Dispatcher created at: ${event.args.dispatcher}`)
            }
        }
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
        SUPPLIER_ADDRESS,
        INITIAL_MAX_LIQUIDITY,
        LP_WHITELIST
    )
}

module.exports.createDispatcher = createDispatcher