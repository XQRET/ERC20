pragma solidity ^0.4.24;
/**
1.Create tokens
2.There is five account(foreign sales,research,foundation reserves,group,partnership)
after the success of the tokens created,call the corresponding method,according to the regulation
will automatically distribute tokens by different proportion to five accounts
3.Implement token transfer
*/
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
   To prevent the integer overflow
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
 
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
     assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title ERC20 interface
 */
contract ERC20 {

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


//Set the administrator of contract for token
contract Owned {
 
    // `modifier`(conditions),It's meaning that the owner just do it which is like administrator
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;//do something 
    }
 
	// The owner of the power
    address public owner;
 
	//when the contract is created,the creator is the owner.
    constructor() public {
        owner = msg.sender;
    }
	//similar to null,the new onwer that we initial address is empty
    address newOwner=0x0;
 
	//when the owner changed tell me
    event OwnerUpdate(address _prevOwner, address _newOwner);
 
    //current owner give the onwership to the new onwer which need the new onwer call `acceptOwnership` function to take effect(just only this way)
    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }
 
    // new owner to accept onwership
    function acceptOwnership(address tempAddress) public{
        newOwner = tempAddress;
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

/**
 * @title ERC token
 * XQ
 */
contract UtilityToken is ERC20,Owned {
  
  using SafeMath for uint256;

   uint256 totalSupply_;
   string public name = "UtilityToken"; // name of tokens
   string public symbol = "RET";        // short name just you look
   uint8  public  decimals = 18;           // support a few deciaml places,for example 0.0001
   uint256 public INITIAL_SUPPLY = 400000000; //total amount


   //flag to assigned account
   bool public DistributionAccountEnabled = true;

   //declare five account balance
   uint256  public tokenSaleBalance;
   uint256  public technicalAndEcoSystemBalance;
   uint256  public foundationReserveBalance;
   uint256  public teamBalance;
   uint256  public partnershipBalance;
    mapping (address => mapping (address => uint256)) internal allowed;
    
   //set the blacklist
    mapping (address => bool) public frozenAccount;
  
    //blacklist notification events
    event FrozenFunds(address target, bool frozen);
  
    /* create an event on block chain to inform the client*/
    event Transfer(address indexed from, address indexed to, uint256 value);  //transfer notification event
    
    mapping(address => uint256) balances;  


    /* initial contract and give all tokens to the founder of this contract
     * @param totalSupply_ total number of tokens
     * @param tokenName name of tokens
     * @param tokenSymbol short name just you look
     */
    constructor() public {
         totalSupply_ = INITIAL_SUPPLY* 10** uint256(decimals);
         balances[msg.sender] = totalSupply_;  // set the number of tokens to the creator,all token is the creator
     }

  
  //set the blacklist
  function freezeAccount(address target, bool freeze) public onlyOwner {
    frozenAccount[target] = freeze;
    emit FrozenFunds(target, freeze);
  }
  
    /**
  * @dev Get the balance of address
  * @param _owner the address that you need to search
  * @return An uint256 the balance of the specified address
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  /**
   * @dev Function check the owner that allows to use of the number of token
   * @param _owner address address with money
   * @param _spender address the address that willcost money
   * @return A uint256 the specified number that can be used,rest of token
   */
  function allowance(address _owner, address _spender) public view returns (uint256){
    return allowed[_owner][_spender];
  }

    /**
     * from the contract caller send the token to _to
     * @param  _to address the address of accepting tokens
     * @param  _value uint256 accept the number of tokens
     */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));
    require(!frozenAccount[msg.sender]);
    require(!frozenAccount[_to]);
    
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
    /**
     * from a specified account to another account to send tokens
     * when call process that will check the max amount can be used
     * @param  _from address the address of sender
     * @param  _to address the address of recipient
     * @param  _value uint256 the number of tokens to transfer
     * @return success        success or false
     */
  function transferFrom(address _from, address _to,uint256 _value) public returns (bool) {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));
    require(!frozenAccount[_from]);
    require(!frozenAccount[_to]);    
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

    /**
     * set the account pay the max amount are allowed
     * when in contract we need to avoid pay more that is not you want so will cause risk
     * @param _spender the account address
     * @param _value amount
     */
  function approve(address _spender, uint256 _value) public onlyOwner returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }


   // administrator distribute tokens methods to five accounts(foreign sales,research,foundation reserves,group,partnership)
   function  distributionToFiveAccount(address _tokenSale,address _technicalAndEcoSystem,address _foundationReserve,address _team,address _partnership ) public onlyOwner returns (bool success){
        require(_tokenSale != address(0));
        require(_technicalAndEcoSystem != address(0));
        require(_foundationReserve != address(0));
        require(_team != address(0));
        require(_partnership != address(0));
        require(totalSupply_>0);

        if(DistributionAccountEnabled){
        // computing distribution number
        tokenSaleBalance= totalSupply_.div(4);
        technicalAndEcoSystemBalance=totalSupply_.mul(35).div(100);
        foundationReserveBalance=totalSupply_.mul(20).div(100);
        teamBalance=totalSupply_.mul(10).div(100);
        partnershipBalance=totalSupply_.mul(10).div(100);
        // assignment
        transfer(_tokenSale, tokenSaleBalance);
        transfer(_technicalAndEcoSystem, technicalAndEcoSystemBalance);
        transfer(_foundationReserve, foundationReserveBalance);
        transfer(_team, teamBalance);
        //
        transfer(_partnership, partnershipBalance);
        return true;
        }

   }

}

