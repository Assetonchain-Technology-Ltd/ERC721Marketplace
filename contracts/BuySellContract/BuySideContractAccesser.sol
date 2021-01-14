pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";

contract buySideContractAccessor {
    
    using SafeMath for uint256;
    using Address for address;
    
    function _getEarlySettle(address _a) internal 
    returns(uint256 _b)
    {
        bytes memory payload = abi.encodeWithSignature("getEarlySettle()");
        (bool success , bytes memory result) = _a.call(payload);
        require(success,"C01");
        return abi.decode(result, (uint256));
    }
    
    
    function _setEarlySettle(address _a,uint256 _amount) internal
    {
        bytes memory payload = abi.encodeWithSignature("setEarlySettle(uint256)",_amount);
       (bool success,) = _a.call(payload);
       require(success,"C02");
    }
}