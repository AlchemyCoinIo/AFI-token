pragma solidity ^0.4.21;

import "./Ownable.sol";
import "./ERC20.sol";

contract AssignRevenue is Ownable {
    ERC20 public APPROVE_CONTRACT;
    address public APPROVE_OWNER;

    event RevenueAssign(address indexed beneficiary, address revenue_contract, uint256 amount);

    function setContract(ERC20 _contract, address _owner) external onlyOwner {
        APPROVE_CONTRACT = _contract; 
        APPROVE_OWNER = _owner;
    }

    function transferRevenue(address _address, uint256 _amount) external onlyOwner {
        APPROVE_CONTRACT.transferFrom(APPROVE_OWNER,_address, _amount);
        emit RevenueAssign(
            msg.sender,
            APPROVE_CONTRACT,
            _amount
        );
    }
}