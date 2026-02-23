import { ethers } from 'ethers';
import { VaultService } from './vaultService';
import { StrategyService } from './strategyService';

/**
 * Main Contract Service serving as a factory/registry for protocol services
 */
export class ContractService {
    private provider: ethers.Provider | ethers.Signer;

    public vault: VaultService;
    public strategies: StrategyService;

    constructor(providerOrSigner: ethers.Provider | ethers.Signer) {
        this.provider = providerOrSigner;
        this.vault = new VaultService(providerOrSigner);
        this.strategies = new StrategyService(providerOrSigner);
    }

    /**
     * Helper to ensure the service is connected to a Signer (for write operations)
     */
    hasSigner(): boolean {
        // Basic check if the provider object has a signMessage method
        return 'signMessage' in this.provider;
    }
}
