module.exports = async ({ ethers, getNamedAccounts, deployments }) => {
  const { execute, log } = deployments;
  const { deployer, admin } = await getNamedAccounts();
  const tipJarProxy = await deployments.get("TipJarProxy")
  const timelockController = await deployments.get("TimelockController")
  const TIMELOCK_CRITICAL_DELAY = process.env.TIMELOCK_CRITICAL_DELAY
  const TIMELOCK_REGULAR_DELAY = process.env.TIMELOCK_REGULAR_DELAY

  log(`8) TipJarManager Init`)
  // Initialize TipJarManager contract
  await execute('TipJarManager', {from: deployer }, 'initialize', tipJarProxy.address, admin, timelockController.address, TIMELOCK_CRITICAL_DELAY, TIMELOCK_REGULAR_DELAY);
  og(`- TipJar Manager initialized`)
};

module.exports.skip = async function({ deployments }) {
    const { read, log } = deployments
    const tipJar = await read('TipJarManager', 'tipJar');
    const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"
    if(tipJar == ZERO_ADDRESS) {
        return false
    }
    log(`8) TipJarManager Init`)
    log(`- Skipping step, TipJar Manager already initialized`)
    return true
}

module.exports.tags = ["8", "TipJarManagerInit"]
module.exports.dependencies = ["7"]