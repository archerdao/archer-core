const { deployments, getNamedAccounts } = require("hardhat");

const REWARDS_MANAGER_ADDRESS = process.env.REWARDS_MANAGER_ADDRESS


async function setRewardsManager(rewardsManager) {
    const { admin } = await getNamedAccounts()
    console.log(`- Setting Rewards Manager to ${rewardsManager}`)
    const receipt = await deployments.execute(
        'Bouncer', 
        { from: admin, gasLimit: 2000000 }, 
        'setRewardsManager',
        rewardsManager
    );

    if(receipt.status) {
        for(const event of receipt.events) {
            if(event.event == 'RewardsManagerChanged') {
                console.log(`- New Rewards Manager changed from ${event.args.oldAddress} to ${event.args.newAddress}`)
                return event.args.newAddress;
            }
        }
    } else {
        console.log(`- Error setting Rewards Manager:`)
        console.log(receipt)
    }
}

if (require.main === module) {
    setRewardsManager(REWARDS_MANAGER_ADDRESS)
}

module.exports.setRewardsManager = setRewardsManager