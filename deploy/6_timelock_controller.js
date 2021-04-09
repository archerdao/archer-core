module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const TIMELOCK_MIN_DELAY = process.env.TIMELOCK_MIN_DELAY
  const tipJarManager = await deployments.get("TipJarManager")
  
  log(`6) TimelockController`)
  // Deploy TimelockController contract
  const deployResult = await deploy("TimelockController", {
    from: deployer,
    contract: "TimelockController",
    gas: 4000000,
    args: [TIMELOCK_MIN_DELAY, [tipJarManager.address], [tipJarManager.address]],
    skipIfAlreadyDeployed: true
  });

  if (deployResult.newlyDeployed) {
    log(`- ${deployResult.contractName} deployed at ${deployResult.address} using ${deployResult.receipt.gasUsed} gas`);
  } else {
    log(`- Deployment skipped, using previous deployment at: ${deployResult.address}`)
  }
};

module.exports.tags = ["6", "TimelockController"]
module.exports.dependencies = ["5"]