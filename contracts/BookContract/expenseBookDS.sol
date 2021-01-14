pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "./stateMachine.sol";
import "openzeppelin-solidity/contracts/utils/Counters.sol";

import "./orderBookLibrary.sol";
import "../utils/erc721DirectoryLookup.sol";
import "../utils/access.sol";

//contract expenseBook is  AccessControl, GSNRecipient {

contract expenseBookDS is Access {   
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address;

    address bookkeepingtoken;
    address contractfactory;

    orderbookLibrary orderbook;
    StateMachine statemachine;
    erc721DirectoryService lookup;
    uint256 feesprecentage_decimal;
    Counters.Counter _orderID;
    mapping(uint256 => address) orders;
    mapping(address => uint256) address2orders;
    mapping(string => uint8 ) public currencydecimal;
    mapping(uint256 => bool ) public token; // check if there is open order in expensebook
    
    
    
}
