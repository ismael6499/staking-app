# 🥩 Staking App: DeFi Mechanics & Time-Based Logic

Continuing my **Master in Blockchain Development** at **Blockchain Accelerator Academy**, this project simulates a core DeFi mechanism: **Staking**.

As a **Java Software Engineer**, I'm used to handling dates and scheduled tasks with libraries like `Quartz` or `Cron`. In **Solidity**, time management relies on `block.timestamp`. This project explores how to lock assets (ERC-20 tokens) and distribute rewards (ETH) based on time duration.

## 💡 Project Overview

**Staking App** allows users to deposit a fixed amount of `STK` tokens to earn `ETH` rewards after a specific period (e.g., 7 days).

### 🔍 Key Technical Features:

* **DeFi Architecture:**
    * [cite_start]**Inter-Contract Interaction:** The system involves a custom ERC-20 token (`StakingToken`) interacting with the main logic contract (`StakingApp`) via the `IERC20` interface[cite: 18].
    * [cite_start]**SafeERC20 Library:** Implemented OpenZeppelin's `SafeERC20` wrapper to ensure safe transfer operations, handling non-standard tokens correctly[cite: 19].
    * [cite_start]**Time-Based Logic:** Usage of `block.timestamp` to track deposit durations and validate reward eligibility[cite: 30].

* **Advanced Foundry Testing:**
    * **100% Line Coverage:** I went beyond the "Happy Path". [cite_start]I wrote a helper contract (`RejectEther`) specifically to test the `TransferFailed` error, ensuring even the `receive()` fallback logic is robust[cite: 120, 126].
    * [cite_start]**Fuzzing & Cheatcodes:** Used `vm.warp()` to simulate time travel (waiting 7 days in milliseconds) and `vm.prank()` to simulate multiple users[cite: 110, 100].

## 🛠️ Stack & Tools

* **Framework:** Foundry (Forge).
* **Language:** Solidity `0.8.24`.
* **Libraries:** OpenZeppelin (`Ownable`, `ReentrancyGuard`, `SafeERC20`).
* **Concepts:** Time manipulation, State Machines, Unit Testing.

---

*This project bridges the gap between simple smart contracts and real-world DeFi protocols.*
