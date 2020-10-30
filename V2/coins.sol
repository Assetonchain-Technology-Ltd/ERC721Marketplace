pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/presets/ERC20PresetMinterPauser.sol";

contract Coins is ERC20PresetMinterPauser {
    constructor(uint256 initialSupply, uint8 decimal) public ERC20PresetMinterPauser("AOCCoins", "AOC") {
        _setupDecimals(decimal);
        mint(msg.sender, initialSupply);
    }
}


