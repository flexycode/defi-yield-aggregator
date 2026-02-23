// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./BaseStrategy.sol";
import "../interfaces/external/ICurvePool.sol";
import "../interfaces/external/ICurveGauge.sol";
import "../interfaces/external/ICurveMinter.sol";

/**
 * @title CurveStrategy
 * @notice Yield strategy for Curve Finance
 * @dev Deposits want token into Curve pool, stakes LP in gauge, claims CRV
 */
contract CurveStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    ICurvePool public immutable curvePool;
    ICurveGauge public immutable curveGauge;
    ICurveMinter public immutable curveMinter;
    IERC20 public immutable curveLpToken;
    IERC20 public immutable crvToken;

    int128 public immutable coinIndex; // Index of the want token in the Curve pool
    uint256 public immutable numCoins; // Total coins in the pool (2 or 3 supported)

    constructor(
        address _vault,
        address _want,
        address _curvePool,
        address _curveGauge,
        address _curveMinter,
        address _curveLpToken,
        address _crvToken,
        int128 _coinIndex,
        uint256 _numCoins,
        string memory _name
    ) BaseStrategy(_vault, _want, _name) {
        require(_curvePool != address(0), "CurveStrategy: zero pool");
        require(_curveGauge != address(0), "CurveStrategy: zero gauge");
        require(_curveLpToken != address(0), "CurveStrategy: zero lp");
        require(
            _numCoins == 2 || _numCoins == 3,
            "CurveStrategy: unsupported pool size"
        );

        curvePool = ICurvePool(_curvePool);
        curveGauge = ICurveGauge(_curveGauge);
        curveMinter = ICurveMinter(_curveMinter);
        curveLpToken = IERC20(_curveLpToken);
        crvToken = IERC20(_crvToken);
        coinIndex = _coinIndex;
        numCoins = _numCoins;

        // Initial approvals
        IERC20(_want).approve(_curvePool, type(uint256).max);
        IERC20(_curveLpToken).approve(_curveGauge, type(uint256).max);
    }

    /// @inheritdoc IStrategy
    function apr() external view override returns (uint256) {
        // APR calculation for Curve incorporates trading fees + CRV emissions
        // Typically fetched via an off-chain oracle or registry for aggregate display.
        return 500; // Mock: 5.00%
    }

    // ============ Internal Functions ============

    /// @inheritdoc BaseStrategy
    function _deployedBalance() internal view override returns (uint256) {
        uint256 lpBalance = curveGauge.balanceOf(address(this)) +
            curveLpToken.balanceOf(address(this));
        if (lpBalance == 0) return 0;

        // Estimate the underlying asset equivalent
        try curvePool.calc_withdraw_one_coin(lpBalance, coinIndex) returns (
            uint256 amount
        ) {
            return amount;
        } catch {
            return 0; // Fallback if calc reverts
        }
    }

    /// @inheritdoc BaseStrategy
    function _deposit(uint256 amount) internal override {
        // Pool requires an array of amounts depending on numCoins
        if (numCoins == 2) {
            uint256[2] memory amounts;
            amounts[uint256(int256(coinIndex))] = amount;
            curvePool.add_liquidity(amounts, 0); // min_mint_amount = 0 (Requires external slippage bounds logic typically)
        } else if (numCoins == 3) {
            uint256[3] memory amounts;
            amounts[uint256(int256(coinIndex))] = amount;
            curvePool.add_liquidity(amounts, 0);
        }

        // Stake all LP tokens into the gauge to earn CRV
        uint256 lpBalance = curveLpToken.balanceOf(address(this));
        if (lpBalance > 0) {
            curveGauge.deposit(lpBalance);
        }
    }

    /// @inheritdoc BaseStrategy
    function _withdraw(uint256 amount) internal override {
        // Withdraw all LP from gauge to ensure we have enough liquidity locally
        uint256 gaugeBalance = curveGauge.balanceOf(address(this));
        if (gaugeBalance > 0) {
            curveGauge.withdraw(gaugeBalance);
        }

        uint256 lpBalance = curveLpToken.balanceOf(address(this));
        if (lpBalance > 0) {
            // Remove liquidity from pool, receiving the single underlying coin
            curvePool.remove_liquidity_one_coin(lpBalance, coinIndex, 0);
        }

        uint256 wantBalance = wantToken.balanceOf(address(this));
        require(wantBalance >= amount, "CurveStrategy: insufficient withdrawn");

        // Redeposit any excess underlying tokens not needed for this withdrawal
        if (wantBalance > amount) {
            _deposit(wantBalance - amount);
        }
    }

    /// @inheritdoc BaseStrategy
    function _withdrawAll() internal override {
        uint256 gaugeBalance = curveGauge.balanceOf(address(this));
        if (gaugeBalance > 0) {
            curveGauge.withdraw(gaugeBalance);
        }

        uint256 lpBalance = curveLpToken.balanceOf(address(this));
        if (lpBalance > 0) {
            curvePool.remove_liquidity_one_coin(lpBalance, coinIndex, 0);
        }
    }

    /// @inheritdoc BaseStrategy
    function _harvest() internal override {
        // Claim CRV from gauge using Minter or directly if V2 gauge
        if (address(curveMinter) != address(0)) {
            curveMinter.mint(address(curveGauge));
        } else {
            curveGauge.claim_rewards();
        }

        uint256 crvBalance = crvToken.balanceOf(address(this));
        if (crvBalance > 0) {
            // In a production system, harvest would route CRV -> ETH -> Underlying Asset
            // and redeposit it to compound the yield.
        }
    }

    /// @inheritdoc BaseStrategy
    function _emergencyWithdraw() internal override {
        _withdrawAll();
    }
}
