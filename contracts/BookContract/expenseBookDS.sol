pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "./stateMachine.sol";
import "openzeppelin-solidity/contracts/utils/Counters.sol";
import "openzeppelin-solidity/contracts/access/RBAC.sol";
import "./orderBookLibrary.sol";


//contract expenseBook is  AccessControl, GSNRecipient {

contract expenseBookDS {   
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address;

    address bookkeepingtoken;
    orderbookLibrary orderbook;
    StateMachine statemachine;
    PermissionControl access;
    uint256 feesprecentage_decimal;
    Counters.Counter _orderID;
    mapping(uint256 => address) orders;
    mapping(address => uint256) address2orders;
    mapping(string => uint8 ) public currencydecimal;
    mapping(uint256 => bool ) public token; // check if there is open order in expensebook
    
    
    function _isSettlement(address _a) internal view 
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
    
    function _isAccount(address _a) internal view 
    returns(bool a)
    {
        return access.hasRole(access.ACCOUNT(),_a);
    }
    
    function _isSupplier(address _a) internal view 
    returns(bool a)
    {
        return access.hasRole(access.SUPPLIER(),_a);
    }
    
    function _isOrder(address _a) internal view
    returns(bool a)
    {
        return access.hasRole(access.ORDER(),_a);
    }
    
    
    function _isCR(address _a) public view
    returns(bool t)
    {
        return access.hasRole(access.COMPREG(),_a);
    }
}
