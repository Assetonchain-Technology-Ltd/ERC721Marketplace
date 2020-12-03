pragma solidity ^0.6.0;

import "../utils/access.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/presets/ERC20PresetMinterPauser.sol";
import "openzeppelin-solidity/contracts/utils/Counters.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../utils/access.sol";

abstract contract  BaseContract is Access {
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

     constructor (uint256 _itemid, address _base,uint256  _price, string memory _currency,
                    uint256 _createdatetime,address _access) public {
        access = PermissionControl(_access);
        require(_isAdmin(msg.sender) || _isSales(msg.sender) || _isExpense(msg.sender) || _isSupplier(msg.sender) || _isOrder(msg.sender),"G1");
        (ERC721ID,ERC721baseaddress)=(_itemid,_base);
        feesprecentage = 0;
        currency = _currency;
        state = "OPEN";
        stateChange["OPEN"]=_createdatetime;
            
        mindeposit=0;
      
        unit_price=_price;
        _settlementcount.increment();
        
    } 
    

    function getState() public view
    returns(string memory s){
        require( _isOrderViewer(msg.sender), "G23");
        return state;
    }
    
    function getSettlementCount() public view
    returns(uint256 i){
        require( _isOrderViewer(msg.sender), "G24");
        return _settlementcount.current()-1;
    }
    
    function getFeePercent() public view 
    returns(uint256 _d)
    {
        require( _isOrderViewer(msg.sender), "G25");
        return feesprecentage;    
    }
    
    function getFeeAmount() public view 
    returns(uint256 _d)
    {
        require( _isOrderViewer(msg.sender), "G26");
        return feesamount;    
    }
    
    function getMindeposit() public view
    returns(uint256 _d){
        require( _isOrderViewer(msg.sender), "G27");
        return mindeposit;
    }
    
    function getStateChange(string memory _state) public view
    returns(uint256 _d)
    {
        require( _isOrderViewer(msg.sender), "G28");
        return stateChange[_state];
    }
    
    function getTradeID() public virtual view returns(uint256 _d);
    
    function getItem() public view
    returns(uint256 _d,address)
    {
        require( _isOrderViewer(msg.sender), "G2");
        return (ERC721ID,ERC721baseaddress);
    }
    
    function getOrderPrice() public view 
    returns(uint256 p)
    {
        require( _isOrderViewer(msg.sender), "G3");
       
        return unit_price;
    }
    
    function getCreditor() public view 
    returns(address a)
    {
        require( _isOrderViewer(msg.sender), "G4");
        return creditor;
    }
    
    function getDebtor() public view
    returns(address a)
    {
        require( _isOrderViewer(msg.sender), "G5");
        return debtor;
    }
    
    function getSeller() public view
    returns(address a)
    {
        require( _isOrderViewer(msg.sender), "G6");
        return seller;
    }
    
    function getMeta(uint64 _key) public view
    returns(string memory s)
    {
        require( _isOrderViewer(msg.sender), "G7");
        return meta[_key];
    }
    
    function getOrderDetail() public virtual view returns  (uint256, uint256, address,uint256 ,uint256, string memory ,uint256,address,address,string memory,uint256);

    
    function getActiveSettlementPlan() public view
    returns(uint256 _i,uint256 _d,uint256 _a)
    {
        require( _isOrder(msg.sender) || _isOrderViewer(msg.sender), "G8");
        uint256 minindex=0;
        uint256 min;
        bool firstrun=true;
        for(uint256 i=1;i<_settlementcount.current();i++){
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
    
    function getSettlementPlan(uint256 _i) public view
    returns(uint256 _sd,uint256 _sa,uint256 _cd,uint8 _p,bool _a, bool _s,uint256 _pd,string memory _tx)
    {   
        require( _isOrderViewer(msg.sender), "G29");
        settlementplan memory m = settlement[_i];
        
        return(m.settlementdate,m.settlementamount,m.createdatetime,m.paymenttype,m.active,m.settled,m.paymentdate,m.bankrecRef);
    }
    
    function getSettledAmount() public view
    returns(uint256 _a)
    {
        require( _isOrderViewer(msg.sender), "G29");
        uint256 settledamount=0;
        for(uint i=1;i<_settlementcount.current();i++){
            settledamount = settlement[i].settled?(settledamount+settlement[i].settlementamount):settledamount;
        }
        return settledamount;
    }
    
    function getPlanedSettlementAmount() public view
    returns(uint256 _a)
    {
        require( _isOrderViewer(msg.sender), "G29");
        uint256 p=0;
        for(uint i=1;i<_settlementcount.current();i++){
            p = (settlement[i].settled || settlement[i].active)?(p+settlement[i].settlementamount):p;
        }
        return p;
    }
    
    function isSettled() public view
    returns(bool t)
    {
        require( _isOrderViewer(msg.sender) || _isExpense(msg.sender) || _isOrder(msg.sender), "G25");
                
        return (getSettledAmount() == unit_price.add(feesamount));
                
    }
    
    function setState(string memory _s,uint256 _d) public 
    {
         require( _allowedit(msg.sender), "G11");
         state=_s;
         stateChange[_s]=_d;
    }
    
    function setFeePercent(uint256 _d) public 
    {
         require( _allowedit(msg.sender) || _isSales(msg.sender), "G12");
         feesprecentage = _d;
    }
    
    function setFeeAmount(uint256 _d) public 
    {
         require( _allowedit(msg.sender) || _isSales(msg.sender), "G13");
         feesamount = _d;
    }
    
    function setDebtor(address _d) public 
    {
         require( _allowedit(msg.sender), "G14");
         debtor = _d;
    }
    
    function setSeller(address _d) public 
    {
         require( _allowedit(msg.sender), "G15");
         seller = _d;
    }
    
    
    function setMindeposit(uint256 _a) public
    {
         require( _allowedit(msg.sender) || _isSales(msg.sender), "G16");
         mindeposit=_a;

    }
    
    function setMeta(uint64 _key,string memory _d) public
    {
        require( _allowedit(msg.sender)|| _isSales(msg.sender) || _isAccount(msg.sender) || _isSettlement(msg.sender), "G17");
        meta[_key]=_d;

    }
    
    function withdrawalERC721Token(uint256 _id,address _dest) public 
    {
        require( _allowedit(msg.sender), "G18");
        ERC721 token = ERC721(ERC721baseaddress);
        _id = (_id==0)?ERC721ID:_id;
        require(token.ownerOf(_id)==address(this),"G25");
        token.transferFrom(address(this),_dest,_id);
    }
    
    function withdrawalERC20Token(address base,uint256 _amount,address _dest) public 
    {
        require( _allowedit(msg.sender), "G19");
        ERC20 token = ERC20(base);
        token.transfer(_dest,_amount);
    }
    
    function addSettlementPlan(uint256 _amount,uint256 _settlementdate,uint256 _datetime,bool _active)public
    {
        require( _allowedit(msg.sender) || _isSettlement(msg.sender), "G20");
        _settlementcount.increment();
        uint256 id = _settlementcount.current()-1;
        settlement[id].settlementamount=_amount;
        settlement[id].settlementdate=_settlementdate;
        settlement[id].createdatetime=_datetime;
      
        settlement[id].active=_active;
        settlement[id].settled=false;
        
    }
    
    function disableSettlementPlan(uint256 _id,uint256 _datetime) public 
    {
        require( _allowedit(msg.sender) || _isSettlement(msg.sender), "G21");
        require(_id>=0 && _id <_settlementcount.current(),"G22");
        require(settlement[_id].settled==false && settlement[_id].active==true,"G23");
        settlement[_id].active=false;
        settlement[_id].paymentdate= _datetime;
    }
    
    
    function completePayment(uint256 _id,string memory _tx,uint256 _date,uint8 _paymenttype) public 
    {
        require( _allowedit(msg.sender) || _isSettlement(msg.sender) , "G24");
        settlement[_id].settled=true;
        settlement[_id].active=false;
        settlement[_id].bankrecRef=_tx;
        settlement[_id].paymenttype=_paymenttype;
        settlement[_id].paymentdate = _date;
        
    }
    
    
    function _isOrderViewer(address _a) internal view
    returns(bool t)
    {
        return (_a==creditor || _a==debtor || _isAdmin(_a) || 
                _isSales(_a) || _isSettlement(_a) || _isAccount(_a) || 
                _isExpense(_a) || _isOrder(_a) || address(this)==_a);
    }
    
    function _allowedit(address _a) internal view
    returns(bool t)
    {
        return (_isAdmin(_a) || _isOrder(_a) || _isExpense(_a));
    }
 
    
}