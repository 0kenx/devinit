# Optimized Solidity Development Template

A batteries-included Nix flake template for Solidity smart contract development with Foundry.

## Features

- **Foundry Suite**: Complete toolkit (forge, cast, anvil, chisel)
- **Security Analysis**: Slither for vulnerability detection
- **Reproducible Builds**: Nix flakes for consistent environments
- **Modern Tooling**: Latest Solidity compiler and testing framework
- **Task Automation**: Just for common development tasks
- **CI Ready**: Pre-configured checks and testing pipeline

## Quick Start

1. **Clone or copy this template to your project directory**

2. **Enter the development environment**
   ```bash
   nix develop
   # or with direnv
   echo "use flake" > .envrc && direnv allow
   ```

3. **Initialize Foundry project**
   ```bash
   just init
   ```

4. **Start developing**
   ```bash
   just build       # Build contracts
   just test        # Run tests
   just help        # See all commands
   ```

## Project Structure

```
.
├── flake.nix          # Nix development environment
├── foundry.toml       # Foundry configuration
├── justfile           # Task automation
├── src/               # Smart contracts
├── test/              # Test files
├── script/            # Deployment scripts
└── lib/               # Dependencies (via forge install)
```

## Common Tasks

```bash
# Development
just build              # Build contracts
just test               # Run tests
just test-verbose       # Run tests with detailed output
just watch-test         # Run tests on file changes
just fmt                # Format Solidity code

# Security
just slither            # Run security analysis
just slither-high       # Check high-severity issues only

# Local Testing
just anvil              # Start local Ethereum node
just anvil-fork         # Fork mainnet locally
just deploy-local       # Deploy to local network

# Gas Optimization
just test-gas           # Test with gas reporting
just snapshot           # Create gas snapshot
just snapshot-diff      # Compare gas usage

# Code Coverage
just coverage           # Generate coverage report
just coverage-report    # Generate detailed coverage

# Contract Inspection
just abi CONTRACT       # Show contract ABI
just storage CONTRACT   # Show storage layout
just flatten CONTRACT   # Flatten for verification

# CI/CD
just check              # Run all checks
just ci                 # Full CI pipeline
```

## Environment Variables

Create a `.env` file (gitignored) for sensitive data:

```bash
# RPC URLs
ETH_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY

# API Keys
ETHERSCAN_API_KEY=your_etherscan_key
ARBISCAN_API_KEY=your_arbiscan_key

# Private keys (for deployment)
PRIVATE_KEY=0x...
```

## Foundry Configuration

The `foundry.toml` includes:
- **Solidity 0.8.24** with Cancun EVM features
- **Optimizer** enabled with 200 runs
- **Gas reporting** on all contracts
- **Multiple profiles**: default, ci, lite
- **Multi-chain RPC endpoints**

## Testing

```bash
# Run all tests
just test

# Run specific test
just test-match testDepositAndWithdraw

# Run tests for specific contract
just test-contract MyTokenTest

# Verbose output
just test-verbose

# With gas reporting
just test-gas

# Watch mode
just watch-test
```

## Deployment

```bash
# Deploy to local anvil
just deploy-local

# Deploy to Sepolia testnet
just deploy-sepolia

# Verify on Etherscan
just verify ContractName 0xContractAddress
```

## Security

Always run security checks before deployment:

```bash
just slither              # Full security analysis
just slither-high         # High-severity issues only
```

## Tips

1. **Use Chisel for quick testing**: `just repl`
2. **Fork mainnet for integration tests**: `just anvil-fork`
3. **Generate templates**: `just new-contract MyToken`
4. **Keep snapshots updated**: `just snapshot` after optimizations
5. **Run CI locally**: `just ci` before pushing

## Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Docs](https://docs.soliditylang.org/)
- [Slither Documentation](https://github.com/crytic/slither)
