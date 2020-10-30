pragma solidity ^0.6.0;

import "./expenseBookDS.sol";
//contract expenseBook is  AccessControl, GSNRecipient {
    

contract expenseBookLibrary is expenseBookDS {       
    
    event OrderStatusChange(uint256 ad, string status, string action,uint256 _datetime);
    event NewOrderRequest(uint256 ad, address seller, uint256 itemID,uint256 p,uint256 f,string c,uint8 pt,uint256 d);
    
    function createOrderRequest(uint256 _itemID, uint256 _price, uint256 _feesprecentage, string memory _currency,uint8 _paymenttype, uint256 _createdatetime,address _seller) public {
        require(orderbook.isopen(_itemID)==false, "E1");
        require(token[_itemID]==false, "E2");
        require(_isSupplier(msg.sender) || _isSales(msg.sender) || _isAdmin(msg.sender),"E0");
        require(diamondtoken.ownerOf(_itemID)==msg.sender, "E4" );
        require( _price >= 0 , "E5");
        _orderID.increment();
        uint256 id = _orderID.current()-1;
        SellSideContract i = new SellSideContract(_itemID, _price,1,_feesprecentage,_currency,_paymenttype,_createdatetime,address(access),_seller,owner);
        orders[id] = address(i);
        token[_itemID]=true;
        emit NewOrderRequest(id,_seller,_itemID,_price,_feesprecentage,_currency,_paymenttype,_createdatetime);
        
    } 
    
    function rejectRequest(uint256 _orderid,uint256 _datetime) public {
        require( _isAdmin(msg.sender) || _isSales(msg.sender), "E6");
        (bool exist, string memory nextstate)=_transitionExists(_getInvoiceState(orders[_orderid]),"rejectRequest");
        require(exist , "E7");
        _setInvoiceState(orders[_orderid],nextstate,_datetime);
        emit OrderStatusChange(_orderid, nextstate,"rejectRequest",_datetime);
        
    }
    
    function cancelRequest(uint256 _orderid,uint256 _datetime) public {
        address i = orders[_orderid];
        require(_isSales(msg.sender) ||  _isAdmin(msg.sender) || (msg.sender == _getInvoiceCreditor(i)) , "E8");
        (bool exist, string memory nextstate)=_transitionExists(_getInvoiceState(i),"cancelRequest");
        require(exist , "E9");
        _setInvoiceState(i,nextstate,_datetime);
        token[_getInvoiceItem(i)]=false;
        emit OrderStatusChange(_orderid, nextstate,"cancelRequest",_datetime);
        
    }
    
    function acceptRequest(uint256 _orderid, uint256 _price,bool _createtrade,uint256 _datetime) public {
        address i = orders[_orderid];
        require( _isSales(msg.sender) ||  _isAdmin(msg.sender) , "E10");
        require(_price>=_getInvoiceTotalPrice(i),"E30");
        (bool exist, string memory nextstate)=_transitionExists(_getInvoiceState(i),"acceptRequest");
        require(exist , "E11");
        _setInvoiceState(i,nextstate,_datetime);
        emit OrderStatusChange(_orderid, nextstate,"acceptRequest",_datetime);
        if(_createtrade){
            uint256 tradeid = orderbook.openTrade(_getInvoiceItem(i),_getInvoiceCreditor(i),_price,_orderid,_datetime);
            _setInvoiceAddTrade(i,tradeid,_datetime);
        }
               
    }  

    function cancelOrder(uint256 _orderid, uint256 _datetime) public {
        address i = orders[_orderid];
        require( _isSales(msg.sender) ||  _isAdmin(msg.sender) , "E12");
        (bool exist, string memory nextstate)=_transitionExists(_getInvoiceState(i),"cancelOrder");
        require(exist , "E13");
        uint256 itemid = _getInvoiceItem(i);
        if(orderbook.isopen(itemid)){ //check if there exists open trade in orderbook
            //got open trade in orderbook
            orderbook.cancelTrade(_getInvoiceCurrentTradeID(i),_datetime,true);
        }else {
            //cancel trade should call before, expenseBook is the item owner ,return back the item to seller
            
            diamondtoken.transferFrom(address(this),_getInvoiceCreditor(i),itemid);
        }
        token[itemid]=false;
        _setInvoiceState(i,nextstate,_datetime);
        emit OrderStatusChange(_orderid, nextstate,"cancelOrder",_datetime);
         
    }
    
     function addTrade(uint256 _orderid, uint256 _price, uint256 _datetime) public {
        address i = orders[_orderid];
        require( _isSales(msg.sender) ||  _isAdmin(msg.sender), "E14");
        require(_price>=_getInvoiceTotalPrice(i),"E30");
        (bool exist, string memory nextstate)=_transitionExists(_getInvoiceState(i),"addTrade");
        require(exist , "E15");
        uint256 itemid = _getInvoiceItem(i);
        require(orderbook.isopen(itemid)==false,"E16");
        uint256 tradeid = orderbook.openTrade(itemid,_getInvoiceCreditor(i),_price,_orderid,_datetime);
        _setInvoiceAddTrade(i,tradeid,_datetime);
        _setInvoiceState(i,nextstate,_datetime);
        emit OrderStatusChange(_orderid, nextstate,"addTrade",_datetime);
               
    }
    
    function cancelTrade(uint256 _orderid, uint256 _datetime) public {
        address i = orders[_orderid];
        require( _isSales(msg.sender) ||  _isAdmin(msg.sender), "E17");
        (bool exist, string memory nextstate)=_transitionExists(_getInvoiceState(i),"cancelTrade");
        require(exist , "E18");
        orderbook.cancelTrade(_getInvoiceCurrentTradeID(i),_datetime,false);
        _setInvoiceState(i,nextstate,_datetime);
        emit OrderStatusChange(_orderid, nextstate,"cancelTrade",_datetime);
               
    }
    
    function fullFillTrade(uint256 _orderid, uint256 _datetime) public {
        address i = orders[_orderid];
        require( access.hasRole(access.ORDER(),msg.sender) , "E19");
        (bool exist, string memory nextstate)=_transitionExists(_getInvoiceState(i),"fullFillTrade");
        require(exist , "E20");
        _setInvoiceState(i,nextstate,_datetime);
        emit OrderStatusChange(_orderid, nextstate,"fullFillTrade",_datetime);
        token[_getInvoiceItem(i)]=false;
               
    }
    
    
    function updateINV_settledate(uint256 _orderid, uint256 _settledate ,uint256 _settleamount, uint256 _datetime) public {
        address i = orders[_orderid];
        require( _isSettlement(msg.sender) ||  _isAdmin(msg.sender), "E21");
        require(bookkeepingtoken.balanceOf(address(this))>=_getInvoiceTotalPrice(i),"E31");
        (bool exist, string memory nextstate)=_transitionExists(_getInvoiceState(i),"updateINV_settledate");
        require(exist , "E22");
        _setInvoiceSettlementAmount(i,_settleamount,_settledate);
        _setInvoiceState(i,nextstate,_datetime);
        emit OrderStatusChange(_orderid, nextstate,"updateINV_settledate",_datetime);
        
    }
    
    
    function updateINV_settleURL(uint256 _orderid, string memory _settleurl , uint256 _datetime) public {
        address i = orders[_orderid];
        require( _isSettlement(msg.sender) ||  _isAdmin(msg.sender) ||  (msg.sender == _getInvoiceCreditor(i)) , "E23");
        (bool exist, string memory nextstate)=_transitionExists(_getInvoiceState(i),"updateINV_settleURL");
        require(exist , "E24");
        _setInvoiceSettlementURL(i,_settleurl);
        _setInvoiceState(i,nextstate,_datetime);
        emit OrderStatusChange(_orderid, nextstate,"updateINV_settleURL",_datetime);
  
    }
    
    function updateINV_paymentURL(uint256 _orderid, string memory _paymenturl , uint256 _datetime) public {
        address i = orders[_orderid];
        require( _isSettlement(msg.sender) ||  _isAdmin(msg.sender), "E25");
        (bool exist, string memory nextstate)=_transitionExists(_getInvoiceState(i),"updateINV_paymentURL");
        require(exist , "E26");
        _setInvoicePaymentURL(i,_paymenturl);
        _setInvoiceState(i,nextstate,_datetime);
        emit OrderStatusChange(_orderid, nextstate,"updateINV_settleURL",_datetime);
   
    }
    
    function updateINV_updateMeta(uint256 _orderid, uint64 key , string memory value) public {
        require( _isSettlement(msg.sender) ||  _isAdmin(msg.sender) || _isAccount(msg.sender), "E27");
        _setInvoiceMeta(orders[_orderid],key,value);
    }
    
    function updateINV_confirm(uint256 _orderid, uint256 _datetime) public {
        address i = orders[_orderid];
        require( _isSettlement(msg.sender) ||  _isAdmin(msg.sender) || _isAccount(msg.sender) ||  (msg.sender == _getInvoiceCreditor(i)) , "E28");

        (bool exist, string memory nextstate)=_transitionExists(_getInvoiceState(i),"updateINV_confirm");
        require(exist , "E29");
        _setInvoiceState(i,nextstate,_datetime);
        emit OrderStatusChange(_orderid, nextstate,"updateINV_confirm",_datetime);
        
    }
    
    function withdrawalDiamond(uint256 _itemid) public {
        require( _isSettlement(msg.sender) ||  _isAdmin(msg.sender) || _isAccount(msg.sender) , "E29");
        diamondtoken.transferFrom(address(this), msg.sender, _itemid);
    }
    
    function withdrawalbookeep(uint256 _amount) public  {
        require( _isSettlement(msg.sender) ||  _isAdmin(msg.sender) || _isAccount(msg.sender) , "E29");
        bookkeepingtoken.transferFrom(address(this), msg.sender, _amount);
    }
    
    function _transitionExists(string memory state,string memory funname) internal view
    returns(bool e,string memory s)
    {
        (bool exist, string memory ns) = statemachine.transitionExists(state, keccak256(bytes(funname)));
        return (exist,ns);
    }
    
    function _getInvoiceState(address _a) internal
    returns(string memory s){
        bytes memory payload = abi.encodeWithSignature("getState()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (string));
    }
    
    function _setInvoiceState(address _a,string memory _s,uint256 _d) internal
    {
        bytes memory payload = abi.encodeWithSignature("setState(string,uint256)",_s,_d);
        (bool success, ) = _a.call(payload);
        require(success,"O23");
     
    }
    
    function _getInvoiceCreditor(address _a) internal
    returns(address _c)
    {
        bytes memory payload = abi.encodeWithSignature("getCreditor()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (address));
    }
    
    function _getInvoiceItem(address _a) internal
    returns(uint256 _c)
    {
        bytes memory payload = abi.encodeWithSignature("getItem()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (uint256));
    }
    
    function _getInvoiceTotalPrice(address _a) internal
    returns(uint256 _c)
    {
        bytes memory payload = abi.encodeWithSignature("getOrderPrice()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (uint256));
    }
    
    function _getInvoiceCurrentTradeID(address _a) internal
    returns(uint256 _c)
    {
         bytes memory payload = abi.encodeWithSignature("getCurrentTradeID()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (uint256));
    }
    
    function _setInvoiceAddTrade(address _a,uint256 _id,uint256 _d) internal
    {
        
        bytes memory payload = abi.encodeWithSignature("setTradeID(uint256,uint256)",_id,_d);
        (bool success,) = _a.call(payload);
        require(success,"O23");
    }
    
    function _setInvoiceSettlementAmount(address _a,uint256 _s,uint256 _d) internal
    {
        
        bytes memory payload = abi.encodeWithSignature("setSettlementAmount(uint256,uint256)",_s,_d);
        (bool success,) = _a.call(payload);
        require(success,"O23");
    }
    
    function _setInvoiceSettlementURL(address _a,string memory _s) internal
    {
        
        bytes memory payload = abi.encodeWithSignature("setSettlementURL(string)",_s);
        (bool success,) = _a.call(payload);
        require(success,"O23");
    }
    
    function _setInvoicePaymentURL(address _a,string memory _s) internal
    {
        
        bytes memory payload = abi.encodeWithSignature("setpaymentURL(string)",_s);
        (bool success,) = _a.call(payload);
        require(success,"O23");
    }
    
    function _setInvoiceMeta(address _a, uint64 _key,string memory _s) internal
    {
        
        bytes memory payload = abi.encodeWithSignature("etMeta(uint64,string)",_key,_s);
        (bool success,) = _a.call(payload);
        require(success,"O23");
    }
  
    
}