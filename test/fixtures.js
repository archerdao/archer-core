const { deployments } = require("hardhat");

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"

const tokenFixture = deployments.createFixture(async ({ethers}, options) => {
    const accounts = await ethers.getSigners();
    const deployer = accounts[0]
    const alice = accounts[1]
    const bob = accounts[2]
    const SimpleTokenFactory = await ethers.getContractFactory("SimpleToken");
    const SimpleToken = await SimpleTokenFactory.deploy("Simple Token", "SMPL");
    return {
        token: SimpleToken,
        deployer: deployer,
        alice: alice,
        bob: bob,
        ZERO_ADDRESS: ZERO_ADDRESS
    };
})

module.exports.tokenFixture = tokenFixture;