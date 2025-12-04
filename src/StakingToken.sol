// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Staking Mock Token
/// @author Agustin Acosta
/// @notice A mock ERC20 token with controlled minting for testing purposes
contract StakingToken is ERC20, Ownable {

    constructor(string memory _name, string memory _symbol) 
        ERC20(_name, _symbol) 
        Ownable(msg.sender) 
    {}

    /// @notice Mints new tokens to a specific address
    /// @dev Only the owner (test deployer) can mint to prevent abuse
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }
}