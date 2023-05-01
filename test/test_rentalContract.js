const { time, expectRevert } = require('@openzeppelin/test-helpers');
const rental = artifacts.require("rentalContract");

contract("rentalContract", (accounts) => {

    let rentalContract;
    let priceAssetOne = web3.utils.toWei('0.5', 'ether')

    it("Mint tokens", async() => {
        rentalContract = await rental.deployed();

        await rentalContract.mint(1, priceAssetOne)
        const balance = await rentalContract.balanceOf(accounts[0])
        assert.equal(balance, 1, "Incorrect expected balance")
    })

    it("Rent an asset", async() => {
        await rentalContract.rentAsset(1, {from: accounts[1], value: priceAssetOne})
        const tenant = await rentalContract.tokenTenant(1) 
        assert.equal(tenant, accounts[1], "Account 1 is not the tenant")

        const date = await rentalContract.accquiredDate(1)
        console.log("Accquisition date: ", date[0].toString(), date[1].toString())
        
    })

    it("Pay two months", async() => {
        // await time.increase(time.duration.years(2));
        await rentalContract.monthlyPayment(1, {from: accounts[1], value: priceAssetOne})

        await time.increase(time.duration.weeks(5)); //May
        await rentalContract.monthlyPayment(1, {from: accounts[1], value: priceAssetOne}) 

    })

    it("Try to add a charge to the month already paid", async() => {
        // await rentalContract.addCharge(1, priceAssetOne, 2023, 4)
        await expectRevert(rentalContract.addCharge(1, priceAssetOne, 2023, 4), "Month already paid")
    })

    it("Try to add a charge to a future month", async() => {
        await expectRevert(rentalContract.addCharge(1, priceAssetOne, 2024, 2), "Impossible to add charge for future dates")
        await expectRevert(rentalContract.addCharge(1, priceAssetOne, 2023, 10), "Impossible to add charge for future dates")
    })

    it("Try to add a charge to a month where tenant doesn't had the asset", async() => {
        await expectRevert(rentalContract.addCharge(1, priceAssetOne, 2023, 1), "Charges cannot be entered for dates prior to the purchase of the asset")
    })

    it("Add a charge to an unpaid month", async() => {
        await time.increase(time.duration.weeks(13)); //Skip 3 months
        await rentalContract.addCharge(1, priceAssetOne, 2023, 6)
        await rentalContract.addCharge(1, priceAssetOne, 2023, 7)

        const unpaidMonths = await rentalContract.getUnpaidMonths(1)
        assert.equal(unpaidMonths, 2)

        await expectRevert(rentalContract.addCharge(1, priceAssetOne, 2023, 8), "Impossible to add charge for future dates")
    })

    it("Pay that charge", async() => {
        await rentalContract.payCharge(1, 2023, 6, {from: accounts[1], value: priceAssetOne})
        await rentalContract.payCharge(1, 2023, 7, {from: accounts[1], value: priceAssetOne})

        const unpaidMonths = await rentalContract.getUnpaidMonths(1)
        assert.equal(unpaidMonths, 0)
    })

    it("Add a charge for the next 4 months", async() => {
        await time.increase(time.duration.weeks(21)); //Skip 4 months 
        await rentalContract.addCharge(1, priceAssetOne, 2023, 9)
        await rentalContract.addCharge(1, priceAssetOne, 2023, 10)
        await rentalContract.addCharge(1, priceAssetOne, 2023, 11)
        // await rentalContract.addCharge(1, priceAssetOne, 2023, 12)

        const unpaidMonths = await rentalContract.getUnpaidMonths(1)
        assert.equal(unpaidMonths, 3)
    })

    it("Try to seize the asset", async() => {
        await expectRevert(rentalContract.seizeAsset(1), "Tenant must debt at least 5 months")
    })

    it("Add a charge for the next 2 months", async() => {
        await time.increase(time.duration.weeks(9)); //Skip 2 months 
        await rentalContract.addCharge(1, priceAssetOne, 2023, 12)
        await rentalContract.addCharge(1, priceAssetOne, 2024, 1)

        const unpaidMonths = await rentalContract.getUnpaidMonths(1)
        assert.equal(unpaidMonths, 5)
    })

    it("Seize the asset", async() => {
        await rentalContract.seizeAsset(1)
        
        const tenant = await rentalContract.tokenTenant(1) 
        assert.equal(tenant, "0x0000000000000000000000000000000000000000", "Account 0 is not the tenant")
    })
})