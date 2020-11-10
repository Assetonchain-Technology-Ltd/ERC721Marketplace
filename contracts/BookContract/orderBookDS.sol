pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "openzeppelin-solidity/contracts/utils/Counters.sol";
import "./stateMachine.sol";
import "openzeppelin-solidity/contracts/access/RBAC.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";



//contract expenseBook is  AccessControl, GSNRecipient {

contract orderBookDS {   
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address;

    address expensebook;
    address bookkeepingtoken;
    address platform;
    address platformfees;
    StateMachine statemachine;
    PermissionControl access;
    ERC721 erc721token;
    uint256 fixdeposit;
    uint256 percentage_decimal;
    uint256 depositpercentage;
    uint256 expiryday;
    
    Counters.Counter  _tradeID;
    Counters.Counter  _salesID;
    
    mapping(uint256 => address)  trades;
    mapping(uint256 => bool) public isopen;
    mapping(uint256 => uint256)  salesTrademap;
    
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
    
    function _isExpense(address _a) internal view
    returns(bool a)
    {
        return access.hasRole(access.EXPENSE(),_a);
    }
    
    function _isCR(address _a) public view
    returns(bool t)
    {
        return access.hasRole(access.COMPREG(),_a);
    }
    
   
}
