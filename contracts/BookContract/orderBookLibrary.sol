pragma solidity ^0.6.0;

import "../BuySellContract/SellSideContract.sol";
import "../BuySellContract/baseContractAccesser.sol";
import "./orderBookDS.sol";
import "openzeppelin-solidity/contracts/presets/ERC20PresetMinterPauser.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";


contract orderbookLibrary is orderBookDS ,baseContractAccessor{
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
        require(_ownerOf(_base,_itemID)==_sellsideorder,"O18");
        require(isopen[_itemID]==false,"O30");
        _tradeID.increment();
        uint256 currentID = _tradeID.current()-1;
        address _seller = _getCreditor(_sellsideorder);
        uint256 _mindeposit = (fixdeposit>0)?fixdeposit:_price.mul(depositpercentage).div(percentage_decimal.mul(100));
        SellSideContract b = new SellSideContract(_itemID,_base,_price,_currency,_datetime,address(access),_seller,currentID,_sellsideorder);
        _base = address(b);
        _setMindeposit(_base,_mindeposit);
        trades[currentID] = _base;
        _WithdrawERC721Token(_sellsideorder,_itemID,_base);
        isopen[_itemID]=true;
        emit NewTrade(currentID,msg.sender,_itemID,_price,_sellsideorder,_mindeposit,_datetime);
        return currentID;
        
    }
    
    function markTrade(uint256 _trade,uint256 _feespercentage, uint256 _datetime,bool _fullpay) public
    {   
        address i = trades[_trade];
        (bool exist,string memory nextstate) = _transitionExists(_getState(i),"markTrade");
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
    
    function executeTrade(uint256 _trade,uint8 _paymenttype, uint256 _amount, string memory _tx,uint256 _datetime) public
    {
        address i = trades[_trade];
        (bool exist,string memory nextstate) = _transitionExists(_getState(i),"executeTrade");
        //profile checking
        require(exist , "O3");
        require( _isAdmin(msg.sender) || _isSettlement(msg.sender), "O2");
        ERC20PresetMinterPauser bookkeep = ERC20PresetMinterPauser(bookkeepingtoken);
        (uint256 _index,uint256 _d,uint256 _a)=_getActiveSettlementPlan(i);
        while(_amount>=_a){
            _completePayment(i,_index,_tx,_datetime,_paymenttype);
            bookkeep.transferFrom(account_receivable,i,_a);
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
            _WithdrawERC721Token(i,_a,debtor);
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
        (bool exist,string memory nextstate) = _transitionExists(_getState(i),"executeExpensebook");
        require(exist , "O3");
        require( _isAdmin(msg.sender) || _isSettlement(msg.sender), "O2");
        address s = _getBuySideContract(i);
        uint256 cost =_getTotalAmount(s);
        uint256 sales = _getTotalAmount(i);
        require(sales>=cost,"O32");
        uint256 fees = _getFeeAmount(i);
        uint256 profit = sales.sub(cost);
        //profile checking
        //require(_msgSender()==address(paymentbook),"O20");
        ERC20PresetMinterPauser bookkeep = ERC20PresetMinterPauser(bookkeepingtoken);
        require(bookkeep.balanceOf(address(this))>=sales.add(fees),"O23");
        _WithdrawERC20Token(i,bookkeepingtoken,cost,s);
        _WithdrawERC20Token(i,bookkeepingtoken,fees,platformfees);
        _WithdrawERC20Token(i,bookkeepingtoken,profit,platform);
        bytes memory payload = abi.encodeWithSignature("fullFillTrade(uint256,uint256)",s,_datetime);
        expensebook.call(payload);
        
    }

    function cancelTrade(uint256 _trade,uint256 _datetime,bool return2owner)
        public
    {
        address i = trades[_trade];
        uint256 _itemid;
        (bool exist,string memory nextstate) = _transitionExists(_getState(i),"cancelTrade");
        require(exist , "O11");
        address c = _getBuySideContract(i);
        address s = _getSeller(i);
        require( _isAdmin(msg.sender) || _isSettlement(msg.sender) || _isExpense(msg.sender), "O2");
        address d = return2owner?s:c;
        (_itemid,) = _getItem(i);
        _WithdrawERC721Token(i,_itemid,d);
        _setState(i,nextstate,_datetime);
        isopen[_itemid]=false;
        emit TradeStatusChange(_trade,"cancelTrade",nextstate,msg.sender,0,_datetime);
    }
    
    
    function expireTrade(uint256 _trade,uint256 _datetime) public{
        address i = trades[_trade];
        (bool exist,string memory nextstate) = _transitionExists(_getState(i),"expireTrade");
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
    
    function _transitionExists(string memory state,string memory funname) internal view
    returns(bool e,string memory s)
    {
        (bool exist, string memory ns) = statemachine.transitionExists(state, keccak256(bytes(funname)));
        return (exist,ns);
    }
    
    function _getBuySideContract(address _a) internal 
    returns(address _c)
    {
        bytes memory payload = abi.encodeWithSignature("getSellSideContract()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (address));
    }
    
    function _ownerOf(address _base,uint256 _id) public view
    returns(address e)
    {
        ERC721 token = ERC721(_base);
        return token.ownerOf(_id);
        
    }
    

}
