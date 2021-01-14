pragma solidity ^0.6.0;

import "./orderBookDS.sol";

contract orderBookProxy is orderBookDS {
    
    
    event TradeStatusChange(uint256 ad,string action,string status,address b,uint256 p,uint256 d);
    event NewTrade(address i,uint256 t, address seller, uint256 itemID,uint256 p,address o,uint256 m,uint256 _datetime);
    address public implementation;
  

    constructor (address _statemachine, address _access) public virtual
    {
        access = PermissionControl(_access);
        statemachine = StateMachine(_statemachine);
        //_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        percentage_decimal = 100;
        fixdeposit=0;
        depositpercentage = 300;
        expiryday = 3;
        _tradeID.increment();
    }
    

    function upgradeTo(address _address) public {
        require( _isAdmin(msg.sender) || _isCR(msg.sender) , "OP01");
        implementation = _address;
    }
    
    function setexpenseProxy(address _expensebookproxy) public {
        require( _isCR(msg.sender) , "OP02");
        expensebook=_expensebookproxy;
    }

    function setAccountReceivable(address _a) public {
        require( _isCR(msg.sender),"OP03");
        account_receivable = _a;
    }
    
    function setbookkeep(address _bookkeep) public {
        require( _isCR(msg.sender) , "OP04");
        bookkeepingtoken=_bookkeep;
    }
    
    function setplatformfees(address _a) public {
        require( _isCR(msg.sender) , "OP05");
        platformfees=_a;
    }
    
    function setClientForfeit(address _a) public {
        require( _isCR(msg.sender) , "OP24");
        client_forfeit=_a;
    }
    
    function setSupplierForfeit(address _a) public {
        require( _isCR(msg.sender) , "OP26");
        supplier_forfeit=_a;
    }
    
    function setBadDebt(address _a) public {
        require( _isCR(msg.sender) , "OP25");
        baddebt=_a;
    }
    
    function setplatform(address _a) public {
        require( _isCR(msg.sender) , "OP06");
        platform=_a;
    }
    
    function setStateMachine(address _machine) public  {
        require( _isAdmin(msg.sender) , "OP07");
        statemachine=StateMachine(_machine);
    }
    
    function setPermissionControl(address _a)public {
        require(_isCR(msg.sender),"OP08");
        access = PermissionControl(_a);
    }
    
    function setERC721Lookup(address _a)public {
        require(_isCR(msg.sender),"OP09");
        lookup = erc721DirectoryService(_a);
    }
    
    
    function setprecentage_decimal(uint256 d) public {
        require( _isAdmin(msg.sender) , "OP10");
        percentage_decimal=d;

    }
    
    function setfixdeposit(uint256 d) public {
        require( _isAdmin(msg.sender) , "OP11");
        fixdeposit=d;

    }
    
    function setdepositPercentage(uint256 d) public {
        require( _isAdmin(msg.sender) , "OP12");
        depositpercentage=d;
    }
    
    function setexpiryday(uint256 d) public {
        require( _isAdmin(msg.sender) , "OP13");
        expiryday=d;
    }
    
    function setContractFactory(address _cf) public {
        require( _isCR(msg.sender) , "OP22");
        contractfactory=_cf;
    }
    
    function getAllContract() public view
    returns(address,address,address,address,address)
    {
        require( _isAdmin(msg.sender) || _isSales(msg.sender) || _isAccount(msg.sender) || _isSettlement(msg.sender) , "OP14");
        return(address(expensebook),address(bookkeepingtoken),address(statemachine),contractfactory,implementation);
    }
    
    function getTradeCount() public view
    returns(uint256 _c)
    {
        require( _isAdmin(msg.sender) || _isSales(msg.sender) || _isAccount(msg.sender) || _isSettlement(msg.sender) , "OP15");
        return _tradeID.current()-1;
    }
    
    function getSellSideContractAddress(uint256 _i) public view
    returns(address _a)
    {
        require( _isAdmin(msg.sender) || _isSales(msg.sender) || _isAccount(msg.sender) || _isSettlement(msg.sender) 
                || _isExpense(msg.sender), "OP17");
        return trades[_i];
    }
    
    function getprecentage_decimal() public view
    returns(uint256)
    {
        require( _isAdmin(msg.sender) || _isSales(msg.sender) || _isAccount(msg.sender) || _isSettlement(msg.sender) , "OP18");
        
        return percentage_decimal;
    }
    
    function getfixdeposit() public view
    returns(uint256)
    {
        require( _isAdmin(msg.sender) || _isSales(msg.sender) || _isAccount(msg.sender) || _isSettlement(msg.sender) , "OP19");
        
        return fixdeposit;
    }
    
    function getdepositPercentage() public view
    returns(uint256)
    {
        require( _isAdmin(msg.sender) || _isSales(msg.sender) || _isAccount(msg.sender) || _isSettlement(msg.sender) , "OP20");
        
        return depositpercentage;
    }
    
    function getexpiryday() public view
    returns(uint256)
    {
        require( _isAdmin(msg.sender) || _isSales(msg.sender) || _isAccount(msg.sender) || _isSettlement(msg.sender) , "OP21");
        
        return expiryday;
    }
    
    


/**
* @dev Fallback function allowing to perform a delegatecall to the given implementation.
* This function will return whatever the implementation call returns
*/
    fallback() external payable  {
        address _impl = implementation;
        require(_impl != address(0),"OP23");
        
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