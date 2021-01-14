pragma solidity ^0.6.0;
import "openzeppelin-solidity/contracts/access/RBAC.sol";

contract Access {
    
    PermissionControl access;
    
    function _isSettlement(address _a)  internal view 
    returns(bool a)
    {
        return access.hasRole(access.SETTLEMENT(),_a);
    }
    
    
    function _isSales(address _a) internal view 
    returns(bool a)
    {
        return access.hasRole(access.SALE(),_a);
    }
    
    function _isAdmin(address _a) internal view 
    returns(bool a)
    {
        return access.hasRole(access.ADMIN_ROLE(),_a);
    }
    
    function _isSupplier(address _a)  internal view
    returns(bool a)
    {
        return access.hasRole(access.SUPPLIER(),_a);
    }
    
   
    function _isAccount(address _a)  internal view 
    returns(bool a)
    {
        return access.hasRole(access.ACCOUNT(),_a);
    }
    
    function _isExpense(address _a) internal view
    returns(bool a)
    {
        return access.hasRole(access.EXPENSE(),_a);
    }
    
    function _isCR(address _a) internal view
    returns(bool t)
    {
        return access.hasRole(access.COMPREG(),_a);
    }
    
    function _isOrder(address _a) internal view
    returns(bool a)
    {
        return access.hasRole(access.ORDER(),_a);
    }
    

    
}