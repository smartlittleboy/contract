
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface IERC721 {
    function transferFrom(address from, address to, uint256 nftId) external;
}

contract DutchAution {
    uint256 private constant DURATION = 7 days;
    IERC721 public immutable nft;
    uint256 public immutable nftId; //售卖nft id

    address public immutable seller; //卖家地址
    uint256 public immutable startingPrice; //开始售卖价格
    uint256 public immutable startAt; //开始售卖时间
    uint256 public immutable expiresAt; //售卖结束时间
    uint256 public immutable discountRate; //折后汇率

    constructor(
        uint256 _startingPrice,
        uint256 _discountRate,
        address _nft,
        uint256 _nftId
    ){
         //用payable是为了接收用户购买的以太
          seller = payable(msg.sender);
          startingPrice = _startingPrice;
          discountRate = _discountRate;
          startAt = block.timestamp;
          expiresAt = block.timestamp + DURATION;
          require(
            _startingPrice >= _discountRate * DURATION,
           "starting price < discount");

          nft = IERC721(_nft);
          nftId = _nftId;
    }

     //查询价格函数
     function getPrice() public view returns (uint256){
         uint timelapsed  = block.timestamp - startAt;
         uint discount = discountRate * timelapsed;
         return startingPrice - discount;
     }

     //买家购买
     function buy() external payable {

        require(block.timestamp < expiresAt, "aution expired");
        uint price = getPrice();
        require(msg.value >= price, "ETH < Price");

        nft.transferFrom(seller, msg.sender, nftId);
        uint refund = msg.value - price;
        
        if(refund > 0){
            payable(msg.sender).transfer(refund);
        }
     }

}