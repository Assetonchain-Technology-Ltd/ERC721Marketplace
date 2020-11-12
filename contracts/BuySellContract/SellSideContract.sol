pragma solidity ^0.6.0;

import "./baseContract.sol";


contract SellSideContract is BaseContract {

     address sellsidecontract;
     uint256 tradeID;
     
     constructor (uint256 _itemid, address _base,uint256  _price, string memory _currency,
                    uint256 _createdatetime,address _access, address _seller,uint256 _tradeID,address _sellsidecontract) 
                public BaseContract( _itemid,  _base,  _price, _currency,_createdatetime, _access) 
    {
        require(_isAdmin(msg.sender) || _isSales(msg.sender) || _isExpense(msg.sender),"E0");
        creditor = msg.sender;
        seller = _seller;
        sellsidecontract = _sellsidecontract;
        tradeID = _tradeID;
        
        
    } 
    
    
    function getOrderDetail() public override view
    returns (uint256, uint256, address,uint256 ,uint256, string memory ,uint256,address,address,string memory,uint256)
    {
        require( _isOrderViewer(msg.sender), "E0");
        
        return (tradeID,ERC721ID,ERC721baseaddress,unit_price,feesprecentage,currency,mindeposit,creditor,debtor,state,_settlementcount.current());
    }         
    
    function getSellSideContract() public view
    returns(address _a)
    {
        require( _isOrderViewer(msg.sender), "E0");
        
        return (sellsidecontract);
    }

    function getTradeID() override public view
    returns(uint256 _d)
    {
        return tradeID;
    }
    
    function setTrade(uint256 _id) public 
    {
         require( _isAdmin(msg.sender) || _isOrder(msg.sender), "E0");
         tradeID = _id;

    }
  
}