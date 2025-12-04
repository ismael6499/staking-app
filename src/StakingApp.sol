// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingApp is Ownable{
    
    address public stakingToken;
    uint256 public stakingPeriod;
    uint256 public fixedStakingAmount;
    uint256 public rewardPerPeriod;

    mapping(address => uint256) public userBalance;
    mapping(address => uint256) public userToBlockTimestamp;

    event ChangedStakingPeriod(uint256 _newStakingPeriod);
    event DepositTokens(address _userAddress, uint256 _amount);
    event WithdrawTokens(address _userAddress, uint256 _amount);

    constructor(address _stakingToken, address _owner, uint256 _stakingPeriod, uint256 _fixedStakingAmount, uint256 _rewardPerPeriod) Ownable(_owner){
        stakingToken = _stakingToken;
        stakingPeriod = _stakingPeriod;
        fixedStakingAmount = _fixedStakingAmount;
        rewardPerPeriod = _rewardPerPeriod;
    }

    function depositTokens(uint256 _tokenAmountToDeposit) external {
        require(_tokenAmountToDeposit == fixedStakingAmount, "Incorrect Amount");
        require(userBalance[msg.sender] == 0, "User already deposited");

        userBalance[msg.sender] += _tokenAmountToDeposit;
        IERC20(stakingToken).transferFrom(msg.sender, address(this), _tokenAmountToDeposit);
        userToBlockTimestamp[msg.sender] = block.timestamp;
        
        emit DepositTokens(msg.sender, _tokenAmountToDeposit);
    }

    function withdrawTokens() external {
        uint256 currentUserBalance = userBalance[msg.sender];
        userBalance[msg.sender] -= currentUserBalance;
        IERC20(stakingToken).transfer(msg.sender, currentUserBalance);
        
        emit WithdrawTokens(msg.sender, currentUserBalance);
    }

    function claimRewards() external {
        require(userBalance[msg.sender] == fixedStakingAmount, "Not staking");
        
        uint256 elapsedPeriod = block.timestamp - userToBlockTimestamp[msg.sender];
        require(elapsedPeriod >= stakingPeriod, "Need to wait");
        
        userToBlockTimestamp[msg.sender] = block.timestamp;
        
        (bool success,) = msg.sender.call{value: rewardPerPeriod}("");
        require(success, "Transfer failed");
    }

    function changeStakingPeriod(uint256 _newStakingPeriod) external onlyOwner {
        stakingPeriod = _newStakingPeriod;
        emit ChangedStakingPeriod(_newStakingPeriod);
    }

}