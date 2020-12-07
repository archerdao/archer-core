const { expect } = require("chai")
const { ethers } = require("hardhat");
const { tokenFixture } = require("../fixtures")

describe('SimpleToken', () => {
    let token
    let alice
    let bob
    let ZERO_ADDRESS

    beforeEach(async () => {
      const fix = await tokenFixture()
      token = fix.token
      deployer = fix.deployer
      alice = fix.alice
      bob = fix.bob
      ZERO_ADDRESS = fix.ZERO_ADDRESS
    })

    context('transfer', async () => {
      it('allows a valid transfer', async () => {
        const amount = 100
        const balanceBefore = await token.balanceOf(alice.address)
        await token.transfer(alice.address, amount)
        expect(await token.balanceOf(alice.address)).to.eq(balanceBefore.add(amount))
      })

      it('does not allow a transfer to the zero address', async () => {
        const amount = 100
        await expect(token.transfer(ZERO_ADDRESS, amount)).to.revertedWith("cannot transfer to the zero address")
      })
    })

    context('transferFrom', async () => {
      it('allows a valid transferFrom', async () => {
        const amount = 100
        const senderBalanceBefore = await token.balanceOf(deployer.address)
        const receiverBalanceBefore = await token.balanceOf(bob.address)
        await token.approve(alice.address, amount)
        expect(await token.allowance(deployer.address, alice.address)).to.eq(amount)
        await token.connect(alice).transferFrom(deployer.address, bob.address, amount)
        expect(await token.balanceOf(deployer.address)).to.eq(senderBalanceBefore.sub(amount))
        expect(await token.balanceOf(bob.address)).to.eq(receiverBalanceBefore.add(amount))
        expect(await token.allowance(deployer.address, alice.address)).to.eq(0)
      })

      it('allows for infinite approvals', async () => {
        const amount = 100
        const maxAmount = ethers.constants.MaxUint256
        await token.approve(alice.address, maxAmount)
        expect(await token.allowance(deployer.address, alice.address)).to.eq(maxAmount)
        await token.connect(alice).transferFrom(deployer.address, bob.address, amount)
        expect(await token.allowance(deployer.address, alice.address)).to.eq(maxAmount)
      })

      it('cannot transfer in excess of the spender allowance', async () => {
        await token.transfer(alice.address, 100)
        const balance = await token.balanceOf(alice.address)
        await expect(token.transferFrom(alice.address, bob.address, balance)).to.revertedWith("transfer amount exceeds allowance")
      })
    })
  })