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
    uint256 public minRevenueToDeliver = 0;
    address public assignRevenueContract;
    uint256 public snapshotBlockHeight;
    mapping(address => uint256) public snapshotBalance;
    // Custom Setting values ---------------------------------
    uint256 constant _openingTimePeriodOne = 1531713600;
    uint256 constant _closingTimePeriodOne = 1534132800;
    uint256 constant _openingTimePeriodTwo = 1535342400;
    uint256 constant _closingTimePeriodTwo = 1536552000;
    uint256 constant _bonusDeliverTime = 1552276800;
    address _wallet = 0x2Dc02F830072eB33A12Da0852053eAF896185910;
    address _afiWallet = 0x991E2130f5bF113E2282A5F58E626467D2221599;
    // -------------------------------------------------------
    uint256 constant _rate = 1000;
    uint256 constant _bonusRatePrivateSale = 250;
    uint256 constant _bonusRatePeriodOne = 150;
    uint256 constant _bonusRatePeriodTwo = 50;
    

    constructor() public 
    Crowdsale(_openingTimePeriodOne, _closingTimePeriodOne, _openingTimePeriodTwo, _closingTimePeriodTwo, _bonusDeliverTime,
        _rate, _bonusRatePrivateSale, _bonusRatePeriodOne, _bonusRatePeriodTwo, 
        _wallet, this, decimals, ICO_SUPPLY, ICO_BONUS)
    {
        totalSupply_ = INITIAL_SUPPLY;
        emit Transfer(0x0, _afiWallet, INITIAL_SUPPLY - ICO_SUPPLY - ICO_BONUS);
        emit Transfer(0x0, this, ICO_SUPPLY);
        balances[_afiWallet] = INITIAL_SUPPLY - ICO_SUPPLY - ICO_BONUS;
        
        // add admin
        whitelist[_afiWallet] = true;
        whitelistArray.push(_afiWallet);
        whitelistLength = whitelistLength.add(1);
        whitelistIndexMap[_afiWallet] = whitelistLength;
        
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

    function createBalanceSnapshot() external onlyOwner {
        snapshotBlockHeight = block.number;
        for(uint256 i = 0; i < whitelistLength; i++) {
            snapshotBalance[whitelistArray[i]] = balances[whitelistArray[i]];
        }
    }

    function setMinRevenue(uint256 _minRevenue) external onlyOwner {
        minRevenueToDeliver = _minRevenue;
    }

    function assignRevenue(uint256 _totalRevenue) external onlyOwner{
        address contractAddress = assignRevenueContract;

        for (uint256 i = 0; i<whitelistLength; i++){
            if(whitelistArray[i] == address(this)){
                continue;
            }
            uint256 amount = _totalRevenue.mul(snapshotBalance[whitelistArray[i]]).div(INITIAL_SUPPLY);
            if(amount > minRevenueToDeliver){
                bool done = contractAddress.call(bytes4(keccak256("transferRevenue(address,uint256)")),whitelistArray[i],amount);
                require(done == true);
            }
        }
    }
}
