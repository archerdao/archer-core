module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  log(`1) Query Engine`)
  // Deploy QueryEngine contract
  const deployResult = await deploy("QueryEngine", {
    from: deployer,
    contract: "QueryEngine",
    gas: 4000000,
    args: [],
    skipIfAlreadyDeployed: true
  });

  if (deployResult.newlyDeployed) {
    log(`- ${deployResult.contractName} deployed at ${deployResult.address} using ${deployResult.receipt.gasUsed} gas`);
  } else {
    log(`- Deployment skipped, using previous deployment at: ${deployResult.address}`)
  }
};

module.exports.tags = ["1", "QueryEngine"]