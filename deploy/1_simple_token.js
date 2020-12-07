module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  log(`1) Simple Token`)
  // Deploy SimpleToken contract
  const deployResult = await deploy("SimpleToken", {
    from: deployer,
    contract: "SimpleToken",
    gas: 4000000,
    args: ["Simple Token", "SMPL"],
    skipIfAlreadyDeployed: true
  });

  if (deployResult.newlyDeployed) {
    log(`- ${deployResult.contractName} deployed at ${deployResult.address} using ${deployResult.receipt.gasUsed} gas`);
  } else {
    log(`- Deployment skipped, using previous deployment at: ${deployResult.address}`)
  }
};

module.exports.tags = ["1", "SimpleToken"]