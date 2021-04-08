module.exports = async ({ ethers, getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const tipJar = await deployments.get("TipJar")
  const timelockController = await deployments.get("TimelockController")
  const TIP_JAR_FEE_COLLECTOR = process.env.TIP_JAR_FEE_COLLECTOR
  const TIP_JAR_FEE = process.env.TIP_JAR_FEE
  const tipJarInterface = new ethers.utils.Interface(tipJar.abi);
  const initData = tipJarInterface.encodeFunctionData("initialize", [
      timelockController.address,
      timelockController.address,
      TIP_JAR_FEE_COLLECTOR,
      TIP_JAR_FEE
    ]
  );

  log(`7) TipJarProxy`)
  // Deploy TipJarProxy contract
  const deployResult = await deploy("TipJarProxy", {
    from: deployer,
    contract: "TipJarProxy",
    gas: 4000000,
    args: [tipJar.address, timelockController.address, initData],
    skipIfAlreadyDeployed: true
  });

  if (deployResult.newlyDeployed) {
    log(`- ${deployResult.contractName} deployed at ${deployResult.address} using ${deployResult.receipt.gasUsed} gas`);
  } else {
    log(`- Deployment skipped, using previous deployment at: ${deployResult.address}`)
  }
};

module.exports.tags = ["7", "TipJarProxy"]
module.exports.dependencies = ["6"]