pragma solidity ^0.4.21;

import "./Ownable.sol";
import "./SafeMath.sol";

contract Bonus is Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) public buyerBonus;
    mapping(address => bool) hasBought;
    address[] public buyerList;
    
    function _addBonus(address _beneficiary, uint256 _bonus) internal {
        if(hasBought[_beneficiary]){
            buyerBonus[_beneficiary] = buyerBonus[_beneficiary].add(_bonus);
        } else {
            hasBought[_beneficiary] = true;
            buyerList.push(_beneficiary);
            buyerBonus[_beneficiary] = _bonus;
        }
    }
}