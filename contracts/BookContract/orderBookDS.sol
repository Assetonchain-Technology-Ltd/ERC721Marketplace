pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "openzeppelin-solidity/contracts/utils/Counters.sol";
import "./stateMachine.sol";
import "../utils/access.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "../utils/erc721DirectoryLookup.sol";


//contract expenseBook is  AccessControl, GSNRecipient {

contract orderBookDS is Access{   
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address;

    address expensebook;
    address bookkeepingtoken;
    address contractfactory;
    address account_receivable;
    address platform;
    address platformfees;
    address client_forfeit;
    address supplier_forfeit;
    address baddebt;
    StateMachine statemachine;
    erc721DirectoryService lookup;
    uint256 fixdeposit;
    uint256 percentage_decimal;
    uint256 depositpercentage;
    uint256 expiryday;
    
    Counters.Counter  _tradeID;
    
    mapping(uint256 => address)  trades;
    mapping(uint256 => bool) public isopen;
    mapping(uint256 => uint256)  salesTrademap;
    
    
    
   
}
