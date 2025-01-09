// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface IERC721 {
    function transferFrom(address _from, address _to, uint _nftId) external;
}

contract EnglishAution {
    
    event Start();
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);
    //最高出价者只有一个人，不用去查询，所以不用索引(indexed)
    event End(address highestBidder, uint highestBid);

    //售卖的nft地址
    IERC721 public immutable nft;

    //售卖的nft id
    uint public immutable nftId;

    //卖家信息
    address payable public immutable seller;

    //结束时间
    uint32 public endAt;

    //是否已经开始售卖
    bool public started;

    //是否已经结束售卖
    bool public ended;

    //最高出价者
    address public highestBidder;

    //最高价
    uint public highestBid;

    //记录哪些出价者最高的地址和价格
    mapping(address => uint) public bids;

    constructor(
        address _nft,
        uint _nftId,
        uint _startingBid
    ) {
        nft = IERC721(_nft);
        nftId = _nftId;
        seller = payable(msg.sender);
        highestBid = _startingBid;
    }


    function start() external {
        require(seller == msg.sender, "not seller");
        require(!started, "started");

        started = true;
        endAt = uint32(block.timestamp + 60);
         
        //卖家的nft 从seller转到我们的合约里面来
        nft.transferFrom(seller, address(this), nftId);

        emit Start();
    }

    //出价函数
    function bid() external payable{
        //判断开始没
        require(started, "not started");
        //判断结束没
        require(block.timestamp < endAt, "ended");
        //判断钱包的钱要比起始价要多
        require(msg.value >= highestBid, "value < highestBid");

        //区分是否有人出价，address(0)是没人出价的情况
        if(highestBidder != address(0)){
            bids[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;
        emit Bid(msg.sender, msg.value);
    }

    //取钱函数
    function withdraw() external {
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);
        emit Withdraw(msg.sender, bal);
    }

    //结束函数
    function end() external {
        //判断开始没
        require(started, "not started");
        //判断结束没
        require(!ended, "ended");
        require(block.timestamp >= endAt, "not ended");

        ended = true;
        if(highestBidder != address(0)){
            nft.transferFrom(address(this), highestBidder, nftId);
             //以太转给seller
             seller.transfer(highestBid);
        }else{
            nft.transferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);
    }
        

}
