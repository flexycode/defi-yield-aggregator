import { useWallet } from './hooks/useWallet'
import './App.css'

function App() {
  const { account, isConnected, isConnecting, connect, disconnect } = useWallet()

  return (
    <div className="app-container">
      <header className="header">
        <h1>DeFi Yield Aggregator</h1>
        <div className="wallet-section">
          {isConnected ? (
            <div className="wallet-info">
              <span>{account?.slice(0, 6)}...{account?.slice(-4)}</span>
              <button onClick={disconnect}>Disconnect</button>
            </div>
          ) : (
            <button onClick={connect} disabled={isConnecting}>
              {isConnecting ? 'Connecting...' : 'Connect Wallet'}
            </button>
          )}
        </div>
      </header>

      <main className="main-content">
        <section className="hero">
          <h2>Optimize Your DeFi Yields</h2>
          <p>
            Automated cross-protocol yield optimization across Aave, Compound, and Curve.
          </p>
        </section>

        <div className="card">
          <h3>Phase 2: Frontend Initialized</h3>
          <p>
            React + Vite + TypeScript + Ethers setup complete.
          </p>
        </div>
      </main>
    </div>
  )
}

export default App
