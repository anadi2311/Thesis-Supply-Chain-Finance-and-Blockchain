pragma solidity >=0.5.0 <0.6.9;

interface RegisterCompanyInterface{
    
    function createCompany( string calldata _companyName, string calldata _location, string calldata  _businessNumber) external returns(uint);
    
    function getCompany (uint _companyId) external view returns ( 
        uint companyId,
        address payable owner,
        string memory companyName,
        string memory  location,
        string memory  businessNumber,
        bool isInsuranceCompany
        );
    
    function registerProduct(  uint _companyId, string calldata _prodName,uint _sellingPrice ) external returns(bool);
    
    function getProduct (uint _productId ) external view returns (
        uint productId,
        string memory prodName,
        uint companyId,
        uint sellingPrice
        );
}