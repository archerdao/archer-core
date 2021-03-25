module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const ROLE_MANAGER_ADDRESS = process.env.ROLE_MANAGER_ADDRESS
  const TIP_POOL_ADMIN_ADDRESS = process.env.TIP_POOL_ADMIN_ADDRESS
  const tipPool = deployments.get("TipPool")

  log(`5) TipJar`)
  // Deploy TipJar contract
  const deployResult = await deploy("TipJar", {
    from: deployer,
    contract: "TipJar",
    gas: 4000000,
    args: [ROLE_MANAGER_ADDRESS, TIP_POOL_ADMIN_ADDRESS, tipPool.address],
    skipIfAlreadyDeployed: true
  });

  if (deployResult.newlyDeployed) {
    log(`- ${deployResult.contractName} deployed at ${deployResult.address} using ${deployResult.receipt.gasUsed} gas`);
  } else {
    log(`- Deployment skipped, using previous deployment at: ${deployResult.address}`)
  }
};

module.exports.tags = ["5", "TipJar"]
module.exports.dependencies = ["4"]