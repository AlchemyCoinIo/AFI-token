pragma solidity ^0.4.23;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Bonus.sol";

contract Crowdsale is Bonus {
    using SafeMath for uint256;

    // The token being sold
    ERC20 public token;

    // Address where funds are collected
    address public wallet;

    // ICO exchange rate
    uint256 public rate;

    // ICO Time
    uint256 public openingTimePeriodOne;
    uint256 public closingTimePeriodOne;
    uint256 public openingTimePeriodTwo;
    uint256 public closingTimePeriodTwo;
    uint256 public bonusDeliverTime;

    // Diff bonus rate decided by time
    uint256 public bonusRatePrivateSale;
    uint256 public bonusRatePeriodOne;
    uint256 public bonusRatePeriodTwo;

    // Token decimal
    uint256 decimals;
    uint256 public tokenUnsold;
    uint256 public bonusUnsold;
    uint256 public constant minPurchaseAmount = 0.1 ether;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event TokenBonus(address indexed purchaser, address indexed beneficiary, uint256 bonus);

    modifier onlyWhileOpen {
        require(block.timestamp <= closingTimePeriodTwo);
        _;
    }

    constructor (uint256 _openingTimePeriodOne, uint256 _closingTimePeriodOne, uint256 _openingTimePeriodTwo, uint256 _closingTimePeriodTwo, uint256 _bonusDeliverTime,
        uint256 _rate, uint256 _bonusRatePrivateSale, uint256 _bonusRatePeriodOne, uint256 _bonusRatePeriodTwo, 
        address _wallet, ERC20 _token, uint256 _decimals, uint256 _tokenUnsold, uint256 _bonusUnsold) public {
        require(_wallet != address(0));
        require(_token != address(0));
        require(_openingTimePeriodOne >= block.timestamp);
        require(_closingTimePeriodOne >= _openingTimePeriodOne);
        require(_openingTimePeriodTwo >= _closingTimePeriodOne);
        require(_closingTimePeriodTwo >= _openingTimePeriodTwo);

        wallet = _wallet;
        token = _token;
        openingTimePeriodOne = _openingTimePeriodOne;
        closingTimePeriodOne = _closingTimePeriodOne;
        openingTimePeriodTwo = _openingTimePeriodTwo;
        closingTimePeriodTwo = _closingTimePeriodTwo;
        bonusDeliverTime = _bonusDeliverTime;
        rate = _rate;
        bonusRatePrivateSale = _bonusRatePrivateSale;
        bonusRatePeriodOne = _bonusRatePeriodOne;
        bonusRatePeriodTwo = _bonusRatePeriodTwo;
        tokenUnsold = _tokenUnsold;
        bonusUnsold = _bonusUnsold;
        decimals = _decimals;
    }

    function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be sent
        uint256 tokens = _getTokenAmount(weiAmount);
        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens
        );

        // calculate bonus amount to be sent
        uint256 bonus = _getTokenBonus(weiAmount);
        _addBonus(_beneficiary, bonus);
        bonusUnsold = bonusUnsold.sub(bonus);
        emit TokenBonus(
            msg.sender,
            _beneficiary,
            bonus
        );
        _forwardFunds();
    }
	
    function isClosed() public view returns (bool) {
        return block.timestamp > closingTimePeriodTwo;
    }

    function isOpened() public view returns (bool) {
        return (block.timestamp < closingTimePeriodOne && block.timestamp > openingTimePeriodOne) || (block.timestamp < closingTimePeriodTwo && block.timestamp > openingTimePeriodTwo);
    }

    function privateCrowdsale(address _beneficiary, uint256 _ethAmount) external onlyOwner{
        _preValidatePurchase(_beneficiary, _ethAmount);

        // calculate token amount to be sent
        uint256 tokens = _getTokenAmount(_ethAmount);
        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            _ethAmount,
            tokens
        );

        // calculate bonus amount to be sent
        uint256 bonus = _ethAmount.mul(10 ** uint256(decimals)).div(1 ether).mul(bonusRatePrivateSale);
        _addBonus(_beneficiary, bonus);
        bonusUnsold = bonusUnsold.sub(bonus);
        emit TokenBonus(
            msg.sender,
            _beneficiary,
            bonus
        );
    }
    
    function returnToken() external onlyOwner{
        require(block.timestamp > closingTimePeriodTwo);
        require(tokenUnsold > 0);
        token.transfer(wallet,tokenUnsold);
        tokenUnsold = tokenUnsold.sub(tokenUnsold);
    }

    /**
     * WARNING: Make sure that user who owns bonus is still in whitelist!!!
     */
    function deliverBonus() public onlyOwner {
        require(bonusDeliverTime <= block.timestamp);
        for (uint i = 0; i<buyerList.length; i++){
            uint256 amount = buyerBonus[buyerList[i]];
            token.transfer(buyerList[i], amount);
            buyerBonus[buyerList[i]] = 0;
        }
    }

    function returnBonus() external onlyOwner{
        require(block.timestamp > bonusDeliverTime);
        require(bonusUnsold > 0);
        token.transfer(wallet, bonusUnsold);
        bonusUnsold = bonusUnsold.sub(bonusUnsold);
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view onlyWhileOpen
    {
        require(_beneficiary != address(0));
        require(_weiAmount >= minPurchaseAmount);
    }

    function _validateMaxSellAmount(uint256 _tokenAmount) internal view onlyWhileOpen {
        require(tokenUnsold >= _tokenAmount);
    }

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transfer(_beneficiary, _tokenAmount);
        tokenUnsold = tokenUnsold.sub(_tokenAmount);
    }

    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _validateMaxSellAmount(_tokenAmount);
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    function _getTokenAmount( uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(10 ** uint256(decimals)).div(1 ether).mul(rate);
    }

    function _getTokenBonus(uint256 _weiAmount) internal view returns (uint256) {
        uint256 bonusRate = 0;
        if(block.timestamp > openingTimePeriodOne && block.timestamp < closingTimePeriodOne){
            bonusRate = bonusRatePeriodOne;
        } else if(block.timestamp > openingTimePeriodTwo && block.timestamp < closingTimePeriodTwo){
            bonusRate = bonusRatePeriodTwo;
        }
        return _weiAmount.mul(10 ** uint256(decimals)).div(1 ether).mul(bonusRate);
    }

    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}
