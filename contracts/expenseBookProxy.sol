pragma solidity ^0.6.0;

import "./expenseBookDS.sol";

contract expenseBookProxy is expenseBookDS {
    
    address public implementation;


    constructor (address _orderbook, address _diamondtoken, address _statemachine,address _bookeep,address _access ) public virtual
    {
        orderbook = Orderbook(_orderbook);
        diamondtoken = ERC721(_diamondtoken);
        bookkeepingtoken = PaymentBook(_bookeep);
        statemachine = StateMachine(_statemachine);
        access = PermissionControl(_access);
        //_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        currencydecimal["HKD"]=2;
        currencydecimal["USD"]=2;
        feesprecentage_decimal = 2;
        diamondtoken.setApprovalForAll(_orderbook,true);
        owner = msg.sender;
        _orderID.increment();
        
    }
    

    function upgradeTo(address _address) public {
        require( (access.hasRole(access.ADMIN_ROLE(),msg.sender)) , "E0");
        implementation = _address;
    }
    
    function setOrdBook(address _orderbook) public {
        require( (access.hasRole(access.ADMIN_ROLE(),msg.sender)) , "E0");
        orderbook=Orderbook(_orderbook);
    }
    
    function setbookkeep(address _bookkeep) public {
        require( (access.hasRole(access.ADMIN_ROLE(),msg.sender)) , "E0");
        bookkeepingtoken=PaymentBook(_bookkeep);
    }
    
    function setStateMachine(address _machine) public  {
        require( (access.hasRole(access.ADMIN_ROLE(),msg.sender)) , "E0");
        statemachine=StateMachine(_machine);
    }
    
    function getAllContract() public view
    returns(address,address,address)
    {
        return(address(orderbook),address(bookkeepingtoken),address(statemachine));
    }
    
   
    
    function setfeesprecentage_decimal(uint256 d) public {
        require( (access.hasRole(access.ADMIN_ROLE(),msg.sender)) , "E0");
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
        require(_impl != address(0));
        
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