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
    uint256 public whitelistDate;

    // Amount of raised money in wei.
    uint256 public weiRaised;
    
    //  Tokens rate formule
    uint256 public tokensSold = 0;
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
        //  **************** TEST CODE *******************************************
        //  Ropsten multisig 0x766C0CBcb73608611Ca09D7C7d8C18eeB5b08155
        //  Rinkeby multisig 0xf1C0C02355EF9cA31371C5660a36C1e83333e4e1
        address twallet = 0x766C0CBcb73608611Ca09D7C7d8C18eeB5b08155;
        initialize( twallet, now + 1 hours, now + 2 hours, 50000000 ether, 100000000 ether);
        //  ************************* END TEST CODE ******************************
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
    
    function getRateAt() constant returns (uint256)
    {
        uint256 traunch = tokensSold.div(tokensPerTraunch);
        
        //  Price curve based on function at:
        //  https://github.com/AnkorusTokenIco/Smart-Contract/blob/master/Price_curve.png
        
        if     ( traunch == 0 )  {return 600;}
        else if( traunch == 1 )  {return 598;}
        else if( traunch == 2 )  {return 596;}
        else if( traunch == 3 )  {return 593;}
        else if( traunch == 4 )  {return 588;}
        else if( traunch == 5 )  {return 583;}
        else if( traunch == 6 )  {return 578;}
        else if( traunch == 7 )  {return 571;}
        else if( traunch == 8 )  {return 564;}
        else if( traunch == 9 )  {return 556;}
        else if( traunch == 10 ) {return 547;}
        else if( traunch == 11 ) {return 538;}
        else if( traunch == 12 ) {return 529;}
        else if( traunch == 13 ) {return 519;}
        else if( traunch == 14 ) {return 508;}
        else if( traunch == 15 ) {return 498;}
        else if( traunch == 16 ) {return 487;}
        else if( traunch == 17 ) {return 476;}
        else if( traunch == 18 ) {return 465;}
        else if( traunch == 19 ) {return 454;}
        else if( traunch == 20 ) {return 443;}
        else if( traunch == 21 ) {return 432;}
        else if( traunch == 22 ) {return 421;}
        else if( traunch == 23 ) {return 410;}
        else if( traunch == 24 ) {return 400;}
        else return 400;
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
        whitelistDate = startDate - 1 days;
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
        uint256 actualRate = getRateAt();
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
        TokenPurchase(msg.sender, weiAmount, amount);

        // Update state.
        uint256 updatedWeiRaised = weiRaised.add(weiAmount);
        uint256 updatedTokensSold = tokensSold.add(amount);
        weiRaised = updatedWeiRaised;
        tokensSold = updatedTokensSold;

        // Forward the fund to fund collection wallet.
        wallet.transfer(msg.value);
    }
    
    function setWhitelist(address beneficiary, bool inList) onlyOwner
    {
        whitelist[beneficiary] = inList;
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
    
    function push(address buyer, uint256 amount, uint256 lockout) onlyOwner 
    {
        require(balanceOf[wallet] >= amount);

        // Transfer
        balanceOf[wallet] = balanceOf[wallet].sub(amount);
        balanceOf[buyer] = balanceOf[buyer].add(amount);
        CompanyTokenPushed(buyer, amount);
        
        //  Set lockout if there's a lockout time
        if( lockout > 0 )
            setLockout( buyer, lockout );
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
        //  conditions: Sale has started 
        //  Or purchaser has been whitelisted to purchase tokens before The start date
        //  and the whitelistDate is active
        bool checkSaleBegun = ( whitelist[msg.sender] && getCurrentTimestamp() > whitelistDate ) || 
            getCurrentTimestamp() >= startDate;
        
        //  Sale of tokens can not happen after the ico date or with no
        //  supply in any case
        bool canPurchase = checkSaleBegun && 
            getCurrentTimestamp() < endDate &&
            supply() > 0;
            
        return(canPurchase);
    }
}






