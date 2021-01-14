pragma solidity ^0.6.0;

import "../BuySellContract/BuySideContractFactory.sol";
import "../BuySellContract/baseContractAccesser.sol";
import "./expenseBookDS.sol";

contract expenseBookLibrary is expenseBookDS,baseContractAccessor {       
    
    event OrderStatusChange(uint256 ad, string status, string action,uint256 _datetime);
    event NewOrderRequest(address cd,uint256 ad, address seller, uint256 itemID,uint256 p,uint256 f,string c,uint256 d);
    
    function createOrderRequest(uint256 _itemID, uint256 _price, uint256 _feesprecentage, string memory _currency, uint256 _createdatetime,address _seller) public {
        address _baseaddr = lookup.getBaseAddress(_itemID);
        require(orderbook.isopen(_itemID)==false, "E0");
        require(token[_itemID]==false, "E1");
        require(_isSupplier(msg.sender) || _isSales(msg.sender) || _isAdmin(msg.sender),"E2");
        bool ownershipcheck = (_isSales(msg.sender) || _isAdmin(msg.sender))?false:true;
        ERC721 erc721token = ERC721(_baseaddr);
        if(ownershipcheck){
            require((erc721token.ownerOf(_itemID)==msg.sender && _seller==msg.sender), "E3" );
        }
        require( _price >= 0 , "E4");
        _orderID.increment();
        uint256 id = _orderID.current()-1;
        BuySideContractFactory c = BuySideContractFactory(contractfactory);
        address i = c.createNewBuySideContract(_itemID,_price, _feesprecentage, _currency,_createdatetime, _seller,address(access),_baseaddr); 
        erc721token.transferFrom(_seller,i,_itemID);
        orders[id] = i;
        address2orders[i]=id;
        token[_itemID]=true;
        emit NewOrderRequest(i,id,_seller,_itemID,_price,_feesprecentage,_currency,_createdatetime);
        
    } 
    
    function rejectRequest(uint256 _orderid,uint256 _datetime,string memory _msg)public {
        require( _isAdmin(msg.sender) || _isSales(msg.sender), "E6");
        (bool exist, string memory nextstate)=_transitionExists(_getState(orders[_orderid]),"rejectRequest");
        require(exist , "E5");
        _setMeta(orders[_orderid],0,_msg);
        _setState(orders[_orderid],nextstate,_datetime);
        emit OrderStatusChange(_orderid, nextstate,"rejectRequest",_datetime);
        
    }
    


    function cancelRequest(uint256 _orderid,uint256 _datetime) public {
        address i = orders[_orderid];
        require(_isSales(msg.sender) ||  _isAdmin(msg.sender) || (msg.sender == _getCreditor(i)) , "E6");
        (bool exist, string memory nextstate)=_transitionExists(_getState(i),"cancelRequest");
        require(exist , "E7");
        _setState(i,nextstate,_datetime);
        (_orderid,)=_getItem(i);
         address c = _getCreditor(i);
        _WithdrawERC721Token(i,_orderid,c);
        token[_orderid]=false;
        emit OrderStatusChange(_orderid, nextstate,"cancelRequest",_datetime);
        
    }
    
    function acceptRequest(uint256 _orderid, uint256 _price,bool _createtrade,uint256 _datetime,string memory _currency) public {
        address i = orders[_orderid];
        require( _isSales(msg.sender) ||  _isAdmin(msg.sender) , "E8");
        require(_price>=_getTotalAmount(i),"E9");
        (bool exist, string memory nextstate)=_transitionExists(_getState(i),"acceptRequest");
        require(exist , "E10");
        _setState(i,nextstate,_datetime);
        emit OrderStatusChange(_orderid, nextstate,"acceptRequest",_datetime);
        if(_createtrade){
            
            (uint256 _itemID,address _base) = _getItem(i);
            uint256 tradeid = orderbook.openTrade(_itemID,_base,_price,i,_datetime,_currency);
            _setbuySideAddTrade(i,tradeid,_datetime);
        }
               
    }  

    function cancelOrder(uint256 _orderid, uint256 _datetime) public {
        address i = orders[_orderid];
        require( _isSales(msg.sender) ||  _isAdmin(msg.sender) || _getCreditor(i)==msg.sender, "E11");
        (bool exist, string memory nextstate)=_transitionExists(_getState(i),"cancelOrder");
        require(exist , "E12");
        (uint256 itemid,) = _getItem(i);
        require(!orderbook.isopen(itemid),"E31"); 
        _WithdrawERC721Token(i,itemid,_getCreditor(i));
        token[itemid]=false;
        _setState(i,nextstate,_datetime);
        emit OrderStatusChange(_orderid, nextstate,"cancelOrder",_datetime);
        
    }

    
     function addTrade(uint256 _orderid, uint256 _price, uint256 _datetime,string memory _currency) public {
        address i = orders[_orderid];
        require( _isSales(msg.sender) ||  _isAdmin(msg.sender), "E13");
        require(_price>=_getTotalAmount(i),"E14");
        (bool exist, string memory nextstate)=_transitionExists(_getState(i),"addTrade");
        require(exist , "E15");
        (uint256 itemid,address base) = _getItem(i);
        require(orderbook.isopen(itemid)==false,"E16");

        uint256 tradeid = orderbook.openTrade(itemid,base,_price,i,_datetime,_currency);
        _setbuySideAddTrade(i,tradeid,_datetime);
        _setState(i,nextstate,_datetime);
        emit OrderStatusChange(_orderid, nextstate,"addTrade",_datetime);
               
    }
    
    function cancelTrade(uint256 _orderid, uint256 _datetime) public {
        address i = orders[_orderid];
        require( _isSales(msg.sender) ||  _isAdmin(msg.sender), "E17");
        (bool exist, string memory nextstate)=_transitionExists(_getState(i),"cancelTrade");
        require(exist , "E18");
        orderbook.cancelTrade(_getSellSideCurrentTradeID(i),_datetime,false);
        _setState(i,nextstate,_datetime);
        emit OrderStatusChange(_orderid, nextstate,"cancelTrade",_datetime);
               
    }
    
    function fullFillTrade(address _contract, uint256 _datetime) public {
        require(_contract!=address(0),"E19");
        uint256 i = address2orders[_contract];
        require( _isOrder(msg.sender) || _isSettlement(msg.sender) || _isAdmin(msg.sender), "E20");
        //ERC20PresetMinterPauser erc20 = ERC20PresetMinterPauser(bookkeepingtoken);
        //require(erc20.balanceOf(_contract)>0,"E33");
        (bool exist, string memory nextstate)=_transitionExists(_getState(_contract),"fullFillTrade");
        require(exist , "E21");
        _setState(_contract,nextstate,_datetime);
        emit OrderStatusChange(i, nextstate,"fullFillTrade",_datetime);
        (i,)=_getItem(_contract);
        token[i]=false;
               
    }
    
    
    function addSettlementPlan(uint256 _orderid, uint256 _settledate ,uint256 _settleamount, uint256 _datetime) public {
        address i = orders[_orderid];
        uint256 p = _getPlanedSettlementAmount(i);
        uint256 o = _getTotalAmount(i);
        require(_settleamount.add(p)<=o,"E32");
        require( _isSettlement(msg.sender) ||  _isAdmin(msg.sender), "E22");
        (bool exist, string memory nextstate)=_transitionExists(_getState(i),"addSettlementPlan");
        require(exist , "E24");
        _addSettlementPlan(i, _settleamount,_settledate,_datetime,true);
        _setState(i,nextstate,_datetime);
        emit OrderStatusChange(_orderid, nextstate,"addSettlementPlan",_datetime);
        
    }
   
    function settleOrder(uint256 _orderid,string memory _banktx ,uint256 _paymentdate,uint8 _paymenttype,uint256 _datetime) public {
        address i = orders[_orderid];
        require( _isSettlement(msg.sender) ||  _isAdmin(msg.sender), "E26");
        (bool exist, string memory nextstate)=_transitionExists(_getState(i),"settleOrder");
        require(exist , "E27");
        ERC20PresetMinterPauser token = ERC20PresetMinterPauser(bookkeepingtoken);
        uint256 _amount = token.balanceOf(i);
        (uint256 _index,uint256 _d,uint256 _a)=_getActiveSettlementPlan(i);
        address creditor = _getCreditor(i);
        while(_amount>=_a && _d >0 ){
            _completePayment(i,_index,_banktx,_paymentdate,_paymenttype);
            _WithdrawERC20Token(i,bookkeepingtoken,_a,creditor);
            (_index,_d,_a)=_getActiveSettlementPlan(i);
        }
        if(_isSettled(i)){
            require(token.balanceOf(i)==0,"E30");
             _setState(i,"SETTLE",_datetime);
            emit OrderStatusChange(_orderid, "SETTLE","settleOrder",_datetime);
        }else{
            _setState(i,nextstate,_datetime);
            emit OrderStatusChange(_orderid, nextstate,"settleOrder",_datetime);
        }
    }
    
    
    function refund(uint256 _orderid,uint256 _datetime) public{
        address i = orders[_orderid];
        (bool exist,string memory nextstate) = _transitionExists(_getState(i),"refund");
        require(exist , "E34");
        require( _isAdmin(msg.sender) || _isSettlement(msg.sender) , "E35");
        ERC20PresetMinterPauser token = ERC20PresetMinterPauser(bookkeepingtoken);
        uint256 amount = _getSettledAmount(i);
        require(token.balanceOf(i)==amount,"E36");
        _setState(i,nextstate,_datetime);
        uint256 tradeid = _getSellSideCurrentTradeID(i);
        address TradeAddress = orderbook.getSellSideContractAddress(tradeid);
        _WithdrawERC20Token(i,bookkeepingtoken,amount,TradeAddress);
        
    }
    
    
    function _transitionExists(string memory state,string memory funname) internal view
    returns(bool e,string memory s)
    {
        (bool exist, string memory ns) = statemachine.transitionExists(state, keccak256(bytes(funname)));
        return (exist,ns);
    }
    
    
    function _setbuySideAddTrade(address _a,uint256 _id,uint256 _d) internal
    {
        
        bytes memory payload = abi.encodeWithSignature("setTradeID(uint256,uint256)",_id,_d);
        (bool success,) = _a.call(payload);
        require(success,"E28");
    }
  
    function _getSellSideCurrentTradeID(address _a) internal
    returns(uint256 _c)
    {
         bytes memory payload = abi.encodeWithSignature("getTradeID()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"E29");
        return abi.decode(result, (uint256));
    }
    
    
}