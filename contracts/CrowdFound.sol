// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface IERC20 {
    function transfer(address,uint) external returns (bool); 
    function transferFrom(address,address,uint) external returns (bool);
}

contract CrowdFound {

    event Launch(uint id, address indexed creator, uint goal, uint32 startAt, uint32 endAt);
    event Cancel(uint id);
    event Pledge(uint indexed id, address indexed caller, uint amount);
    event UnPledge(uint indexed id, address indexed caller, uint amount);
    event Claim(uint id);
    event Refund(uint indexed id, address indexed caller, uint amount);

    struct Campaign {
     address creator;//活动发起地址
     uint goal;      //目标金额
     uint  pledged;  //已经参与金额
     uint32 startAt;
     uint32 endAt;
     bool claimed;   //发起方有没有领取金额
    }

     //同一种IERC20 token 作为项目募集的 token
     IERC20 public immutable token;

     //记录多少个活动在发起中
     uint count;

     //id 指向 活动结构体
     mapping (uint => Campaign) public campaigns;

     //每个用户参与了多少金额, 第一个uinit 代表活动id  用户地址 参与金额
     mapping(uint => mapping(address => uint)) public pledgedAmount;

     constructor (address _token){
        token = IERC20(_token);
     }

    //项目发起方
    function launch(
        uint _goal, //需要众筹的金额
        uint32 _startAt, //开始时间
        uint32 _endAt //结束时间
    ) external {
         //活动必须是还没开始的
         require(_startAt >= block.timestamp, "start at < now");
         //结束时间大于开始时间
         require(_endAt >= _startAt,"end at < start at");
         //设置活动持续时间最大为90天
         require(_endAt <= block.timestamp + 90, "end at > max duration");

         count += 1;
         campaigns[count] = Campaign({
            creator: msg.sender,
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
         });

         emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    } 

    //取消
    function cancel(uint _id) external {
        //通过id拿到活动
        Campaign memory campaign = campaigns[_id];

        //检查地址是不是发起方
        require(campaign.creator == msg.sender,"not creator");
        //检查活动还没开始，活动开始了就不能取消了
        require(campaign.startAt > block.timestamp, "started");

        delete campaigns[_id];
        emit Cancel(_id);
    }

    //用户参与
    function pledge(uint _id,uint _amount) external {
         Campaign memory campaign = campaigns[_id];

         //检查活动已经开始
         require(campaign.startAt <= block.timestamp,"not started");

         //检查活动还没结束
         require(campaign.endAt >= block.timestamp,"ended");

         campaign.pledged += _amount;
         pledgedAmount[_id][msg.sender] += _amount;
         token.transferFrom(msg.sender, address(this), _amount);

         emit Pledge(_id, msg.sender, _amount);
    } 

    //用户取消参与
    function  unpledge(uint _id, uint _amount) external{
         Campaign memory campaign = campaigns[_id];
         //检查活动还没结束
         require(campaign.endAt >= block.timestamp,"ended");

          campaign.pledged -= _amount;
          pledgedAmount[_id][msg.sender] -= _amount;

          token.transfer(msg.sender, _amount);
          emit UnPledge(_id, msg.sender, _amount);
    }

    //众筹的目标把以太转回去（项目发起方）
    //活动结束后，如果达成目标了，发起方是可以申领我们的金额
    function claimed(uint _id) external {
        Campaign memory campaign = campaigns[_id];

        //检查地址是不是发起方
        require(campaign.creator == msg.sender,"not creator");
        //活动必须已经结束掉
        require(campaign.endAt < block.timestamp, "not ended");
        //达成目标金额
        require(campaign.pledged >= campaign.goal,"pledged < goal");
        //不能申领两次
        require(!campaign.claimed,"claimed");

        campaign.claimed = false;
        token.transfer(msg.sender, campaign.pledged);

        emit Claim(_id);
    }

    //用户把参数项目的金额退回来
    //时间到了，参与的目标没有达成，用户就可以退回自己参加过的金额
    function refund(uint _id) external{

         Campaign memory campaign = campaigns[_id];
         //活动必须已经结束掉
         require(campaign.endAt < block.timestamp, "not ended");
         //目标没有达成
         require(campaign.pledged < campaign.goal,"pledged < goal");

         uint bal = pledgedAmount[_id][msg.sender];
         pledgedAmount[_id][msg.sender] = 0;
         token.transfer(msg.sender, bal);
        
        emit Refund(_id, msg.sender, bal);
    }
}

