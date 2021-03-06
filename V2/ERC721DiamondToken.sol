pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721Burnable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721Pausable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "./DiamondContract.sol";

contract TestingERC721 is AccessControl,ERC721Burnable, ERC721Pausable {
    event NewToken(uint256 itemid);
    using SafeMath for uint256;
    using Address for address;
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    DiamondContract public diamond;
    
	constructor(string memory _symbolname,string memory _symbol,string memory _baseURI) public ERC721(_symbolname, _symbol) {
		 _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        _setBaseURI(_baseURI);



	}

    function listDiamond (address player, string memory tokenURI, address supplier,string memory gia,string memory color, string memory threeEX, string memory clarity, string memory carat)
        public
        returns (uint256)
    {
		require(hasRole(MINTER_ROLE, _msgSender()), "TestingERC721 : must have minter role to mint");
		diamond = new DiamondContract(supplier,color,threeEX,clarity,carat,gia);
		uint256 tokenID = uint256(address(diamond));
        _mint(player, tokenID);
        _setTokenURI(tokenID, tokenURI);
        emit  NewToken(tokenID);
        return tokenID;
    }

	function mint(address to) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");

    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
	
}
