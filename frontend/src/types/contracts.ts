import { ethers } from 'ethers';

export interface TransactionReceipt extends ethers.TransactionReceipt { }

export interface VaultService {
    deposit(amount: bigint): Promise<TransactionReceipt>;
    withdraw(shares: bigint): Promise<TransactionReceipt>;
    getBalance(account: string): Promise<bigint>;
    getTotalAssets(): Promise<bigint>;
    getSharePrice(): Promise<bigint>;
}

export interface StrategyInfo {
    address: string;
    name: string;
    allocation: bigint;
    apr: bigint;
    isActive: boolean;
}
