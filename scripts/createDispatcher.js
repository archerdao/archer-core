const { ethers, deployments, getNamedAccounts } = require("hardhat");

const ROLE_MANAGER_ADDRESS = process.env.ROLE_MANAGER_ADDRESS
const LP_MANAGER_ADDRESS = process.env.LP_MANAGER_ADDRESS
const WITHDRAWER_ADDRESS = process.env.WITHDRAWER_ADDRESS
const TRADER_ADDRESS = process.env.TRADER_ADDRESS
const SUPPLIER_ADDRESS = process.env.SUPPLIER_ADDRESS
const INITIAL_MAX_LIQUIDITY = process.env.INITIAL_MAX_LIQUIDITY
let BOUNCER_ADDRESS = process.env.BOUNCER_ADDRESS

let LP_WHITELIST = [SUPPLIER_ADDRESS]
const ADD_BOUNCER_TO_WHITELIST = true
const JOIN_BANKROLL_PROGRAM = true

async function getBouncerAddress() {
    const bouncer = await deployments.get("Bouncer")
    return bouncer.address
}

async function getQueryEngineAddress() {
    const queryEngine = await deployments.get('QueryEngine')
    return queryEngine.address
}

async function joinBankrollProgram(dispatcher) {
    const { admin } = await getNamedAccounts()
    console.log(`- Dispatcher ${dispatcher} joining bankroll program`)
    const receipt = await deployments.execute(
        'Bouncer', 
        { from: admin, gasLimit: 2000000 }, 
        'join',
        dispatcher
    );

    if(receipt.status) {
        for(const event of receipt.events) {
            if(event.event == 'BankrollTokenCreated') {
                console.log(`- New Bankroll Token created at: ${event.args.tokenAddress}`)
                return event.args.tokenAddress;
            }
        }
    } else {
        console.log(`- Error joining bankroll program:`)
        console.log(receipt)
    }
}

async function createDispatcher(
    queryEngine,
    roleManager,
    lpManager,
    withdrawer,
    trader,
    supplier,
    initialMaxLiquidity,
    lpWhitelist
) {
    const { admin } = await getNamedAccounts()
    console.log(`- Creating new Dispatcher`)
    const receipt = await deployments.execute(
        'DispatcherFactory', 
        { from: admin, gasLimit: 6000000 }, 
        'createNewDispatcher',
        queryEngine,
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
                return event.args.dispatcher;
            }
        }
    } else {
        console.log(`- Error creating new Dispatcher:`)
        console.log(receipt)
    }
}

if (require.main === module) {
    if(ADD_BOUNCER_TO_WHITELIST) {
        if(!BOUNCER_ADDRESS) {
            getBouncerAddress()
            .then((result) => {
                BOUNCER_ADDRESS = result
                LP_WHITELIST.push(BOUNCER_ADDRESS)
                getQueryEngineAddress()
                .then((result) => {
                    const QUERY_ENGINE_ADDRESS = result
                    createDispatcher(
                        QUERY_ENGINE_ADDRESS,
                        ROLE_MANAGER_ADDRESS,
                        LP_MANAGER_ADDRESS,
                        WITHDRAWER_ADDRESS,
                        TRADER_ADDRESS,
                        SUPPLIER_ADDRESS,
                        INITIAL_MAX_LIQUIDITY,
                        LP_WHITELIST 
                    ).then((dispatcher) => {
                        if (JOIN_BANKROLL_PROGRAM) {
                            joinBankrollProgram(dispatcher)
                        }
                    })
                })
            })
        } else {
            LP_WHITELIST.push(BOUNCER_ADDRESS)
            getQueryEngineAddress()
            .then((result) => {
                const QUERY_ENGINE_ADDRESS = result
                createDispatcher(
                    QUERY_ENGINE_ADDRESS,
                    ROLE_MANAGER_ADDRESS,
                    LP_MANAGER_ADDRESS,
                    WITHDRAWER_ADDRESS,
                    TRADER_ADDRESS,
                    SUPPLIER_ADDRESS,
                    INITIAL_MAX_LIQUIDITY,
                    LP_WHITELIST 
                ).then((dispatcher) => {
                    if (JOIN_BANKROLL_PROGRAM) {
                        joinBankrollProgram(dispatcher)
                    }
                })
            })
        }
        
    } else {
        getQueryEngineAddress()
        .then((result) => {
            const QUERY_ENGINE_ADDRESS = result
            createDispatcher(
                QUERY_ENGINE_ADDRESS,
                ROLE_MANAGER_ADDRESS,
                LP_MANAGER_ADDRESS,
                WITHDRAWER_ADDRESS,
                TRADER_ADDRESS,
                SUPPLIER_ADDRESS,
                INITIAL_MAX_LIQUIDITY,
                LP_WHITELIST 
            )
        })
    }
    
}

module.exports.createDispatcher = createDispatcher