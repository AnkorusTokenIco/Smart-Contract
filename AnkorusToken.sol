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
    
    //  Tokens rate formule
    uint16 public tokensSold = 0;
    uint256 public tokensPerTraunch = 2000000;
    
    //  Whitelist approval mapping
    mapping (address => bool) public whitelist;
    
    //  Lockout mapping
    mapping (address => uint256) public lockoutMap;
    
    //  This is the 'Ticker' symbol and name for our Token.
    string public constant symbol = "ANKV12";
    string public constant name = "Ankorus Test Token V12";
    
    //  This is for how your token can be fracionalized. 
    uint8 public decimals = 18; 
    
    // Event
    event TokenPurchase(address indexed purchaser, uint256 value, 
        uint256 amount);
    event CompanyTokenPushed(address indexed buyer, uint256 amount);
    
    function AnkorusTestToken()
    {
        address twallet = 0x3336c2EB32F3bc5cC63154c4315031e5985B8fDc;
        initialize( twallet, now + 1 hours, now + 1 days, 50000000 ether, 100000000 ether);
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
    
    function getRateAt(uint256 _tokens) constant returns (uint256)
    {
        uint256 tokenssold = _tokens;
        uint256 numberOfTraunches = 25;
        
	    //	This level of precision allows for calculation of 
	    //	( x * ( numerator ** 2 ) ) / totalTraunchesSq to remain close to a whole number
	    //	while not losing too much information
	    uint256 precision = 1000000;

	    //	0.000835 * precision;
	    uint256 x = 835;

	    //	0.001665 * precision;
	    uint256 y = 1665;

	    //	Numerator is current traunch level used to determine price
	    //	Will be truncated to a whole number between 1 and 24 with the number being >=25
	    //	impossible as we can't complete a purchase if more than 49999999 tokens are 
	    //	sold (no more remaining)
	    uint256 numerator = 1 + ( tokenssold / tokensPerTraunch );
	
	    //	Calculate token price before precision. Based on the formula p = x * (traunch/totalTraunches)^2 + y
	    //	re-written in the form of p = ( x * traunch ^ 2 ) / totalTraunches ^ 2 + y to avoid floating point result
	    //	As we can assume ( x * traunch ^ 2 ) will be greater than totalTraunches ^ 2 with a large enough precision
	    uint256 totalTraunchesSq = numberOfTraunches ** 2;
	    uint256 tokenPriceBeforePrecision = ( ( x * ( numerator ** 2 ) ) / totalTraunchesSq ) + y;

	    //	The purpose of this function is to determine the amount of tokens for 1 ether, or tokensPerEther.
	    //	what we have now is the price of a single in ether, or tokenPrice, which we can get from 
	    //	tokenPriceBeforePrecision / precision - which would be a floating point number less than 0, 
	    //	which we cant calculate given the lack of floating point math. 
	    	
	    //	However, if 1 / tokenPrice gives us the amount of tokens per ether, and
	    //	tokenPrice = tokenPriceBeforePrecision / precision than what we end up as a final function
	    //	is tokensPerEther = 1 / ( tokenPriceBeforePrecision / precision )
	    //	which based on the rule that 1/(x/y) = y/x we can re write our formula as 
	    //	tokensPerEther = precision / tokenPriceBeforePrecision giving us a result while
	    //	avoiding any calulation resulting in a non whole number 
	    uint256 tokensPerEther = precision / tokenPriceBeforePrecision;
	    return tokensPerEther;
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
    
    //  Fallback function is entry point to buy tokens
    function () payable
    {
        buyTokens(msg.sender, msg.value);
    }

    //  Internal token purchase function
    function buyTokens(address beneficiary, uint256 value) payable
    {
        require(beneficiary != 0x0);
        require(value >= 0.1 ether);
        
        // Calculate token amount to be purchased
        uint256 weiAmount = value;
        uint256 actualRate = getRateAt(0)[3];
        uint256 amount = weiAmount.mul(actualRate);

        //  Check our supply
        //  Potentially redundant as balanceOf[0xb1].sub(amount) will
        //  throw with insufficient supply
        require(supply() >= amount);

        //  Check conditions for sale
        require(saleActive());
        
        // Transfer
        balanceOf[0xb1] = balanceOf[0xb1].sub(amount);
        balanceOf[beneficiary] = balanceOf[beneficiary].add(amount);
        //TokenPurchase(msg.sender, beneficiary, weiAmount, amount);

        // Update state.
        uint256 updatedWeiRaised = weiRaised.add(weiAmount);
        weiRaised = updatedWeiRaised;

        // Forward the fund to fund collection wallet.
        wallet.transfer(msg.value);
    }
    
    function addWhitelist(address beneficiary) onlyOwner
    {
        whitelist[beneficiary] = true;
    }
    
    function transfer( address _recipient, uint256 _value ) returns( bool )
    {
        //  Check to see if the sender is locked out from transferring tokens
        require(startDate + lockoutMap[msg.sender] < getCurrentTimestamp() );
        
        //  Check to see if the sale has ended
        require(getCurrentTimestamp() > endDate);
        
        //  transfer
        super.transfer( _recipient, _value );
        
        return true;
    }
    
    function setLockout(address target, uint256 time) onlyOwner
    {
        lockoutMap[target] = time;
    }
    
    function finalize() onlyOwner 
    {
        require(!saleActive());

        // Transfer the remainder of tokens to Ankorus wallet
        balanceOf[wallet] = balanceOf[wallet].add(balanceOf[0xb1]);
        balanceOf[0xb1] = 0;
    }

    function saleActive() public constant returns (bool) 
    {
        //  Ability to purchase has begun for this purchaser with either 2 
        //  conditions: Sale has started Or purchaser has been whitelisted to 
        //  purchase tokens before The start date
        bool checkSaleBegun = whitelist[msg.sender] || 
            getCurrentTimestamp() >= startDate;
        
        //  Sale of tokens can not happen after the ico date or with no
        //  supply in any case
        bool canPurchase = checkSaleBegun && 
            getCurrentTimestamp() < endDate &&
            supply() > 0;
            
        return(canPurchase);
    }
    
    event Transfer( address indexed _owner, address indexed _recipient, uint256 _value );
    event Approval( address _owner, address _spender, uint256 _value );
}
