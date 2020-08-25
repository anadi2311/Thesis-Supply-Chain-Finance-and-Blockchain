pragma solidity >=0.5.0 <0.6.9;
pragma experimental ABIEncoderV2;

import "./RegisterCompanyInterface.sol";

contract RegisterCompany is RegisterCompanyInterface{
    
    address payable admin;
    
    constructor() public {
        admin = msg.sender;
    }
    
    event CompanyRegistered( uint companyId, string name);
    event ProductRegistered (uint productId, string prodName);
    event Error(string message);
    
    struct Company {
        uint companyId; // unique ID of every company
        address payable owner; // address that owns that company-- each address can have multiple companies 
        string companyName; // name of the company
        string location; // location for delivery 
        string businessNumber; // a unique identification number to match with public address
        bool isInsuranceCompany; // true if insurance company
        
    }
    
    struct Product {
        uint productId; // unique Id of product
        string prodName; // product's name
        uint companyId; // company ID which has the product registered
        uint sellingPrice; // price in wei for the product
    }
    
    uint private initProductId = 0; // initial Id of the product
    uint private companyId = 0; // initial company ID
    uint internal totalCompanies = 0; // total number of the companies
    uint internal totalProducts = 0; // total number of products
   
    mapping (uint => Company) public companies; // mapping containing all the companies (id=>struct)
    mapping (uint => Product) public products; // mapping containing all the products (id=>struct)
    mapping (address => uint) private ownedCompanies; // total number of companies owned by an address


    function generateCompanyId() internal returns(uint){
        companyId +=1;
        return companyId;
        
    }

    function createCompany( string memory _companyName, string memory _location, string memory  _businessNumber) public returns( uint) { 
        // check if businessNumber is right using api oracle
        // check if name and address matches the businessNumber
        //requre businessNumber =9digits
        require(bytes(_companyName).length >0 && (bytes(_location).length >0));
        
        
        Company memory company;
        
        company = Company(generateCompanyId(), msg.sender,_companyName,_location,_businessNumber,false);
        uint _companyId = company.companyId;
        companies[_companyId] = company;
        
        ownedCompanies[msg.sender] +=1;
        totalCompanies +=1;
        
        emit CompanyRegistered(_companyId, _companyName);
        return _companyId;
    }
    
    function getCompany (uint _companyId) public view returns (
        uint companyId,
        address payable owner,
        string memory companyName,
        string memory  location,
        string memory  businessNumber,
        bool isInsuranceCompany)
        {
     Company memory company = companies[_companyId];
     
     return(
        company.companyId,
        company.owner,
        company.companyName,
        company.location,
        company.businessNumber,
        company.isInsuranceCompany
         );
     
        
    }
    
    
    function generateProductId()private returns(uint){
        initProductId +=1;
        return initProductId;
    } 
    
    function registerProduct ( uint _companyId, string memory _prodName,uint _sellingPrice ) public returns(bool success) {
        // oracle if company actually manufactures that _product
        // don't register if already registered
        require( companies[_companyId].owner == msg.sender,"check companyID");
        require(bytes(_prodName).length >0, "product length cannot be zero");
        
        Product memory product;
        product = Product(generateProductId(),_prodName, _companyId,_sellingPrice);
        uint _productId = product.productId;
        products[_productId] = product;
        // productToCompany[_productId] = _companyId;
        // companyOwnedProductNumber[_companyId]+=1;
        totalProducts+=1;
        emit ProductRegistered(_productId,_prodName);
        return true;
    }
    
    function getProduct(uint _productId) public view returns (uint productId,
        string memory prodName,
        uint companyId,
        uint sellingPrice
        ){
            Product memory product = products[_productId];
            return(
            product.productId,
            product.prodName,
            product.companyId,
            product.sellingPrice
        );
        }
    
    
}   
    