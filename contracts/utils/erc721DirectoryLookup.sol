pragma solidity ^0.6.0;
import "./access.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
contract erc721DirectoryService is Access {
    
    using Address for address;
    
    uint256 count;
    
    mapping(uint256 => address) private baseAddressLooup;

    constructor(address _access) public 
    {
        access = PermissionControl(_access);
        require(_isAdmin(msg.sender),"DS01");
        count=0;
    }
    
    function getBaseAddress(uint256 _id) public view
    returns(address _a)
    {
        require(access.hasRole(access.MEMBER(),msg.sender),"DS02");
        require(baseAddressLooup[_id]!=address(0),"D1");
        return(baseAddressLooup[_id]);
        
    }
    
    function setBaseAddress(uint256 _id,address _base) public
    {
        require(access.hasRole(access.ERC721TOKEN(),msg.sender) || _isAdmin(msg.sender),"DS03");
        require(_id!=0 && _base!=address(0),"D3");
        baseAddressLooup[_id]=_base;
        count+=1;
    }
    
    function getCount() public view
    returns(uint256 _c)
    {
        require( _isAdmin(msg.sender),"DS04");
        return count;
    }
    
}