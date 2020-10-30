pragma solidity ^0.6.0;

//import "openzeppelin-solidity/contracts/presets/ERC20PresetMinterPauser.sol";
import "openzeppelin-solidity/contracts/presets/ERC20PresetMinterPauser.sol";
import "openzeppelin-solidity/contracts/utils/Counters.sol";
import "./orderbook.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


contract PaymentBook is ERC20PresetMinterPauser {
  
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    event PaymentStatusChange(uint256 ad, string status,string tx ,string br,uint256 s,uint256 _datetime,uint8 ptype);
    event NewPayment(address p,uint256 a,uint256 s,uint256 pid,string state,uint8 ptype,uint256 _datetime,uint256 _seq);

    
    Orderbook ordbook;
    struct Payment{
        address payer;
        uint256 amount;
        uint256 salesID;
        string state;
        string tx;
        uint8 paymenttype;
        string bankrectx;
        uint256 settledate;
        uint256 seq;
        mapping(string => uint256) stateChange;
        
    }
    
    Counters.Counter private _paymentID;
    mapping(uint256 => Payment) private payments;
    mapping(uint256 => mapping(uint256 => uint256)) private payment2sales;
    
    function setOrdBoook(address _ordbook) public {
        require(hasRole(MINTER_ROLE,_msgSender()),"P1");
        ordbook = Orderbook(_ordbook); 
    }
    
    function getpaymentcount() public view
    returns(uint256)
    {
        return _paymentID.current()-1;
    }
    
    function getpaymentIDbySale(uint256 _salesID, uint256 _seq) public view
    returns(uint256 id)
    {
        return payment2sales[_salesID][_seq];    
    }
    
    function addpayment(uint256 _salesID,uint256 _amount,address _payer,uint8 _paymenttype,uint256 _seq,uint256 _datetime) public 
    returns(uint256)    
    {
        require(_msgSender()==address(ordbook)|| hasRole(MINTER_ROLE,_msgSender()),"P1");
        require(payment2sales[_salesID][_seq]==0,"P2");
        require(_amount>0,"P3");
        _paymentID.increment();
        uint256 currentid = _paymentID.current()-1;
        payment2sales[_salesID][_seq]=currentid;
        payments[currentid] = Payment({
           payer : _payer,
           amount : _amount,
           salesID : _salesID,
           state : "P-SETTLE",
           tx : "",
           paymenttype : _paymenttype,
           bankrectx : "",
           settledate : 0,
           seq : _seq
           
        });
        payments[currentid].stateChange["P-SETTLE"]=_datetime;
        emit NewPayment(_payer,_amount,_salesID,currentid,"P-SETTLE",_paymenttype,_datetime,_seq);
        return currentid;
    }
    
    
    function getPaymentdetail(uint256 _paymentid) public view
    returns(address,uint256,uint256,string memory,string memory ,uint8,string memory,uint256,uint256)
    {
        require(hasRole(MINTER_ROLE,_msgSender()),"P6");
        Payment memory p = payments[_paymentid];
        
        return(p.payer,p.amount,p.salesID,p.state,p.tx,p.paymenttype,p.bankrectx,p.settledate,p.seq);
        
        
    }
    
    function cancelPayment(uint256 _paymentid,uint256 _datetime) public {
        require(hasRole(MINTER_ROLE,_msgSender()),"P7");
        require(keccak256(bytes(payments[_paymentid].state))==keccak256(bytes("P-SETTLE")),"P5");
        payments[_paymentid].state="CANCEL";
        payments[_paymentid].settledate=_datetime;
        payments[_paymentid].stateChange["CANCEL"]=_datetime;
        payment2sales[payments[_paymentid].salesID][payments[_paymentid].seq]=0;
        emit PaymentStatusChange(_paymentid, "CANCEL",payments[_paymentid].tx,"CANCEL",_datetime,_datetime,0);
    }
    
    
    function bankrec(uint256 _paymentid, string memory _bankrectx, uint256 _settledate,bool _accept,uint256 _datetime,uint8 _paymenttpye) public 
    returns(uint256)
    {
        require(hasRole(MINTER_ROLE,_msgSender()),"P4");
        uint256 ordid=payments[_paymentid].salesID;
        require(ordbook.isopen(ordid),"P6");
        require(keccak256(bytes(payments[_paymentid].state))==keccak256(bytes("P-SETTLE")),"P5");
        if(_accept){
                payments[_paymentid].state="SETTLE";
                payments[_paymentid].bankrectx=_bankrectx;
                payments[_paymentid].settledate=_settledate;
                payments[_paymentid].paymenttype=_paymenttpye;
                _mint(address(ordbook),payments[_paymentid].amount);
                payments[_paymentid].stateChange["SETTLE"]=_datetime;
                
                uint256 balance = ordbook.executeTrade(payments[_paymentid].salesID,payments[_paymentid].amount, _settledate);
                emit PaymentStatusChange(_paymentid, "SETTLE",payments[_paymentid].tx,_bankrectx,_settledate,_datetime,_paymenttpye);
                return balance;
        }else{
             payments[_paymentid].state="REJECT";
             payments[_paymentid].settledate=_settledate;
             payments[_paymentid].stateChange["REJECT"]=_datetime;
             emit PaymentStatusChange(_paymentid, "REJECT",payments[_paymentid].tx,_bankrectx,_settledate,_datetime,0);
        }
        
    }
    
    constructor(uint256 initialSupply, uint8 decimal) public ERC20PresetMinterPauser("AOCCoins", "AOC") {
        _setupDecimals(decimal);
        mint(msg.sender, initialSupply);
        _paymentID.increment();
    }
}


