// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "../interfaces/IRouter.sol";
import "../interfaces/IVault.sol";

/**
 * @title Router
 * @notice Core routing contract for user interactions
 * @dev Implements slippage protection, EIP-2612 permits, and batch transactions via Multicall
 */
contract Router is IRouter, Multicall {
    using SafeERC20 for IERC20;

    /// @notice Custom errors
    error SlippageExceeded();
    error ZeroAddress();
    error InsufficientAllowance();

    constructor() {}

    /// @notice Execute ERC20 permit for token approvals in the same tx
    /// @param token Address of the ERC20 token
    /// @param value Amount to approve
    /// @param deadline Permit deadline
    /// @param v Signature v
    /// @param r Signature r
    /// @param s Signature s
    function permit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        IERC20Permit(token).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
    }

    /// @inheritdoc IRouter
    function deposit(
        address vault,
        uint256 assets,
        address receiver,
        uint256 minSharesOut
    ) external override returns (uint256 shares) {
        if (vault == address(0)) revert ZeroAddress();

        IERC20 asset = IERC20(IVault(vault).asset());

        // Transfer assets from user to router
        asset.safeTransferFrom(msg.sender, address(this), assets);

        // Approve vault
        _approveTokenIfNeeded(address(asset), vault, assets);

        // Deposit
        shares = IVault(vault).deposit(assets, receiver);

        // Slippage check
        if (shares < minSharesOut) revert SlippageExceeded();
    }

    /// @inheritdoc IRouter
    function mint(
        address vault,
        uint256 shares,
        address receiver,
        uint256 maxAssetsIn
    ) external override returns (uint256 assets) {
        if (vault == address(0)) revert ZeroAddress();

        IERC20 asset = IERC20(IVault(vault).asset());

        assets = IVault(vault).previewMint(shares);
        if (assets > maxAssetsIn) revert SlippageExceeded();

        // Transfer assets from user to router
        asset.safeTransferFrom(msg.sender, address(this), assets);

        // Approve vault
        _approveTokenIfNeeded(address(asset), vault, assets);

        // Mint
        uint256 actualAssets = IVault(vault).mint(shares, receiver);

        // If the actual required assets are higher than the preview, we might revert in vault or here
        if (actualAssets > maxAssetsIn) revert SlippageExceeded();

        // If actual is less than preview, refund the difference
        if (actualAssets < assets) {
            asset.safeTransfer(msg.sender, assets - actualAssets);
        }

        assets = actualAssets;
    }

    /// @inheritdoc IRouter
    function withdraw(
        address vault,
        uint256 assets,
        address receiver,
        address owner,
        uint256 maxSharesIn
    ) external override returns (uint256 shares) {
        if (vault == address(0)) revert ZeroAddress();

        shares = IVault(vault).previewWithdraw(assets);
        if (shares > maxSharesIn) revert SlippageExceeded();

        // Transfer shares from user to router
        if (msg.sender == owner) {
            IERC20(vault).safeTransferFrom(msg.sender, address(this), shares);
        } else {
            uint256 allowed = IERC20(vault).allowance(owner, msg.sender);
            if (allowed < shares) revert InsufficientAllowance();
            IERC20(vault).safeTransferFrom(owner, address(this), shares);
        }

        // Router withdraws and sends assets directly to receiver
        uint256 actualShares = IVault(vault).withdraw(
            assets,
            receiver,
            address(this)
        );

        if (actualShares > maxSharesIn) revert SlippageExceeded();

        // Return any excess shares
        if (actualShares < shares) {
            IERC20(vault).safeTransfer(msg.sender, shares - actualShares);
        }

        shares = actualShares;
    }

    /// @inheritdoc IRouter
    function redeem(
        address vault,
        uint256 shares,
        address receiver,
        address owner,
        uint256 minAssetsOut
    ) external override returns (uint256 assets) {
        if (vault == address(0)) revert ZeroAddress();

        // Transfer shares from user to router
        if (msg.sender == owner) {
            IERC20(vault).safeTransferFrom(msg.sender, address(this), shares);
        } else {
            uint256 allowed = IERC20(vault).allowance(owner, msg.sender);
            if (allowed < shares) revert InsufficientAllowance();
            IERC20(vault).safeTransferFrom(owner, address(this), shares);
        }

        // Redeem assets directly to receiver
        assets = IVault(vault).redeem(shares, receiver, address(this));

        if (assets < minAssetsOut) revert SlippageExceeded();
    }

    /**
     * @dev Approves token to spender if current allowance is insufficient
     */
    function _approveTokenIfNeeded(
        address token,
        address spender,
        uint256 amount
    ) internal {
        if (IERC20(token).allowance(address(this), spender) < amount) {
            // Safe approve sequence for non-compliant tokens like USDT
            IERC20(token).safeApprove(spender, 0);
            IERC20(token).safeApprove(spender, type(uint256).max);
        }
    }
}
