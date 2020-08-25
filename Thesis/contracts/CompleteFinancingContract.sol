pragma solidity >=0.5.0 <0.6.9;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./RegisterCompany.sol";
import "./CompleteFinancingContractInterface.sol";

contract CompleteFinancingContract is CompleteFinancingContractInterface, RegisterCompany{
    
    address public contractAddress;// address of the contract
    string  public REC = "REC for Recievables"; // name of the REC token 
    string  public SEC = "SEC for Securities"; // name of SEC token
    using SafeMath for uint256;
    
    constructor() public {
        contractAddress = address(this);
    }
    
    struct PurchaseOrderRequest{
        uint purchaseOrderId;// unique ID of the order
        uint productId; // the product ordered
        uint buyerCompanyId; // the company ordering
        uint qty; // quantity ordered
        bool isAccepted; // whether order is accepted
        // put time for PO, invoice,shipping
    }
    
    struct Invoice{
        uint invoiceId; // unique ID of invoice
        uint orderId;   // order for which invoice is associated
        uint paymentdeadline; // the payment deadline to be decided by the seller
        bool isInvoiceApproved; // is invoice Approved by the buyer confirming Shipment
        bool isPaymentDoneByBuyer; // true if payment made by the buyer
        bool isPaymenttakenBySupplier; // true if payment taken by the supplier
        bool isFinanceRequested; // true if finance requested by the buyer
        bool isInvoiceFinanceAccepted; // true if invoice FInance is accepted by the bank
        uint timeOfCreation; // time of creation of invoice for automatic payment in the future
    }
    
    struct BillOfLading{
        uint bolId; // unique ID for bill of lading
        uint orderId; // order for which BOL is made
        uint buyerCompanyId; // company Id which is getting the bill of Lading
        uint carrierId; // carrier which will transport
        string carrierName; // carrier's name
    }
    
    struct Shipment{
        uint trackingId; // tracking ID for the provenance contract
        uint carrierId; // carrier ID 
        string deliveryAddress;// address of the buyer
        uint qty; // order quantity
        bool isShipmentRecieved; // true if shipment delivered
    }
    
    struct Bank{
        uint bankId; //bank's unique ID
        string bankName; // name of the bank
        string bankCode;// unique code of bank associated with public address
        address payable bankAddress; // bank's public address
    }

    struct PoFinance{
        uint poFinanceId; // unique purchase order finance id
        uint bankId; // bank which can approve or decline the po
        uint orderId; // the order for which finance has been applied
        uint buyerCompanyId; // the company which made the request
        uint value;// value of the order
        bool isApproved; // true if the finance approved
        uint timeOfApproval; // time at which finance is approved
    }
    
    
    struct InvoiceFinance{
        uint invoiceFinanceId; // unique ID of invoice finance
        uint bankId; // bank's ID which can approve or decline the invoice finance
        uint invoiceId; // the invoice's ID for which finance is applied
        uint buyerCompanyId; // buyer company's ID
        uint value; // value of the invoice
        bool isApproved; // true if finance is Approved
    }
    
    struct SPV{
        uint spvId; //unique ID of the SPV
        uint issuerId; // ID of the buyer which issues Security
        uint insuraceCompanyId; // ID of the insurance company to rate
        uint8 rating; // rating out of 5
        
    }
    
    struct Security{
        uint sId; //unique ID of the Security
        uint amount; // amount of securities issued -- SEC tokens 
        uint buyerCompanyId; // the companyID which issues the Security
        uint spvId; // SPV generated for Security
    }
    
    struct Note{
        uint noteId; // unique ID of the Note
        uint sId; // Security associated to the note
        uint amount; // amount of SEC tokens
        address payable owner;// owner's public address
        bool isRedeemed; // true if note is redemmed for ether
    }
    
    
    event Faliure(string message);
    event BankRegistered(uint bankId, string bankName);
    event PoFinanceApproved(uint poFinanceId);
    event OrderAccepted(uint _orderId);
    event ShipmentDelivered(uint OrderId);
    event InvoiceFinanceApproved(uint invoiceFinanceId);
    event PaymentMade(uint _invoiceId);

    mapping(address => mapping(address => uint256)) private allowances;// REC token from address to address
    mapping(address => mapping(address => uint256)) private secAllowances; //SEC tokens from address to address
    
    mapping (uint => uint) private productToInventory; // inventory associated to the product ID
    mapping (uint => PurchaseOrderRequest) private purchaseOrderRequests; // all the purchaseOrderRequests 
    mapping (uint => bool) private isPOFinanceRequested; // whether PO finance is Requested
    mapping (uint => Invoice) private invoices; // stores all the invoices to their IDs
    mapping (uint => BillOfLading) private billofLadings; // all bill of ladinfs
    mapping (uint => Shipment) private orderToShipment; // all the shipments indexed by orderID
    mapping (uint=> Bank) public banks; // all the banks
    mapping (address => uint) private ownedBanks;// number of banks to a public address
    mapping (uint => PoFinance) private poFinances; // all the poFinances
    mapping (uint => InvoiceFinance) private invoiceFinances; // all the invoiceFinances
    mapping (uint => uint) private companyOwnedFinanceAcceptedInvoices; // number of invoices accepting invoiceFinances
    mapping (uint => SPV) public spvs; //all the spvs
    mapping (uint => Security) public securities; //all the securities
    mapping (uint => Note) private notes; // all the notes
    
    uint private orderId =0; //initial orderId
    uint private totalbolId = 0; //initial billofLading ID
    uint private trackingId = 0; //initial shipment ID
    uint private totalInvoices = 0; //initial invoice ID 

    uint private bankId =0; //bank's ID
    uint8 public poDiscountRate= 80; // po discount in percentage
    uint8 public invoiceDiscountRate  = 90; // invoice discount in percentage
    
    uint private totalpof = 0;// initial poFinance ID and total poFinances
    uint private totalInvoiceFinances = 0;  // initial invoice ID and and total invoice finances
    
    uint private sId  = 0; // initial security ID
    uint private spvId = 0; // initla spv ID
    uint private noteId = 0; // initial note ID

    
    function manufactureProd(uint _productId, uint _amount)public returns(bool success) {
        require(companies[products[_productId].companyId].owner == msg.sender,"you are not the owner of the product");
        productToInventory[_productId]= productToInventory[_productId].add(_amount);
        return true;
    }
    
    function getInventory(uint _productId) public view returns(uint){
        require(companies[products[_productId].companyId].owner == msg.sender,"Not your product");
        return productToInventory[_productId];
        
    }
    function removeProduct(uint _productId) public returns (bool success){
        
        uint _companyId = products[_productId].companyId;
        address owner = companies[_companyId].owner;
        require(msg.sender == owner && products[_productId].companyId>0, "You are not the owner of the Product");
        
        productToInventory[_productId] =0;
        delete products[_productId];
        return true;
    }
        
    function calculateRecievables(uint _qty, uint _price) internal pure returns(uint _recievables){
       _recievables = _qty.mul(_price);
       return _recievables;
    }
    
    function approveRecievables(address _from , address _to, uint256 _value) private returns (bool success) {
    allowances[_from][_to] = allowances[_from][_to].add(_value);
        return true;
    }
    
    function registerBank(string memory _bankName, string memory _bankCode )public returns (bool success){
    require(ownedBanks[msg.sender] <1);
    bankId = bankId.add(1);
    Bank memory bank;
    bank = Bank(bankId,_bankName, _bankCode, msg.sender);
    banks[bankId] = bank;
    ownedBanks[msg.sender] = ownedBanks[msg.sender].add(1);
    emit BankRegistered(bankId,_bankName);
    return true;
    }
    
    function getBank(uint _bankId) public view returns (
        uint bankId,
        string memory bankName,
        string memory bankCode,//confirm with prof 
        address payable bankAddress){
            Bank memory bank = banks[_bankId];
            return(
                bank.bankId,
                bank.bankName,
                bank.bankCode, 
                bank.bankAddress
                        );
        }
    
    function makePurchaseOrderRequest(uint _productId, uint _qty, uint _buyerCompanyId ) public returns(bool success){
        require(companies[_buyerCompanyId].owner == msg.sender && companies[products[_productId].companyId].owner != msg.sender ,"check the company ID or you might be ordering your own product");
        orderId = orderId.add(1);
        purchaseOrderRequests[orderId] = PurchaseOrderRequest(orderId,_productId, _buyerCompanyId, _qty,false);
        isPOFinanceRequested[orderId] = false;
        // emit RequestSent(orderId);
        return true;
        }
    
    function getPurchaseOrderRequest(uint _orderId) public view returns(uint purchaseOrderId,
        uint productId,
        uint buyerCompanyId,
        uint qty,
        bool isAccepted){
        address poBankAddress = banks[poFinances[getpofId(_orderId)].bankId].bankAddress;
        // address invoiceFinanceBankAddress = banks[invoiceFinances[getinvoiceFinanceId(_orderId)].bankId].bankAddress;
        require(msg.sender == companies[products[purchaseOrderRequests[_orderId].productId].companyId].owner || msg.sender == companies[purchaseOrderRequests[_orderId].buyerCompanyId].owner || msg.sender == poBankAddress
        , "access denied");
        
        PurchaseOrderRequest memory purchaseOrderRequest = purchaseOrderRequests[_orderId];
        return (
            purchaseOrderRequest.purchaseOrderId,
            purchaseOrderRequest.productId,
            purchaseOrderRequest.buyerCompanyId,
            purchaseOrderRequest.qty,
            purchaseOrderRequest.isAccepted
        );
    }
    
    function acceptOrder( uint _orderId, uint _carrierId, uint _paymentDueDays, bool _invoiceFinanceAccepted) public returns (bool success){
        require(companies[products[purchaseOrderRequests[_orderId].productId].companyId].owner == msg.sender && purchaseOrderRequests[_orderId].isAccepted == false, "cannot accept the order"); 
        uint _productId = purchaseOrderRequests[_orderId].productId;
        uint _qty = purchaseOrderRequests[_orderId].qty;
        uint _currentInventory = productToInventory[_productId];
        if (_qty <= _currentInventory){
            productToInventory[purchaseOrderRequests[_orderId].productId] = productToInventory[purchaseOrderRequests[_orderId].productId].sub(purchaseOrderRequests[_orderId].qty);
            purchaseOrderRequests[_orderId].isAccepted = true;
            
            //getter for pof 
            if(poFinances[getpofId(_orderId)].isApproved ==true){
                _invoiceFinanceAccepted = false;
            }
            makeInvoice(_orderId,_paymentDueDays,_invoiceFinanceAccepted);
            makeBillOfLading(_orderId,_carrierId);
            shipThisOrder(_carrierId,_orderId);
            emit OrderAccepted(_orderId);
        }
        else {
            emit Faliure("Not enough inventory! Cannot Accpet Order. Manufacture remaining or Request for PO Finance! ");        
        }
        return true;
    }
    
    
    function makeInvoice( uint _orderId,  uint _paymentDueDays, bool _invoiceFinanceAccepted) private returns (bool success) {
       
       bool _isFinanceRequested = false;
       uint  _timeofCreation = now;
       totalInvoices = totalInvoices.add(1);
       invoices[totalInvoices] = Invoice(totalInvoices,_orderId, _paymentDueDays,false, false,false,_isFinanceRequested,_invoiceFinanceAccepted, _timeofCreation);
       if(_invoiceFinanceAccepted == true){
       companyOwnedFinanceAcceptedInvoices[purchaseOrderRequests[_orderId].buyerCompanyId] = companyOwnedFinanceAcceptedInvoices[purchaseOrderRequests[_orderId].buyerCompanyId].add(1);
       }
       return true;
    }
    
    function makeBillOfLading(uint _orderId, uint _carrierId) private returns (bool success) {
        totalbolId = totalbolId.add(1);
        uint _buyerCompanyId = purchaseOrderRequests[_orderId].buyerCompanyId;
        string memory _carrierName = companies[_carrierId].companyName;
        billofLadings[totalbolId] = BillOfLading(totalbolId,_orderId,_buyerCompanyId,_carrierId,_carrierName);
        return true;        
    }
    
    // decline Request function is not needed. Buyer can just not accept a request
    
    function shipThisOrder( uint _carrierId, uint _orderId) private returns (bool success) {
        require(purchaseOrderRequests[_orderId].isAccepted = true);
        // vehicleNo = vehicleNo.add(1);
        trackingId = trackingId.add(1);
        uint _qty = purchaseOrderRequests[_orderId].qty;// determine by for loop
        // uint _productId = purchaseOrderRequests[_orderId].productId; // determine by QR and hash
        uint _bolId = getBillofLadingID(_orderId);
        string memory _recieverLocation = companies[purchaseOrderRequests[_orderId].buyerCompanyId].location; // check from the location GPS
        // assuming right checkQuantity and ProductId
        string memory _deliveryAddress =  companies[billofLadings[_bolId].buyerCompanyId].location;
        
        orderToShipment[_orderId] = Shipment(trackingId,_carrierId,_deliveryAddress, _qty,false );
        return true;
    }
    
    function getInvoiceId( uint _orderId) public view returns( uint invoiceId){
        
        address poBankAddress = banks[poFinances[getpofId(_orderId)].bankId].bankAddress;
        address invoiceFinanceBankAddress = banks[invoiceFinances[getinvoiceFinanceId(_orderId)].bankId].bankAddress;
        require(msg.sender == companies[products[purchaseOrderRequests[_orderId].productId].companyId].owner || msg.sender == companies[purchaseOrderRequests[_orderId].buyerCompanyId].owner 
        || msg.sender == poBankAddress || msg.sender == invoiceFinanceBankAddress);
        
        for (uint i = 0; i<= totalInvoices; i++){
            if( invoices[i].orderId == _orderId){
                return i;
    }
    }
    }   
    
    
    function getInvoice(uint _orderId) public view returns(
        uint invoiceId,
        uint orderId,
        uint paymentdeadline,
        bool isInvoiceApproved,
        bool isPaymentDoneByBuyer,
        bool isPaymenttakenBySupplier,
        bool isFinanceRequested,
        bool isInvoiceFinanceAccepted,
        uint timeOfCreation
        ){
        
                Invoice memory invoice = invoices[getInvoiceId(_orderId)];
                return( invoice.invoiceId,
                        invoice.orderId,
                        invoice.paymentdeadline,
                        invoice.isInvoiceApproved,
                        invoice.isPaymentDoneByBuyer,
                        invoice.isPaymenttakenBySupplier,
                        invoice.isFinanceRequested,
                        invoice.isInvoiceFinanceAccepted,
                        invoice.timeOfCreation
                    );
            }
    
    
    function getBillofLadingID( uint _orderId) private view returns(uint bolId){
        
        require(msg.sender == companies[products[purchaseOrderRequests[_orderId].productId].companyId].owner || msg.sender == companies[purchaseOrderRequests[_orderId].buyerCompanyId].owner);
       
        for (uint i = 0; i<= totalbolId; i++){
            if( billofLadings[i].orderId == _orderId){
                return i;
            }
        }
    }


    function getBillofLading( uint _orderId) public view returns(
        uint bolId,
        uint orderId,
        uint buyerCompanyId,
        uint carrierId,
        string memory carrierName
        ){
        BillOfLading memory billOfLading = billofLadings[getBillofLadingID(_orderId)];
        return(
            billOfLading.bolId,
            billOfLading.orderId,
            billOfLading.buyerCompanyId,
            billOfLading.carrierId,
            billOfLading.carrierName
            );
    }
  
    function getShipment( uint _orderId) public view returns(
        uint trackingId,
        uint carrierId,
        string memory deliveryAddress,
        uint qty,
        bool isShipmentRecieved
    ){
        address poBankAddress = banks[poFinances[getpofId(_orderId)].bankId].bankAddress;
        address invoiceFinanceBankAddress = banks[invoiceFinances[getinvoiceFinanceId(_orderId)].bankId].bankAddress;
        require(msg.sender == companies[products[purchaseOrderRequests[_orderId].productId].companyId].owner || msg.sender == companies[purchaseOrderRequests[_orderId].buyerCompanyId].owner 
        || msg.sender == poBankAddress || msg.sender == invoiceFinanceBankAddress);
       Shipment memory shipment = orderToShipment[_orderId];
       return(
        shipment.trackingId,
        shipment.carrierId,
        shipment.deliveryAddress,
        shipment.qty,
        shipment.isShipmentRecieved
           );
        
    }
        
    function confirmShipment(uint _invoiceId) public returns (bool success){
        // use oracle to confirm the location
        // notofy seller of delivery if location has reached
        // buyer has to checkQuantity
        require(orderToShipment[invoices[_invoiceId].orderId].isShipmentRecieved == false);
        address payable _reciever = companies[purchaseOrderRequests[invoices[_invoiceId].orderId].buyerCompanyId].owner;
        require(msg.sender == _reciever);
        address payable _seller = companies[products[purchaseOrderRequests[invoices[_invoiceId].orderId].productId].companyId].owner;
        //assuming correct qty
        uint _qty = purchaseOrderRequests[invoices[_invoiceId].orderId].qty;
        uint _price = products[purchaseOrderRequests[invoices[_invoiceId].orderId].productId].sellingPrice;
        invoices[_invoiceId].isInvoiceApproved = true;
        orderToShipment[invoices[_invoiceId].orderId].isShipmentRecieved = true;
        uint _value = calculateRecievables(_qty,_price);
        // if qty wrong then notify Bank and paymen
        if(invoices[_invoiceId].isFinanceRequested == true){
            // Invoice Financing    --do nothing.
        }
        else if(isPOFinanceRequested[invoices[_invoiceId].orderId] == false){
            approveRecievables(msg.sender,_seller, _value);           
        }
        else if(isPOFinanceRequested[invoices[_invoiceId].orderId] == true){
            // Purchase Order Financing
            uint _poFinanceId = getpofId(invoices[_invoiceId].orderId);
            if(poFinances[_poFinanceId].isApproved==true){
                address payable _bankAddress = banks[poFinances[_poFinanceId].bankId].bankAddress;
                approveRecievables(msg.sender, _bankAddress,_value);
                invoices[_invoiceId].isPaymenttakenBySupplier =true;
            }
            else{
                emit Faliure("finance not approved but shipment reached!");
            }
        }
    emit ShipmentDelivered(invoices[_invoiceId].orderId);
    return true;
    }
    
       
    function cancelOrder(uint _orderId) public returns(bool success) {
        uint _poFinanceId = getpofId(_orderId);
        require(purchaseOrderRequests[_orderId].isAccepted == false && companies[purchaseOrderRequests[_orderId].buyerCompanyId].owner == msg.sender &&
        poFinances[_poFinanceId].isApproved == false);
        delete purchaseOrderRequests[_orderId];
        return true;
    }
    
    function makePayment( uint _invoiceId) public payable returns (bool success) {
        //_buyer use this to send money to contract
        require(msg.sender == companies[purchaseOrderRequests[invoices[_invoiceId].orderId].buyerCompanyId].owner && invoices[_invoiceId].isPaymentDoneByBuyer == false && invoices[_invoiceId].isInvoiceApproved == true);
        uint _qty = orderToShipment[invoices[_invoiceId].orderId].qty;
        uint _price = products[purchaseOrderRequests[invoices[_invoiceId].orderId].productId].sellingPrice;
        uint _value = calculateRecievables(_qty,_price);
        require(msg.value >= _value);
        if(msg.value > _value ) {
            address(uint160(msg.sender)).transfer(msg.value.sub(_value));
        }
       invoices[_invoiceId].isPaymentDoneByBuyer = true;
        emit PaymentMade(_invoiceId);
        return true;
    }
    
    function liquidateRecievables( uint _invoiceId) public returns (bool success){
        
        address payee =    companies[purchaseOrderRequests[invoices[_invoiceId].orderId].buyerCompanyId].owner;
        
        address seller = companies[products[purchaseOrderRequests[invoices[_invoiceId].orderId].productId].companyId].owner;
        
        
        uint _amount   = allowances[payee][msg.sender];
        require(_amount>0);

        if(msg.sender == seller){
        if (invoices[_invoiceId].isFinanceRequested == true && invoices[_invoiceId].isPaymentDoneByBuyer == false){
            // reverseSEc case
            msg.sender.transfer(_amount*invoiceDiscountRate/100);
            allowances[payee][msg.sender] = allowances[payee][msg.sender].sub(_amount);
        }
        else{
            //normal business case
        msg.sender.transfer(_amount);
        allowances[payee][msg.sender] = allowances[payee][msg.sender].sub(_amount);
        }
        invoices[_invoiceId].isPaymenttakenBySupplier= true;
        }
        else if(invoices[_invoiceId].isPaymentDoneByBuyer == true) {
        // for banks
        msg.sender.transfer(_amount);
        allowances[payee][msg.sender] = allowances[payee][msg.sender].sub(_amount);
        }

        return true;
    }    
    
        //-----------------------------------------------------------------------------------------------------------------------------------------//
    function getpofId(uint _orderId) private view returns(uint pofId){
        for (uint i = 0; i<= totalpof; i++){
            if( poFinances[i].orderId == _orderId){
                return i ;
            }
        }
    }
    
    function applyPoFinance(uint _orderId, uint _bankId) public returns(bool success){
        bool _isFinanceRequested = isPOFinanceRequested[_orderId];
        uint _sellerCompanyId = products[purchaseOrderRequests[_orderId].productId].companyId;
        address seller = companies[_sellerCompanyId].owner;
        uint _buyerCompanyId = purchaseOrderRequests[_orderId].buyerCompanyId;
        require(_isFinanceRequested == false && seller == msg.sender && purchaseOrderRequests[_orderId].isAccepted == false
            && invoices[getInvoiceId(_orderId)].invoiceId == 0);
        uint _qty = purchaseOrderRequests[_orderId].qty;
        uint _price = products[purchaseOrderRequests[_orderId].productId].sellingPrice;
        uint _value = calculateRecievables(_qty,_price);
        isPOFinanceRequested[_orderId]= true;
        bool _isApproved = false;
        // poFinanceId =  poFinanceId.add(1);
        totalpof = totalpof.add(1);
        poFinances[totalpof] = PoFinance(totalpof,_bankId,_orderId,_buyerCompanyId,_value,_isApproved,0);
        return true;
    }
    
    function getPoFinanceStruct(uint _poFinanceId) private view returns(PoFinance memory poFinance ){
        address poBankAddress = banks[poFinances[_poFinanceId].bankId].bankAddress;
        require(msg.sender == companies[products[purchaseOrderRequests[poFinances[_poFinanceId].orderId].productId].companyId].owner 
        || msg.sender == poBankAddress);
        PoFinance memory poFinance = poFinances[_poFinanceId];
        return(poFinance);
    }
    
    function getPoFinance(uint _poFinanceId) public view returns( 
        uint poFinanceId,
        uint bankId,
        uint orderId,
        uint buyerCompanyId,
        uint value,
        bool isApproved,
        uint timeOfApproval
        ){
        PoFinance memory pofinace = getPoFinanceStruct(_poFinanceId);
        return(
        pofinace.poFinanceId,
        pofinace.bankId,
        pofinace.orderId,
        pofinace.buyerCompanyId,
        pofinace.value,
        pofinace.isApproved,
        pofinace.timeOfApproval
                    );
        
    }
    
    function approvePOFinance(uint _poFinanceId) public payable returns(bool success){
        address payable _sellerAddress = companies[products[purchaseOrderRequests[poFinances[_poFinanceId].orderId].productId].companyId].owner;
        address payable _buyerAddress = companies[purchaseOrderRequests[poFinances[_poFinanceId].orderId].buyerCompanyId].owner;
        uint _recievablesValue = poFinances[_poFinanceId].value;
        uint _transferAmount = poDiscountRate*_recievablesValue/100 ;
        address payable _bankAddress = banks[poFinances[_poFinanceId].bankId].bankAddress;
        require ( _bankAddress ==msg.sender && poFinances[_poFinanceId].isApproved == false && (msg.value >= _transferAmount));
        if(msg.value > _transferAmount ) {
            address(uint160(msg.sender)).transfer(msg.value.sub(_transferAmount));
        }
        address(uint160(_sellerAddress)).transfer(_transferAmount);
        poFinances[_poFinanceId].isApproved = true;
        poFinances[_poFinanceId].timeOfApproval = now;        

        invoices[getInvoiceId(poFinances[_poFinanceId].orderId)].isPaymenttakenBySupplier = true;
        emit PoFinanceApproved(_poFinanceId);
        return true;
    }

    //-----------------------------------------------------------------------------------------------------------------------------------------//

    function applyApprovedPayableInvoiceFinance(uint _invoiceId, uint _bankId) public returns (bool success){
        require(isPOFinanceRequested[invoices[_invoiceId].orderId] == false && invoices[_invoiceId].isFinanceRequested == false && invoices[_invoiceId].isPaymentDoneByBuyer == false && 
        companies[purchaseOrderRequests[invoices[_invoiceId].orderId].buyerCompanyId].owner == msg.sender && invoices[_invoiceId].isInvoiceFinanceAccepted == true && invoices[_invoiceId].isInvoiceApproved==true);
        invoices[_invoiceId].isFinanceRequested = true;
        totalInvoiceFinances = totalInvoiceFinances.add(1);
        uint _buyerCompanyId = purchaseOrderRequests[invoices[_invoiceId].orderId].buyerCompanyId;
        uint _qty = purchaseOrderRequests[invoices[_invoiceId].orderId].qty;
        uint _price = products[purchaseOrderRequests[invoices[_invoiceId].orderId].productId].sellingPrice;
        uint _value = calculateRecievables(_qty,_price);
        invoiceFinances[totalInvoiceFinances] = InvoiceFinance(totalInvoiceFinances, _bankId,_invoiceId, _buyerCompanyId, _value, false);
        return true;
    }
    
    function approveInvoiceFinance( uint _invoiceFinanceId) public payable returns (bool success){
        
        address payable _sellerAddress = companies[products[purchaseOrderRequests[invoices[invoiceFinances[_invoiceFinanceId].invoiceId].orderId].productId].companyId].owner;
        address payable _buyerAddress = companies[purchaseOrderRequests[invoices[invoiceFinances[_invoiceFinanceId].invoiceId].orderId].buyerCompanyId].owner;
        uint _recievablesValue = invoiceFinances[_invoiceFinanceId].value;
        uint _transferAmount = invoiceDiscountRate*_recievablesValue/100 ;
        require( msg.sender == banks[invoiceFinances[_invoiceFinanceId].bankId].bankAddress && invoiceFinances[_invoiceFinanceId].isApproved == false && msg.value >= _transferAmount);
        if(msg.value > _transferAmount ) {
            address(uint160(msg.sender)).transfer(msg.value.sub(_transferAmount));
        }
        address(uint160(_sellerAddress)).transfer(_transferAmount);
        invoiceFinances[_invoiceFinanceId].isApproved = true;
        invoices[invoiceFinances[_invoiceFinanceId].invoiceId].isPaymenttakenBySupplier= true;
        allowances[_buyerAddress][_sellerAddress] = allowances[_buyerAddress][_sellerAddress].sub(_recievablesValue);
        approveRecievables(_buyerAddress,msg.sender,_recievablesValue);
        emit InvoiceFinanceApproved(_invoiceFinanceId);
        return true;
    }
    
    
    function getinvoiceFinanceId(uint _invoiceId) private view returns(uint) {
        for (uint i = 0; i<= totalInvoiceFinances; i++){
            if( invoiceFinances[i].invoiceId == _invoiceId){
                return i ;
            }
        }
    }
    
    function getInvoiceFinanceStruct(uint _invoiceFinanceId) private view returns( InvoiceFinance memory invoiceFinance){
        // uint _invoiceFinanceId = getinvoiceFinanceId(_invoiceId);
        address invoiceFinanceBankAddress = banks[invoiceFinances[_invoiceFinanceId].bankId].bankAddress;
        require(msg.sender == companies[products[purchaseOrderRequests[invoices[invoiceFinances[_invoiceFinanceId].invoiceId].orderId].productId].companyId].owner || msg.sender == companies[invoiceFinances[_invoiceFinanceId].buyerCompanyId].owner 
        || msg.sender == invoiceFinanceBankAddress);
        invoiceFinance = invoiceFinances[_invoiceFinanceId];
        return(invoiceFinance );
    }
    
    
    function getInvoiceFinance(uint _invoiceFinanceId) public view returns( 
        uint invoiceFinanceId,
        uint bankId,
        uint invoiceId,
        uint buyerCompanyId,
        uint value,
        bool isApproved
    ){  
        InvoiceFinance memory invoiceFinance = getInvoiceFinanceStruct(_invoiceFinanceId);
        return(
                invoiceFinance.invoiceFinanceId,
                invoiceFinance.bankId,
                invoiceFinance.invoiceId,
                invoiceFinance.buyerCompanyId,
                invoiceFinance.value,
                invoiceFinance.isApproved

            );
    }
    //-----------------------------------------------------------------------------------------------------------------------------------------//

    function registerAsInsuranceCompany( string memory _companyName, string memory _location, string memory _businessNumber)public {
        uint _companyId  = createCompany(_companyName,_location,_businessNumber);
        companies[_companyId].isInsuranceCompany = true;
    }
    
    function createSpv(uint _issuerId, uint _insuranceCompanyId) private returns( uint){
        spvId = spvId.add(1);
        spvs[spvId] = SPV(spvId,_issuerId,_insuranceCompanyId,0);
        return spvId;
    }
    
    function rateSpv( uint _spvId, uint8 _rating)  public {
        require(companies[spvs[_spvId].insuraceCompanyId].owner == msg.sender && _rating >=0 && _rating<=5);
        spvs[_spvId].rating = _rating;
        
    }
    
    function getSpv( uint _spvId) public view returns(
        uint spvId,
        uint issuerId,
        uint insuraceCompanyId,
        uint8 rating){
            
            SPV memory spv = spvs[_spvId];
            return(
                    spv.spvId,
                    spv.issuerId,
                    spv.insuraceCompanyId,
                    spv.rating
                            );
        }
    
    
    
    
    function getAllBuyerInvoiceFinancePayable(uint _buyerCompanyId) private returns(uint _totalfinanciablePayable){
        
        uint i;
        uint _ownedFinancedAcceptedInvoices = companyOwnedFinanceAcceptedInvoices[_buyerCompanyId];
        if(_ownedFinancedAcceptedInvoices == 0){
            return 0;
        }
        else{
        for(i=1; i<= totalInvoices; i++){
            if (purchaseOrderRequests[invoices[i].orderId].buyerCompanyId == _buyerCompanyId && invoices[i].isInvoiceApproved && invoices[i].isPaymenttakenBySupplier == false && invoices[i].isInvoiceFinanceAccepted == true){
                invoices[i].isFinanceRequested = true;
                uint _qty= purchaseOrderRequests[invoices[i].orderId].qty;
                uint _price = products[purchaseOrderRequests[invoices[i].orderId].productId].sellingPrice;
                
                uint _payable = calculateRecievables(_qty,_price);
                _totalfinanciablePayable = _totalfinanciablePayable.add(_payable);
            }
            
        }
        return _totalfinanciablePayable;
        }
    
    }
    
    function applyReverseSecuritization(uint _buyerCompanyId, uint _insuranceCompanyId) public {
        address _buyerAddress = companies[_buyerCompanyId].owner;
        uint _totalfinanciablePayable = getAllBuyerInvoiceFinancePayable(_buyerCompanyId);
        require(companies[_insuranceCompanyId].isInsuranceCompany ==true && _totalfinanciablePayable>0 && _buyerAddress== msg.sender);
        
        spvId = createSpv(_buyerCompanyId,_insuranceCompanyId);
        sId = sId.add(1);
        
        securities[sId] = Security(sId,_totalfinanciablePayable,_buyerCompanyId,spvId);
    }
    
    function getSecurity( uint _securityId) public view returns (
        uint sId,
        uint amount,
        uint buyerCompanyId,
        uint spvId
    ){
        Security memory security = securities[_securityId];
        return(
                security.sId,
                security.amount,
                security.buyerCompanyId,
                security.spvId
            );
    }

 
 
    function getNoteInfo(uint _noteId) public view returns(
        uint noteId,
        uint sId,
        uint amount,
        address payable owner,
        bool isRedeemed
        ){
        
        require(notes[_noteId].owner == msg.sender);
        
        Note memory note = notes[_noteId];
    
        return(
                note.noteId,
                note.sId,
                note.amount,
                note.owner,
                note.isRedeemed
            );
        
    }

    
    function buySecurities( uint _sId) public payable{
       // replace _totalSecurityAmount by amount>0 in require
       require(msg.value > 0);
       uint _totalSecurityAmount = securities[_sId].amount;
        // how many wei's of securities to buy
       address _buyerAddress = companies[securities[_sId].buyerCompanyId].owner;
       uint _securitiesBought = msg.value*100/invoiceDiscountRate;
       noteId = noteId.add(1);
       if(_securitiesBought > _totalSecurityAmount ) {
           
            address(uint160(msg.sender)).transfer((msg.value.sub( _totalSecurityAmount*invoiceDiscountRate/100)));
            securities[_sId].amount = 0;
            secAllowances[_buyerAddress][msg.sender] = secAllowances[_buyerAddress][msg.sender].add(_totalSecurityAmount);
            notes[noteId] = Note(noteId,_sId, _totalSecurityAmount,msg.sender,false);
        }
        
        else{
        uint _securitiesLeft = _totalSecurityAmount.sub(_securitiesBought);
        securities[_sId].amount = _securitiesLeft;
        
        secAllowances[_buyerAddress][msg.sender] = secAllowances[_buyerAddress][msg.sender].add( _securitiesBought);
        
        notes[noteId] = Note(noteId,_sId, _securitiesBought,msg.sender,false);
        }
    }
    
    
    function liquidateNote ( uint _noteId) public {
        require(notes[_noteId].isRedeemed == false && notes[_noteId].owner == msg.sender);
        
        address _buyerAddress = companies[securities[notes[_noteId].sId].buyerCompanyId].owner;
        uint _amount   = secAllowances[_buyerAddress][msg.sender];
        require(address(this).balance>= _amount);
        
        msg.sender.transfer(_amount);
        
        secAllowances[_buyerAddress][msg.sender] = secAllowances[_buyerAddress][msg.sender].sub(_amount);
        notes[_noteId].isRedeemed = true;
                
    }
    
    
    function getRecBalance(address _from) public view returns(uint recbalance){
        
        return allowances[_from][msg.sender];
        
    }
    
    
    function getSecBalance(address _from) public view returns(uint){
        
        return secAllowances[_from][msg.sender];
    }
    
    function() external payable {
}
 
}