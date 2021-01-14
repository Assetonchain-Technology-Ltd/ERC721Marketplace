pragma solidity ^0.6.0;

import "../BuySellContract/SellSideContractFactory.sol";
import "../BuySellContract/baseContractAccesser.sol";
import "../BuySellContract/BuySideContractAccesser.sol";
import "./orderBookDS.sol";



contract orderbookLibrary is orderBookDS ,baseContractAccessor , buySideContractAccessor{
    event TradeStatusChange(uint256 ad,string action,string status,address b,uint256 p,uint256 d);
    event NewTrade(address i,uint256 t, address seller, uint256 itemID,uint256 p,address o,uint256 m,uint256 _datetime);
    
 
    function setindividualDeposit(uint256 _tradeid,uint256 _deposit) public{
        address order = trades[_tradeid];
        require(_isAdmin(msg.sender) || _isSales(msg.sender), "O1");
        require(_deposit > _getTradeMindeposit(order)&& _deposit < _getTotalAmount(order),"O2");
        _setMindeposit(order,_deposit); 
    }
    
    
    function openTrade(uint256 _itemID,address _base,uint256 _price,address _sellsideorder, uint256 _datetime,string memory _currency) public virtual
    returns (uint256 tradeid)
    {
        _base = lookup.getBaseAddress(_itemID);
        require( _isExpense(msg.sender) || _isAdmin(msg.sender) || _isSales(msg.sender), "O3");
        require( _price > 0 , "O4" );
        require(_ownerOf(_base,_itemID)==_sellsideorder,"O5");
        require(isopen[_itemID]==false,"O6");
        _tradeID.increment();
        uint256 currentID = _tradeID.current()-1;
        address _seller = _getCreditor(_sellsideorder);
        uint256 _mindeposit = (fixdeposit>0)?fixdeposit:_price.mul(depositpercentage).div(percentage_decimal.mul(100));
        SellSideContractFactory c = SellSideContractFactory(contractfactory);
        _base = c.createNewSellSideContract(_itemID,_base,_price, _sellsideorder, _datetime, _currency,address(access),_seller,currentID);
        _setMindeposit(_base,_mindeposit);
        trades[currentID] = _base;
        _WithdrawERC721Token(_sellsideorder,_itemID,_base);
        isopen[_itemID]=true;
        emit NewTrade(_base,currentID,msg.sender,_itemID,_price,_sellsideorder,_mindeposit,_datetime);
        return currentID;
        
    }
    
    function markTrade(uint256 _trade,uint256 _feespercentage, uint256 _datetime,bool _fullpay) public
    {   
        address i = trades[_trade];
        (bool exist,string memory nextstate) = _transitionExists(_getState(i),"markTrade");
        //profile checking
        require(exist , "O7");
        require(_getSeller(i)!=msg.sender,"O8");
        _setState(i,nextstate,_datetime);
        _setFeePercent(i,_feespercentage);
        _setDebtor(i,msg.sender);
        uint256 price = _getTotalAmount(i);
        uint256 fees  = (price.mul( _feespercentage)).div(percentage_decimal.mul(100));
        _setFeeAmount(i,fees);
        emit TradeStatusChange(_trade,"markTrade", nextstate,msg.sender,0,_datetime);
        ERC20PresetMinterPauser bookkeep = ERC20PresetMinterPauser(bookkeepingtoken);
        bookkeep.mint(account_receivable,fees.add(price));
        if(_fullpay){
        
             _addSettlementPlan(i, fees.add(price),_datetime.add(expiryday.mul(86400)),_datetime,true); 
             
        }else{
            
            uint256 mindeposit = _getTradeMindeposit(i);
            uint256 settledate = _datetime.add(expiryday.mul(86400));
            _addSettlementPlan(i, fees.add(mindeposit),settledate,_datetime,true);
            _addSettlementPlan(i, price.sub(mindeposit),settledate.add(expiryday.mul(86400)),_datetime,true);
         
        }
    }
    
    function executeTrade(uint256 _trade,uint8 _paymenttype, string memory _tx,uint256 _datetime) public
    {
        address i = trades[_trade];
        (bool exist,string memory nextstate) = _transitionExists(_getState(i),"executeTrade");
        //profile checking
        require(exist , "O9");
        require( _isAdmin(msg.sender) || _isSettlement(msg.sender), "O10");
        ERC20PresetMinterPauser token = ERC20PresetMinterPauser(bookkeepingtoken);
        (uint256 _index,uint256 _d,uint256 _a)=_getActiveSettlementPlan(i);
        require(token.balanceOf(account_receivable)>=_a,"O23");
        token.transferFrom(account_receivable,i,_a);
        _completePayment(i,_index,_tx,_datetime,_paymenttype);
        _a = _getTotalAmount(i);
        _d = _getFeeAmount(i);
        _a  = _a.add(_d);
        if(_isSettled(i)){
            uint256 alreadypaid=_getEarlySettle(i);
            require(token.balanceOf(i)>=_a.sub(alreadypaid),"O22");
            address d = _getDebtor(i);
            (_a,) = _getItem(i);
            _WithdrawERC721Token(i,_a,d);
            _setState(i,"EXEC",_datetime);
            isopen[_a]=false;
            d = _getCreditor(i);
            bytes memory payload = abi.encodeWithSignature("fullFillTrade(address,uint256)",d,_datetime);
            (bool success, ) = expensebook.call(payload);
            require(success,"O29");
            emit TradeStatusChange(_trade,"executeTrade","EXEC",msg.sender,_a,_datetime);
        }else{
            _setState(i,nextstate,_datetime);
            emit TradeStatusChange(_trade,"executeTrade",nextstate,msg.sender,_a,_datetime);
        }
       
    }
    
   function settleBuySide(uint256 _trade,uint256 _datetime,uint256 _amount) public 
   {
       address i = trades[_trade];
       address buyside = _getCreditor(i);
       (bool exist,string memory nextstate) = _transitionExists(_getState(i),"settleBuySide");
       require(exist , "O25");
       require( _isAdmin(msg.sender) || _isSettlement(msg.sender), "O28");
       uint256 psettle = _getPlanedSettlementAmount(buyside);
       ERC20PresetMinterPauser token = ERC20PresetMinterPauser(bookkeepingtoken);
       require(_amount>0 && _amount<=psettle && token.balanceOf(i)>=_amount,"O27");
       _WithdrawERC20Token(i,bookkeepingtoken,_amount,buyside);
       _setEarlySettle(i,_amount);
       _setMeta(i,2,"settleBuySide Call");
       _setState(i,nextstate,_datetime);
   }
   
    function profitDistribution(uint256 _trade,uint256 _datetime) public 
    {
        address i = trades[_trade];
        (bool exist,string memory nextstate) = _transitionExists(_getState(i),"profitDistribution");
        require(exist , "O12");
        require( _isAdmin(msg.sender) || _isSettlement(msg.sender), "O13");
        address s = _getCreditor(i);
        uint256 earlypay = _getEarlySettle(i);
        uint256 cost =_getTotalAmount(s);
        uint256 sales = _getTotalAmount(i);
        uint256 fees = _getFeeAmount(i);
        uint256 profit = sales.sub(cost);
        ERC20PresetMinterPauser token = ERC20PresetMinterPauser(bookkeepingtoken);
        require(token.balanceOf(i)>=cost.sub(earlypay).add(fees),"O15");
        _WithdrawERC20Token(i,bookkeepingtoken,cost.sub(earlypay),s);
        _WithdrawERC20Token(i,bookkeepingtoken,fees,platformfees);
        _WithdrawERC20Token(i,bookkeepingtoken,profit,platform);
        _setState(i,nextstate,_datetime);
        
    }

    function cancelTrade(uint256 _trade,uint256 _datetime,bool return2owner) public
    {
        address i = trades[_trade];
        uint256 _itemid;
        (bool exist,string memory nextstate) = _transitionExists(_getState(i),"cancelTrade");
        require(exist , "O16");
        address c = _getDebtor(i);
        nextstate = (msg.sender==c)?"CANC-C":"CANC-S";
        require( _isAdmin(msg.sender) || _isSettlement(msg.sender) || _isExpense(msg.sender) || msg.sender==c, "O17");
        address s = _getSeller(i);
        c = _getCreditor(i);
        c = return2owner?s:c;
        (_itemid,) = _getItem(i);
        _WithdrawERC721Token(i,_itemid,c);
        
        _setState(i,nextstate,_datetime);
        isopen[_itemid]=false;
        emit TradeStatusChange(_trade,"cancelTrade",nextstate,msg.sender,0,_datetime);
    }
    
    
    function expireTrade(uint256 _trade,uint256 _datetime) public{
        address i = trades[_trade];
        (bool exist,string memory nextstate) = _transitionExists(_getState(i),"expireTrade");
        require(exist , "O18");
        uint256 _d =_getStateChange(i,_getState(i));
        require(_datetime>_d,"O19");
        _d = _datetime.sub(_d);
        require(_d.div(86400)>expiryday,"O20");
        _setState(i,nextstate,_datetime);
        (_d,) =_getItem(i);
        address _s =  _getCreditor(i);
        _WithdrawERC721Token(i,_d,_s);
        isopen[_d]=false;
        emit TradeStatusChange(_trade,"expireTrade",nextstate,msg.sender,0,_datetime);
        
    }
    
    
    function forfeit(uint256 _trade,uint256 _datetime) public {
        address i = trades[_trade];
        (bool exist,string memory nextstate) = _transitionExists(_getState(i),"forfeit");
        require(exist , "O30");
        require( _isAdmin(msg.sender) || _isSettlement(msg.sender) , "O31");
         _setState(i,nextstate,_datetime);
        uint256 settledAmount = _getSettledAmount(i);
        uint256 baddebt_amount = _getTotalAmount(i).sub(settledAmount);
        uint256 forfeit_amount = settledAmount.sub(_getEarlySettle(i));
        ERC20PresetMinterPauser token = ERC20PresetMinterPauser(bookkeepingtoken);
        token.transferFrom(account_receivable,baddebt,baddebt_amount);
        _WithdrawERC20Token(i,bookkeepingtoken,forfeit_amount,client_forfeit);   
        emit TradeStatusChange(_trade,"_forfeit",nextstate,msg.sender,0,_datetime);
    }
    
    
    function refund(uint256 _trade,uint256 _datetime) public{
        address i = trades[_trade];
        (bool exist,string memory nextstate) = _transitionExists(_getState(i),"refund");
        require(exist , "O32");
        require( _isAdmin(msg.sender) || _isSettlement(msg.sender) , "O33");
        ERC20PresetMinterPauser token = ERC20PresetMinterPauser(bookkeepingtoken);
        uint256 amount = _getSettledAmount(i);
        require(token.balanceOf(i)==amount,"O34");
        _setState(i,nextstate,_datetime);
        _WithdrawERC20Token(i,bookkeepingtoken,amount,supplier_forfeit);
    }
    
    

    function getSellSideContractAddress(uint256 _i) public view
    returns(address _a)
    {
        require( _isAdmin(msg.sender) || _isSales(msg.sender) || _isAccount(msg.sender) || _isSettlement(msg.sender) 
                || _isExpense(msg.sender), "OP17");
        return trades[_i];
    }
    
    
    function _transitionExists(string memory state,string memory funname) internal view
    returns(bool e,string memory s)
    {
        (bool exist, string memory ns) = statemachine.transitionExists(state, keccak256(bytes(funname)));
        return (exist,ns);
    }
    
 
    function _ownerOf(address _base,uint256 _id) public view
    returns(address e)
    {
        ERC721 token = ERC721(_base);
        return token.ownerOf(_id);
        
    }
    

}
