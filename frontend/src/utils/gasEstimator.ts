import { ethers } from 'ethers';

/**
 * Utility function to estimate gas for a transaction and add a buffer (e.g., 20%)
 * to ensure execution success under volatile network conditions.
 * 
 * @param contract The ethers contract instance
 * @param methodName The name of the method to estimate
 * @param args The arguments array for the method
 * @param bufferMultiplier Multiplier to add safety buffer (default: 1.2 for 20%)
 * @returns Estimated gas limit with buffer
 */
export const estimateGasWithBuffer = async (
    contract: ethers.Contract,
    methodName: string,
    args: any[],
    bufferMultiplier = 120n
): Promise<bigint> => {
    try {
        const estimatedGas = await contract[methodName].estimateGas(...args);
        // Apply buffer (e.g., multiply by 120, divide by 100 for a 20% buffer)
        return (estimatedGas * bufferMultiplier) / 100n;
    } catch (error) {
        console.warn(`Gas estimation failed for ${methodName}, falling back to default or failing tx.`, error);
        throw error;
    }
};
