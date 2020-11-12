pragma solidity ^0.6.0;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
contract DiamondContract is Ownable {
	
	address public initialsupplier;
	string public GIA;
	string public color;
	string public threeEX;
	string public clarity;
	string public carat;

	constructor(address a,string memory _color, string memory _3EX,string memory _clarity,string memory _carat,string memory _gia) public{
		initialsupplier =a;
		GIA =_gia;
		color =_color;
		threeEX = _3EX;
		clarity = _clarity;
		carat = _carat;
	}


}
