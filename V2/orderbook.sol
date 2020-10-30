pragma solidity ^0.6.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721Holder.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

import "./compliance.sol";
import "./stateMachine.sol";

contract Orderbook is Ownable {
    event TradeStatusChange(uint256 ad, string status);
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    
    ERC20 currency;
    ERC721 diamondToken;
    StateMachine statemachine;
    Compliance compliance;
    address expensebook;
    address platformfees;
    Counters.Counter private _tradeID;
    uint256 feespercentage_decimal = 100;
    uint256 depositpercentage = 3;
    
    struct Trade{
        address seller;
        address owner;
        uint256 item;
        uint256 price;
        string status;
        uint256 orderid;
        address buyer;
        uint256 payment;
        uint256 mindeposit;
        mapping(string => uint256) stateChange;
    }
    
    mapping(uint256 => Trade) private trades;
    mapping(uint256 => bool) public isopen;
    
    constructor (address _currencyTokenAddress, address _itemTokenAddress,address _compliance , address _statemachine, address _platform) public virtual
    {
        currency = ERC20(_currencyTokenAddress);
        diamondToken = ERC721(_itemTokenAddress);
        compliance = Compliance(_compliance);
        statemachine = StateMachine(_statemachine);
        _tradeID.increment();
        platformfees=_platform;
        if(_platform==address(0)){
            platformfees=address(this);
        }

    }
    
    function setexpensebook(address _add) public onlyOwner
    {
        expensebook = _add;
        diamondToken.setApprovalForAll(_add,true);
    }
    
    function setcurrency(address _add) public onlyOwner
    {
        currency = ERC20(_add);
    }
    
    function setdiamondtoken(address _add) public onlyOwner
    {
        diamondToken = ERC721(_add);
    }
    
    function setcompliance(address _add) public onlyOwner
    {
        compliance = Compliance(_add);
    }
    
    function setstatemachine(address _add) public onlyOwner
    {
        statemachine = StateMachine(_add);  
    }
    
    function getAllContractInfo() public onlyOwner view
        returns(address, address , address , address , address )
    {
        return (address(currency),address(diamondToken),address(compliance),address(statemachine),expensebook);
    }
    
    function getTradeCount() public view 
        returns (uint256 c)
    {
        return _tradeID.current() - 1;
    }
    
    function getTrade(uint256 _trade) public virtual view
        returns(address, address, uint256, uint256, string memory,uint256, uint256)
    {
        require(compliance.isPass(_msgSender()), "O1");
        Trade memory trade = trades[_trade];
        return (trade.seller,trade.buyer, trade.item, trade.price, trade.status,trade.mindeposit,trade.payment);
    }
    
    function setfeespercentage_decimal(uint256 u) public onlyOwner{
            feespercentage_decimal=u;
    }
    
    function getfeespercentage_decimal() public view
    returns (uint256)
    {
        return feespercentage_decimal;
    }
        
 
    function setindividualDeposit(uint256 _tradeid,uint256 _deposit) public{
        require(_msgSender()==expensebook, "O12");
        require(_deposit > trades[_tradeid].mindeposit && _deposit < trades[_tradeid].price,"O13");
        trades[_tradeid].mindeposit = _deposit;
    }

    
    function getdepositpercentage() public view
    returns (uint256)
    {
        return depositpercentage;
    }
     
    function setdepositpercentage(uint256 u) public onlyOwner{
            depositpercentage = u;
    }

    
    
    function openTrade(uint256 _itemID, address _owner, uint256 _price,uint256 _orderid, uint256 _datetime) public virtual
        returns (uint256 tradeid)
    {
        require(_msgSender()==expensebook, "O2");
        require( _price > 0 , "O14" );
        address destination = diamondToken.ownerOf(_itemID);
        require(destination==expensebook || destination==_owner,"O18");
        diamondToken.transferFrom(destination, address(this), _itemID);
        uint256 newtrade = _tradeID.current();
        uint256 _mindeposit = _price.mul(depositpercentage).div(100);
        trades[newtrade] = Trade({
            seller: _msgSender(),
            owner : _owner,
            item: _itemID,
            price: _price,
            status: "OPEN",
            orderid : _orderid,
            buyer : address(0),
            payment : 0,
            mindeposit : _mindeposit
        });
        
        trades[newtrade].stateChange["OPEN"]=_datetime;
        _tradeID.increment();
        isopen[_itemID]=true;
        emit TradeStatusChange(_tradeID.current() - 1, "Open");
        return newtrade;
    }
    
    function executeTrade(uint256 _trade,uint256 _feespercentage, uint256 _payment, uint256 _datetime)
        public
        virtual
        returns (uint256)
    {
        Trade memory trade = trades[_trade];
        (bool exist,string memory nextstate) = statemachine.transitionExists(trade.status,bytes32(keccak256("executeTrade")));
        //profile checking
        require(exist , "O3");
        require(compliance.isPass(_msgSender()), "O4");
        require(trade.owner!=_msgSender(),"O17");
        
        //balance checking
        uint256 fees = (trade.price.mul( _feespercentage)).div(100*feespercentage_decimal);
        uint256 minrequir= fees.add(trade.mindeposit);
        uint256 total = fees.add(trade.price);
        if(trade.payment==0){
            // initial 
             require((currency.balanceOf(_msgSender())>=minrequir), "O6");
             require((_payment>=minrequir && _payment<=total), "O7");
             currency.transferFrom(_msgSender(),platformfees, fees);
             _payment = _payment.sub(fees);
        }else{
            // settle balance
             require(trade.buyer==_msgSender(), "O5" );
             uint256 balance = trade.price.sub(trade.payment);
             require((currency.balanceOf(_msgSender())>=balance), "O8");
             require((_payment==balance), "O9");
        }
        //Make payment 
        currency.transferFrom(_msgSender(), address(this), _payment);
        trades[_trade].buyer=_msgSender();
        trades[_trade].payment=trades[_trade].payment.add(_payment);
        if(trades[_trade].payment>=trade.price){
            diamondToken.transferFrom(address(this), _msgSender(), trade.item);
            currency.transfer(trade.seller, trade.price);
            trades[_trade].status = "EXEC";  
            trades[_trade].stateChange["EXEC"]=_datetime;
            bytes memory payload = abi.encodeWithSignature("fullFillTrade(uint256,uint256)",trades[_trade].orderid,now);
            expensebook.call(payload);
            isopen[trade.item]=false;
            emit TradeStatusChange(_trade, "EXEC");
           
        }else{
            trades[_trade].status = nextstate;
            trades[_trade].stateChange[nextstate]=_datetime;
            emit TradeStatusChange(_trade, nextstate);
       
        }
       
         return trades[_trade].price.sub(trades[_trade].payment);
    }

    function cancelTrade(uint256 _trade,uint256 _datetime,bool return2owner)
        public
        virtual
    {
        Trade memory trade = trades[_trade];
        require(_msgSender() == trade.seller,"O10");
        (bool exist,string memory nextstate) = statemachine.transitionExists(trade.status,bytes32(keccak256("cancelTrade")));
        require(exist , "O11");
        address destination = return2owner?trade.owner:trade.seller;
        diamondToken.transferFrom(address(this), destination, trade.item);
        trades[_trade].status = nextstate;
        trades[_trade].stateChange[nextstate]=_datetime;
        isopen[trade.item]=false;
        emit TradeStatusChange(_trade, nextstate);
    }
    
    
    
    function withdrawDiamonToken(uint256 _itemid) public onlyOwner {
        require(diamondToken.ownerOf(_itemid)==address(this),"O15");
        diamondToken.transferFrom(address(this),_msgSender(),_itemid);
    }
    
    
    function withdrawToken(uint256 amount) public onlyOwner {
        require(currency.balanceOf(address(this))>=amount,"O16");
        currency.transferFrom(address(this),_msgSender(),amount);
    }
    
    

}