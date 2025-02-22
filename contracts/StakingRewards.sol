// SPDX-License-Identifier: UNLICENSED
//质押奖励
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingRewards {
    //质押token
    IERC20 public immutable stakingToken;
    //奖励token
    IERC20 public immutable rewardsToken;

    //状态变量
    address public owner;

    //奖励时长
    uint public duration;
    //奖励结束时间
    uint public finishAt;
    //合约更新时间
    uint public updatedAt;
    //奖励速率
    uint public rewardRate;
    //全局的RPT记录值
    uint public rewardPerTokenStored;

    //每个用户的RPT
    mapping(address => uint) public userRewardPerTokenPaid;
    //用户拿了多少奖励
    mapping(address => uint) public rewards;
    //一共质押了多少token
    uint public totalSupply;
    //用户质押了多少token
    mapping(address => uint) public balanceOf;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();
        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    constructor(address _stakingToken, address _rewardsToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    //owner 设置的奖励持续时间
    function setRewardsDuration(uint _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    //当owner设置奖励金额的时候，通过时长计算出 rewardsRate
    function notifyRewardAmount(uint _amount) external onlyOwner updateReward(address(0)) {
        if (block.timestamp > finishAt) {
            //已经完成一轮奖励
            rewardRate = _amount / duration;
        } else {
            //奖励还在持续发放中
            uint remainingRewards = rewardRate * (finishAt - block.timestamp);
            rewardRate = (remainingRewards + _amount) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * duration <= rewardsToken.balanceOf(address(this)),
            "reward amount > balance"
        );
        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    //质押stake
    function stake(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
    }

    //取出来withdraw, 用户提取质押在合约里面的token
    function withdraw(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(block.timestamp, finishAt);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            ((rewardRate * (lastTimeRewardApplicable() - updatedAt)) * 1e18) /
            totalSupply;
    }

    //用户earn奖励金额
    function earned(address _account) public view returns (uint) {
        return
            (balanceOf[_account] *
            (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18 +
            rewards[_account];
    }

    //奖励提出来
    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        if(reward > 0){
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
        }
    }
    
    
    function _min(uint x, uint y) private pure returns (uint) {
        // pure是不需要读取任何状态变量
        return x <= y ? x : y;
    }
}
