import { InjectedConnector } from '@web3-react/injected-connector';

export const injected = new InjectedConnector({
    supportedChainIds: [1, 5, 137, 11155111], // Mainnet, Goerli, Polygon, Sepolia
});

export const NETWORKS = {
    1: {
        name: 'Ethereum Mainnet',
        currency: 'ETH',
        rpc: 'https://mainnet.infura.io/v3/YOUR_PROJECT_ID',
        explorer: 'https://etherscan.io',
    },
    11155111: {
        name: 'Sepolia Testnet',
        currency: 'ETH',
        rpc: 'https://sepolia.infura.io/v3/YOUR_PROJECT_ID',
        explorer: 'https://sepolia.etherscan.io',
    },
};
