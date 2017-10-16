pragma solidity ^0.4.16;

import './BasicToken.sol';
import './SafeMath.sol';

contract AnkorusTestToken is BasicToken, Ownable
{
    using SafeMath for uint256;
    
    // Token Cap for each rounds
    uint256 public saleCap;

    // Address where funds are collected.
    address public wallet;
    
    // Sale period.
    uint256 public startDate;
    uint256 public endDate;

    // Amount of raised money in wei.
    uint256 public weiRaised;
    
    //  This is the 'Ticker' symbol and name for our Token.
    string public constant symbol = "ANKV10";
    string public constant name = "Ankorus Test Token V10";
    
    //  This is for how your token can be fracionalized. 
    uint8 public decimals = 18; 
    
    // Event
    event TokenPurchase(address indexed purchaser, uint256 value, 
        uint256 amount);
    event PreICOTokenPushed(address indexed buyer, uint256 amount);
    
    function AnkorusTestToken()
    {
        address twallet = 0x7e72a358d823eecC0e2bf087dAB2503EA9aF441B;
        initialize( twallet, now, now + 1 days, 30000000 ether, 60000000 ether);
    }
    
    function supply() internal constant returns (uint256) 
    {
        return balanceOf[0xb1];
    }

    modifier uninitialized() 
    {
        require(wallet == 0x0);
        _;
    }

    function getCurrentTimestamp() internal constant returns (uint256) 
    {
        return now;
    }
    
    function getRateAt(uint256 at) constant returns (uint256) 
    {
        if (at < startDate) {
            return 0;
        } else if (at < (startDate + 1 hours)) {
            return 5600;
        } else if (at < (startDate + 2 hours)) {
            return 5200;
        } else if (at < (startDate + 3 hours)) {
            return 4800;
        } else if (at < (startDate + 4 hours)) {
            return 4400;
        } else if (at <= endDate) {
            return 4000;
        } else {
            return 0;
        }
    }
    
    function initialize(address _wallet, uint256 _start, uint256 _end,
                        uint256 _saleCap, uint256 _totalSupply)
                        onlyOwner uninitialized
    {
        require(_start >= getCurrentTimestamp());
        require(_start < _end);
        require(_wallet != 0x0);
        require(_totalSupply > _saleCap);

        startDate = _start;
        endDate = _end;
        saleCap = _saleCap;
        wallet = _wallet;
        totalCoinSupply = _totalSupply;

        balanceOf[wallet] = _totalSupply.sub(saleCap);
        balanceOf[0xb1] = saleCap;
    }
    
    // fallback function can be used to buy tokens
    function () payable
    {
        buyTokens(msg.sender, msg.value);
    }

    function saleActive() public constant returns (bool) 
    {
        return (getCurrentTimestamp() >= startDate &&
                getCurrentTimestamp() < endDate && supply() > 0);
    }

    // low level token purchase function
    function buyTokens(address beneficiary, uint256 value) payable
    {
        /*require(beneficiary != 0x0);
        
        require(value >= 0.1 ether);
    
        
        uint256 updatedWeiRaised = weiRaised.add(weiAmount);
        weiRaised = updatedWeiRaised;*/
    
        // Calculate token amount to be purchased
        uint256 weiAmount = value;
        uint256 actualRate = getRateAt(getCurrentTimestamp());
        uint256 amount = weiAmount.mul(actualRate);

        //  Check our supply
        require(supply() >= amount);

        //address owner = 0x4f04B097f04A2376bC380245008bFDF88D05B836;
        
        // Transfer
        require(saleActive());
        //uint256 amount = 4000;
        balanceOf[0xb1] = balanceOf[0xb1].sub(amount);
        balanceOf[beneficiary] = balanceOf[beneficiary].add(amount);
        //TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        //forwardFunds();
    }
    
    event Transfer( address indexed _owner, address indexed _recipient, uint256 _value );
    event Approval( address _owner, address _spender, uint256 _value );
}






