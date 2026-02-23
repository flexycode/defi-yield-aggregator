import { ethers } from 'ethers';
import { parseContractError } from '../utils/errorHandler';
import VaultABI from '../abis/Vault.json';

const VAULT_ADDRESS = import.meta.env.VITE_VAULT_ADDRESS || '0x0000000000000000000000000000000000000000'; // Default to zero address if not set

export class VaultService {
    private contract: ethers.Contract;

    constructor(providerOrSigner: ethers.Provider | ethers.Signer) {
        this.contract = new ethers.Contract(VAULT_ADDRESS, VaultABI, providerOrSigner);
    }

    /**
     * Helper to execute a transaction with error handling
     */
    private async executeTx(txPromise: Promise<ethers.ContractTransactionResponse>): Promise<ethers.TransactionReceipt> {
        try {
            const tx = await txPromise;
            const receipt = await tx.wait();
            if (!receipt) throw new Error("Transaction failed or receipt is null");
            return receipt;
        } catch (error: any) {
            throw new Error(parseContractError(error));
        }
    }

    /**
     * Deposit assets into the vault
     * @param assets Amount of underlying assets
     * @param receiver Address receiving the vault shares
     */
    async deposit(assets: bigint, receiver: string): Promise<ethers.TransactionReceipt> {
        return this.executeTx(this.contract.deposit(assets, receiver));
    }

    /**
     * Withdraw assets from the vault
     * @param assets Amount of underlying assets to withdraw
     * @param receiver Address receiving the underlying assets
     * @param owner Address owning the vault shares
     */
    async withdraw(assets: bigint, receiver: string, owner: string): Promise<ethers.TransactionReceipt> {
        return this.executeTx(this.contract.withdraw(assets, receiver, owner));
    }

    /**
     * Get vault shares balance for an account
     * @param account Wallet address
     */
    async getBalance(account: string): Promise<bigint> {
        try {
            return await this.contract.balanceOf(account);
        } catch (error) {
            console.error('Error fetching balance:', error);
            return 0n;
        }
    }

    /**
     * Get total assets managed by the vault
     */
    async getTotalAssets(): Promise<bigint> {
        try {
            return await this.contract.totalAssets();
        } catch (error) {
            console.error('Error fetching total assets:', error);
            return 0n;
        }
    }

    /**
     * Get the current share price (assets per 1 amount of shares, usually scaled by 1e18)
     */
    async convertToAssets(shares: bigint): Promise<bigint> {
        try {
            return await this.contract.convertToAssets(shares);
        } catch (error) {
            console.error('Error converting to assets:', error);
            return shares; // Fallback to 1:1 if error
        }
    }

    /**
     * Listen to deposit events
     */
    onDeposit(callback: (sender: string, owner: string, assets: bigint, shares: bigint) => void) {
        this.contract.on('Deposit', callback);
        return () => {
            this.contract.off('Deposit', callback); // Cleanup
        };
    }
}
