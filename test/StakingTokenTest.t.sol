// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/StakingToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingTokenTest is Test {
    
    StakingToken public stakingToken;
    
    address public owner = makeAddr("owner");
    address public randomUser = makeAddr("randomUser");

    // Events (Copied from IERC20 for testing assertions)
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function setUp() public {
        vm.startPrank(owner);
        stakingToken = new StakingToken("Staking Token", "STK");
        vm.stopPrank();
    }

    function test_Metadata_CorrectlySet() public view {
        assertEq(stakingToken.name(), "Staking Token");
        assertEq(stakingToken.symbol(), "STK");
    }

    function test_Mint_Success_Owner() public {
        vm.startPrank(owner);
        uint256 amount = 100 ether;

        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), randomUser, amount);

        stakingToken.mint(randomUser, amount);
        
        assertEq(stakingToken.balanceOf(randomUser), amount);
        assertEq(stakingToken.totalSupply(), amount);
        vm.stopPrank();
    }

    function test_Mint_RevertIf_NotOwner() public {
        vm.startPrank(randomUser);
        uint256 amount = 1 ether;

        // Expect the specific Ownable error selector
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector, 
                randomUser
            )
        );
        
        stakingToken.mint(randomUser, amount);
        vm.stopPrank();
    }

    // --- Fuzzing ---

    function testFuzz_Mint_Success(uint256 amount) public {
        // Cap at unlikely high number to avoid overflow in future logic logic
        vm.assume(amount < type(uint128).max);

        vm.startPrank(owner);
        stakingToken.mint(randomUser, amount);
        
        assertEq(stakingToken.balanceOf(randomUser), amount);
        vm.stopPrank();
    }
}