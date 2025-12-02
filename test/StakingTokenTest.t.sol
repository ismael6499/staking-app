//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/StakingToken.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingTokenTest is Test {
    
    StakingToken stakingToken;
    string name = "Staking Token";
    string symbol = "STK";
    address randomUser = vm.addr(1);
    
    function setUp() public {
        stakingToken = new StakingToken(name, symbol);
    }

    function testStakingTokenMintsCorrectly() public {
        vm.startPrank(randomUser);

        uint256 amount = 1 ether;

        uint256 balanceBefore = stakingToken.balanceOf(randomUser);
        stakingToken.mint(amount);
        uint256 balanceAfter = stakingToken.balanceOf(randomUser);

        assertEq(balanceAfter, balanceBefore + amount);

        vm.stopPrank();
    }
}
