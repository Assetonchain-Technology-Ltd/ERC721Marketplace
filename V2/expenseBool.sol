pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721Holder.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/GSN/GSNRecipient.sol";

import "./orderbook.sol";
import "./compliance.sol";
import "./stateMachine.sol";

//contract expenseBook is  AccessControl, GSNRecipient {

contract expenseBook is Ownable , AccessControl {   
    event OrderStatusChange(uint256 ad, string status);
    event NewOrderRequest(address seller, uint256 itemID);
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address;

    struct Order{
        address seller;
        uint256 tradeID;
        uint256 diamondTokenID;
        uint256 unit_price;
        uint256 feesprecentage;
        string currency;
        uint8 paymenttype;
        uint256 settlementdate;
        string settlementReferenceURL;
        string  paymentReferenceURL;
        string state;
        mapping(string => uint256) stateChange;
        mapping(uint64 => string) meta;
        //meta[0] = rejectresaon
    }

    Orderbook orderbook;
    Compliance compliance;
    ERC721 diamondtoken;
    ERC20 bookkeepingtoken;
    StateMachine statemachine;
    uint256 feesprecentage_decimal;
    Counters.Counter private _orderID;
    
    mapping(uint256 => Order) private orders;
    mapping(string => uint8 ) public currencydecimal;
    mapping(uint256 => bool ) public token; // check if there is open order in expensebook
    
    constructor (address _orderbook, address _compliance, address _diamondtoken, address _statemachine,address _bookeep ) public virtual
    {
        orderbook = Orderbook(_orderbook);
        compliance = Compliance(_compliance);
        diamondtoken = ERC721(_diamondtoken);
        bookkeepingtoken = ERC20(_bookeep);
        statemachine = StateMachine(_statemachine);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        currencydecimal["HKD"]=2;
        currencydecimal["USD"]=2;
        feesprecentage_decimal = 10;
        diamondtoken.setApprovalForAll(_orderbook,true);
        
        
    }
    
    
    function setfeesprecentage_decimal(uint256 d) public onlyOwner{
        feesprecentage_decimal=d;
    }
    
    function getfeesprecentage_decimal() public view
    returns(uint256)
    {
        return feesprecentage_decimal;
    }
    
    
    
    function getOrder(uint256 _order) public virtual view
        returns(address, uint256, uint256, uint256 ,uint256, string memory , uint8, uint256, string memory, string memory, string memory)
        
    {
        Order memory order = orders[_order];
        require( (hasRole(DEFAULT_ADMIN_ROLE,_msgSender())) ||  (_msgSender() == order.seller) , "E0");
        return (order.seller, order.tradeID, order.diamondTokenID, order.unit_price, order.feesprecentage, order.currency, order.paymenttype , order.settlementdate,order.settlementReferenceURL,order.paymentReferenceURL,order.state);
    }
    
    function createOrderRequest(uint256 _itemID, uint256 _price, uint256 _feesprecentage, string memory _currency,uint8 _paymenttype, uint256 _createdatetime) public {
        require(orderbook.isopen(_itemID)==false, "E1");
        require(token[_itemID]==false, "E2");
        require(compliance.isPass(_msgSender()),"E3");
        require(diamondtoken.ownerOf(_itemID)==_msgSender(), "E4" );
        require( _price >= 0 , "E5");
        orders[_orderID.current()] = Order({
            seller: _msgSender(),
            tradeID: 0,
            diamondTokenID:_itemID,
            unit_price: _price,
            feesprecentage : _feesprecentage,
            currency : _currency,
            paymenttype: _paymenttype,
            settlementdate : 0,
            settlementReferenceURL : "NULL",
            paymentReferenceURL : "NULL",
            state : "OI"
        });
        orders[_orderID.current()].stateChange["OI"]=_createdatetime;
        _orderID.increment();
        token[_itemID]=true;
        emit NewOrderRequest(_msgSender(),_itemID);
        
    }
    
    function rejectRequest(uint256 _orderid,string memory rejectreason,uint256 _datetime) public {
        require( hasRole(DEFAULT_ADMIN_ROLE,_msgSender()), "E6");
        bytes32 functionhash = keccak256("rejectRequest");
        (bool exist, string memory nextstate) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E7");
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        orders[_orderid].meta[0]=rejectreason;
        
        emit OrderStatusChange(_orderid, nextstate);
        
    }
    
    function cancelRequest(uint256 _orderid,uint256 _datetime) public {
        
        require( (hasRole(DEFAULT_ADMIN_ROLE,_msgSender())) ||  (_msgSender() == orders[_orderid].seller) , "E8");
        bytes32 functionhash = keccak256("cancelRequest");
        (bool exist,string memory nextstate) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E9");
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        token[orders[_orderid].diamondTokenID]=false;
        emit OrderStatusChange(_orderid, nextstate);
        
    }
    
    function acceptRequest(uint256 _orderid, uint256 _price,bool _createtrade,uint256 _datetime) public {
        require( hasRole(DEFAULT_ADMIN_ROLE,_msgSender()), "E10");
        require(_price>=orders[_orderid].unit_price,"E30");
        bytes32 functionhash = keccak256("acceptRequest");
        (bool exist, string memory nextstate ) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E11");
        Order memory o = orders[_orderid];
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        emit OrderStatusChange(_orderid, nextstate);
   
        if(_createtrade){
            uint256 tradeid = orderbook.openTrade(o.diamondTokenID,o.seller,_price,_orderid,_datetime);
            orders[_orderid].tradeID=tradeid;
        }
               
    }  

    function cancelOrder(uint256 _orderid, uint256 _datetime) public {
        require( hasRole(DEFAULT_ADMIN_ROLE,_msgSender()), "E12");
        bytes32 functionhash = keccak256("cancelOrder");
        (bool exist, string memory nextstate ) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E13");
        uint256 itemid = orders[_orderid].diamondTokenID;
        if(token[itemid]){ //check if there exists open trade in orderbook
            //got open trade in orderbook
            orderbook.cancelTrade(orders[_orderid].tradeID,_datetime,true);
        }else {
            //cancel trade should call before, expenseBook is the item owner ,return back the item to seller
            diamondtoken.transferFrom(address(this),orders[_orderid].seller,itemid);
        }
        token[itemid]=false;
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        emit OrderStatusChange(_orderid, nextstate);
         
    }
    
     function addTrade(uint256 _orderid, uint256 _price, uint256 _datetime) public {
        require( hasRole(DEFAULT_ADMIN_ROLE,_msgSender()), "E14");
        require(_price>=orders[_orderid].unit_price,"E30");
        bytes32 functionhash = keccak256("addTrade");
        (bool exist, string memory nextstate ) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E15");
        require(orderbook.isopen(orders[_orderid].diamondTokenID)==false,"E16");
        uint256 tradeid = orderbook.openTrade(orders[_orderid].diamondTokenID,orders[_orderid].seller,_price,_orderid,_datetime);
        orders[_orderid].tradeID= tradeid;
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        emit OrderStatusChange(_orderid, nextstate);
        
               
    }
    
    function cancelTrade(uint256 _orderid, uint256 _datetime) public {
        require( hasRole(DEFAULT_ADMIN_ROLE,_msgSender()), "E17");
        bytes32 functionhash = keccak256("cancelTrade");
        (bool exist, string memory nextstate ) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E18");
        orderbook.cancelTrade(orders[_orderid].tradeID,_datetime,false);
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        emit OrderStatusChange(_orderid, nextstate);
               
    }
    
    function fullFillTrade(uint256 _orderid, uint256 _datetime) public {
        
        require( address(orderbook)==_msgSender() , "E19");
        bytes32 functionhash = keccak256("fullFillTrade");
        (bool exist, string memory nextstate ) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E20");
        
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        emit OrderStatusChange(_orderid, nextstate);
        token[orders[_orderid].diamondTokenID]=false;
               
    }
    
    
    function updateINV_settledate(uint256 _orderid, uint256 _settledate , uint256 _datetime) public {
        require( hasRole(DEFAULT_ADMIN_ROLE,_msgSender()), "E21");
        bytes32 functionhash = keccak256("updateINV_settledate");
        (bool exist, string memory nextstate ) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E22");
        orders[_orderid].settlementdate = _settledate;
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        emit OrderStatusChange(_orderid, nextstate);
        
    }
    
    
    function updateINV_settleURL(uint256 _orderid, string memory _settleurl , uint256 _datetime) public {
        require( (hasRole(DEFAULT_ADMIN_ROLE,_msgSender())) ||  (_msgSender() == orders[_orderid].seller) , "E23");
        bytes32 functionhash = keccak256("updateINV_settleURL");
        (bool exist, string memory nextstate ) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E24");
        orders[_orderid].settlementReferenceURL = _settleurl;
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        emit OrderStatusChange(_orderid, nextstate);
        
    }
    
    function updateINV_paymentURL(uint256 _orderid, string memory _paymenturl , uint256 _datetime) public {
        require( hasRole(DEFAULT_ADMIN_ROLE,_msgSender()), "E25");
        bytes32 functionhash = keccak256("updateINV_paymentURL");
        (bool exist, string memory nextstate ) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E26");
        orders[_orderid].paymentReferenceURL = _paymenturl;
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        emit OrderStatusChange(_orderid, nextstate);
        
    }
    
    function updateINV_updateMeta(uint256 _orderid, uint64 key , string memory value) public {
        require( hasRole(DEFAULT_ADMIN_ROLE,_msgSender()), "E27");
        orders[_orderid].meta[key]=value;
        
    }
    
    function updateINV_confirm(uint256 _orderid, uint256 _datetime) public {
        require( (hasRole(DEFAULT_ADMIN_ROLE,_msgSender())) ||  (_msgSender() == orders[_orderid].seller) , "E28");
        bytes32 functionhash = keccak256("updateINV_confirm");
        (bool exist, string memory nextstate ) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E29");
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        emit OrderStatusChange(_orderid, nextstate);
        
    }
    
    function withdrawalDiamond(uint256 _itemid) public onlyOwner {
        diamondtoken.transferFrom(address(this), _msgSender(), _itemid);
    }
    
    function withdrawalbookeep(uint256 _amount) public onlyOwner {
        bookkeepingtoken.transferFrom(address(this), _msgSender(), _amount);
    }
    
    /*function _msgSender() internal view virtual override(Context,GSNRecipient) returns (address payable) 
    {
        return super._msgSender();
    }
    
    function _msgData() internal view virtual override(Context,GSNRecipient) returns (bytes memory) {
        return super._msgData();
    }
    
    
     function acceptRelayedCall  (
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256 maxPossibleCharge
    ) external override view returns (uint256, bytes memory) {
        return _approveRelayedCall();
    }

    // We won't do any pre or post processing, so leave _preRelayedCall and _postRelayedCall empty
    function _preRelayedCall(bytes memory context) internal override returns (bytes32) {
    }

    function _postRelayedCall(bytes memory context, bool, uint256 actualCharge, bytes32) internal override {
    }*/
  
}