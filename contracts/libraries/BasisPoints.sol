// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title BasisPoints
 * @notice Utility library for precise basis point calculations
 */
library BasisPoints {
    uint256 public constant BPS_DENOMINATOR = 10000;

    /**
     * @notice Calculates the basis point value of an amount
     * @param amount The base amount
     * @param bps The basis points (10000 = 100%)
     * @return The calculated value
     */
    function calculate(
        uint256 amount,
        uint256 bps
    ) internal pure returns (uint256) {
        require(bps <= BPS_DENOMINATOR, "BasisPoints: > 100%");
        return (amount * bps) / BPS_DENOMINATOR;
    }
}
