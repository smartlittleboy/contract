// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
import "../tool/Counters.sol";

contract Voting {
    using Counters for Counters.Counter;

    Counters.Counter public _voterId; //投票id
    Counters.Counter public _candidateId; //候选id

    //投票组织方
    address public votingOrganizer;

    //定义候选人结构
    struct Candidate {
        uint256 candidateId; //id
        string age; //年龄
        string name; //姓名
        string image; //图片地址
        uint256 voteCount; //投票数
        address _address;
        string ipfs; //存储一些关键信息，为了省gas
    }

    event CandidateCreate(
        uint256 indexed candidateId,
        string age,
        string name,
        string image,
        uint256 voteCount,
        address _address,
        string ipfs
    );

    address[] public candidateAddress; //候选人地址集合
    mapping(address => Candidate) public candidates;
    address[] public votedVoters; //已经投票选民地址集合
    address[] public votersAddress;
    mapping(address => Voter) voters;

    struct Voter {
        uint256 voter_voterId; //id
        string voter_name; //姓名
        string voter_image; //图片地址
        uint256 voteCount; //投票数
        address voter_address;
        uint256 voter_allowed; //组织方是否允许选民投票  0: 默认不允许
        bool voter_voted; //是否已投票
        uint256 voter_vote; //用于追踪投票的人选
        string voter_ipfs; //选民的一些信息
    }

    event VoterCreate(
        uint256 voter_voterId,
        string voter_name,
        string voter_image,
        address voter_address,
        uint256 voter_allowed,
        bool voter_voted,
        uint256 voter_vote,
        string voter_ipfs
    );

    constructor() {
        votingOrganizer = msg.sender;
    }

    //添加候选人
    function setCandidate(
        address _address,
        string memory _age,
        string memory _name,
        string memory _image,
        string memory _ipfs
    ) public {
        require(
            votingOrganizer == msg.sender,
            "Only orgainzer can  set candidate"
        );
        _candidateId.increment();

        uint256 idNumber = _candidateId.current();
        Candidate storage candidate = candidates[_address];
        candidate.candidateId = idNumber;
        candidate.age = _age;
        candidate.name = _name;
        candidate.image = _image;
        candidate.voteCount = 0;
        candidate._address = _address;
        candidate.ipfs = _ipfs;

        candidateAddress.push(_address);

        emit CandidateCreate(
            candidate.candidateId,
            _age,
            _name,
            _image,
            candidate.voteCount,
            candidate._address,
            candidate.ipfs
        );
    }

    //获取所有候选人地址
    function getCandidate() public view returns (address[] memory) {
        return candidateAddress;
    }

    function getCandidateLength() public view returns (uint256) {
        return candidateAddress.length;
    }

    //获取候选人具体信息
    function getCandidateData(
        address _address
    )
        public
        view
        returns (
            string memory,
            string memory,
            uint256,
            string memory,
            uint256,
            string memory,
            address
        )
    {
        Candidate memory candidate = candidates[_address];
        return (
            candidate.age,
            candidate.name,
            candidate.candidateId,
            candidate.image,
            candidate.voteCount,
            candidate.ipfs,
            candidate._address
        );
    }

    //设置选民
    function voterRight(
        address _address,
        string memory _name,
        string memory _image,
        string memory _ipfs
    ) public {
        require(
            votingOrganizer == msg.sender,
            "Only orgainzer can create voter"
        );
        _voterId.increment();
        uint256 idNumber = _voterId.current();

        Voter storage voter = voters[_address];
        require(voter.voter_allowed == 0);
        voter.voter_allowed = 1;
        voter.voter_name = _name;
        voter.voter_image = _image;
        voter.voter_address = _address;
        voter.voter_voterId = idNumber;
        voter.voter_vote = 1000;
        voter.voter_voted = false;
        voter.voter_ipfs = _ipfs;

        votersAddress.push(_address);
        emit VoterCreate(
            voter.voter_voterId,
            _name,
            _image,
            _address,
            voter.voter_allowed,
            voter.voter_voted,
            voter.voter_vote,
            voter.voter_ipfs
        );
    }
 
    //投票
    function vote(address _candidateAddress, uint _candidateVoteId) external {

        Voter storage voter = voters[msg.sender];
        require(!voter.voter_voted, "you have already voted");
        //判断有没有投票权利
        require(voter.voter_allowed != 0, "you have not right to vote");

        voter.voter_voted = true;
        voter.voter_vote = _candidateVoteId;

        votedVoters.push(msg.sender);
         //voter_allowed 初始化的时候给的是1票
        candidates[_candidateAddress].voteCount += voter.voter_allowed;
    }

    function getVoterLength() public view returns (uint256) {
        return votersAddress.length;
    }

     function getVoterData(
        address _address
    )
        public
        view
        returns (
            uint256,
            string memory,
            string memory,
            address,
            string memory,
            uint256,
            bool
        )
    {

        Voter storage voter = voters[_address];
        return(
            voter.voter_voterId,
            voter.voter_name,
            voter.voter_image,
            voter.voter_address,
            voter.voter_ipfs,
            voter.voter_allowed,
            voter.voter_voted
        );
    }

     function getVotedVoterList() public view returns (address[] memory) {
        return votedVoters;
     }

     function getVoterList() public view returns (address[] memory) {
        return votersAddress;
     }

     //计算哪个候选人获取投票最多
     function getMostCandidates() external view returns (Candidate  memory){
        
        require(candidateAddress.length > 0, "canditates <= 0");
        uint256 max = 0;
        address maxAddress = candidateAddress[0];
        Candidate memory maxCandidate = candidates[maxAddress];
        for (uint256 i = 0; i < candidateAddress.length; i++) {
             Candidate memory candidate = candidates[candidateAddress[i]];
             if (candidate.voteCount > max) {
                max = candidate.voteCount; 
                maxCandidate = candidates[candidateAddress[i]];
             }
        }
         return maxCandidate;
     }

}
