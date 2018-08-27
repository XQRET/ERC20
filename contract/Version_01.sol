pragma solidity ^0.4.24;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
   防止整数溢出问题
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


//设置代币控制合约的管理员
contract Owned {
 
    // modifier(条件)，表示必须是权力所有者才能do something，类似administrator的意思
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;//do something 
    }
 
	//权力所有者
    address public owner;
 
	//合约创建的时候执行，执行合约的人是第一个owner
    constructor() public {
        owner = msg.sender;
    }
	//新的owner,初始为空地址，类似null
    address newOwner=0x0;
 
	//更换owner成功的事件
    event OwnerUpdate(address _prevOwner, address _newOwner);
 
    //现任owner把所有权交给新的owner(需要新的owner调用acceptOwnership方法才会生效)
    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }
 
    //新的owner接受所有权,权力交替正式生效
    function acceptOwnership(address tempAddress) public{
        newOwner = tempAddress;
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

/**
 * @title ERC代币
 * xingqiao
 */
contract UtilityToken is ERC20,Owned {
  
  using SafeMath for uint256;

   uint256 totalSupply_;
   string public name = "UtilityToken"; // 代币名称
   string public symbol = "RET";        // 简写名称RET
   uint8  public  decimals = 18;           // 支持小数点后几位 例如 0.0001
   uint256 public INITIAL_SUPPLY = 400000000; //代币发行总量


   //分配账户
   bool public DistributionAccountEnabled = true;

   //声明五个账号余额
   uint256  public tokenSaleBalance;
   uint256  public technicalAndEcoSystemBalance;
   uint256  public foundationReserveBalance;
   uint256  public teamBalance;
   uint256  public partnershipBalance;
    mapping (address => mapping (address => uint256)) internal allowed;
    
   //设置黑名单集合
    mapping (address => bool) public frozenAccount;
  
    //设置黑名单通知事件
    event FrozenFunds(address target, bool frozen);
  
    /* 在区块链上创建一个事件，用以通知客户端*/
    event Transfer(address indexed from, address indexed to, uint256 value);  //转帐通知事件
    
    mapping(address => uint256) balances;  


    /* 初始化合约，并且把初始的所有代币都给这合约的创建者
     * @param totalSupply_ 代币的总数
     * @param tokenName 代币名称
     * @param tokenSymbol 代币符号
     */
    constructor() public {
         totalSupply_ = INITIAL_SUPPLY* 10** uint256(decimals);
         balances[msg.sender] = totalSupply_;  // 将合约创建者的代币数量设置为发行量，即发行时所有的代币归创建者所有
     }

  
  //设置黑名单
  function freezeAccount(address target, bool freeze) public onlyOwner {
    frozenAccount[target] = freeze;
    emit FrozenFunds(target, freeze);
  }
  
    /**
  * @dev Gets 指定地址的余额.
  * @param _owner 查询余额的地址.
  * @return An uint256 表示已通过的地址所拥有的金额.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  /**
   * @dev Function 检查所有者允许使用的token数量。.
   * @param _owner address 拥有资金的地址.
   * @param _spender address 将花费资金的地址.
   * @return A uint256 指定仍可用于支出器的令牌数量.
   */
  function allowance(address _owner, address _spender) public view returns (uint256){
    return allowed[_owner][_spender];
  }

    /**
     * 从主帐户合约调用者发送给别人代币
     * @param  _to address 接受代币的地址
     * @param  _value uint256 接受代币的数量
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
     * 从某个指定的帐户中，向另一个帐户发送代币
     * 调用过程，会检查设置的允许最大交易额
     * @param  _from address 发送者地址
     * @param  _to address 接受者地址
     * @param  _value uint256 要转移的代币数量
     * @return success        是否交易成功
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
     * 设置帐户允许支付的最大金额
     * 一般在智能合约的时候，避免支付过多，造成风险
     * @param _spender 帐户地址
     * @param _value 金额
     */
  function approve(address _spender, uint256 _value) public onlyOwner returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }


   //管理员分发代币方法到五个账户,1,对外销售,2科研,3基金会储备,4团队,5合伙
   function  distributionToFiveAccount(address _tokenSale,address _technicalAndEcoSystem,address _foundationReserve,address _team,address _partnership ) public onlyOwner returns (bool success){
        require(_tokenSale != address(0));
        require(_technicalAndEcoSystem != address(0));
        require(_foundationReserve != address(0));
        require(_team != address(0));
        require(_partnership != address(0));
        require(totalSupply_>0);

        if(DistributionAccountEnabled){
        //计算分配数目
        tokenSaleBalance= totalSupply_.div(4);
        technicalAndEcoSystemBalance=totalSupply_.mul(35).div(100);
        foundationReserveBalance=totalSupply_.mul(20).div(100);
        teamBalance=totalSupply_.mul(10).div(100);
        partnershipBalance=totalSupply_.mul(10).div(100);
        //赋值
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

