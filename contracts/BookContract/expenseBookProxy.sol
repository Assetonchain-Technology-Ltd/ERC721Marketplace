pragma solidity ^0.6.0;

import "./expenseBookDS.sol";

contract expenseBookProxy is expenseBookDS {
    
    event OrderStatusChange(uint256 ad, string status, string action,uint256 _datetime);
    event NewOrderRequest(uint256 ad, address seller, uint256 itemID,uint256 p,uint256 f,string c,uint256 d);
    address public implementation;


    constructor (address _statemachine,address _access) public virtual
    {
        access = PermissionControl(_access);
        statemachine = StateMachine(_statemachine);
        //_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        currencydecimal["HKD"]=2;
        currencydecimal["USD"]=2;
        feesprecentage_decimal = 2;
        _orderID.increment();
        
    }
    

    function upgradeTo(address _address) public {
        require( _isAdmin(msg.sender) || _isCR(msg.sender)  , "EP01");
        implementation = _address;
    }
    
    function setOrdBook(address _orderbook) public {
        require( _isCR(msg.sender) , "EP02");
        orderbook=orderbookLibrary(_orderbook);
    }
    
    function setbookkeep(address _bookkeep) public {
        require( _isCR(msg.sender) , "EP03");
        bookkeepingtoken=_bookkeep;
    }
    
    function setPermissionControl(address _a)public {
        require(_isCR(msg.sender),"EP04");
        access = PermissionControl(_a);
    }
    
    function setERC721Lookup(address _a)public {
        require(_isCR(msg.sender),"EP05");
        lookup = erc721DirectoryService(_a);
    }
    
    function setStateMachine(address _machine) public  {
        require( _isAdmin(msg.sender) , "EP06");
        statemachine=StateMachine(_machine);
    }
    
    function setContractFactory(address _a) public {
        
        require( _isCR(msg.sender) , "EP10");
        contractfactory=_a;
    }
    
    function getAllContract() public view
    returns(address,address,address,address,address)
    {
         require( _isAdmin(msg.sender) || _isSales(msg.sender) || _isAccount(msg.sender) || _isSettlement(msg.sender) , "OP14");
        return(address(orderbook),address(bookkeepingtoken),address(statemachine),contractfactory,implementation);
    }
    
   function getOrderCount() public view
   returns(uint256 _c)
   {
       require( _isAdmin(msg.sender) || _isSales(msg.sender) || _isAccount(msg.sender) || _isSettlement(msg.sender) , "EP08");
       return _orderID.current()-1;
   }

   function getBuySideContractAddress(uint256 _i) public view
   returns(address _a)
   {
       require( _isAdmin(msg.sender) || _isSales(msg.sender) || _isAccount(msg.sender) || _isSettlement(msg.sender) , "EP09");
       return(orders[_i]);
   }
    function setfeesprecentage_decimal(uint256 d) public {
        require( (access.hasRole(access.ADMIN_ROLE(),msg.sender)) , "EP07");
        feesprecentage_decimal=d;
    }
    
    function getfeesprecentage_decimal() public view
    returns(uint256)
    {
        return feesprecentage_decimal;
    }
    
  

/**
* @dev Fallback function allowing to perform a delegatecall to the given implementation.
* This function will return whatever the implementation call returns
*/
    fallback() external payable  {
        address _impl = implementation;
        require(_impl != address(0),"EP11");
        
       assembly {
                calldatacopy(0, 0, calldatasize())
                let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch result
                case 0 { revert(0, returndatasize()) }
                default { return(0, returndatasize()) }
            }
    }

} 