pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/access/RBAC.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Holder.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/utils/Counters.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

abstract contract  BaseContract {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address;

    Counters.Counter internal _settlementcount;
    
    address debtor;
    address creditor;
    address seller;
    string state;
    uint256 feesprecentage;
    uint256 feesamount;
    string currency;
    uint8 paymenttype;
  
    uint256 mindeposit;
    
    uint256 ERC721ID;
    uint256 unit_price;
    address ERC721baseaddress; 
     
    struct settlementplan{
        uint256 settlementdate;
        uint256 settlementamount;
        uint256 createdatetime;
        uint8 paymenttype;
        bool active;
        bool settled;
        uint256 paymentdate;
        string bankrecRef;
     }
     mapping(string => uint256) stateChange;
     mapping(uint256 => settlementplan) settlement;
     mapping(uint64 => string) meta;
     PermissionControl access;
     
     constructor (uint256 _itemid, address _base,uint256  _price, string memory _currency,
                    uint256 _createdatetime,address _access, address _sellside) public {
        access = PermissionControl(_access);
        require(_isAdmin(msg.sender) || _isSales(msg.sender) || _isExpense(msg.sender),"E0");
        (ERC721ID,ERC721baseaddress)=(_itemid,_base);
        seller = msg.sender;
        creditor = _sellside;
        feesprecentage = 0;
        currency = _currency;
        paymenttype = 0;
        state = "OPEN";
        stateChange["OPEN"]=_createdatetime;
            
        mindeposit=0;
      
        unit_price=_price;
        
    } 
    

    function getState() public view
    returns(string memory s){
        return state;
    }
    
    function getFeePercent() public view 
    returns(uint256 _d)
    {
        return feesprecentage;    
    }
    
    function getFeeAmount() public view 
    returns(uint256 _d)
    {
        return feesamount;    
    }
    
    function getMindeposit() public view
    returns(uint256 _d){
        return mindeposit;
    }
    
    function getStateChange(string memory _state) public view
    returns(uint256 _d)
    {
        return stateChange[_state];
    }
    
    function getTradeID() public virtual view returns(uint256 _d);
    
    function getItem() public view
    returns(uint256 _d,address)
    {
        require( _isOrderViewer(msg.sender), "E0");
        return (ERC721ID,ERC721baseaddress);
    }
    
    function getOrderPrice() public view 
    returns(uint256 p)
    {
        require( _isOrderViewer(msg.sender), "E0");
       
        return unit_price;
    }
    
    function getCreditor() public view 
    returns(address a)
    {
        require( _isOrderViewer(msg.sender), "E0");
        return creditor;
    }
    
    function getDebtor() public view
    returns(address a)
    {
        require( _isOrderViewer(msg.sender), "E0");
        return debtor;
    }
    
    function getMeta(uint64 _key) public view
    returns(string memory s)
    {
        require( _isOrderViewer(msg.sender), "E0");
        return meta[_key];
    }
    
    function getOrderDetail() public virtual view returns  (uint256, uint256, address,uint256 ,uint256, string memory ,uint256,address,address,string memory,uint256);

    
    function getActiveSettlementPlan() public view
    returns(uint256 _i,uint256 _d,uint256 _a)
    {
        require( _isAdmin(msg.sender) || _isOrder(msg.sender), "E0");
        uint256 minindex=0;
        uint256 min;
        bool firstrun=true;
        for(uint256 i=0;i<_settlementcount.current();i++){
            if(settlement[i].active==true && settlement[i].settled==false && firstrun==true){
                minindex=i;
                min = settlement[minindex].settlementdate;
                firstrun=false;
            }else if( settlement[i].active==true && settlement[i].settled==false) {
                minindex = (settlement[i].settlementdate<min)?i:minindex;
                min=settlement[minindex].settlementdate;
            }
        }
       return(minindex,min,settlement[minindex].settlementamount);
    }
    
    function isSettled() public view
    returns(bool _t)
    {
        require( _isAdmin(msg.sender) || _isOrder(msg.sender), "E0");
        bool settled = true;
        for(uint256 i=0;i<_settlementcount.current();i++){
            settled = (settlement[i].active==true && settlement[i].settled!=false);
        }
       return settled;
    }
  
    function setState(string memory _s,uint256 _d) public 
    {
         require( _isAdmin(msg.sender) || _isOrder(msg.sender), "E0");
         state=_s;
         stateChange[_s]=_d;
    }
    
    function setFeePercent(uint256 _d) public 
    {
         require( _isAdmin(msg.sender) || _isOrder(msg.sender), "E0");
         feesprecentage = _d;
    }
    
    function setFeeAmount(uint256 _d) public 
    {
         require( _isAdmin(msg.sender) || _isOrder(msg.sender), "E0");
         feesamount = _d;
    }
    
    function setDebtor(address _d) public 
    {
         require( _isAdmin(msg.sender) || _isOrder(msg.sender), "E0");
         debtor = _d;
    }
    
    

    
    function setMindeposit(uint256 _a) public
    {
         require( _isAdmin(msg.sender) || _isOrder(msg.sender), "E0");
         mindeposit=_a;

    }
    
    function setMeta(uint64 _key,string memory _d) public
    {
        require( _isAdmin(msg.sender) || _isOrder(msg.sender), "E0");
        meta[_key]=_d;

    }
    
    function withdrawalToken(uint256 _id,address _dest) public 
    {
        require( _isAdmin(msg.sender) || _isExpense(msg.sender) || _isOrder(msg.sender), "E0");
        ERC721 token = ERC721(ERC721baseaddress);
        _id = (_id==0)?ERC721ID:_id;
        require(token.ownerOf(_id)==address(this),"XE");
        token.safeTransferFrom(address(this),_dest,_id);
    }
    
    function addSettlementPlan(uint256 _amount,uint256 _settlementdate,uint256 _datetime,bool _active)public
    {
        require( _isAdmin(msg.sender) || _isOrder(msg.sender), "E0");
        _settlementcount.increment();
        uint256 id = _settlementcount.current()-1;
        settlement[id].settlementamount=_amount;
        settlement[id].settlementdate=_settlementdate;
        settlement[id].createdatetime=_datetime;
      
        settlement[id].active=_active;
        settlement[id].settled=false;
        
    }
    
    function completePayment(uint256 _id,string memory _tx,uint256 _date,uint8 _paymenttype) public 
    {
        require( _isAdmin(msg.sender) || _isOrder(msg.sender), "E0");
        settlement[_id].settled=true;
        settlement[_id].active=false;
        settlement[_id].bankrecRef=_tx;
        settlement[_id].paymenttype=_paymenttype;
        settlement[_id].paymentdate = _date;
        
    }
    
    function _isAdmin(address _a) internal view
    returns(bool t)
    {
        return access.hasRole(access.ADMIN_ROLE(),_a);
    }
    
    function _isSales(address _a) internal view
    returns(bool t)
    {
        return access.hasRole(access.SALE(),_a);
    }
    
    function _isOrder(address _a) internal view
    returns(bool t)
    {
        return access.hasRole(access.ORDER(),_a);
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