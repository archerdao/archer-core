module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const dispatcherFactory = await deployments.get("DispatcherFactory");
  const DISPATCHER_FACTORY_ADMIN_ADDRESS = process.env.DISPATCHER_FACTORY_ADMIN_ADDRESS
  const DISPATCHER_FACTORY_ROLE_ADMIN_ADDRESS = process.env.DISPATCHER_FACTORY_ROLE_ADMIN_ADDRESS
  const VOTING_POWER_PRISM_ADDRESS = process.env.VOTING_POWER_PRISM_ADDRESS
  const GLOBAL_MAX_CONTRIBUTION_PCT = process.env.GLOBAL_MAX_CONTRIBUTION_PCT
  const DISPATCHER_MAX_CONTRIBUTION_PCT = process.env.DISPATCHER_MAX_CONTRIBUTION_PCT
  const BANKROLL_REQUIRED_VOTING_POWER = process.env.BANKROLL_REQUIRED_VOTING_POWER

  log(`3) Bouncer`)
  // Deploy Bouncer contract
  const deployResult = await deploy("Bouncer", {
    from: deployer,
    contract: "Bouncer",
    gas: 4000000,
    args: [dispatcherFactory.address, VOTING_POWER_PRISM_ADDRESS, GLOBAL_MAX_CONTRIBUTION_PCT, DISPATCHER_MAX_CONTRIBUTION_PCT, BANKROLL_REQUIRED_VOTING_POWER, DISPATCHER_FACTORY_ADMIN_ADDRESS, DISPATCHER_FACTORY_ROLE_ADMIN_ADDRESS],
    skipIfAlreadyDeployed: true
  });

  if (deployResult.newlyDeployed) {
    log(`- ${deployResult.contractName} deployed at ${deployResult.address} using ${deployResult.receipt.gasUsed} gas`);
  } else {
    log(`- Deployment skipped, using previous deployment at: ${deployResult.address}`)
  }
};

module.exports.tags = ["3", "Bouncer"]
module.exports.dependencies = ["2"]