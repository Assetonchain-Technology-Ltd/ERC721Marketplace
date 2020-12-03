pragma solidity ^0.6.0;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721Burnable.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721Pausable.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";


import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Pausable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "./DiamondContract.sol";
import "../utils/erc721DirectoryLookup.sol";
import "../utils/access.sol";
contract TestingERC721 is ERC721Burnable, ERC721Pausable, Access {
    event NewToken(uint256 itemid,address owner,string url);
    using SafeMath for uint256;
    using Address for address;
    DiamondContract public diamond;
    erc721DirectoryService lookup;
    
	constructor(string memory _symbolname,string memory _symbol,string memory _baseURI, address _access,address _lookup) public ERC721(_symbolname, _symbol) {
		 
		 access = PermissionControl(_access);
		 lookup = erc721DirectoryService(_lookup);
        _setBaseURI(_baseURI);

	}

    function listDiamond (address player, string memory tokenURI, address supplier,string memory gia,string memory color, string memory threeEX, string memory clarity, string memory carat)
        public
        returns (uint256)
    {
		require(access.hasRole(access.ADMIN_ROLE(),msg.sender), "TestingERC721 : must have minter role to mint");
		diamond = new DiamondContract(supplier,color,threeEX,clarity,carat,gia);
		uint256 tokenID = uint256(address(diamond));
        _mint(player, tokenID);
        _setTokenURI(tokenID, tokenURI);
        lookup.setBaseAddress(tokenID,address(this));
        emit  NewToken(tokenID,player,tokenURI);
        return tokenID;
    }

	function mint(address to) public virtual {
        require(access.hasRole(access.ADMIN_ROLE(), msg.sender), "ERC721PresetMinterPauserAutoId: must have minter role to mint");

    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function setAccess(address _a) public 
    {
        require(access.hasRole(access.ADMIN_ROLE(),msg.sender),"ERC721_1");
        access = PermissionControl(_a);
        
    }
    
    function setLookup(address _a) public
    {
        require(access.hasRole(access.ADMIN_ROLE(),msg.sender),"ERC721_1");
        lookup = erc721DirectoryService(_a);
    }
	
}
