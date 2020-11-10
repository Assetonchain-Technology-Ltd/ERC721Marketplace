pragma solidity ^0.6.0;

import "../BuySellContract/BuySideContract.sol";
import "./orderBookDS.sol";
import "openzeppelin-solidity/contracts/presets/ERC20PresetMinterPauser.sol";



contract orderbookLibrary is orderBookDS {
    event TradeStatusChange(uint256 ad,string action,string status,address b,uint256 p,uint256 d);
    event NewTrade(uint256 t, address seller, uint256 itemID,uint256 p,address o,uint256 m,uint256 _datetime);

    function getTradeCount() public view 
    returns (uint256 c)
    {
        return _tradeID.current() - 1;
    }
    
 
    function setindividualDeposit(uint256 _tradeid,uint256 _deposit) public{
        address order = trades[_tradeid];
        require(_isAdmin(msg.sender) || _isSales(msg.sender), "O12");
        require(_deposit > _getTradeMindeposit(order)&& _deposit < _getTotalAmount(order),"O13");
        _setMindeposit(order,_deposit); 
    }

    
    function getdepositpercentage() public view
    returns (uint256)
    {
        return depositpercentage;
    }
     
    function setdepositpercentage(uint256 u) public {
            depositpercentage = u;
    }

    
    function openTrade(uint256 _itemID, address _base,uint256 _price,address _sellsideorder, uint256 _datetime,string memory _currency) public virtual
    returns (uint256 tradeid)
    {
        require( _isExpense(msg.sender) || _isAdmin(msg.sender) || _isSales(msg.sender), "O2");
        require( _price > 0 , "O14" );
        require(erc721token.ownerOf(_itemID)==_sellsideorder,"O18");
        require(isopen[_itemID]==false,"O30");
        _tradeID.increment();
        uint256 currentID = _tradeID.current()-1;
        address _seller = _getCreditor(_sellsideorder);
        uint256 _mindeposit = (fixdeposit>0)?fixdeposit:_price.mul(depositpercentage).div(percentage_decimal.mul(100));
        BuySideContract b = new BuySideContract(_itemID,_base,_price,_currency,_datetime,address(access),_seller,currentID,_sellsideorder);
        _setMindeposit(address(b),_mindeposit);
        trades[currentID] = address(b);
        _WithdrawToken(_sellsideorder,_itemID,address(b));
        isopen[_itemID]=true;
        emit NewTrade(currentID,msg.sender,_itemID,_price,_sellsideorder,_mindeposit,_datetime);
        return currentID;
        
    }
    
    function markTrade(uint256 _trade,uint256 _feespercentage, uint256 _datetime,bool _fullpay,uint8 _paymenttype) public
    {   
        address i = trades[_trade];
        (bool exist,string memory nextstate) = statemachine.transitionExists(_getState(i),bytes32(keccak256("markTrade")));
        //profile checking
        require(exist , "O3");
        require(_getCreditor(i)!=msg.sender,"O17");
        _setState(i,nextstate,_datetime);
        _setFeePercent(i,_feespercentage);
        _setDebtor(i,msg.sender);
        uint256 price = _getTotalAmount(i);
        uint256 fees  = (price.mul( _feespercentage)).div(percentage_decimal.mul(100));
        _setFeeAmount(i,fees);
        emit TradeStatusChange(_trade,"markTrade", nextstate,msg.sender,0,_datetime);
        
        if(_fullpay){
        
             _addSettlementPlan(i, fees.add(price),_datetime.add(expiryday.mul(86400)),_datetime,_paymenttype,true); 
             
        }else{
            
            uint256 mindeposit = _getTradeMindeposit(i);
            uint256 settledate = _datetime.add(expiryday.mul(86400));
            _addSettlementPlan(i, fees.add(mindeposit),settledate,_datetime,_paymenttype,true);
            _addSettlementPlan(i, price.sub(mindeposit),settledate.add(expiryday.mul(86400)),_datetime,_paymenttype,true);
         
        }
    }
    
    function executeTrade(uint256 _trade,uint8 _paymenttype, uint256 _amount, string memory _tx,uint256 _datetime) public
    {
        address i = trades[_trade];
        (bool exist,string memory nextstate) = statemachine.transitionExists(_getState(i),bytes32(keccak256("executeTrade")));
        //profile checking
        require(exist , "O3");
        require( _isAdmin(msg.sender) || _isSettlement(msg.sender), "O2");
        ERC20PresetMinterPauser bookkeep = ERC20PresetMinterPauser(bookkeepingtoken);
        bookkeep.mint(i,_amount);
        (uint256 _index,uint256 _d,uint256 _a)=_getActiveSettlementPlan(i);
        while(_amount>=_a){
            _completePayment(i,_index,_tx,_datetime,_paymenttype);
            _amount.sub(_a);
            (_index,_d,_a)=_getActiveSettlementPlan(i);
        }
        if(_isSettled(i)){
            address debtor = _getDebtor(i);
            _a = _getTotalAmount(i);
            _d = _getFeeAmount(i);
            _a  = _a.add(_d);
            (_a,) = _getItem(i);
            require(bookkeep.balanceOf(i)>=_a,"O31");
            _WithdrawToken(i,_a,debtor);
            _setState(i,"EXEC",_datetime);
            isopen[_a]=false;
            emit TradeStatusChange(_trade,"executeTrade","EXEC",msg.sender,_amount,_datetime);
        }else{
            _setState(i,nextstate,_datetime);
            emit TradeStatusChange(_trade,"executeTrade",nextstate,msg.sender,_amount,_datetime);
        }
       
    }
    
   
    function executeExpensebook(uint256 _trade,uint256 _datetime) public 
    {
        address i = trades[_trade];
        (bool exist,string memory nextstate) = statemachine.transitionExists(_getState(i),bytes32(keccak256("executeExpensebook")));
        require(exist , "O3");
        require( _isAdmin(msg.sender) || _isSettlement(msg.sender), "O2");
        address s = _getSellSideContract(i);
        uint256 cost =_getTotalAmount(s);
        uint256 sales = _getTotalAmount(i);
        require(sales>=cost,"O32");
        uint256 fees = _getFeeAmount(i);
        uint256 profit = sales.sub(cost);
        //profile checking
        //require(_msgSender()==address(paymentbook),"O20");
        ERC20PresetMinterPauser bookkeep = ERC20PresetMinterPauser(bookkeepingtoken);
        require(bookkeep.balanceOf(address(this))>=sales.add(fees),"O23");
        bookkeep.transfer(s,cost);
        bookkeep.transfer(platformfees,fees);
        bookkeep.transfer(platform,profit);
        bytes memory payload = abi.encodeWithSignature("fullFillTrade(uint256,uint256)",s,_datetime);
        expensebook.call(payload);
        
    }

    function cancelTrade(uint256 _trade,uint256 _datetime,bool return2owner)
        public
    {
        address i = trades[_trade];
        (bool exist,string memory nextstate) = statemachine.transitionExists(_getState(i),bytes32(keccak256("cancelTrade")));
        require(exist , "O11");
        address debtor = _getDebtor(i);
        address creditor = _getCreditor(i);
        address seller = _getCreditor(_getSellSideContract(i));
        require( _isAdmin(msg.sender) || _isSettlement(msg.sender) || msg.sender==debtor || msg.sender == creditor, "O2");
        address destination = return2owner?seller:creditor;
        (uint256 _itemid,) = _getItem(i);
        erc721token.transferFrom(address(this), destination, _itemid);
        _setState(i,nextstate,_datetime);
        isopen[_itemid]=false;
        emit TradeStatusChange(_trade,"cancelTrade",nextstate,msg.sender,0,_datetime);
    }
    
    
    function expireTrade(uint256 _trade,uint256 _datetime) public{
        address i = trades[_trade];
        (bool exist,string memory nextstate) = statemachine.transitionExists(_getState(i),bytes32(keccak256("expireTrade")));
        require(exist , "O21");
        uint256 _d =_getStateChange(i,_getState(i));
        require(_datetime>_d,"O33");
        _d = _datetime.sub(_d);
        require(_d.div(86400)>expiryday,"O22");
        _setState(i,nextstate,_datetime);
        (_d,) =_getItem(i);
        isopen[_d]=false;
        ERC20PresetMinterPauser bookkeep = ERC20PresetMinterPauser(bookkeepingtoken);
        emit TradeStatusChange(_trade,"expireTrade",nextstate,msg.sender,bookkeep.balanceOf(address(this)),_datetime);
        
    }
    
    
    
    function _getState(address _a) internal
    returns(string memory s){
        bytes memory payload = abi.encodeWithSignature("getState()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (string));
    }
    
    function _getStateChange(address a,string memory s) internal 
    returns(uint256 d)
    {
        bytes memory payload = abi.encodeWithSignature("getStateChange(string)",s);
        (bool success, bytes memory result) = a.call(payload);
        require(success,"O23");
        return abi.decode(result, (uint256));
    }
    
    function _getFeePercentage(address _a) internal 
    returns(uint256 d)
    {
        bytes memory payload = abi.encodeWithSignature("getFeePercent()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (uint256));
        
    }
    
    function _getFeeAmount(address _a) internal 
    returns(uint256 d)
    {
        bytes memory payload = abi.encodeWithSignature("getFeeAmount()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (uint256));
        
    }
    
    function _getTradeMindeposit(address _a) internal 
    returns(uint256 d)
    {
        bytes memory payload = abi.encodeWithSignature("getMindeposit()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (uint256));
    }
    
    function _getTotalAmount(address _a) internal 
    returns(uint256 d)
    {
        bytes memory payload = abi.encodeWithSignature("getOrderPrice()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (uint256));
    }
    
    function _getItem(address _a) internal 
    returns(uint256 d,address c)
    {
         bytes memory payload = abi.encodeWithSignature("getItem()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (uint256,address));
    }
    
    function _getCreditor(address _a)internal 
    returns(address _d)
    {
        bytes memory payload = abi.encodeWithSignature("getCreditor()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (address));
    }
    
    function _getDebtor(address _a) internal 
    returns(address _c)
    {
        bytes memory payload = abi.encodeWithSignature("getDebtor()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (address));
    }
    
    function _getSellSideContract(address _a) internal 
    returns(address _c)
    {
        bytes memory payload = abi.encodeWithSignature("getSellSideContract()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (address));
    }
    
    function _getActiveSettlementPlan(address _a) internal  
    returns(uint256 _i,uint256 _d,uint256 _c)
    {
        bytes memory payload = abi.encodeWithSignature("getActiveSettlementPlan()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (uint256,uint256,uint256));
    }
    
    function _isSettled(address _a) internal 
    returns(bool _t)
    {
        bytes memory payload = abi.encodeWithSignature("isSettled()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (bool));
    }
    
    function _setState(address _a,string memory _s,uint256 _d) internal
    {
        bytes memory payload = abi.encodeWithSignature("setState(string,uint256)",_s,_d);
        (bool success, ) = _a.call(payload);
        require(success,"O23");
     
    }
    
    function _setFeePercent(address _a,uint256 _d) internal
    {
        bytes memory payload = abi.encodeWithSignature("setFeePercent(uint256)",_d);
        (bool success, ) = _a.call(payload);
        require(success,"O23");
     
    }
    
    function _setFeeAmount(address _a,uint256 _d) internal
    {
        bytes memory payload = abi.encodeWithSignature("setFeeAmount(uint256)",_d);
        (bool success, ) = _a.call(payload);
        require(success,"O23");
     
    }
    
    function _setDebtor(address _a,address _d) internal
    {
        bytes memory payload = abi.encodeWithSignature("setDebtor(address)",_d);
        (bool success, ) = _a.call(payload);
        require(success,"O23");
     
    }
    
    function _setMindeposit(address _a,uint256 _s) internal 
    {
        bytes memory payload = abi.encodeWithSignature("setMindeposit(uint256)",_s);
        (bool success, ) = _a.call(payload);
        require(success,"O23");
    }
    
    function _WithdrawToken(address _a, uint256 _id,address _dest) internal
    {
        bytes memory payload = abi.encodeWithSignature("withdrawalToken(uint256,address)",_id,_dest);
        (bool success, ) = _a.call(payload);
        require(success,"O23");
    }
    
    
    function _addSettlementPlan(address _a, uint256 _amount,uint256 _settlementdate,uint256 _datetime,uint8 _p,bool _active) internal 
    {
        bytes memory payload = abi.encodeWithSignature("addSettlementPlan(uint256,uint256,uint256,uint8,bool)",_amount,_settlementdate,_datetime,_p,_active);
        (bool success,) = _a.call(payload);
        require(success,"O23");
    }
    
    function _completePayment(address _a,uint256 _id, string memory _tx,uint256 _date,uint8 _p) internal 
    {
        bytes memory payload = abi.encodeWithSignature("completePayment(uint256,string)",_id,_tx,_date,_p);
        (bool success,) = _a.call(payload);
        require(success,"O23");
    }
    

}
