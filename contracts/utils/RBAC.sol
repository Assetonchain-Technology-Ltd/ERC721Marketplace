pragma solidity ^0.6.0;
import "./AccessControl.sol";

contract PermissionControl is AccessControl {
    
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant APPR = keccak256("APPROVAL");
    bytes32 public constant ACCOUNT = keccak256("ACCOUNT");
    bytes32 public constant EXPENSE = keccak256("EXPENSE");
    bytes32 public constant ORDER = keccak256("ORDER");
    bytes32 public constant ORDER_VIEWER = keccak256("ORDER_VIEWER");
    bytes32 public constant SUPPLIER = keccak256("SUPPLIER");
    bytes32 public constant SALE = keccak256("SALE");
    bytes32 public constant SETTLEMENT = keccak256("SETTLEMENT");
    bytes32 public constant COMPREG = keccak256("COMPREG");
    bytes32 public constant MEMBER = keccak256("MEMBER");
    bytes32 public constant ERC721TOKEN = keccak256("ERC721TOKEN");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
   
}