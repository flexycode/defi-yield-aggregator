// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Guardian
 * @notice Dedicated emergency multisig capable of pausing the vault independently of the admin
 * @dev Protects against fast exploits by allowing a subset of signers to halt operations
 */
contract Guardian is AccessControl {
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    // Multisig config
    uint256 public requiredSignatures;

    // Array of Vaults this guardian controls
    address[] public managedVaults;

    struct PauseRequest {
        bool active;
        uint256 approvals;
    }

    mapping(uint256 => mapping(address => bool)) public hasSigned;
    mapping(uint256 => PauseRequest) public pauseRequests;
    uint256 public requestCounter;

    // Events
    event PauseRequested(uint256 indexed requestId, address indexed requester);
    event PauseExecuted(uint256 indexed requestId);
    event VaultAdded(address indexed vault);
    event VaultRemoved(address indexed vault);

    /**
     * @notice Constructor
     * @param signers Array of initial guardian signers
     * @param _requiredSignatures Signatures needed to execute a global pause
     */
    constructor(address[] memory signers, uint256 _requiredSignatures) {
        require(
            _requiredSignatures > 0 && _requiredSignatures <= signers.length,
            "Guardian: invalid required signatures"
        );

        requiredSignatures = _requiredSignatures;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint i = 0; i < signers.length; i++) {
            require(signers[i] != address(0), "Guardian: zero address signer");
            _grantRole(SIGNER_ROLE, signers[i]);
        }
    }

    /**
     * @notice Adds a vault to management
     */
    function addManagedVault(
        address vault
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(vault != address(0), "Guardian: zero address");
        managedVaults.push(vault);
        emit VaultAdded(vault);
    }

    /**
     * @notice Submits a new pause request
     */
    function createPauseRequest()
        external
        onlyRole(SIGNER_ROLE)
        returns (uint256)
    {
        uint256 requestId = requestCounter++;
        pauseRequests[requestId] = PauseRequest({active: true, approvals: 1});
        hasSigned[requestId][msg.sender] = true;

        emit PauseRequested(requestId, msg.sender);

        // Auto execute if only 1 signature is required
        if (1 >= requiredSignatures) {
            _executePause();
            pauseRequests[requestId].active = false;
        }
        return requestId;
    }

    /**
     * @notice Approves an existing pause request
     */
    function approvePauseRequest(
        uint256 requestId
    ) external onlyRole(SIGNER_ROLE) {
        require(
            pauseRequests[requestId].active,
            "Guardian: request not active"
        );
        require(!hasSigned[requestId][msg.sender], "Guardian: already signed");

        hasSigned[requestId][msg.sender] = true;
        pauseRequests[requestId].approvals++;

        if (pauseRequests[requestId].approvals >= requiredSignatures) {
            _executePause();
            pauseRequests[requestId].active = false;
            emit PauseExecuted(requestId);
        }
    }

    /**
     * @notice Internal execution of the global pause
     */
    function _executePause() internal {
        for (uint i = 0; i < managedVaults.length; i++) {
            // Call pause(), assuming generic pausability
            (bool success, ) = managedVaults[i].call(
                abi.encodeWithSignature("pause()")
            );
            require(success, "Guardian: Pause failed on vault"); // This ensures the guardian correctly halts the system
        }
    }
}
