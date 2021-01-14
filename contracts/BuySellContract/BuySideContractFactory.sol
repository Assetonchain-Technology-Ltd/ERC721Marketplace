pragma solidity ^0.6.0;

import "./BuySideContract.sol";
import "../utils/access.sol";
contract BuySideContractFactory is Access {
    
    
    constructor(address _a) public {
        access = PermissionControl(_a);
        require(_isAdmin(msg.sender),"F1");
    
    }
    
    function updateAccessControl(address _a) public {
        require(_isCR(msg.sender),"F2");
        access = PermissionControl(_a);
        
    }
    
    function createNewBuySideContract(uint256 _itemID, uint256 _price, uint256 _feesprecentage, string memory _currency,
                                        uint256 _createdatetime,address _seller,address _access,address _baseaddr) public
    returns(address _i)
    {
        
        require(_isAdmin(msg.sender) || _isExpense(msg.sender),"F3");
        BuySideContract i = new BuySideContract(_itemID,_baseaddr, _price,_feesprecentage,_currency,_createdatetime,_access,_seller,msg.sender);
        return(address(i));
        
    }
    
    
    
    
}