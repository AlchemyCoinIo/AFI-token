pragma solidity ^0.4.23;
import "./StandardToken.sol";
import "./Whitelist.sol";
import "./CrowdSale.sol";
import "./SafeMath.sol";

contract AFIToken is StandardToken, Crowdsale, Whitelist {
    using SafeMath for uint256;
    string public constant name = "AlchemyCoin";
    string public constant symbol = "AFI";
    uint8 public constant decimals = 8;
    uint256 constant INITIAL_SUPPLY = 125000000 * (10 ** uint256(decimals));
    uint256 constant ICO_SUPPLY = 50000000 * (10 ** uint256(decimals));
    uint256 constant ICO_BONUS = 12500000 * (10 ** uint256(decimals));
    uint256 public constant LIMIT_REVENUE = 10 ** 8;
    address public assignRevenueContract;
    uint256 constant _openingTimePeriodOne = 1530867600;
    uint256 constant _closingTimePeriodOne = 1530867600;
    uint256 constant _openingTimePeriodTwo = 1530867600;
    uint256 constant _closingTimePeriodTwo = 1530867600;
    uint256 constant _bonusDeliverTime = 1530867660;
    uint256 constant _rate = 1000;
    uint256 constant _bonusRatePrivateSale = 250;
    uint256 constant _bonusRatePeriodOne = 150;
    uint256 constant _bonusRatePeriodTwo = 50;
    address _wallet = msg.sender;

    constructor() public 
    Crowdsale(_openingTimePeriodOne, _closingTimePeriodOne, _openingTimePeriodTwo, _closingTimePeriodTwo, _bonusDeliverTime,
        _rate, _bonusRatePrivateSale, _bonusRatePeriodOne, _bonusRatePeriodTwo, 
        _wallet, this, decimals, ICO_SUPPLY, ICO_BONUS)
    {
        totalSupply_ = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY - ICO_SUPPLY - ICO_BONUS);
        emit Transfer(0x0, this, ICO_SUPPLY);
        balances[msg.sender] = INITIAL_SUPPLY - ICO_SUPPLY - ICO_BONUS;
        
        // add admin
        whitelist[msg.sender] = true;
        whitelistArray.push(msg.sender);
        whitelistLength = whitelistLength.add(1);
        whitelistIndexMap[msg.sender] = whitelistLength;
        
        // add contract
        whitelist[this] = true;
        whitelistArray.push(this);
        whitelistLength = whitelistLength.add(1);
        whitelistIndexMap[this] = whitelistLength;
        balances[this] = ICO_SUPPLY + ICO_BONUS;
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view isWhitelisted(_beneficiary){
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

    function transfer(address _to, uint256 _value) public isWhitelisted(_to) isWhitelisted(msg.sender) returns (bool) {
        super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public isWhitelisted(_to) isWhitelisted(_from)  returns (bool){
        super.transferFrom(_from, _to, _value);
    }

    function setRevenueContract(address _contract) external onlyOwner{
        assignRevenueContract = _contract;
    }

    function assignRevenue(uint256 _totalRevenue) external onlyOwner{
        address contractAddress = assignRevenueContract;
        // uint256 revenueSupply = 0;
        uint i;

        for (i = 0; i<whitelistLength; i++){
            if(balances[whitelistArray[i]] > LIMIT_REVENUE){
                uint256 amount = _totalRevenue.mul(balances[whitelistArray[i]]).div(INITIAL_SUPPLY);
                require(contractAddress.call(bytes4(keccak256("transferRevenue(address,uint256)")),whitelistArray[i],amount));
            }
        }
    }
}
