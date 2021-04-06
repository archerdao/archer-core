module.exports = async ({ ethers, getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer, admin } = await getNamedAccounts();
  const tipJar = await deployments.get("TipJar")
  const TIP_JAR_ROLE_MANAGER_ADDRESS = process.env.TIP_JAR_ROLE_MANAGER_ADDRESS
  const TIP_JAR_ADMIN_ADDRESS = process.env.TIP_JAR_ADMIN_ADDRESS
  const TIP_JAR_MINER_MANAGER = process.env.TIP_JAR_MINER_MANAGER
  const TIP_JAR_FEE_SETTER = process.env.TIP_JAR_FEE_SETTER
  const TIP_JAR_FEE_COLLECTOR = process.env.TIP_JAR_FEE_COLLECTOR
  const TIP_JAR_FEE = process.env.TIP_JAR_FEE
  const tipJarInterface = new ethers.utils.Interface(tipJar.abi);
  const initData = tipJarInterface.encodeFunctionData("initialize", [
      TIP_JAR_ROLE_MANAGER_ADDRESS,
      TIP_JAR_ADMIN_ADDRESS,
      TIP_JAR_MINER_MANAGER,
      TIP_JAR_FEE_SETTER,
      TIP_JAR_FEE_COLLECTOR,
      TIP_JAR_FEE
    ]
  );

  log(`5) TipJarProxy`)
  // Deploy TipJarProxy contract
  const deployResult = await deploy("TipJarProxy", {
    from: deployer,
    contract: "TipJarProxy",
    gas: 4000000,
    args: [tipJar.address, admin, initData],
    skipIfAlreadyDeployed: true
  });

  if (deployResult.newlyDeployed) {
    log(`- ${deployResult.contractName} deployed at ${deployResult.address} using ${deployResult.receipt.gasUsed} gas`);
  } else {
    log(`- Deployment skipped, using previous deployment at: ${deployResult.address}`)
  }
};

module.exports.tags = ["5", "TipJarProxy"]
module.exports.dependencies = ["4"]