import React, { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { ethers } from 'ethers';

interface Web3ContextType {
    account: string | null;
    chainId: number | null;
    isConnected: boolean;
    isConnecting: boolean;
    provider: ethers.BrowserProvider | null;
    signer: ethers.JsonRpcSigner | null;
    connect: () => Promise<void>;
    disconnect: () => void;
    switchNetwork: (chainId: number) => Promise<void>;
}

const Web3Context = createContext<Web3ContextType | undefined>(undefined);

export const Web3Provider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const [account, setAccount] = useState<string | null>(null);
    const [chainId, setChainId] = useState<number | null>(null);
    const [isConnecting, setIsConnecting] = useState(false);
    const [provider, setProvider] = useState<ethers.BrowserProvider | null>(null);
    const [signer, setSigner] = useState<ethers.JsonRpcSigner | null>(null);

    const connect = useCallback(async () => {
        if (typeof window.ethereum === 'undefined') {
            alert('Please install MetaMask');
            return;
        }

        try {
            setIsConnecting(true);
            const browserProvider = new ethers.BrowserProvider(window.ethereum);
            const accounts = await browserProvider.send('eth_requestAccounts', []);
            const network = await browserProvider.getNetwork();
            const browserSigner = await browserProvider.getSigner();

            setAccount(accounts[0]);
            setChainId(Number(network.chainId));
            setProvider(browserProvider);
            setSigner(browserSigner);
        } catch (error) {
            console.error('Connection error:', error);
        } finally {
            setIsConnecting(false);
        }
    }, []);

    const disconnect = useCallback(() => {
        setAccount(null);
        setChainId(null);
        setProvider(null);
        setSigner(null);
    }, []);

    const switchNetwork = useCallback(async (targetChainId: number) => {
        if (!window.ethereum) return;
        try {
            await window.ethereum.request({
                method: 'wallet_switchEthereumChain',
                params: [{ chainId: `0x${targetChainId.toString(16)}` }],
            });
        } catch (error) {
            console.error('Network switch error:', error);
        }
    }, []);

    useEffect(() => {
        if (window.ethereum) {
            window.ethereum.on('accountsChanged', (accounts: string[]) => {
                if (accounts.length > 0) {
                    setAccount(accounts[0]);
                } else {
                    disconnect();
                }
            });

            window.ethereum.on('chainChanged', (hexChainId: string) => {
                setChainId(parseInt(hexChainId, 16));
            });
        }

        return () => {
            if (window.ethereum) {
                window.ethereum.removeListener('accountsChanged', () => { });
                window.ethereum.removeListener('chainChanged', () => { });
            }
        };
    }, [disconnect]);

    return (
        <Web3Context.Provider
            value={{
                account,
                chainId,
                isConnected: !!account,
                isConnecting,
                provider,
                signer,
                connect,
                disconnect,
                switchNetwork,
            }}
        >
            {children}
        </Web3Context.Provider>
    );
};

export const useWeb3 = () => {
    const context = useContext(Web3Context);
    if (context === undefined) {
        throw new Error('useWeb3 must be used within a Web3Provider');
    }
    return context;
};
