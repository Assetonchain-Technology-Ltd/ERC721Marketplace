pragma solidity ^0.6.0;

import "./baseContract.sol";

contract SellSideContract is BaseContract {

     uint256 tradeID;
     uint256 earlysettle=0;
     
     constructor (uint256 _itemid, address _base,uint256  _price, string memory _currency,
                    uint256 _createdatetime,address _access, address _seller,uint256 _tradeID,address _sellsidecontract) 
                public BaseContract( _itemid,  _base,  _price, _currency,_createdatetime, _access) 
    {
        require(_isAdmin(msg.sender) || _isSales(msg.sender) || _isOrder(msg.sender),"SSC00");
        seller = _seller;
        creditor = _sellsidecontract;
        tradeID = _tradeID;
        
        
    } 
    
    
    function getOrderDetail() public override view
    returns (uint256, uint256, address,uint256 ,uint256, string memory ,uint256,address,address,string memory,uint256)
    {
        require( _isOrderViewer(msg.sender), "SSC01");
        
        return (tradeID,ERC721ID,ERC721baseaddress,unit_price,feesprecentage,currency,mindeposit,creditor,debtor,state,_settlementcount.current());
    }         
    
    function getEarlySettle() public view
    returns(uint256 s)
    {
        return earlysettle;
    }

    function getTradeID() override public view
    returns(uint256 _d)
    {
        return tradeID;
    }
    
    function setTrade(uint256 _id) public 
    {
         require( _isAdmin(msg.sender) || _isOrder(msg.sender), "SSC03");
         tradeID = _id;

    }
    
    function setEarlySettle(uint256 _a) public
    {
         require( _isAdmin(msg.sender) || _isOrder(msg.sender), "SSC03");
         earlysettle += _a;
    }
    
     

  
  
}