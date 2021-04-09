const { expect } = require("chai")
const { ethers } = require("hardhat");
const { bankrollFixture } = require("../fixtures")
const DISPATCHER_ABI = require("../abis/Dispatcher.json")
const BANKROLL_TOKEN_ABI = require("../abis/BankrollToken.json")
const VOTING_POWER_PRISM_ADDRESS = process.env.VOTING_POWER_PRISM_ADDRESS
const GLOBAL_MAX_CONTRIBUTION_PCT = process.env.GLOBAL_MAX_CONTRIBUTION_PCT
const DISPATCHER_MAX_CONTRIBUTION_PCT = process.env.DISPATCHER_MAX_CONTRIBUTION_PCT
const BANKROLL_REQUIRED_VOTING_POWER = process.env.BANKROLL_REQUIRED_VOTING_POWER

describe('Bouncer', () => {
    let dispatcherFactory
    let bouncer
    let queryEngine
    let deployer
    let admin
    let alice
    let bob
    let ZERO_ADDRESS
    let dispatchers = []

    beforeEach(async () => {
      const fix = await bankrollFixture()
      dispatcherFactory = fix.dispatcherFactory
      bouncer = fix.bouncer
      queryEngine = fix.queryEngine
      deployer = fix.deployer
      admin = fix.admin
      alice = fix.alice
      bob = fix.bob
      ZERO_ADDRESS = fix.ZERO_ADDRESS

      let tx = await dispatcherFactory.connect(admin).createNewDispatcher(queryEngine.address, admin.address, admin.address, deployer.address, alice.address, alice.address, "100000000000000000000", [alice.address, bouncer.address])
      let receipt = await tx.wait()
      let dispatcherAddress
      for(const event of receipt.events) {
        if(event.event == 'DispatcherCreated') {
            dispatcherAddress = event.args.dispatcher;
        }
      }
      dispatchers.push(new ethers.Contract(dispatcherAddress, DISPATCHER_ABI, deployer))
      tx = await dispatcherFactory.connect(admin).createNewDispatcher(queryEngine.address, admin.address, admin.address, deployer.address, alice.address, alice.address, "200000000000000000000", [alice.address, bouncer.address])
      receipt = await tx.wait()
      for(const event of receipt.events) {
        if(event.event == 'DispatcherCreated') {
            dispatcherAddress = event.args.dispatcher;
        }
      }
      dispatchers.push(new ethers.Contract(dispatcherAddress, DISPATCHER_ABI, deployer))
      tx = await dispatcherFactory.connect(admin).createNewDispatcher(queryEngine.address, admin.address, admin.address, deployer.address, bob.address, bob.address, "100000000000000000000", [bob.address])
      receipt = await tx.wait()
      for(const event of receipt.events) {
        if(event.event == 'DispatcherCreated') {
            dispatcherAddress = event.args.dispatcher;
        }
      }
      dispatchers.push(new ethers.Contract(dispatcherAddress, DISPATCHER_ABI, deployer))
      tx = await dispatcherFactory.connect(admin).createNewDispatcher(queryEngine.address, admin.address, admin.address, deployer.address, bob.address, bob.address, "400000000000000000000", [bob.address, bouncer.address])
      receipt = await tx.wait()
      for(const event of receipt.events) {
        if(event.event == 'DispatcherCreated') {
            dispatcherAddress = event.args.dispatcher;
        }
      }
      dispatchers.push(new ethers.Contract(dispatcherAddress, DISPATCHER_ABI, deployer))
      tx = await dispatcherFactory.connect(admin).createNewDispatcher(queryEngine.address, admin.address, admin.address, deployer.address, alice.address, alice.address, "200000000000000000000", [alice.address, bouncer.address])
      receipt = await tx.wait()
      for(const event of receipt.events) {
        if(event.event == 'DispatcherCreated') {
            dispatcherAddress = event.args.dispatcher;
        }
      }
      dispatchers.push(new ethers.Contract(dispatcherAddress, DISPATCHER_ABI, deployer))
      tx = await dispatcherFactory.connect(admin).createNewDispatcher(queryEngine.address, admin.address, admin.address, deployer.address, alice.address, alice.address, "500000000000000000000", [alice.address])
      receipt = await tx.wait()
      for(const event of receipt.events) {
        if(event.event == 'DispatcherCreated') {
            dispatcherAddress = event.args.dispatcher;
        }
      }
      dispatchers.push(new ethers.Contract(dispatcherAddress, DISPATCHER_ABI, deployer))
      await bouncer.join(dispatchers[0].address)
      await bouncer.join(dispatchers[1].address)
      await bouncer.join(dispatchers[2].address)
    })

    context('join', async () => {
      it('allows a valid join', async () => {
        await bouncer.join(dispatchers[3].address)
        expect(await bouncer.bankrollTokens(dispatchers[3].address, ZERO_ADDRESS)).to.not.eq(ZERO_ADDRESS)
      })

      it('does not allow a dispatcher to join multiple times with same asset', async () => {
        const bankrollToken = await bouncer.bankrollTokens(dispatchers[0].address, ZERO_ADDRESS)
        expect(await bouncer.bankrollTokens(dispatchers[0].address, ZERO_ADDRESS)).to.not.eq(ZERO_ADDRESS)
        await bouncer.join(dispatchers[0].address)
        expect(await bouncer.bankrollTokens(dispatchers[0].address, ZERO_ADDRESS)).to.eq(bankrollToken)
      })
    })

    context('migrate', async () => {
      it('allows a valid migrate', async () => {
        const bankrollTokenAddress = await bouncer.bankrollTokens(dispatchers[0].address, ZERO_ADDRESS)
        const bankrollToken = new ethers.Contract(bankrollTokenAddress, BANKROLL_TOKEN_ABI, deployer)
        const BouncerFactory = await ethers.getContractFactory("Bouncer")
        const newBouncer = await BouncerFactory.deploy(
            dispatcherFactory.address,
            VOTING_POWER_PRISM_ADDRESS,
            GLOBAL_MAX_CONTRIBUTION_PCT,
            DISPATCHER_MAX_CONTRIBUTION_PCT,
            BANKROLL_REQUIRED_VOTING_POWER,
            admin.address,
            admin.address
        )
        await bouncer.connect(admin).migrate(bankrollTokenAddress, newBouncer.address)
        expect(await bankrollToken.supplyManager()).to.eq(newBouncer.address)
      })

      it('does not allow a non-admin to migrate', async () => {
        const bankrollTokenAddress = await bouncer.bankrollTokens(dispatchers[0].address, ZERO_ADDRESS)
        const BouncerFactory = await ethers.getContractFactory("Bouncer")
        const newBouncer = await BouncerFactory.deploy(
            dispatcherFactory.address,
            VOTING_POWER_PRISM_ADDRESS,
            GLOBAL_MAX_CONTRIBUTION_PCT,
            DISPATCHER_MAX_CONTRIBUTION_PCT,
            BANKROLL_REQUIRED_VOTING_POWER,
            admin.address,
            admin.address
        )
        await expect(bouncer.migrate(bankrollTokenAddress, newBouncer.address)).to.revertedWith("Caller must have BOUNCER_ADMIN_ROLE role")
      })

      it('cannot migrate to zero address', async () => {
        const bankrollTokenAddress = await bouncer.bankrollTokens(dispatchers[0].address, ZERO_ADDRESS)
        await expect(bouncer.connect(admin).migrate(bankrollTokenAddress, ZERO_ADDRESS)).to.revertedWith("cannot migrate to zero")
      })
    })
  })