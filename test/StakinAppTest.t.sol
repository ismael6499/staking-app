// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/StakingToken.sol";
import "../src/StakingApp.sol";

contract StakingAppTest is Test {

    StakingApp public stakingApp;
    StakingToken public stakingToken;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");
    
    uint256 public constant STAKING_PERIOD = 7 days;
    uint256 public constant FIXED_AMOUNT = 100 ether;
    uint256 public constant REWARD_AMOUNT = 0.5 ether;

    event TokensDeposited(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ContractFunded(address indexed funder, uint256 amount);

    function setUp() public {
        // Deploy Token
        vm.startPrank(owner);
        stakingToken = new StakingToken("Staking Token", "STK");
        
        // Deploy App
        stakingApp = new StakingApp(
            address(stakingToken), 
            STAKING_PERIOD, 
            FIXED_AMOUNT, 
            REWARD_AMOUNT
        );
        vm.stopPrank();

        // Setup: Mint tokens to user and approve app
        vm.startPrank(owner);
        stakingToken.mint(user, 1000 ether);
        vm.stopPrank();

        vm.startPrank(user);
        stakingToken.approve(address(stakingApp), type(uint256).max);
        vm.stopPrank();

        // Setup: Fund StakingApp with ETH for rewards
        vm.deal(address(stakingApp), 10 ether);
    }

    // ==========================================
    //           DEPLOYMENT & CONFIG
    // ==========================================

    function test_Deployment_SetsCorrectValues() public view {
        assertEq(address(stakingApp.stakingToken()), address(stakingToken));
        assertEq(stakingApp.stakingPeriod(), STAKING_PERIOD);
        assertEq(stakingApp.fixedStakingAmount(), FIXED_AMOUNT);
        assertEq(stakingApp.rewardPerPeriod(), REWARD_AMOUNT);
    }

    // Coverage: Validate constructor zero-address check
    function test_Deployment_RevertIf_ZeroAddress() public {
        vm.expectRevert(StakingApp.InvalidConfiguration.selector);
        new StakingApp(
            address(0), 
            STAKING_PERIOD, 
            FIXED_AMOUNT, 
            REWARD_AMOUNT
        );
    }

    function testFuzz_ChangeStakingPeriod(uint256 newPeriod) public {
        vm.assume(newPeriod > 0 && newPeriod < 365 days);
        
        vm.prank(owner);
        stakingApp.changeStakingPeriod(newPeriod);
        
        assertEq(stakingApp.stakingPeriod(), newPeriod);
    }

    // ==========================================
    //                 DEPOSIT
    // ==========================================

    function test_Deposit_Success() public {
        vm.startPrank(user);
        
        vm.expectEmit(true, false, false, true);
        emit TokensDeposited(user, FIXED_AMOUNT);
        
        stakingApp.depositTokens(FIXED_AMOUNT);
        
        assertEq(stakingApp.userBalance(user), FIXED_AMOUNT);
        assertEq(stakingApp.userLastActionTimestamp(user), block.timestamp);
        vm.stopPrank();
    }

    function test_Deposit_RevertIf_IncorrectAmount() public {
        vm.startPrank(user);
        uint256 wrongAmount = FIXED_AMOUNT + 1;
        
        vm.expectRevert(abi.encodeWithSelector(
            StakingApp.IncorrectAmount.selector, 
            FIXED_AMOUNT, 
            wrongAmount
        ));
        stakingApp.depositTokens(wrongAmount);
        vm.stopPrank();
    }

    function test_Deposit_RevertIf_AlreadyDeposited() public {
        vm.startPrank(user);
        stakingApp.depositTokens(FIXED_AMOUNT);

        vm.expectRevert(StakingApp.UserAlreadyDeposited.selector);
        stakingApp.depositTokens(FIXED_AMOUNT);
        vm.stopPrank();
    }

    // ==========================================
    //                 WITHDRAW
    // ==========================================

    function test_Withdraw_Success() public {
        vm.startPrank(user);
        stakingApp.depositTokens(FIXED_AMOUNT);

        uint256 balanceBefore = stakingToken.balanceOf(user);
        stakingApp.withdrawTokens();
        uint256 balanceAfter = stakingToken.balanceOf(user);

        assertEq(balanceAfter - balanceBefore, FIXED_AMOUNT);
        assertEq(stakingApp.userBalance(user), 0);
        vm.stopPrank();
    }

    // Coverage: Validate withdrawal without active stake
    function test_Withdraw_RevertIf_NotStaking() public {
        vm.startPrank(user);
        vm.expectRevert(StakingApp.NotStaking.selector);
        stakingApp.withdrawTokens();
        vm.stopPrank();
    }

    // ==========================================
    //              CLAIM REWARDS
    // ==========================================

    function test_Claim_Success() public {
        vm.startPrank(user);
        stakingApp.depositTokens(FIXED_AMOUNT);

        // Advance time exactly to period
        vm.warp(block.timestamp + STAKING_PERIOD);

        uint256 ethBalanceBefore = user.balance;
        
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(user, REWARD_AMOUNT);
        
        stakingApp.claimRewards();
        
        uint256 ethBalanceAfter = user.balance;
        assertEq(ethBalanceAfter - ethBalanceBefore, REWARD_AMOUNT);
        
        // Verify timestamp reset
        assertEq(stakingApp.userLastActionTimestamp(user), block.timestamp);
        vm.stopPrank();
    }

    function test_Claim_RevertIf_PeriodNotFinished() public {
        vm.startPrank(user);
        stakingApp.depositTokens(FIXED_AMOUNT);

        // Advance time but not enough
        vm.warp(block.timestamp + STAKING_PERIOD - 1 seconds);

        vm.expectRevert(abi.encodeWithSelector(
            StakingApp.StakingPeriodNotFinished.selector,
            1 seconds
        ));
        stakingApp.claimRewards();
        vm.stopPrank();
    }

    // Coverage: Validate claiming without active stake
    function test_Claim_RevertIf_NotStaking() public {
        vm.startPrank(user);
        vm.expectRevert(StakingApp.NotStaking.selector);
        stakingApp.claimRewards();
        vm.stopPrank();
    }

    // ==========================================
    //           EDGE CASES & RECEIVE
    // ==========================================

    // Coverage: Validate receive() function and event emission
    function test_ReceiveEther_EmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit ContractFunded(owner, 1 ether);

        // Fund owner to enable transfer
        vm.deal(owner, 1 ether);

        // Send raw ETH to trigger receive()
        vm.startPrank(owner);
        (bool success, ) = address(stakingApp).call{value: 1 ether}("");
        require(success, "Transfer failed");
        vm.stopPrank();
    }

    // Coverage: Validate ETH transfer failure (using RejectEther helper)
    function test_Claim_RevertIf_TransferFailed() public {
        // 1. Setup a contract that refuses ETH
        RejectEther rejector = new RejectEther(address(stakingApp), address(stakingToken));
        
        // 2. Fund the rejector with tokens
        vm.startPrank(owner);
        stakingToken.mint(address(rejector), FIXED_AMOUNT);
        vm.stopPrank();

        // 3. Rejector deposits tokens
        rejector.deposit();

        // 4. Warp time to unlock rewards
        vm.warp(block.timestamp + STAKING_PERIOD + 1);

        // 5. Rejector claims -> StakingApp tries to send ETH -> Rejector reverts -> StakingApp reverts with TransferFailed
        vm.expectRevert(StakingApp.TransferFailed.selector);
        rejector.claim();
    }
}

// --- Helper Contract for testing Transfer Failures ---
// This contract is required to trigger the "TransferFailed" error in coverage
contract RejectEther {
    StakingApp app;
    StakingToken token;

    constructor(address _app, address _token) {
        app = StakingApp(payable(_app));
        token = StakingToken(_token);
    }

    function deposit() external {
        token.approve(address(app), app.fixedStakingAmount());
        app.depositTokens(app.fixedStakingAmount());
    }

    function claim() external {
        app.claimRewards();
    }

    // This reverts incoming ETH transfers, causing the StakingApp's .call to fail
    receive() external payable {
        revert("I do not accept ETH");
    }
}