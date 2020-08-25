const { parse } = require('path');

const CompleteFinancingContract = artifacts.require("CompleteFinancingContract");
require('chai')
.use(require('chai-as-promised'))
.should();

contract("CompleteFinancingContract", (accounts) => {
    // defining the accounts of the GanacheCLI
    let[supplier1,supplier2,buyer1, buyer2,bank1,bank2,insurance1,insurance2,investor1,investor2] = accounts;

    let contractInstance;

    beforeEach(async () => {
        contractInstance = await CompleteFinancingContract.deployed();
    })
    
    describe("CORRECT DEPLOYMENT.", async () =>{
        it("should return Contract Address", async() =>{
            const contractAddress = await contractInstance.contractAddress();
            assert.notEqual(contractAddress,"");
            assert.notEqual(contractAddress,null);
            assert.notEqual(contractAddress,undefined);

        })

        it("should return correct token names", async() => {
            const REC = await contractInstance.REC();
            const SEC = await contractInstance.SEC();
            assert.equal(REC,"REC for Recievables");
            assert.equal(SEC,"SEC for Securities");
        })
    })

    describe("BASIC BUSINEE OPERATIONS MUST BE FLUID ", async() => {
        describe("MUST ONBOARD ACTORS AND PRODUCTS CORRECTLY.", async() =>{
            it("should onboard suppliers correctly ---> createCompany and GetCompany must work", async()=> {
                result = await contractInstance.createCompany("supplier","supplier", "1",{from: supplier1});
                result2 = await contractInstance.getCompany("1", {from:supplier1});
                const event = result.logs[0].args;
                assert.equal(event.companyId.toNumber(),1,"companyId is right and event can be read");
                assert.equal(event.name,"supplier","Name is right and event can be read" );
                assert.equal(result2.owner,supplier1,"owner is right and info can be fetched!");
                assert.equal(result2.location, "supplier", "location is right! getCompany is working!!");
            })

            it(" should allow suppliers to register product and update inventory", async() => {
                result = await contractInstance.registerProduct("1","product1","1000000000000000000",{from:supplier1});
                result2 = await contractInstance.getProduct("1",{from:buyer1});
                result3 = await contractInstance.manufactureProd("1","2",{from:supplier1});
                await contractInstance.manufactureProd("1","2",{from:supplier2}).should.be.rejected;
                result4 = await contractInstance.getInventory("1",{from:supplier1})
                await contractInstance.getInventory("1",{from:supplier2}).should.be.rejected;
                await contractInstance.removeProduct("1",{from:supplier2}).should.be.rejected;
                result5 = await contractInstance.removeProduct("1",{from:supplier1});
                result6 = await contractInstance.getProduct("1",{from:supplier2});
                const event = result.logs[0].args;
                assert.equal(event.productId.toNumber(),1,"productId is right and event can be read");
                assert.equal(event.prodName,"product1","product name is right.");
                assert.equal(result2.sellingPrice, "1000000000000000000","get Product is working");
                assert.equal(result4,"2","manufactureProd is working.");
                assert.equal(result6.productId,0,"removeProduct working.")
            })
            it("should onboard Bank and Insurance Company",async() => {
                result = await contractInstance.registerBank("bank","bank",{from:bank1})
                result2 = await contractInstance.getBank("1",{from:buyer1});
                assert.equal(result2.bankName,"bank","correct bank Name");
                assert.equal(result2.bankAddress,bank1,"correct Address");
                result3 = await contractInstance.registerAsInsuranceCompany("Insurance","Insurance","4",{from:insurance1})
                result4 = await contractInstance.getCompany("2", {from: supplier2});
                assert.equal(result4.companyName, "Insurance", "correct name");
                assert.equal(result4.isInsuranceCompany,true,"registered as an insurance company")
            })
        })  

        describe ( "MUST ENABLE ORDERING, ACCEPTING AND PAYMENT",async() => {

            it("should be able to make order request and accept it", async() => {
                await contractInstance.registerProduct("1","product1","1000000000000000000",{from:supplier1});
                await contractInstance.manufactureProd("2","2",{from: supplier1});
                await contractInstance.createCompany("buyer","buyer", "3",{from: buyer1});
                await contractInstance.createCompany("carrier","carrier", "4",{from: buyer2});
                await contractInstance.makePurchaseOrderRequest("2","2","3",{from:buyer1});
                await contractInstance.getPurchaseOrderRequest("1",{from:supplier2}).should.be.rejected;
                result = await contractInstance.getPurchaseOrderRequest("1",{from: supplier1})
                assert.equal(result.productId,"2","correct product ID requested for purchase");
                assert.equal(result.isAccepted,false,"PO not accepted yet");
                await contractInstance.acceptOrder("1","4","30",true,{from:supplier2}).should.be.rejected;
                await contractInstance.acceptOrder("1","4","30",false,{from:supplier1});
                await contractInstance.getInvoice("1",{from:bank1}).should.be.rejected;
                result2 = await contractInstance.getInvoice("1",{from:buyer1});
                result3 = await contractInstance.getBillofLading("1",{from:buyer1});
                assert.equal(result3.carrierId,"4","correct carrier is chosen");
                assert.equal(result3.buyerCompanyId,"3","correct delivery address")
                assert.equal(result.isAccepted,false,"PO not accepted yet");
                assert.equal(result2.orderId.toNumber(),1,"correct order number");
                assert.equal(result2.isPaymentDoneByBuyer, false, "Invoice is not yet accepted");
            })

            it("buyer should be able to make payment and seller should be able to accept the payment ", async() => {
                await contractInstance.makePayment("1",{from:supplier2,value:2000000000000000000}).should.be.rejected;
                await contractInstance.makePayment("1",{from:buyer1,value:2000000000000000000}).should.be.rejected;
                await contractInstance.confirmShipment("1",{from:buyer1});
                result = await contractInstance.getShipment("1",{from:supplier1});
                assert.equal(result.isShipmentRecieved,true,"shipment correctly delivered")
                assert.equal(result.deliveryAddress,"buyer","delivered at the correct address")
                let paymentB = await contractInstance.makePayment("1",{from:buyer1,value:2000000000000000000});
                const contractAddress = await contractInstance.contractAddress();
                await contractInstance.getInvoice("1",{from:buyer1});
                result1 = await contractInstance.getInvoice("1",{from:buyer1});
                assert.equal(result1.isPaymentDoneByBuyer,true, "invoice payment successfuly done");
                let sellerOldBalance;
                sellerOldBalance = await web3.eth.getBalance(supplier1);
                // sellerOlBalance = await new web3.utils.BN(sellerOldBalance);
                sellerOldBalance = parseInt(sellerOldBalance);
                let totalRecievables;
                totalRecievables = await contractInstance.getRecBalance(buyer1, {from:supplier1});
                totalRecievables = parseInt(totalRecievables);
                // totalRecievables = new web3.utils.BN(totalRecievables);
                await contractInstance.liquidateRecievables("1",{from: supplier2}).should.be.rejected;
                liquidateRec = await contractInstance.liquidateRecievables("1",{from: supplier1}).should.not.be.rejected;
                const gasUsed = liquidateRec.receipt.gasUsed;
                let expectedBalance = totalRecievables + sellerOldBalance -gasUsed;
                expectedBalance = expectedBalance.toString();
                expectedBalance = await new web3.utils.BN(expectedBalance);
                sellerNewBalance = await web3.eth.getBalance(supplier1);
                sellerNewBalance = await new web3.utils.BN(sellerNewBalance);
                const difference = expectedBalance - sellerNewBalance;
                const contractBalance = await web3.eth.getBalance(contractAddress);
                // console.log(difference);
                // console.log(contractBalance1);
                // console.log(contractBalance);
                // console.log(totalRecievables);
                // console.log(await contractInstance.getInvoice("1", {from:supplier1}));
           
            })
        })   
    })   
    describe("FINANCING SHOULD WORK", async()=>{
        it("seller should be able to apply and bank should be able to accept POF", async()=>{
            await contractInstance.registerBank("bank2","bank2",{from:bank2});
            result = await contractInstance.getCompany("4",{from:supplier1});
            await contractInstance.makePurchaseOrderRequest("2","2","3",{from:buyer1});
            await contractInstance.applyPoFinance("2","2",{from:supplier2}).should.be.rejected;
            await contractInstance.applyPoFinance("2","2",{from:supplier1});
            await contractInstance.getPoFinance("1",{from:bank1}).should.be.rejected;
            result = await contractInstance.getPoFinance("1",{from:bank2});
            assert.equal(result.orderId, "2","orderID is right");
            assert.equal(result.buyerCompanyId,"3","buyer company Id is right")
            assert.equal(result.isApproved, false, "PO is correctly not approved")
            assert.equal(parseInt(result.value,10),2000000000000000000);
            let sellerOldBalance;
            sellerOldBalance = await web3.eth.getBalance(supplier1);
            // // sellerOlBalance = await new web3.utils.BN(sellerOldBalance);
            sellerOldBalance = parseInt(sellerOldBalance);
            await contractInstance.approvePOFinance("1",{from: bank1,value:2000000000000000000}).should.be.rejected;
            await contractInstance.approvePOFinance("1",{from: bank2,value:2000000000000000000});
            bankOldBalance = await web3.eth.getBalance(bank2);
            bankOldBalance = parseInt(bankOldBalance);
            let sellerNewBalance = await web3.eth.getBalance(supplier1);
            sellerNewBalance =  parseInt(sellerNewBalance);
            let expectedBalance = sellerOldBalance + 1600000000000000000;
            // console.log(expectedBalance);
            // console.log(sellerNewBalance);
            result1 = await contractInstance.getPoFinance("1",{from:bank2});
            assert.equal(result1.isApproved, true, "PO finance is correctly approved.");
            assert.equal(sellerNewBalance,expectedBalance);
            await contractInstance.manufactureProd("2","2",{from: supplier1});
            await contractInstance.acceptOrder("2","4","30",true,{from:supplier1});
            await contractInstance.confirmShipment("2",{from:buyer1});
            await contractInstance.makePayment("2",{from:buyer1,value:2000000000000000000});
            liquidateRec = await contractInstance.liquidateRecievables("2",{from: bank2}).should.not.be.rejected;
            ////Ask Ali
            // bankNewBalance = await web3.eth.getBalance(bank2);
            // bankNewBalance = parseInt(bankNewBalance);                        
            // console.log(2000000000000000000 - (bankNewBalance - bankOldBalance));
        })
        it("should allow buyer to apply invoiceFinance and bank to accept it",async() => {
            // will reject Invoice Financing if seller specifies false
            await contractInstance.makePurchaseOrderRequest("2","2","3",{from:buyer1});
            await contractInstance.manufactureProd("2","2",{from: supplier1});
            await contractInstance.acceptOrder("3","4","30",false,{from:supplier1});
            await contractInstance.confirmShipment("3",{from:buyer1});
            await contractInstance.applyApprovedPayableInvoiceFinance("3","1",{from:buyer2}).should.be.rejected;
            await contractInstance.applyApprovedPayableInvoiceFinance("3","1",{from:buyer1}).should.be.rejected;
            //buyer has to do normal payment
            await contractInstance.makePayment("3",{from:buyer1,value:2000000000000000000});
            await contractInstance.liquidateRecievables("3",{from: supplier1}).should.not.be.rejected;
            await contractInstance.makePurchaseOrderRequest("2","2","3",{from:buyer1});
            await contractInstance.manufactureProd("2","2",{from: supplier1});
            await contractInstance.acceptOrder("4","4","30",true,{from:supplier1});
            await contractInstance.confirmShipment("4",{from:buyer1});
            await contractInstance.applyApprovedPayableInvoiceFinance("4","1",{from:buyer1});
            result = await contractInstance.getInvoiceFinance("1",{from:bank1})
            assert.equal(result.invoiceFinanceId,1, "InvoiceDinance ID is correct.");
            assert.equal(result.isApproved,false, "Correctly not yet approved.");
            let sellerOldBalance;
            sellerOldBalance = await web3.eth.getBalance(supplier1);
            // // sellerOlBalance = await new web3.utils.BN(sellerOldBalance);
            sellerOldBalance = parseInt(sellerOldBalance);
            // bankOldBalance = await web3.eth.getBalance(bank1);
            // bankOldBalance = parseInt(bankOldBalance);
            await contractInstance.approveInvoiceFinance("1",{from:bank2,value:2000000000000000000}).should.be.rejected;
            await contractInstance.approveInvoiceFinance("1",{from:bank1,value:2000000000000000000});
            result1 = await contractInstance.getInvoiceFinance("1",{from:bank1})            
            assert.equal(result1.isApproved,true, "correctly approved.");
            let value = parseInt(result.value);
            let expectedBalance = sellerOldBalance + value*90/100;
            let sellerNewBalance =  await web3.eth.getBalance(supplier1);
            sellerNewBalance =  parseInt(sellerNewBalance);
            assert.equal(sellerNewBalance,expectedBalance, "seller sent money");
            await contractInstance.makePayment("4",{from:buyer1,value:2000000000000000000});
            liquidateRec = await contractInstance.liquidateRecievables("4",{from: bank1}).should.not.be.rejected;
            // bankNewBalance = await web3.eth.getBalance(bank1);
            // bankNewBalance = parseInt(bankNewBalance);   
            // console.log(value);
            // console.log(bankOldBalance);                     
            // console.log(200000000000000000 - (bankNewBalance - bankOldBalance))
            // console.log(bankNewBalance)
        })

        it("should allow buyer to securitize the invoices and investors to buy the securities issued", async() => {
            await contractInstance.makePurchaseOrderRequest("2","2","3",{from:buyer1});
            await contractInstance.createCompany("supplier2","supplier2", "5",{from: supplier2});
            await contractInstance.registerProduct("5","product1","2000000000000000000",{from:supplier2});
            await contractInstance.makePurchaseOrderRequest("3","2","3",{from:buyer1});         
            await contractInstance.manufactureProd("2","2",{from: supplier1});
            await contractInstance.manufactureProd("3","2",{from: supplier2});
            await contractInstance.acceptOrder("5","4","30",true,{from:supplier1});
            await contractInstance.acceptOrder("6","4","30",true,{from:supplier2});
            await contractInstance.confirmShipment("5",{from:buyer1});
            await contractInstance.confirmShipment("6",{from:buyer1});
            await contractInstance.applyReverseSecuritization("3","2",{from:buyer2}).should.be.rejected;
            await contractInstance.applyReverseSecuritization("3","2",{from:buyer1});
            result = await contractInstance.getSecurity("1",{from:investor1});
            assert.equal(result.sId, "1","correct security ID");
            assert.equal(result.amount,"6000000000000000000","securities correctly issued");
            assert.equal(result.spvId,"1","correct SPV")
            await contractInstance.rateSpv("1","4",{from: insurance2}).should.be.rejected;
            await contractInstance.rateSpv("1","4",{from: insurance1});
            result1 = await contractInstance.getSpv("1",{from:investor1});
            assert.equal(result1.rating,"4","correctly rated by insurance company.")
            await contractInstance.buySecurities("1",{from:investor1,value:4000000000000000000});
            await contractInstance.buySecurities("1",{from:investor2,value:4000000000000000000});
            await contractInstance.liquidateRecievables("5",{from:supplier1}).should.not.be.rejected;
            await contractInstance.liquidateRecievables("6",{from:supplier2}).should.not.be.rejected;
            await contractInstance.getNoteInfo("1",{from:investor2}).should.be.rejected;
            result3 = await contractInstance.getNoteInfo("1",{from:investor1});
            result4 = await contractInstance.getNoteInfo("2",{from:investor2});
            assert.equal(result3.owner,investor1,"owner is correct");
            assert.equal(result4.noteId,"2","note ID is correct");
            assert.equal(result3.isRedeemed,false,"correctly not redeemed");
            assert.equal(result4.isRedeemed,false,"correctly not redeemed");
            await contractInstance.makePayment("5",{from:buyer1,value:2000000000000000000});
            await contractInstance.makePayment("6",{from:buyer1,value:4000000000000000000});
            // let investor1OldBalance =  await web3.eth.getBalance(investor1);
            // let investor2OldBalance =  await web3.eth.getBalance(investor2);
            // investor1OldBalance = parseInt(investor1OldBalance);
            // investor2OldBalance = parseInt(investor2OldBalance);
            await contractInstance.liquidateNote("1",{from:investor2}).should.be.rejected;
            await contractInstance.liquidateNote("1",{from:investor1}).should.not.be.rejected;
            await contractInstance.liquidateNote("2",{from:investor2}).should.not.be.rejected;
            // investor1Expected = investor1OldBalance + parseInt(result3.amount);
            // investor2Expected = investor2OldBalance + parseInt(result4.amount);
            // let investor1newBalance =  await web3.eth.getBalance(investor1);
            // let investor2newBalance =  await web3.eth.getBalance(investor2);
            // investor1newBalance = parseInt(investor1newBalance);
            // investor2newBalance = parseInt(investor2newBalance);
            // console.log(investor2OldBalance);
            // console.log(parseInt(result4.amount));
            // console.log(parseInt(result3.amount));
            // console.log(investor2newBalance);
            // console.log(parseInt(result4.amount)-(investor2newBalance-investor2OldBalance));
        })
    })
})