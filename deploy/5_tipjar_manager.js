module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  
  log(`5) TipJarManager`)
  // Deploy TipJarManager contract
  const deployResult = await deploy("TipJarManager", {
    from: deployer,
    contract: "TipJarManager",
    gas: 4000000,
    skipIfAlreadyDeployed: true
  });

  if (deployResult.newlyDeployed) {
    log(`- ${deployResult.contractName} deployed at ${deployResult.address} using ${deployResult.receipt.gasUsed} gas`);
  } else {
    log(`- Deployment skipped, using previous deployment at: ${deployResult.address}`)
  }
};

module.exports.tags = ["5", "TipJarManager"]
module.exports.dependencies = ["4"]