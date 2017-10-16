pragma solidity ^0.4.16;

import './ERC20Interface.sol';
import './SafeMath.sol';
import './Owned.sol';

contract BasicToken
{
    using SafeMath for uint256;
    
     //  Total number of Tokens
    uint totalCoinSupply;
    
    //  allowance map
    //  ( owner => (spender => amount ) ) 
    mapping (address => mapping (address => uint256)) public AllowanceLedger;
    
    //  ownership map
    //  ( owner => value )
    mapping (address => uint256) public balanceOf;

    //  @dev transfer token for a specified address
    //  @param _to The address to transfer to.
    //  @param _value The amount to be transferred.
    function transfer( address _recipient, uint256 _value ) returns( bool success )
    {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_recipient] = balanceOf[_recipient].add(_value);
        //Transfer(msg.sender, _recipient, _value);
        return true;
    }
    
    function transferFrom( address _owner, address _recipient, uint256 _value ) returns( bool success )
    {
        var _allowance = AllowanceLedger[_owner][msg.sender];
        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balanceOf[_recipient] = balanceOf[_recipient].add(_value);
        balanceOf[_owner] = balanceOf[_owner].sub(_value);
        AllowanceLedger[_owner][msg.sender] = _allowance.sub(_value);
        //Transfer(_owner, _recipient, _value);
        return true;
    }
    
    function approve( address _spender, uint256 _value ) returns( bool success )
    {
        //  _owner is the address of the owner who is giving approval to
        //  _spender, who can then transact coins on the behalf of _owner
        address _owner = msg.sender;
        AllowanceLedger[_owner][_spender] = _value;
        
        //  Fire off Approval event
        //Approval( _owner, _spender, _value);
        return true;
    }
    
    function allowance( address _owner, address _spender ) constant returns ( uint256 remaining )
    {
        //  returns the amount _spender can transact on behalf of _owner
        return AllowanceLedger[_owner][_spender];
    }
    
    function totalSupply() constant returns( uint256 total )
    {  
        return totalCoinSupply;
    }

    //  @dev Gets the balance of the specified address.
    //  @param _owner The address to query the the balance of. 
    //  @return An uint256 representing the amount owned by the passed address.
    function balanceOf(address _owner) constant returns (uint256 balance)
    {
        return balanceOf[_owner];
    }

}