import { ethers } from 'ethers';
import StrategyManagerABI from '../abis/StrategyManager.json';
import StrategyABI from '../abis/Strategy.json';
import type { StrategyInfo } from '../types/contracts';

const STRATEGY_MANAGER_ADDRESS = import.meta.env.VITE_STRATEGY_MANAGER_ADDRESS || '0x0000000000000000000000000000000000000000';

export class StrategyService {
    private managerContract: ethers.Contract;
    private provider: ethers.Provider;

    constructor(provider: ethers.Provider | ethers.Signer) {
        this.managerContract = new ethers.Contract(STRATEGY_MANAGER_ADDRESS, StrategyManagerABI, provider);
        // Extract provider if a Signer was passed
        this.provider = (provider as ethers.Signer).provider || (provider as ethers.Provider);
    }

    /**
     * Get total assets actively deployed in strategies
     */
    async getTotalAssetsInStrategies(): Promise<bigint> {
        try {
            return await this.managerContract.totalAssetsInStrategies();
        } catch (error) {
            console.error('Failed to get strategy assets', error);
            return 0n;
        }
    }

    /**
     * Fetches detailed information for a specific strategy contract
     * @param strategyAddress Address of the strategy
     */
    async getStrategyInfo(strategyAddress: string): Promise<StrategyInfo | null> {
        try {
            const strategyContract = new ethers.Contract(strategyAddress, StrategyABI, this.provider);

            const [name, apr, isActive, allocation] = await Promise.all([
                strategyContract.name(),
                strategyContract.apr(),
                strategyContract.isActive(),
                this.managerContract.getStrategyAllocation(strategyAddress)
            ]);

            return {
                address: strategyAddress,
                name,
                apr,
                isActive,
                allocation
            };
        } catch (error) {
            console.error(`Failed to fetch info for strategy ${strategyAddress}`, error);
            return null;
        }
    }
}
