pragma solidity ^0.6.0;

//import "openzeppelin-solidity/contracts/token/ERC721/ERC721Holder.sol";
//import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
//import "openzeppelin-solidity/contracts/utils/Counters.sol";
//import "openzeppelin-solidity/contracts/access/AccessControl.sol";
//import "openzeppelin-solidity/contracts/math/SafeMath.sol";
//import "openzeppelin-solidity/contracts/utils/Address.sol";



import "./orderbook.sol";
import "./compliance.sol";
import "./stateMachine.sol";
import "./paymentBook.sol";
import "openzeppelin-solidity/contracts/access/RBAC.sol";

//contract expenseBook is  AccessControl, GSNRecipient {

contract expenseBook   {   
    event OrderStatusChange(uint256 ad, string status, string action,uint256 _datetime);
    event NewOrderRequest(uint256 ad, address seller, uint256 itemID,uint256 p,uint256 f,string c,uint8 pt,uint256 d);
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
    PaymentBook bookkeepingtoken;
    StateMachine statemachine;
    PermissionControl access;
    uint256 feesprecentage_decimal;
    address cashout;
    Counters.Counter private _orderID;
    
    mapping(uint256 => Order) private orders;
    mapping(string => uint8 ) public currencydecimal;
    mapping(uint256 => bool ) public token; // check if there is open order in expensebook
    
    
    function setOrdBook(address _orderbook) public {
        require( (access.hasRole(access.ADMIN_ROLE(),msg.sender)) , "E0");
        orderbook=Orderbook(_orderbook);
    }
    
      
    function setCompliance(address _compliance) public {
        require( (access.hasRole(access.ADMIN_ROLE(),msg.sender)) , "E0");
        compliance=Compliance(_compliance);
    }
    
    function setbookkeep(address _bookkeep) public {
        require( (access.hasRole(access.ADMIN_ROLE(),msg.sender)) , "E0");
        bookkeepingtoken=PaymentBook(_bookkeep);
    }
    
    function setStateMachine(address _machine) public  {
        require( (access.hasRole(access.ADMIN_ROLE(),msg.sender)) , "E0");
        statemachine=StateMachine(_machine);
    }
    
    function getAllContract() public view
    returns(address,address,address,address)
    {
        return(address(orderbook),address(compliance),address(bookkeepingtoken),address(statemachine));
    }
    
    constructor (address _orderbook, address _compliance, address _diamondtoken, address _statemachine,address _bookeep,address _access ) public virtual
    {
        orderbook = Orderbook(_orderbook);
        compliance = Compliance(_compliance);
        diamondtoken = ERC721(_diamondtoken);
        bookkeepingtoken = PaymentBook(_bookeep);
        statemachine = StateMachine(_statemachine);
        access = PermissionControl(_access);
        //_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        currencydecimal["HKD"]=2;
        currencydecimal["USD"]=2;
        feesprecentage_decimal = 10;
        diamondtoken.setApprovalForAll(_orderbook,true);
        _orderID.increment();
        
        
    }
    
    
    function setfeesprecentage_decimal(uint256 d) public {
        require( (access.hasRole(access.ADMIN_ROLE(),msg.sender)) , "E0");
        feesprecentage_decimal=d;
    }
    
    function getfeesprecentage_decimal() public view
    returns(uint256)
    {
        return feesprecentage_decimal;
    }
    
    function getOrdercount() public view 
    returns(uint256)
    {
        return(_orderID.current()-1);
    }
    
    
    function getOrder(uint256 _order) public view
        returns(address, uint256, uint256, uint256 ,uint256, string memory , uint8, uint256, string memory, string memory, string memory)
        
    {
        Order memory order = orders[_order];
        require( access.hasRole(access.ORDER_VIEWER(),msg.sender), "E0");
        return (order.seller, order.tradeID, order.diamondTokenID, order.unit_price, order.feesprecentage, order.currency, order.paymenttype , order.settlementdate,order.settlementReferenceURL,order.paymentReferenceURL,order.state);
    }
    
    function getOrderAmount(uint256 _order) public view
        returns (uint256)
        
    {
        Order memory order = orders[_order];
        require(access.hasRole(access.ORDER_VIEWER(),msg.sender) || access.hasRole(access.ORDER(),msg.sender) , "E0");
        return order.unit_price;
    }

    function createOrderRequest(uint256 _itemID, uint256 _price, uint256 _feesprecentage, string memory _currency,uint8 _paymenttype, uint256 _createdatetime) public {
        require(orderbook.isopen(_itemID)==false, "E1");
        require(token[_itemID]==false, "E2");
        require(compliance.isPass(msg.sender),"E3");
        require(access.hasRole(access.SUPPLIER(),msg.sender) || access.hasRole(access.SALE(),msg.sender),"E0");
        require(diamondtoken.ownerOf(_itemID)==msg.sender, "E4" );
        require( _price >= 0 , "E5");
        orders[_orderID.current()] = Order({
            seller: msg.sender,
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
        emit NewOrderRequest(_orderID.current()-1,msg.sender,_itemID,_price,_feesprecentage,_currency,_paymenttype,_createdatetime);
        
    } 
    
    function rejectRequest(uint256 _orderid,string memory rejectreason,uint256 _datetime) public {
        require( access.hasRole(access.ADMIN_ROLE(),msg.sender) || access.hasRole(access.SALE(),msg.sender), "E6");
        bytes32 functionhash = keccak256("rejectRequest");
        (bool exist, string memory nextstate) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E7");
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        orders[_orderid].meta[0]=rejectreason;
        
        emit OrderStatusChange(_orderid, nextstate,"rejectRequest",_datetime);
        
    }
    
    function cancelRequest(uint256 _orderid,uint256 _datetime) public {
        
        require(access.hasRole(access.SALE(),msg.sender) ||  access.hasRole(access.ADMIN_ROLE(),msg.sender) || (msg.sender == orders[_orderid].seller) , "E8");
        bytes32 functionhash = keccak256("cancelRequest");
        (bool exist,string memory nextstate) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E9");
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        token[orders[_orderid].diamondTokenID]=false;
        emit OrderStatusChange(_orderid, nextstate,"cancelRequest",_datetime);
        
    }
    
    function acceptRequest(uint256 _orderid, uint256 _price,bool _createtrade,uint256 _datetime) public {
        require( access.hasRole(access.SALE(),msg.sender) ||  access.hasRole(access.ADMIN_ROLE(),msg.sender) , "E10");
        require(_price>=orders[_orderid].unit_price,"E30");
        bytes32 functionhash = keccak256("acceptRequest");
        (bool exist, string memory nextstate ) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E11");
        Order memory o = orders[_orderid];
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        emit OrderStatusChange(_orderid, nextstate,"acceptRequest",_datetime);
   
        if(_createtrade){
            uint256 tradeid = orderbook.openTrade(o.diamondTokenID,o.seller,_price,_orderid,_datetime);
            orders[_orderid].tradeID=tradeid;
        }
               
    }  

    function cancelOrder(uint256 _orderid, uint256 _datetime) public {
        require( access.hasRole(access.SALE(),msg.sender) ||  access.hasRole(access.ADMIN_ROLE(),msg.sender) , "E12");
        bytes32 functionhash = keccak256("cancelOrder");
        (bool exist, string memory nextstate ) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E13");
        uint256 itemid = orders[_orderid].diamondTokenID;
        if(orderbook.isopen(orders[_orderid].diamondTokenID)){ //check if there exists open trade in orderbook
            //got open trade in orderbook
            orderbook.cancelTrade(orders[_orderid].tradeID,_datetime,true);
        }else {
            //cancel trade should call before, expenseBook is the item owner ,return back the item to seller
            diamondtoken.transferFrom(address(this),orders[_orderid].seller,itemid);
        }
        token[itemid]=false;
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        emit OrderStatusChange(_orderid, nextstate,"cancelOrder",_datetime);
         
    }
    
     function addTrade(uint256 _orderid, uint256 _price, uint256 _datetime) public {
        require( access.hasRole(access.SALE(),msg.sender) ||  access.hasRole(access.ADMIN_ROLE(),msg.sender), "E14");
        require(_price>=orders[_orderid].unit_price,"E30");
        bytes32 functionhash = keccak256("addTrade");
        (bool exist, string memory nextstate ) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E15");
        require(orderbook.isopen(orders[_orderid].diamondTokenID)==false,"E16");
        uint256 tradeid = orderbook.openTrade(orders[_orderid].diamondTokenID,orders[_orderid].seller,_price,_orderid,_datetime);
        orders[_orderid].tradeID= tradeid;
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        emit OrderStatusChange(_orderid, nextstate,"addTrade",_datetime);
               
    }
    
    function cancelTrade(uint256 _orderid, uint256 _datetime) public {
        require(access.hasRole(access.SALE(),msg.sender) ||  access.hasRole(access.ADMIN_ROLE(),msg.sender), "E17");
        bytes32 functionhash = keccak256("cancelTrade");
        (bool exist, string memory nextstate ) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E18");
        orderbook.cancelTrade(orders[_orderid].tradeID,_datetime,false);
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        emit OrderStatusChange(_orderid, nextstate,"cancelTrade",_datetime);
               
    }
    
    function fullFillTrade(uint256 _orderid, uint256 _datetime) public {
        
        require( access.hasRole(access.ORDER(),msg.sender) , "E19");
        bytes32 functionhash = keccak256("fullFillTrade");
        (bool exist, string memory nextstate ) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E20");
        
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        emit OrderStatusChange(_orderid, nextstate,"fullFillTrade",_datetime);
        token[orders[_orderid].diamondTokenID]=false;
               
    }
    
    
    function updateINV_settledate(uint256 _orderid, uint256 _settledate , uint256 _datetime) public {
        require( access.hasRole(access.SETTLEMENT(),msg.sender) ||  access.hasRole(access.ADMIN_ROLE(),msg.sender), "E21");
        require(bookkeepingtoken.balanceOf(address(this))>=orders[_orderid].unit_price,"E31");
        bytes32 functionhash = keccak256("updateINV_settledate");
        (bool exist, string memory nextstate ) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E22");
        orders[_orderid].settlementdate = _settledate;
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        emit OrderStatusChange(_orderid, nextstate,"updateINV_settledate",_datetime);
        
    }
    
    
    function updateINV_settleURL(uint256 _orderid, string memory _settleurl , uint256 _datetime) public {
        require( access.hasRole(access.SETTLEMENT(),msg.sender) ||  access.hasRole(access.ADMIN_ROLE(),msg.sender) ||  (msg.sender == orders[_orderid].seller) , "E23");
        require(bookkeepingtoken.balanceOf(address(this))>=orders[_orderid].unit_price,"E31");
        bytes32 functionhash = keccak256("updateINV_settleURL");
        (bool exist, string memory nextstate ) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E24");
        orders[_orderid].settlementReferenceURL = _settleurl;
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        emit OrderStatusChange(_orderid, nextstate,"updateINV_settleURL",_datetime);
        
    }
    
    function updateINV_paymentURL(uint256 _orderid, string memory _paymenturl , uint256 _datetime) public {
        require( access.hasRole(access.SETTLEMENT(),msg.sender) ||  access.hasRole(access.ADMIN_ROLE(),msg.sender), "E25");
        require(bookkeepingtoken.balanceOf(address(this))>=orders[_orderid].unit_price,"E31");
        bytes32 functionhash = keccak256("updateINV_paymentURL");
        (bool exist, string memory nextstate ) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E26");
        orders[_orderid].paymentReferenceURL = _paymenturl;
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        emit OrderStatusChange(_orderid, nextstate,"updateINV_settleURL",_datetime);
        
    }
    
    function updateINV_updateMeta(uint256 _orderid, uint64 key , string memory value) public {
        require( access.hasRole(access.SETTLEMENT(),msg.sender) ||  access.hasRole(access.ADMIN_ROLE(),msg.sender) || access.hasRole(access.ACCOUNT(),msg.sender), "E27");
        require(bookkeepingtoken.balanceOf(address(this))>=orders[_orderid].unit_price,"E31");
        orders[_orderid].meta[key]=value;
        
    }
    
    function updateINV_confirm(uint256 _orderid, uint256 _datetime) public {
        require( access.hasRole(access.SETTLEMENT(),msg.sender) ||  access.hasRole(access.ADMIN_ROLE(),msg.sender) || access.hasRole(access.ACCOUNT(),msg.sender) ||  (msg.sender == orders[_orderid].seller) , "E28");
        require(bookkeepingtoken.balanceOf(address(this))>=orders[_orderid].unit_price,"E31");
        bytes32 functionhash = keccak256("updateINV_confirm");
        (bool exist, string memory nextstate ) = statemachine.transitionExists(orders[_orderid].state, functionhash);
        require(exist , "E29");
        orders[_orderid].state=nextstate;
        orders[_orderid].stateChange[nextstate]=_datetime;
        emit OrderStatusChange(_orderid, nextstate,"updateINV_confirm",_datetime);
        
    }
    
    function withdrawalDiamond(uint256 _itemid) public {
        require( access.hasRole(access.SETTLEMENT(),msg.sender) ||  access.hasRole(access.ADMIN_ROLE(),msg.sender) || access.hasRole(access.ACCOUNT(),msg.sender) , "E29");
        diamondtoken.transferFrom(address(this), msg.sender, _itemid);
    }
    
    function withdrawalbookeep(uint256 _amount) public  {
        require( access.hasRole(access.SETTLEMENT(),msg.sender) ||  access.hasRole(access.ADMIN_ROLE(),msg.sender) || access.hasRole(access.ACCOUNT(),msg.sender) , "E29");
        bookkeepingtoken.transferFrom(address(this), msg.sender, _amount);
    }
    
   
  
}
