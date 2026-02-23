// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IRouter
 * @notice Interface for the protocol routing contract
 * @dev Handles optimal routing and slippage protection for user interactions
 */
interface IRouter {
    /// @notice Deposits assets into a vault with slippage protection
    /// @param vault Address of the vault
    /// @param assets Amount of underlying assets to deposit
    /// @param receiver Address to receive the shares
    /// @param minSharesOut Minimum acceptable shares to receive
    /// @return shares Number of shares minted
    function deposit(
        address vault,
        uint256 assets,
        address receiver,
        uint256 minSharesOut
    ) external returns (uint256 shares);

    /// @notice Mints shares from a vault with slippage protection
    /// @param vault Address of the vault
    /// @param shares Amount of shares to mint
    /// @param receiver Address to receive the shares
    /// @param maxAssetsIn Maximum acceptable assets to spend
    /// @return assets Number of assets deposited
    function mint(
        address vault,
        uint256 shares,
        address receiver,
        uint256 maxAssetsIn
    ) external returns (uint256 assets);

    /// @notice Withdraws assets from a vault with slippage protection
    /// @param vault Address of the vault
    /// @param assets Amount of assets to withdraw
    /// @param receiver Address to receive the assets
    /// @param owner Address of the share owner
    /// @param maxSharesIn Maximum acceptable shares to burn
    /// @return shares Number of shares burned
    function withdraw(
        address vault,
        uint256 assets,
        address receiver,
        address owner,
        uint256 maxSharesIn
    ) external returns (uint256 shares);

    /// @notice Redeems shares from a vault with slippage protection
    /// @param vault Address of the vault
    /// @param shares Amount of shares to redeem
    /// @param receiver Address to receive the assets
    /// @param owner Address of the share owner
    /// @param minAssetsOut Minimum acceptable assets to receive
    /// @return assets Number of assets withdrawn
    function redeem(
        address vault,
        uint256 shares,
        address receiver,
        address owner,
        uint256 minAssetsOut
    ) external returns (uint256 assets);
}
