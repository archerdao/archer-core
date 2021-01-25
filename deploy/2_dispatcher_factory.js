module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const DISPATCHER_FACTORY_ADMIN_ADDRESS = process.env.DISPATCHER_FACTORY_ADMIN_ADDRESS
  const DISPATCHER_FACTORY_ROLE_ADMIN_ADDRESS = process.env.DISPATCHER_FACTORY_ROLE_ADMIN_ADDRESS

  log(`2) Dispatcher Factory`)
  // Deploy Dispatcher Factory contract
  const deployResult = await deploy("DispatcherFactory", {
    from: deployer,
    contract: "DispatcherFactory",
    gas: 4000000,
    args: [DISPATCHER_FACTORY_ROLE_ADMIN_ADDRESS, DISPATCHER_FACTORY_ADMIN_ADDRESS],
    skipIfAlreadyDeployed: false
  });

  if (deployResult.newlyDeployed) {
    log(`- ${deployResult.contractName} deployed at ${deployResult.address} using ${deployResult.receipt.gasUsed} gas`);
  } else {
    log(`- Deployment skipped, using previous deployment at: ${deployResult.address}`)
  }
};

module.exports.tags = ["2", "DispatcherFactory"]
module.exports.dependencies = ["1"]