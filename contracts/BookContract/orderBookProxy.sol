pragma solidity ^0.6.0;

import "./orderBookDS.sol";

contract orderBookProxy is orderBookDS {
    
    address public implementation;


    constructor (address _statemachine) public virtual
    {
        
        statemachine = StateMachine(_statemachine);
        //_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        percentage_decimal = 100;
        fixdeposit=0;
        depositpercentage = 300;
        expiryday = 3;
    }
    

    function upgradeTo(address _address) public {
        require( _isAdmin(msg.sender) , "E0");
        implementation = _address;
    }
    
    function setexpenseProxy(address _expensebookproxy) public {
        require( _isCR(msg.sender) , "E0");
        expensebook=_expensebookproxy;
    }

    function setAccountReceivable(address _a) public {
        require( _isCR(msg.sender),"E0");
        account_receivable = _a;
    }
    
    function setbookkeep(address _bookkeep) public {
        require( _isCR(msg.sender) , "E0");
        bookkeepingtoken=_bookkeep;
    }
    
    function setplatformfees(address _a) public {
        require( _isCR(msg.sender) , "E0");
        platformfees=_a;
    }
    
    function setplatform(address _a) public {
        require( _isCR(msg.sender) , "E0");
        platform=_a;
    }
    
    function setStateMachine(address _machine) public  {
        require( _isAdmin(msg.sender) , "E0");
        statemachine=StateMachine(_machine);
    }
    
    function setPermissionControl(address _a)public {
        require(_isCR(msg.sender),"E0");
        access = PermissionControl(_a);
    }
    
    
    function setprecentage_decimal(uint256 d) public {
        require( _isAdmin(msg.sender) , "E0");
        percentage_decimal=d;

    }
    
    function setfixdeposit(uint256 d) public {
        require( _isAdmin(msg.sender) , "E0");
        fixdeposit=d;

    }
    
    function setdepositPercentage(uint256 d) public {
        require( _isAdmin(msg.sender) , "E0");
        depositpercentage=d;
    }
    
    function setexpiryday(uint256 d) public {
        require( _isAdmin(msg.sender) , "E0");
        expiryday=d;
    }
    

    
    function getAllContract() public view
    returns(address,address,address)
    {
        return(address(expensebook),address(bookkeepingtoken),address(statemachine));
    }
    
    function getprecentage_decimal() public view
    returns(uint256)
    {
        return percentage_decimal;
    }
    
    function getfixdeposit() public view
    returns(uint256)
    {
        return fixdeposit;
    }
    
    function getdepositPercentage() public view
    returns(uint256)
    {
        return depositpercentage;
    }
    
    function getexpiryday() public view
    returns(uint256)
    {
        return expiryday;
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