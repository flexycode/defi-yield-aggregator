import { useWeb3 } from '../contexts/Web3Context';

export const useWallet = () => {
    const { account, chainId, isConnected, isConnecting, connect, disconnect, switchNetwork } = useWeb3();

    return {
        account,
        chainId,
        isConnected,
        isConnecting,
        connect,
        disconnect,
        switchNetwork,
        shortenedAccount: account ? `${account.slice(0, 6)}...${account.slice(-4)}` : null,
    };
};
