pragma solidity ^0.6.0;

import "./SellSideContract.sol";
import "../utils/access.sol";
contract SellSideContractFactory is Access {
    
    
    constructor(address _a) public {
        access = PermissionControl(_a);
        require(_isAdmin(msg.sender),"F1");
    
    }
    
    function updateAccessControl(address _a) public {
        require(_isCR(msg.sender),"F2");
        access = PermissionControl(_a);
        
    }
    
    
    function createNewSellSideContract(uint256 _itemID,address _base,uint256 _price,address _sellsideorder, uint256 _datetime,
                                        string memory _currency,address _access,address _seller,uint256 currentID) public 
    returns(address _i)
    {
         require(_isAdmin(msg.sender) || _isOrder(msg.sender),"F3");
         SellSideContract b = new SellSideContract(_itemID,_base,_price,_currency,_datetime,_access,_seller,currentID,_sellsideorder);
         return(address(b));
    }
    
    
    
    
}