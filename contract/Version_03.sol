pragma solidity ^0.4.24;
/**
 * 1.Create tokens.
 * 2.There is five account(foreign sales,research,foundation reserves,group,partnership)
 *   after the success of the tokens created,call the corresponding method,according to the regulation
 *   will automatically distribute tokens by different proportion to five accounts.
 * 3.Implement token transfer.
 * /
 
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * To prevent the integer overflow
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
    function acceptOwnership() public{
        //require(msg.sender == newOwner);
        require(msg.sender != newOwner);
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
    function distributionToFiveAccount(address _tokenSale,address _technicalAndEcoSystem,address _foundationReserve,address _team,address _partnership ) public onlyOwner returns (bool success){
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
            // Transfer accounts
            transfer(_partnership, partnershipBalance);
            return true;
        }
    
    }

}

interface token {
    function transfer(address receiver, uint amount) external;
}

contract ICOToken is Owned {
    
    using SafeMath for uint256;
    
    // Defining crowdfunding variables
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    token public tokenReward;
    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;
    
    // Defining lock bin variables
    // The lock chamber has three stages, three stages of status
    bool public triggerOneEnabled;
    bool public triggerTwoEnabled;
    bool public triggerThreeEnabled;
    // The time triggered by each of the three phases
    uint public triggerOneTime;
    uint public triggerTwoTime;
    uint public triggerThreeTime;
    
    uint public triggerTime;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    // Notification events triggered by each of the three phases
    event UpdateTriggerOneTimes(address indexed _from, uint value);
    event UpdateTriggerTwoTimes(address indexed _from, uint value);
    event UpdateTriggerThreeTimes(address indexed _from, uint value);
        
    mapping(address => uint256) balanceOf;
    mapping(address => uint256) balances;
    mapping(address => uint256) fixedAccount;
    mapping(address => uint256) availableBalanceAccount;
    
    address[] public funder;
    
    modifier afterDeadline() { if (now >= deadline) _; }
    
    constructor(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint finneyCostOfEachToken,
        bool _triggerOneEnabled,
        bool _triggerTwoEnabled,
        bool _triggerThreeEnabled,
        address addressOfTokenUsedAsReward) public {
            beneficiary = ifSuccessfulSendTo;
            fundingGoal = fundingGoalInEthers.mul(1 ether);
            deadline = now + durationInMinutes.mul(1 minutes);
            price = finneyCostOfEachToken;
            triggerOneEnabled = _triggerOneEnabled;
            triggerTwoEnabled = _triggerTwoEnabled;
            triggerThreeEnabled = _triggerThreeEnabled;
            tokenReward = token(addressOfTokenUsedAsReward);
    }
    
    event LogPay(address sender, uint value, uint blance, uint amount, bool isClosed);
    function () public payable {
        require(!crowdsaleClosed);
        funder.push(msg.sender);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(msg.value);
        amountRaised = amountRaised.add(msg.value);
        if(amountRaised >= fundingGoal) {
            crowdsaleClosed = true;
            fundingGoalReached = true;
        }
        emit LogPay(msg.sender, msg.value, balanceOf[msg.sender], amountRaised, crowdsaleClosed);
    }
    
    function getThisBalance() public constant returns (uint) {
        return this.balance;
    }
    
    function getFundingGoal() public constant returns (uint) {
        return fundingGoal;
    }
    
    function getNow() public constant returns (uint, uint) {
        return (now, deadline);
    }
    
    function setDeadline(uint minute) public onlyOwner {
        deadline = minute.mul(1 minutes).add(now);
    }
    
    function getAvailableBalanceAccount(address addr) public view returns (uint256) {
        return availableBalanceAccount[addr];
    }
    
    function getBalances(address addr) public view returns (uint256) {
        return balances[addr];
    }
    
    function safeWithdrawal() public onlyOwner afterDeadline {
        triggerTime = now;
        if(amountRaised >= fundingGoal) {
            crowdsaleClosed = true;
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        } else {
            crowdsaleClosed = false;
            fundingGoalReached = false;
        }
        uint i;
        if(fundingGoalReached) {
            if(amountRaised > fundingGoal && funder.length>0) {
                address returnFunder = funder[funder.length.sub(1)];
                uint overFund = amountRaised.sub(fundingGoal);
                if(returnFunder.send(overFund)) {
                    balanceOf[returnFunder] = balanceOf[returnFunder].sub(overFund);
                    amountRaised = fundingGoal;
                }
            }
            for(i = 0; i < funder.length; i++) {
                tokenReward.transfer(funder[i], balanceOf[funder[i]].mul(1000).mul(price));
                fixedAccount[funder[i]] = balanceOf[funder[i]].mul(1000).mul(price);
                balances[funder[i]] = fixedAccount[funder[i]];
                balanceOf[funder[i]] = 0;
            }
            if (beneficiary.send(amountRaised)) {
                emit FundTransfer(beneficiary, amountRaised, false);
            } else {
                fundingGoalReached = false;
            }
            
        } else {
            for(i = 0; i < funder.length; i++) {
                if (balanceOf[funder[i]] > 0 && funder[i].send(balanceOf[funder[i]])) {
                    amountRaised = 0;
                    balanceOf[funder[i]] = 0;
                    emit FundTransfer(funder[i], balanceOf[funder[i]], false);
                }
            }
        }
    }
    
    // The first stage
    function updateTriggerOneTimes(address user) public {
        // Complete lock
        require(triggerOneEnabled);
        require(!triggerTwoEnabled);
        require(!triggerThreeEnabled);
        uint currentTime = now;
        triggerOneTime = triggerTime;
        if(triggerOneTime + 90 days >= currentTime) {
            availableBalanceAccount[user] = fixedAccount[user].mul(25).div(100);
        }
        
        if(triggerOneTime + 90 days < currentTime && currentTime <= triggerOneTime + 180 days) {
            availableBalanceAccount[user] = availableBalanceAccount[user].add(fixedAccount[user].mul(25).div(100));
        }
        
        if(triggerOneTime + 180 days < currentTime && currentTime <= triggerOneTime + 270 days) {
            availableBalanceAccount[user] = availableBalanceAccount[user].add(fixedAccount[user].mul(25).div(100));
        }
        
        if(currentTime >= triggerOneTime + 270 days) {
            availableBalanceAccount[user] = availableBalanceAccount[user].add(fixedAccount[user].mul(25).div(100));
        }
        
        emit UpdateTriggerOneTimes(msg.sender,triggerOneTime);
    }
    
    // second stage
    function updateTriggerTwoTimes(address user) public {
        // Complete lock
        require(triggerOneEnabled);
        require(triggerTwoEnabled);
        require(!triggerThreeEnabled);
        uint currentTime = now;
        triggerTwoTime = triggerTime;
        if(triggerTwoTime + 90 days >= currentTime) {
            availableBalanceAccount[user] = fixedAccount[user].mul(30).div(100);
        }
        
        if(triggerTwoTime + 90 days < currentTime && currentTime <= triggerTwoTime + 180 days) {
            availableBalanceAccount[user] = availableBalanceAccount[user].add(fixedAccount[user].mul(35).div(100));
        }
        
        if(currentTime >= triggerTwoTime + 180 days) {
            availableBalanceAccount[user] = availableBalanceAccount[user].add(fixedAccount[user].mul(35).div(100));
        }
        
        emit UpdateTriggerTwoTimes(msg.sender,triggerTwoTime);
    }
    
    // The third phase
    function updateTriggerThreeTimes(address user) public {
        // Complete lock
        require(triggerOneEnabled);
        require(triggerTwoEnabled);
        require(triggerThreeEnabled);
        triggerThreeTime = triggerTime;
        availableBalanceAccount[user] = fixedAccount[user];
        
        emit UpdateTriggerThreeTimes(msg.sender,triggerThreeTime);
    }
    
    // Transaction between investors
    function transaction(address _to,uint256 compareValue, uint256 _value) public returns (bool) {
        if(_value <= availableBalanceAccount[msg.sender] && availableBalanceAccount[msg.sender] >= compareValue && _value <= compareValue ) {
            tokenReward.transfer(_to, _value);
            availableBalanceAccount[msg.sender] = availableBalanceAccount[msg.sender].sub(_value);
            balances[msg.sender] = balances[msg.sender].sub(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            tokenReward.transfer(msg.sender, compareValue);
            emit Transfer(tokenReward, msg.sender, compareValue);
            return false;
        }
        
    }
    
}


