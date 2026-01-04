# 🥩 Time-Locked Staking Protocol

![Solidity](https://img.shields.io/badge/Solidity-0.8.24-363636?style=flat-square&logo=solidity)
![Coverage](https://img.shields.io/badge/Coverage-100%25-brightgreen?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

A decentralized yield farming protocol enabling time-locked asset staking with native Ether rewards.

This system replaces centralized scheduling (Cron jobs) with **on-chain timekeeping**, creating a trustless mechanism for asset maturity. It is engineered with a "Safety-First" architecture, utilizing defensive coding patterns to handle non-standard ERC20 tokens and potential interactions with malicious contracts.

## 🏗 Architecture & Design Decisions

### 1. Trustless Scheduling
- **EVM Time Management:**
  - Logic relies purely on `block.timestamp` state deltas to determine reward eligibility (`timeElapsed < stakingPeriod`).
  - **Benefit:** Removes dependency on external Keepers or Oracle updates for reward distribution, ensuring the protocol is self-contained and censorship-resistant.

### 2. Defensive Engineering
- **SafeERC20 Integration:**
  - Uses OpenZeppelin's `SafeERC20` wrapper for all token transfers. This ensures compatibility with non-compliant tokens (like USDT) that do not return a boolean value on transfer, preventing silent failures.
- **Hostile Actor Protection:**
  - The `claimRewards` function is protected by `ReentrancyGuard` and strictly validates the return value of the low-level ETH `.call`.
  - **Explicit Failure Handling:** If the recipient cannot accept ETH (e.g., a contract without a `receive()` function), the transaction reverts securely with `TransferFailed` rather than leaving the system in an inconsistent state.

### 3. Advanced QA Strategy (Foundry)
The test suite goes beyond happy paths to achieve **100% Branch Coverage**:
- **Hostile Simulation:** Implemented a `RejectEther` mock contract in the test suite specifically to force low-level call failures, verifying that the protocol correctly reverts when interactions fail.
- **Time Travel Fuzzing:** Leverages `vm.warp()` to simulate weeks of staking duration in milliseconds, validating logic across varied timeframes without mainnet waiting periods.

## 🛠 Tech Stack

* **Core:** Solidity `^0.8.24`
* **Libraries:** OpenZeppelin (SafeERC20, Ownable, ReentrancyGuard)
* **Testing:** Foundry (Fuzzing, Mocking, Time Manipulation)

## 📝 Contract Interface

The protocol exposes a simple state-machine interface for stakers:

```solidity
// Core Interaction
function depositTokens(uint256 amount) external;
function withdrawTokens() external;
function claimRewards() external; // Distributes ETH based on time deltas
