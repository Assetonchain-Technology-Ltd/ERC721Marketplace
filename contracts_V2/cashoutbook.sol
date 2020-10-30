pragma solidity ^0.6.0;

//import "openzeppelin-solidity/contracts/presets/ERC20PresetMinterPauser.sol";
import "openzeppelin-solidity/contracts/utils/Counters.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";



contract CashOutBook is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    event CashOutStatusChange(uint256 ad, string status,uint256 s);
    event NewCashOut(address b,uint256 a,uint256 s,uint256 cid,uint8 ptype);
    
    struct Payment{
        address beneficiary;
        uint256 amount;
        uint256 salesID;
        uint8 paymenttype;
        string bankrectx;
        uint256 settledate;
    }
    
    ERC20 bookkeep;
    address expensebook;
    address admin;
    Counters.Counter private _paymentID;
    mapping(uint256 => Payment) private payments;
    mapping(uint256 => uint256) private payment2sales;
    
    
     constructor(address _bookkeepingtoken ,address _expensebook, address _admin) public {
        bookkeep = ERC20(_bookkeepingtoken);
        expensebook = _expensebook;
        admin = _admin;
        _paymentID.increment();
    }
    
    function addpayment(uint256 _salesID,uint256 _amount,address _beneficiary,uint8 _paymenttype) public 
    returns(uint256)    
    {
        require(_msgSender()==expensebook || _msgSender()==admin,"C1");
        require(payment2sales[_salesID]>0,"C2");
        require(_amount>0,"C3");
        _paymentID.increment();
        uint256 currentid = _paymentID.current()-1;
        payment2sales[_salesID]=currentid;
        payments[currentid] = Payment({
           beneficiary : _beneficiary,
           amount : _amount,
           salesID : _salesID,
           paymenttype : _paymenttype,
           bankrectx : "",
           settledate : 0
           
        });
        emit NewCashOut(_beneficiary,_amount,_salesID,currentid,_paymenttype);
        return currentid;
    }
    
    function bankrec(uint256 _paymentid, string memory _bankrectx, uint256 _settledate) public 
    returns(uint256)
    {
        
        require(_msgSender()==expensebook || _msgSender()==admin,"C4");
        require(bookkeep.balanceOf(expensebook)>=payments[_paymentid].amount,"C5");
        payments[_paymentid].bankrectx=_bankrectx;
        payments[_paymentid].settledate=_settledate;
        bytes memory payload = abi.encodeWithSignature("updateINV_confirm(uint256,uint256)",payments[_paymentid].salesID,_settledate);
        expensebook.call(payload);
        bookkeep.transferFrom(expensebook,address(this),payments[_paymentid].amount);
        emit CashOutStatusChange(_paymentid,_bankrectx,_settledate); 
        
    }
    
  
}


