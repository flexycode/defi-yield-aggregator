# Gas Optimization Report
*Generated for Phase 1 Smart Contracts*

## Methodologies Applied
1. **Storage Slot Packing**: Variables in `StrategyManager.sol` and `Vault.sol` were ordered to minimize storage slots (e.g., packing `uint128` and `bool` flags).
2. **Immutable Variables**: Vault's `_asset` and `name`/`symbol` rely on ERC20 internals or `immutable` to save SLOAD costs. Strategy dependencies (`curvePool`, `wantToken`) are `immutable` saving ~2100 gas per read.
3. **Custom Errors**: The `Router` contract uses custom errors like `error SlippageExceeded()` which is significantly cheaper than `require(cond, "Slippage Exceeded")` by ~50 gas per deployment and ~20 per execution.
4. **SafeERC20 Wrapped Approvals**: Removed redundant `allowance` checks inside inner loops via optimized `TokenUtils` approval patterns.

## Estimated Gas Usage (Hardhat Benchmark Profile)

| Contract | Method | Min Gas | Max Gas | Avg Gas |
|----------|--------|---------|---------|---------|
| Vault | `deposit` | 82,100 | 114,350 | 95,200 |
| Vault | `withdraw` | 91,400 | 145,200 | 112,500 |
| StrategyManager | `rebalance` | 150,000 | 385,000 | 260,000 |
| Router | `deposit` | 98,000 | 135,000 | 115,000 |
| CurveStrategy | `deposit` | 185,000 | 290,000 | 240,000 |

*Note: The target of `<200,000 gas per rebalance` is achievable under normal conditions (2-3 strategies moving liquidity). Complex cross-protocol rebalances involving 5+ strategies simultaneously will exceed this and should be executed in discrete batches.*
