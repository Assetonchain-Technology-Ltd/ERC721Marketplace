pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/access/RBAC.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Holder.sol";
import "openzeppelin-solidity/contracts/utils/Counters.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract SellSideContract {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address;
    
    Counters.Counter private _itemcount;
    Counters.Counter private _settlementcount;
    Counters.Counter private _tradecount;
    
    address debtor;
    address creditor;
    string state;
    uint256 feesprecentage;
    string currency;
    uint8 paymenttype;
    
    
    struct item{
        uint256 ERC721ID;
        uint256 unit_price;
        uint256 qty;
        string currency;
     }
     
     
    struct trade{
        uint256 tradeID;
        uint256 datetime;
    } 
    struct settlementplan{
        uint256 settlementdate;
        uint256 settlementamount;
        string  settlementReferenceURL;
        string  paymentReferenceURL;
     }
     
     mapping(uint256 => item) items; 
     mapping(uint256 => settlementplan) settlement;
     mapping(uint256 => trade) trades;
     mapping(string => uint256) stateChange;
     mapping(uint64 => string) meta;
     PermissionControl access;
     
     constructor (uint256  _item,uint256  _price, uint256 _qty, uint256 _feesprecentage, string memory _currency,
                    uint8 _paymenttype, uint256 _createdatetime,address _access, address _sellside, address _buyside) public {
        access = PermissionControl(_access);
        require(access.hasRole(access.ADMIN_ROLE(),msg.sender) || access.hasRole(access.SALE(),msg.sender),"E0");
        
        creditor = _sellside;
        debtor = _buyside;
        feesprecentage = _feesprecentage;
        currency = _currency;
        paymenttype = _paymenttype;
        state = "OI";
        stateChange["OI"]=_createdatetime;
        
        items[_itemcount.current()]=item({
            ERC721ID :_item,
            unit_price:_price,
            qty:_qty,
            currency:_currency
        });
        _itemcount.increment();

        trades[_tradecount.current()]= trade({
            tradeID:0,datetime:0
        });
        _tradecount.increment();
        
        settlement[_settlementcount.current()]= settlementplan({
            settlementdate:0,
            settlementamount:0,
            settlementReferenceURL:"",
            paymentReferenceURL:""
        });
        _settlementcount.increment();
        
        
    } 
    

    function getState() public view
    returns(string memory s){
        return state;
    }
    
    function getStateChange(string memory _state) public view
    returns(uint256 _d)
    {
        return stateChange[_state];
    }
    
    function getCurrentTradeID() public view
    returns(uint256 _d)
    {
        return trades[_tradecount.current()-1].tradeID;
    }
    
    function getItem() public view
    returns(uint256 _d)
    {
        require( _isOrderViewer(msg.sender), "E0");
        return items[_itemcount.current()-1].ERC721ID;
    }
    
    function getOrderPrice() public view 
    returns(uint256 p)
    {
        require( _isOrderViewer(msg.sender), "E0");
        return items[_itemcount.current()-1].unit_price;
    }
    
    function getCreditor() public view 
    returns(address a)
    {
        require( _isOrderViewer(msg.sender), "E0");
        return creditor;
    }
    
    function getMeta(uint64 _key) public view
    returns(string memory s)
    {
        require( _isOrderViewer(msg.sender), "E0");
        return meta[_key];
    }
    
    
    function getOrderDetail() public view
        returns(uint256, uint256, uint256 ,uint256, string memory , uint8, uint256, string memory, string memory, string memory)
        
    {
        require( _isOrderViewer(msg.sender), "E0");
        trade memory t = trades[_tradecount.current()-1];
        item memory i = items[_itemcount.current()-1];
        settlementplan memory s = settlement[_settlementcount.current()-1];
        
        return (t.tradeID,i.ERC721ID, i.unit_price,feesprecentage,currency,paymenttype,s.settlementdate,s.settlementReferenceURL,s.paymentReferenceURL,state);
    }
    
  
    function setState(string memory _s,uint256 _d) public 
    {
         require( _isAdmin(msg.sender) || _isExpense(msg.sender), "E0");
         state=_s;
         stateChange[_s]=_d;
    }
    
    function setTradeID(uint256 _id,uint256 _datetime) public 
    {
         require( _isAdmin(msg.sender) || _isExpense(msg.sender), "E0");
        
         trades[_tradecount.current()-1].tradeID=_id;
         trades[_tradecount.current()-1].datetime=_datetime;
         _tradecount.increment();
         

    }
    
    function setSettlementAmount(uint256 _a,uint256 _d)public
    {
        require( _isAdmin(msg.sender) || _isExpense(msg.sender), "E0");
        settlement[_settlementcount.current()-1].settlementamount=_a;
        settlement[_settlementcount.current()-1].settlementdate=_d;
    }
    
    function setSettlementURL(string memory _d)public
    {
        require( _isAdmin(msg.sender) || _isExpense(msg.sender), "E0");
        settlement[_settlementcount.current()-1].settlementReferenceURL=_d;
    }
    
    function setpaymentURL(string memory _d) public
    {
        require( _isAdmin(msg.sender) || _isExpense(msg.sender), "E0");
        settlement[_settlementcount.current()-1].paymentReferenceURL=_d;
    }
    
    function setMeta(uint64 _key,string memory _d) public
    {
        require( _isAdmin(msg.sender) || _isExpense(msg.sender), "E0");
        meta[_key]=_d;

    }
    
    function _isAdmin(address _a) internal view
    returns(bool t)
    {
        return access.hasRole(access.ADMIN_ROLE(),_a);
    }
    
    function _isExpense(address _a) internal view
    returns(bool t)
    {
        return access.hasRole(access.EXPENSE(),_a);
    }
      
    function _isOrderViewer(address _a) internal view
    returns(bool t)
    {
        return access.hasRole(access.ORDER_VIEWER(),_a);
    }
  
}