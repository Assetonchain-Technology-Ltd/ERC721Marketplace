pragma solidity ^0.6.0;
import "./access.sol";



contract CompanyRegistry is Access {

    
    address bookkeepingtoken;
    address platform;
    address fees;
    address account_receivable;
    address client_forfeit; 
    address supplier_forfeit;
    address baddebt;
    address orderbookproxy;
    address expensebookproxy;
    //address access_address;
    address erc721DirectoryLookup;
    address SellSideContractFactory;
    address BuySideContractFactory;
    
    uint256 ocount;
    uint256 expensecount;
    mapping(uint256=>address) orderbookImp;
    mapping(uint256=>address) expensebookImp;
     
    constructor(address _access,address _b, address _p, address _f,address _a,address _e,address _bcf, address _scf,
                address _cf,address _sf, address _bad) public 
    {
        access = PermissionControl(_access);
        require(_isAdmin(msg.sender),"CR01");
        bookkeepingtoken=_b;
        platform = _p;
        fees = _f;
        account_receivable=_a;
        erc721DirectoryLookup = _e;
        BuySideContractFactory = _bcf;
        SellSideContractFactory = _scf;
        ocount=0;expensecount=0;client_forfeit=_cf;supplier_forfeit=_sf; baddebt=_bad;
    }
    
    function getImpCount() public view
    returns(uint256,uint256)
    {
        require(_isAdmin(msg.sender),"CR36");
        return (ocount,expensecount);
    }
    
    function getOrdImp(uint256 _i) public view
    returns(address)
    {
        require(_isAdmin(msg.sender),"CR37");
        return orderbookImp[_i];
    }
    
    function getExpImp(uint256 _i) public view
    returns(address)
    {
        return expensebookImp[_i];
    }
    
    function getAllAddress() public view
    returns(address,address,address,address,address,address,address,address,address,address,address,address)
    {
        return (bookkeepingtoken,platform,fees,account_receivable,orderbookproxy,expensebookproxy,address(access),erc721DirectoryLookup,
        SellSideContractFactory,BuySideContractFactory,orderbookImp[ocount],expensebookImp[expensecount]);
    }
    
   function setbookkeepingtoken(address _a) public {
        require(_isAdmin(msg.sender),"CR02");
        bookkeepingtoken=_a;
    }
    
    function setplatform(address _a) public {
        require(_isAdmin(msg.sender),"CR03");
        platform=_a;
 
    }
    
    function setAccountReceivable(address _a) public {
        require(_isAdmin(msg.sender),"CR04");
        account_receivable=_a;
        
    }
    
    
    function setForfeit(address _c,address _s)public {
        require(_isAdmin(msg.sender),"CR38");
        client_forfeit=_c;
        supplier_forfeit=_s;
    }
    
    function setBadDebt(address _c)public {
        require(_isAdmin(msg.sender),"CR39");
        baddebt=_c;
    }
    
    function setfees(address _a) public {
        require(_isAdmin(msg.sender),"CR05");
        fees=_a;
       
            
    }
    
    function setOrderbookproxy(address _a) public {
        require(_isAdmin(msg.sender),"CR06");
        orderbookproxy=_a;
       
    }
    
    function setExpensebookProxy(address _a) public {
        require(_isAdmin(msg.sender),"CR07");
        expensebookproxy=_a;
        
    }
    

    
    
    function setAccess(address _a) public {
        require(_isAdmin(msg.sender),"CR08");
        access = PermissionControl(_a);
       
    }
    
    function setContractFactory(address _s,address _b) public {
        require(_isAdmin(msg.sender),"CR29");
        SellSideContractFactory=_s;
        BuySideContractFactory = _b;
        
    }
    
    function setERC721Lookup(address _a) public {
        require(_isAdmin(msg.sender),"CR09");
        erc721DirectoryLookup = _a;
      
    }
    
    function setOrderbookImp(address _a)public {
        require(_isAdmin(msg.sender),"CR32");
        orderbookImp[ocount]=_a;
        ocount+=1;
    }
    
    function setExpensebookImp(address _a)public {
        require(_isAdmin(msg.sender),"CR33");
        expensebookImp[expensecount]=_a;
        expensecount+=1;
    }
 
    function updateAddress2OrderProxy() public {
        
        require(_isAdmin(msg.sender),"CR10");
        require(orderbookproxy!=address(0) && expensebookproxy!=address(0),"CR11");
        require(platform!=address(0) && account_receivable!=address(0)&&fees!=address(0) && SellSideContractFactory!=address(0) 
                && ocount>0 && client_forfeit!=address(0) && baddebt!=address(0) && supplier_forfeit!=address(0),"CR12");
        bytes memory payload = abi.encodeWithSignature("setplatform(address)",platform);
        (bool success,) = orderbookproxy.call(payload);
        require(success,"CR13");
            
        payload = abi.encodeWithSignature("setAccountReceivable(address)",account_receivable);
        (success,) = orderbookproxy.call(payload);
        require(success,"CR14");
            
        payload = abi.encodeWithSignature("setplatformfees(address)",fees);
        (success,) = orderbookproxy.call(payload);
        require(success,"CR15");
            
        payload = abi.encodeWithSignature("setexpenseProxy(address)",expensebookproxy);
        (success,) = orderbookproxy.call(payload);
        require(success,"CR16");  
        
        payload = abi.encodeWithSignature("setContractFactory(address)",SellSideContractFactory);
        (success,) = orderbookproxy.call(payload);
        require(success,"CR30");
        
        payload = abi.encodeWithSignature("setClientForfeit(address)",client_forfeit);
        (success,) = orderbookproxy.call(payload);
        require(success,"CR40");
        
        payload = abi.encodeWithSignature("setSupplierForfeit(address)",supplier_forfeit);
        (success,) = expensebookproxy.call(payload);
        require(success,"CR39");
 
        
        payload = abi.encodeWithSignature("setBadDebt(address)",baddebt);
        (success,) = orderbookproxy.call(payload);
        require(success,"CR41");
        
        payload = abi.encodeWithSignature("upgradeTo(address)",orderbookImp[ocount-1]);
        (success,) = orderbookproxy.call(payload);
        require(success,"CR34");
    
    }
    
    function updateAddress2ExpenseProxy() public {
         
        require(_isAdmin(msg.sender),"CR17");
        require(orderbookproxy!=address(0) && expensebookproxy!=address(0) && BuySideContractFactory!=address(0)
                && expensecount>0 ,"CR18");
        bytes memory payload = abi.encodeWithSignature("setOrdBook(address)",orderbookproxy);
        (bool success,) = expensebookproxy.call(payload);
        require(success,"CR19");
        
        payload = abi.encodeWithSignature("setContractFactory(address)",BuySideContractFactory);
        (success,) = expensebookproxy.call(payload);
        require(success,"CR31");
        

        payload = abi.encodeWithSignature("upgradeTo(address)",expensebookImp[expensecount-1]);
        (success,) = expensebookproxy.call(payload);
        require(success,"CR35");
    }

    
    function updateAddress2BothProxy() public {
        require(_isAdmin(msg.sender),"CR20");
        require(orderbookproxy!=address(0) && expensebookproxy!=address(0),"CR21");
        require(address(access)!=address(0) && erc721DirectoryLookup!=address(0)&&bookkeepingtoken!=address(0),"CR22");
         
        bytes memory payload = abi.encodeWithSignature("setPermissionControl(address)",access);
        (bool success,) = orderbookproxy.call(payload);
        require(success,"CR23");
        (success,) = expensebookproxy.call(payload);
        require(success,"CR24");
        
        payload = abi.encodeWithSignature("setERC721Lookup(address)",erc721DirectoryLookup);
        (success,) = orderbookproxy.call(payload);
        require(success,"CR25");
            
        (success,) = expensebookproxy.call(payload);
        require(success,"CR26");
        
        payload = abi.encodeWithSignature("setbookkeep(address)",bookkeepingtoken);
        (success,) = orderbookproxy.call(payload);
        require(success,"CR27");
        
        (success,) = expensebookproxy.call(payload);
        require(success,"CR28");
        
    }
    
}