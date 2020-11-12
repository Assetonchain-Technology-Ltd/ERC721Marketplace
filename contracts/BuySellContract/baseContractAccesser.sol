pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";

contract baseContractAccessor {
    
    using SafeMath for uint256;
    using Address for address;


  function _getState(address _a) internal
    returns(string memory s){
        bytes memory payload = abi.encodeWithSignature("getState()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (string));
    }
    
    function _getStateChange(address a,string memory s) internal 
    returns(uint256 d)
    {
        bytes memory payload = abi.encodeWithSignature("getStateChange(string)",s);
        (bool success, bytes memory result) = a.call(payload);
        require(success,"O23");
        return abi.decode(result, (uint256));
    }
    
    function _getFeePercentage(address _a) internal 
    returns(uint256 d)
    {
        bytes memory payload = abi.encodeWithSignature("getFeePercent()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (uint256));
        
    }
    
    function _getFeeAmount(address _a) internal 
    returns(uint256 d)
    {
        bytes memory payload = abi.encodeWithSignature("getFeeAmount()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (uint256));
        
    }
    
    function _getTradeMindeposit(address _a) internal 
    returns(uint256 d)
    {
        bytes memory payload = abi.encodeWithSignature("getMindeposit()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (uint256));
    }
    
    function _getTotalAmount(address _a) internal 
    returns(uint256 d)
    {
        bytes memory payload = abi.encodeWithSignature("getOrderPrice()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (uint256));
    }
    
    function _getItem(address _a) internal 
    returns(uint256 d,address c)
    {
         bytes memory payload = abi.encodeWithSignature("getItem()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (uint256,address));
    }
    
    function _getCreditor(address _a)internal 
    returns(address _d)
    {
        bytes memory payload = abi.encodeWithSignature("getCreditor()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (address));
    }
    
    function _getSeller(address _a) internal
    returns(address _d)
    {
        bytes memory payload = abi.encodeWithSignature("getSeller()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (address));
    }
    
    function _getDebtor(address _a) internal 
    returns(address _c)
    {
        bytes memory payload = abi.encodeWithSignature("getDebtor()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (address));
    }
    

    
    function _getActiveSettlementPlan(address _a) internal  
    returns(uint256 _i,uint256 _d,uint256 _c)
    {
        bytes memory payload = abi.encodeWithSignature("getActiveSettlementPlan()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (uint256,uint256,uint256));
    }
    
    function _isSettled(address _a) internal 
    returns(bool _t)
    {
        bytes memory payload = abi.encodeWithSignature("isSettled()");
        (bool success, bytes memory result) = _a.call(payload);
        require(success,"O23");
        return abi.decode(result, (bool));
    }
    
    function _setState(address _a,string memory _s,uint256 _d) internal
    {
        bytes memory payload = abi.encodeWithSignature("setState(string,uint256)",_s,_d);
        (bool success, ) = _a.call(payload);
        require(success,"O23");
     
    }
    
    function _setFeePercent(address _a,uint256 _d) internal
    {
        bytes memory payload = abi.encodeWithSignature("setFeePercent(uint256)",_d);
        (bool success, ) = _a.call(payload);
        require(success,"O23");
     
    }
    
    function _setFeeAmount(address _a,uint256 _d) internal
    {
        bytes memory payload = abi.encodeWithSignature("setFeeAmount(uint256)",_d);
        (bool success, ) = _a.call(payload);
        require(success,"O23");
     
    }
    
    function _setDebtor(address _a,address _d) internal
    {
        bytes memory payload = abi.encodeWithSignature("setDebtor(address)",_d);
        (bool success, ) = _a.call(payload);
        require(success,"O23");
     
    }
    
    function _setMindeposit(address _a,uint256 _s) internal 
    {
        bytes memory payload = abi.encodeWithSignature("setMindeposit(uint256)",_s);
        (bool success, ) = _a.call(payload);
        require(success,"O23");
    }
    
    function _WithdrawERC721Token(address _a, uint256 _id,address _dest) internal
    {
        bytes memory payload = abi.encodeWithSignature("withdrawalERC721Token(uint256,address)",_id,_dest);
        (bool success, ) = _a.call(payload);
        require(success,"O23");
    }
    
    function _WithdrawERC20Token(address _a,address base,uint256 _amount,address _dest) internal
    {
        bytes memory payload = abi.encodeWithSignature("withdrawalERC20Token(address,uint256,address)",base,_amount,_dest);
        (bool success, ) = _a.call(payload);
        require(success,"O23");
    }
    
    
    function _addSettlementPlan(address _a, uint256 _amount,uint256 _settlementdate,uint256 _datetime,bool _active) internal 
    {
        bytes memory payload = abi.encodeWithSignature("addSettlementPlan(uint256,uint256,uint256,bool)",_amount,_settlementdate,_datetime,_active);
        (bool success,) = _a.call(payload);
        require(success,"O23");
    }
    
    function _completePayment(address _a,uint256 _id, string memory _tx,uint256 _date,uint8 _p) internal 
    {
        bytes memory payload = abi.encodeWithSignature("completePayment(uint256,string)",_id,_tx,_date,_p);
        (bool success,) = _a.call(payload);
        require(success,"O23");
    }
    
}
    