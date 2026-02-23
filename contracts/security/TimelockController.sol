// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @title ProtocolTimelock
 * @notice Extension of OpenZeppelin's TimelockController for protocol upgrades
 * @dev Enforces a mandatory time delay for all sensitive administrative actions (e.g. strategy upgrades, fee changes)
 */
contract ProtocolTimelock is TimelockController {
    /**
     * @notice Constructor
     * @param minDelay Initial minimum delay in seconds
     * @param proposers Array of addresses allowed to propose operations
     * @param executors Array of addresses allowed to execute operations
     * @param admin Optional account to be granted admin role; disable with zero address
     */
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) TimelockController(minDelay, proposers, executors, admin) {}
}
