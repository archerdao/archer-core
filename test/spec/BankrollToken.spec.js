const { expect } = require("chai")
const { ethers } = require("hardhat");
const { bankrollFixture } = require("../fixtures")
const { ecsign } = require("ethereumjs-util")

const DEPLOYER_PRIVATE_KEY = process.env.DEPLOYER_PRIVATE_KEY

const DOMAIN_TYPEHASH = ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
)

const PERMIT_TYPEHASH = ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)')
)

const TRANSFER_WITH_AUTHORIZATION_TYPEHASH = ethers.utils.keccak256(
  ethers.utils.toUtf8Bytes('TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)')
)

const RECEIVE_WITH_AUTHORIZATION_TYPEHASH = ethers.utils.keccak256(
  ethers.utils.toUtf8Bytes('ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)')
)

describe('BankrollToken', () => {
    let dispatcherFactory
    let bouncer
    let deployer
    let admin
    let alice
    let bob
    let ZERO_ADDRESS

    beforeEach(async () => {
      const fix = await bankrollFixture()
      dispatcherFactory = fix.dispatcherFactory
      bouncer = fix.bouncer
      deployer = fix.deployer
      admin = fix.admin
      alice = fix.alice
      bob = fix.bob
      ZERO_ADDRESS = fix.ZERO_ADDRESS
    })

    context('transfer', async () => {
      it('allows a valid transfer', async () => {
        const amount = 100
        const balanceBefore = await bankrollToken.balanceOf(alice.address)
        await bankrollToken.transfer(alice.address, amount)
        expect(await bankrollToken.balanceOf(alice.address)).to.eq(balanceBefore.add(amount))
      })

      it('does not allow a transfer to the zero address', async () => {
        const amount = 100
        await expect(bankrollToken.transfer(ZERO_ADDRESS, amount)).to.revertedWith("Arch::_transferTokens: cannot transfer to the zero address")
      })
    })

    context('transferFrom', async () => {
      it('allows a valid transferFrom', async () => {
        const amount = 100
        const senderBalanceBefore = await bankrollToken.balanceOf(deployer.address)
        const receiverBalanceBefore = await bankrollToken.balanceOf(bob.address)
        await bankrollToken.approve(alice.address, amount)
        expect(await bankrollToken.allowance(deployer.address, alice.address)).to.eq(amount)
        await bankrollToken.connect(alice).transferFrom(deployer.address, bob.address, amount)
        expect(await bankrollToken.balanceOf(deployer.address)).to.eq(senderBalanceBefore.sub(amount))
        expect(await bankrollToken.balanceOf(bob.address)).to.eq(receiverBalanceBefore.add(amount))
        expect(await bankrollToken.allowance(deployer.address, alice.address)).to.eq(0)
      })

      it('allows for infinite approvals', async () => {
        const amount = 100
        const maxAmount = ethers.constants.MaxUint256
        await bankrollToken.approve(alice.address, maxAmount)
        expect(await bankrollToken.allowance(deployer.address, alice.address)).to.eq(maxAmount)
        await bankrollToken.connect(alice).transferFrom(deployer.address, bob.address, amount)
        expect(await bankrollToken.allowance(deployer.address, alice.address)).to.eq(maxAmount)
      })

      it('cannot transfer in excess of the spender allowance', async () => {
        await bankrollToken.transfer(alice.address, 100)
        const balance = await bankrollToken.balanceOf(alice.address)
        await expect(bankrollToken.transferFrom(alice.address, bob.address, balance)).to.revertedWith("revert Arch::transferFrom: transfer amount exceeds allowance")
      })
    })
    
    context('permit', async () => {
      it('allows a valid permit', async () => {
        const domainSeparator = ethers.utils.keccak256(
          ethers.utils.defaultAbiCoder.encode(
            ['bytes32', 'bytes32', 'bytes32', 'uint256', 'address'],
            [DOMAIN_TYPEHASH, ethers.utils.keccak256(ethers.utils.toUtf8Bytes(await bankrollToken.name())), ethers.utils.keccak256(ethers.utils.toUtf8Bytes("1")), ethers.provider.network.chainId, bankrollToken.address]
          )
        )

        const value = 123
        const nonce = await bankrollToken.nonces(deployer.address)
        const deadline = ethers.constants.MaxUint256
        const digest = ethers.utils.keccak256(
          ethers.utils.solidityPack(
            ['bytes1', 'bytes1', 'bytes32', 'bytes32'],
            [
              '0x19',
              '0x01',
              domainSeparator,
              ethers.utils.keccak256(
                ethers.utils.defaultAbiCoder.encode(
                  ['bytes32', 'address', 'address', 'uint256', 'uint256', 'uint256'],
                  [PERMIT_TYPEHASH, deployer.address, alice.address, value, nonce, deadline]
                )
              ),
            ]
          )
        )

        const { v, r, s } = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(DEPLOYER_PRIVATE_KEY, 'hex'))
        
        await bankrollToken.permit(deployer.address, alice.address, value, deadline, v, ethers.utils.hexlify(r), ethers.utils.hexlify(s))
        expect(await bankrollToken.allowance(deployer.address, alice.address)).to.eq(value)
        expect(await bankrollToken.nonces(deployer.address)).to.eq(1)

        await bankrollToken.connect(alice).transferFrom(deployer.address, bob.address, value)
      })

      it('does not allow a permit after deadline', async () => {
        const domainSeparator = ethers.utils.keccak256(
          ethers.utils.defaultAbiCoder.encode(
            ['bytes32', 'bytes32', 'bytes32', 'uint256', 'address'],
            [DOMAIN_TYPEHASH, ethers.utils.keccak256(ethers.utils.toUtf8Bytes(await bankrollToken.name())), ethers.utils.keccak256(ethers.utils.toUtf8Bytes("1")), ethers.provider.network.chainId, bankrollToken.address]
          )
        )

        const value = 123
        const nonce = await bankrollToken.nonces(deployer.address)
        const deadline = 0
        const digest = ethers.utils.keccak256(
          ethers.utils.solidityPack(
            ['bytes1', 'bytes1', 'bytes32', 'bytes32'],
            [
              '0x19',
              '0x01',
              domainSeparator,
              ethers.utils.keccak256(
                ethers.utils.defaultAbiCoder.encode(
                  ['bytes32', 'address', 'address', 'uint256', 'uint256', 'uint256'],
                  [PERMIT_TYPEHASH, deployer.address, alice.address, value, nonce, deadline]
                )
              ),
            ]
          )
        )

        const { v, r, s } = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(DEPLOYER_PRIVATE_KEY, 'hex'))
        
        await expect(bankrollToken.permit(deployer.address, alice.address, value, deadline, v, ethers.utils.hexlify(r), ethers.utils.hexlify(s))).to.revertedWith("revert Arch::permit: signature expired")
      })
    })

    context("mint", async () => {
      it('can perform a valid mint', async () => {
        const totalSupplyBefore = await bankrollToken.totalSupply()
        const mintCap = await bankrollToken.mintCap()
        const maxAmount = totalSupplyBefore.mul(mintCap).div(1000000)
        const supplyChangeAllowed = await bankrollToken.supplyChangeAllowedAfter()
        await ethers.provider.send("evm_setNextBlockTimestamp", [parseInt(supplyChangeAllowed.toString())])
        const balanceBefore = await bankrollToken.balanceOf(alice.address)
        await bankrollToken.mint(alice.address, maxAmount)
        expect(await bankrollToken.balanceOf(alice.address)).to.equal(balanceBefore.add(maxAmount))
        expect(await bankrollToken.totalSupply()).to.equal(totalSupplyBefore.add(maxAmount))
      })

      it('only supply manager can mint', async () => {
        await expect(bankrollToken.connect(alice).mint(bob.address, 1)).to.revertedWith("revert Arch::mint: only the supplyManager can mint")
      })

      it('cannot mint to the zero address', async () => {
        await expect(bankrollToken.mint(ZERO_ADDRESS, 1)).to.revertedWith("revert Arch::mint: cannot transfer to the zero address")
      })

      it('cannot mint in excess of the mint cap', async () => {
        const totalSupply = await bankrollToken.totalSupply()
        const mintCap = await bankrollToken.mintCap()
        const maxAmount = totalSupply.mul(mintCap).div(1000000)
        await expect(bankrollToken.mint(alice.address, maxAmount.add(1))).to.revertedWith("revert Arch::mint: exceeded mint cap")
      })

      it('cannot mint before supply change allowed', async () => {
        await expect(bankrollToken.mint(alice.address, 1)).to.revertedWith("revert Arch::mint: minting not allowed yet")
      })
    })
  
    context("burn", async () => {
      it('can perform a valid burn', async () => {
        const amount = 100
        const totalSupplyBefore = await bankrollToken.totalSupply()
        await bankrollToken.transfer(alice.address, amount)
        const balanceBefore = await bankrollToken.balanceOf(alice.address)
        await bankrollToken.connect(alice).approve(deployer.address, amount)
        const allowanceBefore = await bankrollToken.allowance(alice.address, deployer.address)
        const supplyChangeAllowed = await bankrollToken.supplyChangeAllowedAfter()
        await ethers.provider.send("evm_setNextBlockTimestamp", [parseInt(supplyChangeAllowed.toString())])
        await bankrollToken.burn(alice.address, amount)
        expect(await bankrollToken.balanceOf(alice.address)).to.equal(balanceBefore.sub(amount))
        expect(await bankrollToken.allowance(alice.address, deployer.address)).to.equal(allowanceBefore.sub(amount))
        expect(await bankrollToken.totalSupply()).to.equal(totalSupplyBefore.sub(amount))
      })

      it('only supply manager can burn', async () => {
        await expect(bankrollToken.connect(alice).burn(deployer.address, 1)).to.revertedWith("revert Arch::burn: only the supplyManager can burn")
      })

      it('cannot burn from the zero address', async () => {
        await expect(bankrollToken.burn(ZERO_ADDRESS, 1)).to.revertedWith("revert Arch::burn: cannot transfer from the zero address")
      })

      it('cannot burn before supply change allowed', async () => {
        await expect(bankrollToken.burn(deployer.address, 1)).to.revertedWith("revert Arch::burn: burning not allowed yet")
      })

      it('cannot burn in excess of the spender balance', async () => {
        const supplyChangeAllowed = await bankrollToken.supplyChangeAllowedAfter()
        await ethers.provider.send("evm_setNextBlockTimestamp", [parseInt(supplyChangeAllowed.toString())])
        const balance = await bankrollToken.balanceOf(alice.address)
        await bankrollToken.connect(alice).approve(deployer.address, balance)
        await expect(bankrollToken.burn(alice.address, balance.add(1))).to.revertedWith("revert Arch::burn: burn amount exceeds allowance")
      })

      it('cannot burn in excess of the spender allowance', async () => {
        const supplyChangeAllowed = await bankrollToken.supplyChangeAllowedAfter()
        await ethers.provider.send("evm_setNextBlockTimestamp", [parseInt(supplyChangeAllowed.toString())])
        await bankrollToken.transfer(alice.address, 100)
        const balance = await bankrollToken.balanceOf(alice.address)
        await expect(bankrollToken.burn(alice.address, balance)).to.revertedWith("revert Arch::burn: burn amount exceeds allowance")
      })
    })

    context("setSupplyManager", async () => {
      it('can set a new valid supply manager', async () => {
        await bankrollToken.setSupplyManager(bob.address)
        expect(await bankrollToken.supplyManager()).to.equal(bob.address)
      })

      it('only supply manager can set a new supply manager', async () => {
        await expect(bankrollToken.connect(alice).setSupplyManager(bob.address)).to.revertedWith("revert Arch::setSupplyManager: only SM can change SM")
      })
    })

    context("setMetadataManager", async () => {
      it('can set a new valid metadata manager', async () => {
        await bankrollToken.connect(admin).setMetadataManager(bob.address)
        expect(await bankrollToken.metadataManager()).to.equal(bob.address)
      })

      it('only metadata manager can set a new metadata manager', async () => {
        await expect(bankrollToken.connect(alice).setMetadataManager(bob.address)).to.revertedWith("revert Arch::setMetadataManager: only MM can change MM")
      })
    })

    context("setMintCap", async () => {
      it('can set a new valid mint cap', async () => {
        await bankrollToken.setMintCap(0)
        expect(await bankrollToken.mintCap()).to.equal(0)
      })

      it('only supply manager can set a new mint cap', async () => {
        await expect(bankrollToken.connect(alice).setMintCap(0)).to.revertedWith("revert Arch::setMintCap: only SM can change mint cap")
      })
    })

    context("setSupplyChangeWaitingPeriod", async () => {
      it('can set a new valid supply change waiting period', async () => {
        const waitingPeriodMinimum = await bankrollToken.supplyChangeWaitingPeriodMinimum()
        await bankrollToken.setSupplyChangeWaitingPeriod(waitingPeriodMinimum)
        expect(await bankrollToken.supplyChangeWaitingPeriod()).to.equal(waitingPeriodMinimum)
      })

      it('only supply manager can set a new supply change waiting period', async () => {
        const waitingPeriodMinimum = await bankrollToken.supplyChangeWaitingPeriodMinimum()
        await expect(bankrollToken.connect(alice).setSupplyChangeWaitingPeriod(waitingPeriodMinimum)).to.revertedWith("revert Arch::setSupplyChangeWaitingPeriod: only SM can change waiting period")
      })

      it('waiting period must be > minimum', async () => {
        await expect(bankrollToken.setSupplyChangeWaitingPeriod(0)).to.revertedWith("revert Arch::setSupplyChangeWaitingPeriod: waiting period must be > minimum")
      })
    })

    context("updateTokenMetadata", async () => {
      it('metadata manager can update token metadata', async () => {
        await bankrollToken.connect(admin).updateTokenMetadata("New Token", "NEW")
        expect(await bankrollToken.name()).to.equal("New Token")
        expect(await bankrollToken.symbol()).to.equal("NEW")
      })

      it('only metadata manager can update token metadata', async () => {
        await expect(bankrollToken.connect(alice).updateTokenMetadata("New Token", "NEW")).to.revertedWith("revert Arch::updateTokenMeta: only MM can update token metadata")
      })
    })
  })