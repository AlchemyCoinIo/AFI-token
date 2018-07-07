pragma solidity ^0.4.21;

import "./Ownable.sol";
import "./SafeMath.sol";

contract Whitelist is Ownable {

    using SafeMath for uint256;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) whitelistIndexMap;
    address[] public whitelistArray;
    uint256 public whitelistLength = 0;

    modifier isWhitelisted(address _beneficiary) {
        require(whitelist[_beneficiary]);
        _;
    }

    function addToWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = true;
        if (whitelistIndexMap[_beneficiary] == 0){
            if (whitelistArray.length <= whitelistLength){
                whitelistArray.push(_beneficiary);
            } else {
                whitelistArray[whitelistLength] = _beneficiary;
            }
            whitelistLength = whitelistLength.add(1);
            whitelistIndexMap[_beneficiary] = whitelistLength;
        }
    }

    function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

    function removeFromWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = false;
        if (whitelistIndexMap[_beneficiary] > 0){
            uint index = whitelistIndexMap[_beneficiary]-1;
            whitelistArray[index] = whitelistArray[whitelistLength-1];
            whitelistArray[whitelistLength-1] = 0;
            whitelistIndexMap[_beneficiary] = 0;
            whitelistLength = whitelistLength.sub(1);
        }
    }
}
