const { deployments } = require("hardhat");

const VOTING_POWER_PRISM_ADDRESS = process.env.VOTING_POWER_PRISM_ADDRESS
const GLOBAL_MAX_CONTRIBUTION_PCT = process.env.GLOBAL_MAX_CONTRIBUTION_PCT
const DISPATCHER_MAX_CONTRIBUTION_PCT = process.env.DISPATCHER_MAX_CONTRIBUTION_PCT
const BANKROLL_REQUIRED_VOTING_POWER = process.env.BANKROLL_REQUIRED_VOTING_POWER
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"

const bankrollFixture = deployments.createFixture(async ({deployments, getNamedAccounts, getUnnamedAccounts, ethers}, options) => {
    const accounts = await ethers.getSigners();
    const deployer = accounts[0]
    const admin = accounts[1]
    const alice = accounts[2]
    const bob = accounts[3]
    const QueryEngineFactory = await ethers.getContractFactory("QueryEngine")
    const QueryEngine = await QueryEngineFactory.deploy()
    const DispatcherFactoryFactory = await ethers.getContractFactory("DispatcherFactory")
    const DispatcherFactory = await DispatcherFactoryFactory.deploy(admin.address, admin.address)
    const BouncerFactory = await ethers.getContractFactory("Bouncer")
    const Bouncer = await BouncerFactory.deploy(
        DispatcherFactory.address,
        VOTING_POWER_PRISM_ADDRESS,
        GLOBAL_MAX_CONTRIBUTION_PCT,
        DISPATCHER_MAX_CONTRIBUTION_PCT,
        BANKROLL_REQUIRED_VOTING_POWER,
        admin.address,
        admin.address
    )

    return {
        deployer: deployer,
        admin: admin,
        alice: alice,
        bob: bob,
        dispatcherFactory: DispatcherFactory,
        bouncer: Bouncer,
        queryEngine: QueryEngine,
        ZERO_ADDRESS: ZERO_ADDRESS
    };
})

module.exports.bankrollFixture = bankrollFixture;