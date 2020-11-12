pragma solidity ^0.6.0;

import "../BuySellContract/BuySideContract.sol";
import "../BuySellContract/baseContractAccesser.sol";
import "./expenseBookDS.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";

contract expenseBookLibrary is expenseBookDS,baseContractAccessor {       
    
    event OrderStatusChange(uint256 ad, string status, string action,uint256 _datetime);
    event NewOrderRequest(uint256 ad, address seller, uint256 itemID,uint256 p,uint256 f,string c,uint256 d);
    
    function createOrderRequest(uint256 _itemID,address _baseaddr, uint256 _price, uint256 _feesprecentage, string memory _currency, uint256 _createdatetime,address _seller) public {
        require(orderbook.isopen(_itemID)==false, "E1");
        require(token[_itemID]==false, "E2");
        require(_isSupplier(msg.sender) || _isSales(msg.sender) || _isAdmin(msg.sender),"E0");
        ERC721 erc721token = ERC721(_baseaddr);
        require(erc721token.ownerOf(_itemID)==msg.sender, "E4" );
        require( _price >= 0 , "E5");
        _orderID.increment();
        uint256 id = _orderID.current()-1;
        BuySideContract i = new BuySideContract(_itemID,_baseaddr, _price,_feesprecentage,_currency,_createdatetime,address(access),_seller,address(this));
        erc721token.safeTransferFrom(_seller,address(i),_itemID);
        orders[id] = address(i);
        address2orders[address(i)]=id;
        token[_itemID]=true;
        emit NewOrderRequest(id,_seller,_itemID,_price,_feesprecentage,_currency,_createdatetime);
        
    } 
    
    function rejectRequest(uint256 _orderid,uint256 _datetime) public {
        require( _isAdmin(msg.sender) || _isSales(msg.sender), "E6");
        (bool exist, string memory nextstate)=_transitionExists(_getState(orders[_orderid]),"rejectRequest");
        require(exist , "E7");
        _setState(orders[_orderid],nextstate,_datetime);
        emit OrderStatusChange(_orderid, nextstate,"rejectRequest",_datetime);
        
    }
    
    function cancelRequest(uint256 _orderid,uint256 _datetime) public {
        address i = orders[_orderid];
       
        require(_isSales(msg.sender) ||  _isAdmin(msg.sender) || (msg.sender == _getCreditor(i)) , "E8");
        (bool exist, string memory nextstate)=_transitionExists(_getState(i),"cancelRequest");
        require(exist , "E9");
        _setState(i,nextstate,_datetime);
        (_orderid,)=_getItem(i);
         address c = _getCreditor(i);
        _WithdrawERC721Token(i,_orderid,c);
        token[_orderid]=false;
        emit OrderStatusChange(_orderid, nextstate,"cancelRequest",_datetime);
        
    }
    
    function acceptRequest(uint256 _orderid, uint256 _price,bool _createtrade,uint256 _datetime,string memory _currency) public {
        address i = orders[_orderid];
        require( _isSales(msg.sender) ||  _isAdmin(msg.sender) , "E10");
        require(_price>=_getTotalAmount(i),"E30");
        (bool exist, string memory nextstate)=_transitionExists(_getState(i),"acceptRequest");
        require(exist , "E11");
        _setState(i,nextstate,_datetime);
        emit OrderStatusChange(_orderid, nextstate,"acceptRequest",_datetime);
        if(_createtrade){
            
            (uint256 _itemID,address _base) = _getItem(i);
            orderbook.openTrade(_itemID,_base,_price,i,_datetime,_currency);
            uint256 tradeid = orderbook.openTrade(_itemID,_base,_price,i,_datetime,_currency);
            _setbuySideAddTrade(i,tradeid,_datetime);
        }
               
    }  

    function cancelOrder(uint256 _orderid, uint256 _datetime) public {
        address i = orders[_orderid];
        require( _isSales(msg.sender) ||  _isAdmin(msg.sender) || _getCreditor(i)==msg.sender, "E12");
        (bool exist, string memory nextstate)=_transitionExists(_getState(i),"cancelOrder");
        require(exist , "E13");
        (uint256 itemid,) = _getItem(i);
        if(orderbook.isopen(itemid)){ //check if there exists open trade in orderbook
            //got open trade in orderbook
            orderbook.cancelTrade(_getSellSideCurrentTradeID(i),_datetime,true);
        }else {
            //cancel trade should call before, expenseBook is the item owner ,return back the item to seller
            _WithdrawERC721Token(i,itemid,_getCreditor(i));
        }
        token[itemid]=false;
        _setState(i,nextstate,_datetime);
        emit OrderStatusChange(_orderid, nextstate,"cancelOrder",_datetime);
         
    }
    
     function addTrade(uint256 _orderid, uint256 _price, uint256 _datetime,string memory _currency) public {
        address i = orders[_orderid];
        require( _isSales(msg.sender) ||  _isAdmin(msg.sender), "E14");
        require(_price>=_getTotalAmount(i),"E30");
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
        require(_contract!=address(0),"E32");
        uint256 i = address2orders[_contract];
        require( _isOrder(msg.sender) , "E19");
        (bool exist, string memory nextstate)=_transitionExists(_getState(_contract),"fullFillTrade");
        require(exist , "E20");
        _setState(_contract,nextstate,_datetime);
        emit OrderStatusChange(i, nextstate,"fullFillTrade",_datetime);
        (i,)=_getItem(_contract);
        token[i]=false;
               
    }
    
    
    function addSettlementPlan(uint256 _orderid, uint256 _settledate ,uint256 _settleamount, uint256 _datetime) public {
        address i = orders[_orderid];
        require( _isSettlement(msg.sender) ||  _isAdmin(msg.sender), "E21");
        ERC20 bookkeep = ERC20(bookkeepingtoken);
        require(bookkeep.balanceOf(address(this))>=_getTotalAmount(i),"E31");
        
        (bool exist, string memory nextstate)=_transitionExists(_getState(i),"updateINV_settledate");
        require(exist , "E22");
        _addSettlementPlan(i, _settleamount,_settledate,_datetime,true);
        emit OrderStatusChange(_orderid, nextstate,"updateINV_settledate",_datetime);
        
    }
    
    
   
    function settleOrder(uint256 _orderid,string memory _banktx ,uint256 _paymentdate,uint8 _paymenttype,uint256 _datetime) public {
        address i = orders[_orderid];
        require( _isSettlement(msg.sender) ||  _isAdmin(msg.sender), "E25");
        (bool exist, string memory nextstate)=_transitionExists(_getState(i),"updateINV_paymentURL");
        require(exist , "E26");
        ERC20 bookkeep = ERC20(bookkeepingtoken);
        uint256 _amount = bookkeep.balanceOf(address(this));
        (uint256 _index,uint256 _d,uint256 _a)=_getActiveSettlementPlan(i);
        address creditor = _getCreditor(i);
        while(_amount>=_a){
            _completePayment(i,_index,_banktx,_paymentdate,_paymenttype);
            _WithdrawERC20Token(i,bookkeepingtoken,_a,creditor);
            (_index,_d,_a)=_getActiveSettlementPlan(i);
        }
        if(_isSettled(i)){
             _setState(i,"SETTLE",_datetime);
            emit OrderStatusChange(_orderid, "SETTLE","settleOrder",_datetime);
        }else{
            _setState(i,nextstate,_datetime);
            emit OrderStatusChange(_orderid, nextstate,"settleOrder",_datetime);
        }
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
        require(success,"O23");
    }
  
    function _getSellSideCurrentTradeID(address _a) internal
    returns(uint256 _c)
    {
         bytes memory payload = abi.encodeWithSignature("getTradeID()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (uint256));
    }
    
}