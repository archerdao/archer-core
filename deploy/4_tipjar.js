module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  
  log(`4) TipJar`)
  // Deploy TipPool contract
  const deployResult = await deploy("TipJar", {
    from: deployer,
    contract: "TipJar",
    gas: 4000000,
    skipIfAlreadyDeployed: false
  });

  if (deployResult.newlyDeployed) {
    log(`- ${deployResult.contractName} deployed at ${deployResult.address} using ${deployResult.receipt.gasUsed} gas`);
  } else {
    log(`- Deployment skipped, using previous deployment at: ${deployResult.address}`)
  }
};

module.exports.tags = ["4", "TipJar"]
module.exports.dependencies = ["3"]