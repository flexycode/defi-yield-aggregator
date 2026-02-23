export const parseContractError = (error: any): string => {
    if (!error) return 'An unknown error occurred';

    // Extract from ethers.js specific error structures
    const message = error?.info?.error?.message || error?.data?.message || error?.message || String(error);

    if (message.includes('user rejected')) {
        return 'Transaction was rejected by the user.';
    }

    if (message.includes('insufficient funds')) {
        return 'Insufficient funds for transaction or gas.';
    }

    if (message.includes('allowance exceeded')) {
        return 'Insufficient token allowance. Please approve the vault to spend your tokens.';
    }

    if (message.includes('SlippageExceeded')) {
        return 'Transaction failed due to high slippage. Please try adjusting your slippage tolerance.';
    }

    if (message.includes('paused')) {
        return 'The protocol is currently paused. Transactions cannot be processed right now.';
    }

    // Generic fallback parsing for revert reasons
    const revertMatch = message.match(/execution reverted: (.*?)"/);
    if (revertMatch && revertMatch[1]) {
        return revertMatch[1];
    }

    return message;
};
