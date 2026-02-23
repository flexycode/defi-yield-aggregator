// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title TokenUtils
 * @notice Utility library for safe token transfers and approvals ensuring protocol compatibility
 */
library TokenUtils {
    using SafeERC20 for IERC20;

    /**
     * @notice Safely approves a token max allowance, bypassing USDT-like non-zero requirements
     * @param token The ERC20 token
     * @param spender The address to approve
     */
    function safeApproveMax(IERC20 token, address spender) internal {
        if (token.allowance(address(this), spender) < type(uint256).max / 2) {
            // Reset allowance first to prevent transaction reversion on some tokens like USDT
            token.safeApprove(spender, 0);
            token.safeApprove(spender, type(uint256).max);
        }
    }
}
