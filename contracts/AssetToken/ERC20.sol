pragma solidity ^0.6.0;

//import "openzeppelin-solidity/contracts/presets/ERC20PresetMinterPauser.sol";

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Pausable.sol";
import "../utils/access.sol";


contract Coins is Access, ERC20Burnable, ERC20Pausable {
    
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(uint256 initialSupply, address _access, uint8 decimal) public ERC20("AOCCoins", "AOC") {
        _setupDecimals(decimal);
        access = PermissionControl(_access);
    
        mint(msg.sender, initialSupply);
    }
    
    function mint(address to, uint256 amount) public virtual {
        require(_isOrder(msg.sender) || _isAdmin(msg.sender) || _isAccount(msg.sender), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }
    
    
    function pause() public virtual {
        require(_isOrder(msg.sender) || _isAdmin(msg.sender) || _isAccount(msg.sender), "ERC20PresetMinterPauser: must have pauser role to pause");
       
        _pause();
    }

   
    function unpause() public virtual {
        require(_isOrder(msg.sender) || _isAdmin(msg.sender) || _isAccount(msg.sender), "ERC20PresetMinterPauser: must have pauser role to unpause");
       
        _unpause();
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}


