pragma solidity ^0.6.0;
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721Holder.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";


//import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
//import "openzeppelin-solidity/contracts/token/ERC721/ERC721Holder.sol";
import "openzeppelin-solidity/contracts/utils/Counters.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


import "./compliance.sol";
import "./stateMachine.sol";
import "./paymentBook.sol";

contract Orderbook is Ownable {
    event TradeStatusChange(uint256 ad,string action,string status,address b,uint256 p,uint256 d);
    event NewTrade(uint256 t, address seller, uint256 itemID,uint256 p,uint256 o,uint256 m,uint256 _datetime);
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    
    PaymentBook paymentbook;
    ERC721 diamondToken;
    StateMachine statemachine;
    Compliance compliance;
    address expensebook;
    address platform;
    Counters.Counter private _tradeID;
    Counters.Counter private _salesID;
    uint256 fixdeposit=0;
    uint256 feespercentage_decimal = 100;
    uint256 depositpercentage = 3;
    uint256 expiryday = 3;
    
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
        uint256 feespercentage;
        mapping(uint256 => uint256) paymentbookid;
        mapping(string => uint256) stateChange;
        
    }
    
   
    
    mapping(uint256 => Trade) private trades;
    mapping(uint256 => bool) public isopen;
    mapping(uint256 => uint256) private salesTrademap;
    
    constructor (address _paymentbook, address _itemTokenAddress,address _compliance , address _statemachine, address _platform) public virtual
    {
        
        paymentbook = PaymentBook(_paymentbook);
        diamondToken = ERC721(_itemTokenAddress);
        compliance = Compliance(_compliance);
        statemachine = StateMachine(_statemachine);
        _tradeID.increment();
        platform=_platform;
        _salesID.increment();
        if(_platform==address(0)){
            platform=address(this);
        }

    }
    
    function setexpensebook(address _add) public onlyOwner
    {
        expensebook = _add;
        diamondToken.setApprovalForAll(_add,true);
    }
    
    function setfixdeposit(uint256 _amount) public onlyOwner
    {
        fixdeposit = _amount;
    }
    
    function setpaymentbook(address _add) public onlyOwner
    {
        paymentbook = PaymentBook(_add);
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
        return (address(paymentbook),address(diamondToken),address(compliance),address(statemachine),expensebook);
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
        require(_msgSender()==expensebook || _msgSender()==owner(), "O2");
        require( _price > 0 , "O14" );
        address source = diamondToken.ownerOf(_itemID);
        require(source==expensebook || source==_owner,"O18");
        isopen[_itemID]=true;
        _tradeID.increment();
        uint256 currentID = _tradeID.current()-1;
        diamondToken.transferFrom(source, address(this), _itemID);
        //uint256 newtrade = _tradeID.current();
        uint256 _mindeposit = (fixdeposit>0)?fixdeposit:_price.mul(depositpercentage).div(100);
        trades[currentID] = Trade({
            seller: _msgSender(),
            owner : _owner,
            item: _itemID,
            price: _price,
            status: "OPEN",
            orderid : _orderid,
            buyer : address(0),
            payment : 0,
            mindeposit : _mindeposit,
            feespercentage : 0
        });
        
        trades[currentID].stateChange["OPEN"]=_datetime;
    
        emit NewTrade(currentID,_msgSender(),_itemID,_price,_orderid,_mindeposit,_datetime);
        return currentID;
    }
    
    function markTrade(uint256 _trade,uint256 _feespercentage, uint256 _datetime,bool _fullpay,uint8 _paymenttype) public
    returns(uint256 paymnentid,uint256 amount)
    {
        Trade memory trade = trades[_trade];
        (bool exist,string memory nextstate) = statemachine.transitionExists(trade.status,bytes32(keccak256("markTrade")));
        //profile checking
        require(exist , "O3");
        require(compliance.isPass(_msgSender()), "O4");
        require(trade.owner!=_msgSender(),"O17");
        trades[_trade].status = nextstate;
        trades[_trade].feespercentage = _feespercentage;
        trades[_trade].stateChange[nextstate]=_datetime;
        trades[_trade].buyer=_msgSender();
        uint256 fees = (trade.price.mul( _feespercentage)).div(100*feespercentage_decimal);
        emit TradeStatusChange(_trade,"markTrade", nextstate,_msgSender(),0,_datetime);
  
        
        if(_fullpay){
             trades[_trade].paymentbookid[0] = paymentbook.addpayment(_trade,fees.add(trade.price),_msgSender(),_paymenttype,0,_datetime);
            return (trades[_trade].paymentbookid[0],fees.add(trade.price));
        }else{
           
            trades[_trade].paymentbookid[0] = paymentbook.addpayment(_trade,fees.add(trade.mindeposit),_msgSender(),_paymenttype,0,_datetime);
            trades[_trade].paymentbookid[1] = paymentbook.addpayment(_trade,trade.price.sub(trade.mindeposit),_msgSender(),0,1,_datetime);
            return (trades[_trade].paymentbookid[0],fees.add(trade.mindeposit));
        }
    }
    
    function executeTrade(uint256 _trade, uint256 _payment, uint256 _datetime)
        public
        virtual
        returns (uint256)
    {
        Trade memory trade = trades[_trade];
        (bool exist,string memory nextstate) = statemachine.transitionExists(trade.status,bytes32(keccak256("executeTrade")));
        //profile checking
        require(exist , "O3");
        require(_msgSender()==address(paymentbook),"O17");
        uint256 fees = (trade.price.mul(trades[_trade].feespercentage)).div(100*feespercentage_decimal);
        uint256 totalamount = trades[_trade].price.add(fees);
        trades[_trade].payment=trades[_trade].payment.add(_payment);
        if(trades[_trade].payment>=totalamount){
            diamondToken.transferFrom(address(this),trades[_trade].buyer, trade.item);
            trades[_trade].status = "EXEC";  
            trades[_trade].stateChange["EXEC"]=_datetime;
            isopen[trade.item]=false;
            emit TradeStatusChange(_trade,"executeTrade","EXEC",_msgSender(),_payment,_datetime);
            return trades[_trade].payment.sub(totalamount);
           
        }else{
            trades[_trade].status = nextstate;
            trades[_trade].stateChange[nextstate]=_datetime;
            emit TradeStatusChange(_trade,"executeTrade",nextstate,_msgSender(),_payment,_datetime);
            return totalamount.sub(trades[_trade].payment);
        }
       
    }
    
    function setAllowanceOwner(uint256 _amount) public onlyOwner{
        paymentbook.approve(owner(),0);
        paymentbook.increaseAllowance(owner(), _amount);
        
    }
    
    function executeExpensebook(uint256 _trade,uint256 _datetime) public onlyOwner
    {
        Trade memory trade = trades[_trade];
        (bool exist,string memory nextstate) = statemachine.transitionExists(trade.status,bytes32(keccak256("executeExpensebook")));
        bytes memory payload = abi.encodeWithSignature("getOrderAmount(uint256)",trades[_trade].orderid);
        (bool success, bytes memory result) = expensebook.call(payload);
        require(success,"O23");
        uint256 payamount = abi.decode(result, (uint256));
        uint256 fees = (trade.price.mul(trade.feespercentage)).div(100*feespercentage_decimal);
        uint256 profit = trade.price.sub(payamount);
        //profile checking
        require(exist , "O3");
        //require(_msgSender()==address(paymentbook),"O20");
        require(trade.payment>=payamount.add(fees).add(profit),"O23");
        require(paymentbook.balanceOf(address(this))>=trade.payment,"O19");

        payload = abi.encodeWithSignature("fullFillTrade(uint256,uint256)",trades[_trade].orderid,_datetime);
        expensebook.call(payload);
        paymentbook.transfer(expensebook,payamount);
        paymentbook.transfer(platform,fees);
        paymentbook.transfer(platform,profit);
        
    }

    function cancelTrade(uint256 _trade,uint256 _datetime,bool return2owner)
        public
        virtual
    {
        Trade memory trade = trades[_trade];
        require(_msgSender() == trade.seller || _msgSender() == trade.buyer,"O10");
        (bool exist,string memory nextstate) = statemachine.transitionExists(trade.status,bytes32(keccak256("cancelTrade")));
        require(exist , "O11");
        address destination = return2owner?trade.owner:trade.seller;
        diamondToken.transferFrom(address(this), destination, trade.item);
        trades[_trade].status = nextstate;
        trades[_trade].stateChange[nextstate]=_datetime;
        isopen[trade.item]=false;
        emit TradeStatusChange(_trade,"cancelTrade",nextstate,_msgSender(),0,_datetime);
    }
    
    
    function expireTrade(uint256 _trade,uint256 _datetime) public{
        Trade memory trade = trades[_trade];
        (bool exist,string memory nextstate) = statemachine.transitionExists(trade.status,bytes32(keccak256("expireTrade")));
        require(exist , "O21");
        uint256 diff = _datetime.sub(trades[_trade].stateChange[trade.status]);
        require(diff.div(60).div(60).div(24)>expiryday,"O22");
        trades[_trade].status = nextstate;
        trades[_trade].stateChange[nextstate]=_datetime;
        isopen[trade.item]=false;
        emit TradeStatusChange(_trade,"expireTrade",nextstate,_msgSender(),trades[_trade].payment,_datetime);
        
    }
    
    
    
    function withdrawDiamonToken(uint256 _itemid) public onlyOwner {
        require(diamondToken.ownerOf(_itemid)==address(this),"O15");
        diamondToken.transferFrom(address(this),_msgSender(),_itemid);
    }
    
    
    
    

}
