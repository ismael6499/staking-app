// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Staking Application
/// @author Agustin Acosta
/// @notice A fixed-amount staking contract with time-based ETH rewards
contract StakingApp is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- Custom Errors ---
    error IncorrectAmount(uint256 expected, uint256 provided);
    error UserAlreadyDeposited();
    error NotStaking();
    error StakingPeriodNotFinished(uint256 timeRemaining);
    error TransferFailed();
    error InvalidConfiguration();

    // --- State Variables ---
    IERC20 public immutable stakingToken;
    
    uint256 public stakingPeriod;
    uint256 public fixedStakingAmount;
    uint256 public rewardPerPeriod;

    mapping(address => uint256) public userBalance;
    mapping(address => uint256) public userLastActionTimestamp;

    // --- Events ---
    event StakingPeriodChanged(uint256 newPeriod);
    event TokensDeposited(address indexed user, uint256 amount);
    event TokensWithdrawn(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ContractFunded(address indexed funder, uint256 amount);

    constructor(
        address _stakingToken, 
        uint256 _stakingPeriod, 
        uint256 _fixedStakingAmount, 
        uint256 _rewardPerPeriod
    ) Ownable(msg.sender) {
        if (_stakingToken == address(0)) revert InvalidConfiguration();
        
        stakingToken = IERC20(_stakingToken);
        stakingPeriod = _stakingPeriod;
        fixedStakingAmount = _fixedStakingAmount;
        rewardPerPeriod = _rewardPerPeriod;
    }

    /// @notice Allows users to deposit the fixed amount of tokens
    /// @dev Uses SafeERC20 to handle transfers
    function depositTokens(uint256 _tokenAmountToDeposit) external nonReentrant {
        if (_tokenAmountToDeposit != fixedStakingAmount) {
            revert IncorrectAmount(fixedStakingAmount, _tokenAmountToDeposit);
        }
        if (userBalance[msg.sender] > 0) {
            revert UserAlreadyDeposited();
        }

        // Effect: Update state before interaction
        userBalance[msg.sender] = _tokenAmountToDeposit;
        userLastActionTimestamp[msg.sender] = block.timestamp;
        
        // Interaction
        stakingToken.safeTransferFrom(msg.sender, address(this), _tokenAmountToDeposit);
        
        emit TokensDeposited(msg.sender, _tokenAmountToDeposit);
    }

    /// @notice Allows users to withdraw their staked tokens
    /// @dev Users can withdraw at any time, but it resets their staking timer
    function withdrawTokens() external nonReentrant {
        uint256 currentUserBalance = userBalance[msg.sender];
        if (currentUserBalance == 0) revert NotStaking();

        // Effect
        userBalance[msg.sender] = 0;
        userLastActionTimestamp[msg.sender] = 0;

        // Interaction
        stakingToken.safeTransfer(msg.sender, currentUserBalance);
        
        emit TokensWithdrawn(msg.sender, currentUserBalance);
    }

    /// @notice Claims ETH rewards if the staking period has passed
    function claimRewards() external nonReentrant {
        if (userBalance[msg.sender] == 0) revert NotStaking();

        uint256 timeElapsed = block.timestamp - userLastActionTimestamp[msg.sender];
        
        if (timeElapsed < stakingPeriod) {
            revert StakingPeriodNotFinished(stakingPeriod - timeElapsed);
        }
        
        // Reset the timer for the next period
        userLastActionTimestamp[msg.sender] = block.timestamp;
        
        (bool success, ) = msg.sender.call{value: rewardPerPeriod}("");
        if (!success) revert TransferFailed();

        emit RewardsClaimed(msg.sender, rewardPerPeriod);
    }

    /// @notice Allows the owner to update the required staking duration
    function changeStakingPeriod(uint256 _newStakingPeriod) external onlyOwner {
        stakingPeriod = _newStakingPeriod;
        emit StakingPeriodChanged(_newStakingPeriod);
    }

    /// @notice Allows the contract to receive ETH for rewards
    receive() external payable {
        emit ContractFunded(msg.sender, msg.value);
    }
}