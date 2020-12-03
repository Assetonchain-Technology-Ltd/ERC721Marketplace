pragma solidity ^0.6.0;

import "./baseContract.sol";
contract BuySideContract is BaseContract{
    
    
    Counters.Counter private _tradecount;
    struct trade{
        uint256 tradeID;
        uint256 datetime;
    } 
     
     mapping(uint256 => trade) trades;
                
     constructor (uint256  _itemid,address _base, uint256  _price, uint256 _feesprecentage, string memory _currency,
                    uint256 _createdatetime,address _access, address _sellside, address _buyside) 
                public BaseContract( _itemid,  _base,  _price, _currency,_createdatetime, _access) 
    {
        
        require(_isAdmin(msg.sender) || _isSales(msg.sender) || _isExpense(msg.sender),"BSC00");
        debtor = _buyside;
        creditor = _sellside;
        feesprecentage = _feesprecentage;
       
        state = "OI";
        stateChange["OI"]=_createdatetime;
        _tradecount.increment();
        
    } 
    

    function getTradeID() override public view
    returns(uint256 _d)
    {
        return trades[_tradecount.current()-1].tradeID;
    }
    
    
    function getOrderDetail() public override view
    returns (uint256, uint256, address,uint256 ,uint256, string memory ,uint256,address,address,string memory,uint256)
    {
        require( _isOrderViewer(msg.sender), "BSC01");
        
        return (trades[_tradecount.current()].tradeID,ERC721ID,ERC721baseaddress,unit_price,feesprecentage,currency,mindeposit,creditor,debtor,state,_settlementcount.current());
    }    
    
    
    function setTradeID(uint256 _id,uint256 _datetime) public 
    {
         require( _isAdmin(msg.sender) || _isExpense(msg.sender), "BSC02");
         _tradecount.increment();
         trades[_tradecount.current()-1].tradeID=_id;
         trades[_tradecount.current()-1].datetime=_datetime;
         
         

    }
    
  
  
}