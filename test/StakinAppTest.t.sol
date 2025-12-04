//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/StakingToken.sol";
import "../src/StakingApp.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingAppTest is Test {

    StakingApp stakingApp;
    StakingToken stakingToken;

    string name_ = "Staking Token";
    string symbol_ = "STK";
    address owner_ = vm.addr(1);
    address randomUser_ = vm.addr(2);
    uint256 stakingPeriod_ = 1000000000;
    uint256 fixedStakingAmount_ = 10;
    uint256 rewardPerPeriod_ = 1 ether;

    function setUp() public {
        stakingToken = new StakingToken(name_, symbol_);
        stakingApp = new StakingApp(address(stakingToken), owner_, stakingPeriod_, fixedStakingAmount_, rewardPerPeriod_);
    }

    function testStakingTokenCorrectlyDeployed() external view {
        assertNotEq(address(stakingToken), address(0)); 
    }

    function testStakingAppCorrectlyDeployed() external view {
        assertNotEq(address(stakingApp), address(0));
    }

    function testShouldRevertChangeStakingPeriodIfNotOwner() external {
        uint256 newStakingPeriod = 1;
        
        vm.expectRevert();
        stakingApp.changeStakingPeriod(newStakingPeriod);
    } 
    
    function testShouldChangeStakingPeriod() external {
        vm.startPrank(owner_);
        uint256 newStakingPeriod = 99;
        
        uint256 stakingPeriodBefore = stakingApp.stakingPeriod();
        stakingApp.changeStakingPeriod(newStakingPeriod);
        uint256 stakingPeriodafter = stakingApp.stakingPeriod();

        assertNotEq(stakingPeriodBefore, newStakingPeriod);
        assertEq(stakingPeriodafter, newStakingPeriod);

        vm.stopPrank();
    }


    function testContractReceivesEtherCorrectly() external {
        vm.startPrank(owner_);

        uint256 etherValue = 1 ether;
        vm.deal(owner_, etherValue);

        uint256 balanceBefore = address(stakingApp).balance;

        (bool success, ) = address(stakingApp).call{value: etherValue}("");

        uint256 balanceAfter = address(stakingApp).balance;
        assert(success);

        assertEq(balanceAfter - balanceBefore, etherValue);

        vm.stopPrank();
    }

    function testDepositIncorrectAmountShouldRevert() external {
        vm.startPrank(randomUser_);
        
        uint256 depositAmount = 1;

        vm.expectRevert("Incorrect Amount");
        stakingApp.depositTokens(depositAmount);

        vm.stopPrank();
    }


    function testDepositTokensCorrectly() external {
        vm.startPrank(randomUser_);
        
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser_);
        uint256 userBlockTimeStampBefore = stakingApp.userToBlockTimestamp(randomUser_);
        
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser_);
        uint256 userBlockTimeStampAfter = stakingApp.userToBlockTimestamp(randomUser_);

        assertEq(userBalanceAfter - userBalanceBefore, tokenAmount);
        assertGe(userBlockTimeStampAfter, userBlockTimeStampBefore);

        vm.stopPrank();
    }


    function testUserCannotDepositMultipleTimes() external {
        vm.startPrank(randomUser_);
        
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser_);
        uint256 userBlockTimeStampBefore = stakingApp.userToBlockTimestamp(randomUser_);
        
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser_);
        uint256 userBlockTimeStampAfter = stakingApp.userToBlockTimestamp(randomUser_);

        assertEq(userBalanceAfter - userBalanceBefore, tokenAmount);
        assertGe(userBlockTimeStampAfter, userBlockTimeStampBefore);

        stakingToken.mint(tokenAmount);

        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);

        vm.expectRevert("User already deposited");
        stakingApp.depositTokens(tokenAmount);

        vm.stopPrank();
    }

     function testCanOnlyWithdrawZeroWithoutDeposit() external {
        vm.startPrank(randomUser_);

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser_);
        stakingApp.withdrawTokens();
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser_);

        assertEq(userBalanceBefore, userBalanceAfter);

        vm.stopPrank();
    }


     function testWithdrawTokensCorrectly() external {
        vm.startPrank(randomUser_);
        
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser_);
        uint256 userBlockTimeStampBefore = stakingApp.userToBlockTimestamp(randomUser_);
        
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser_);
        uint256 userBlockTimeStampAfter = stakingApp.userToBlockTimestamp(randomUser_);

        assertEq(userBalanceAfter - userBalanceBefore, tokenAmount);
        assertGe(userBlockTimeStampAfter, userBlockTimeStampBefore);

        uint256 userBalanceBefore2 = IERC20(stakingToken).balanceOf(randomUser_);
        uint256 userBalanceBeforeInMapping = stakingApp.userBalance(randomUser_);
        stakingApp.withdrawTokens();
        uint256 userBalanceAfter2 = IERC20(stakingToken).balanceOf(randomUser_);
        uint256 userBalanceAfterInMapping = stakingApp.userBalance(randomUser_);

        assertNotEq(userBalanceBeforeInMapping, userBalanceAfterInMapping);
        assertEq(userBalanceBeforeInMapping - userBalanceAfterInMapping , tokenAmount);
        
        assertNotEq(userBalanceBefore2, userBalanceAfter2);
        assertEq(userBalanceAfter2 - userBalanceBefore2, tokenAmount);

        vm.stopPrank();
    }
    

    function testCannotClaimIfNotStaking() external {
        vm.startPrank(randomUser_);

        vm.expectRevert("Not staking");
        stakingApp.claimRewards();

        vm.stopPrank();
    }

    function testCannotClaimIfNotElapsedTime() external {
        vm.startPrank(randomUser_);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser_);
        uint256 userBlockTimeStampBefore = stakingApp.userToBlockTimestamp(randomUser_);
        
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser_);
        uint256 userBlockTimeStampAfter = stakingApp.userToBlockTimestamp(randomUser_);

        assertEq(userBalanceAfter - userBalanceBefore, tokenAmount);
        assertGe(userBlockTimeStampAfter, userBlockTimeStampBefore);

        vm.expectRevert("Need to wait");
        stakingApp.claimRewards();

        vm.stopPrank(); 
    }

    function testShouldRevertIfNoEther() external {
        vm.startPrank(randomUser_);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser_);
        uint256 userBlockTimeStampBefore = stakingApp.userToBlockTimestamp(randomUser_);
        
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser_);
        uint256 userBlockTimeStampAfter = stakingApp.userToBlockTimestamp(randomUser_);

        assertEq(userBalanceAfter - userBalanceBefore, tokenAmount);
        assertGe(userBlockTimeStampAfter, userBlockTimeStampBefore);

        
        vm.warp(block.timestamp + stakingPeriod_ );

        vm.expectRevert("Transfer failed");
        stakingApp.claimRewards();

        vm.stopPrank(); 
    }


   function testCanClaimRewardsCorrectly() external {
        vm.startPrank(randomUser_);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser_);
        uint256 userBlockTimeStampBefore = stakingApp.userToBlockTimestamp(randomUser_);
        
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser_);
        uint256 userBlockTimeStampAfter = stakingApp.userToBlockTimestamp(randomUser_);

        assertEq(userBalanceAfter - userBalanceBefore, tokenAmount);
        assertGe(userBlockTimeStampAfter, userBlockTimeStampBefore);

        vm.stopPrank();

        vm.startPrank(owner_);

        uint256 etherAmount = 10 ether;
        vm.deal(owner_, etherAmount);

        (bool success, ) = address(stakingApp).call{value: etherAmount}("");
        require(success, "Test transfer failed");
        vm.stopPrank();

        vm.startPrank(randomUser_);
        vm.warp(block.timestamp + stakingPeriod_ );

        uint256 etherAmountBefore = address(randomUser_).balance;
        stakingApp.claimRewards();
        uint256 etherAmountAfter = address(randomUser_).balance;

        assertEq(etherAmountAfter - etherAmountBefore, rewardPerPeriod_);
        vm.stopPrank(); 
    }

}