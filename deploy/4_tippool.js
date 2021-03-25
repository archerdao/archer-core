module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const ROLE_MANAGER_ADDRESS = process.env.ROLE_MANAGER_ADDRESS
  const TIP_POOL_ADMIN_ADDRESS = process.env.TIP_POOL_ADMIN_ADDRESS
  const TIP_POOL_MINER_MANAGER = process.env.TIP_POOL_MINER_MANAGER
  const TIP_POOL_FEE_SETTER = process.env.TIP_POOL_FEE_SETTER
  const TIP_POOL_FEE_COLLECTOR = process.env.TIP_POOL_FEE_COLLECTOR
  const TIP_POOL_FEE = process.env.TIP_POOL_FEE
  const TIP_POOL_ACCOUNTANT = process.env.TIP_POOL_ACCOUNTANT
  const KNOWN_MINERS = process.env.KNOWN_MINERS.split(",")

  log(`4) TipPool`)
  // Deploy TipPool contract
  const deployResult = await deploy("TipPool", {
    from: deployer,
    contract: "TipPool",
    gas: 4000000,
    args: [ROLE_MANAGER_ADDRESS, TIP_POOL_ADMIN_ADDRESS, TIP_POOL_MINER_MANAGER, TIP_POOL_FEE_SETTER, TIP_POOL_FEE_COLLECTOR, TIP_POOL_FEE, TIP_POOL_ACCOUNTANT, KNOWN_MINERS],
    skipIfAlreadyDeployed: true
  });

  if (deployResult.newlyDeployed) {
    log(`- ${deployResult.contractName} deployed at ${deployResult.address} using ${deployResult.receipt.gasUsed} gas`);
  } else {
    log(`- Deployment skipped, using previous deployment at: ${deployResult.address}`)
  }
};

module.exports.tags = ["4", "TipPool"]
module.exports.dependencies = ["3"]