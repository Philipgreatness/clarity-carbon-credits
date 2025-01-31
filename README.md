# Carbon Credits Trading System

A blockchain-based carbon credits trading system implemented in Clarity for the Stacks blockchain.

## Features

- Issue carbon credits with project metadata
- Multi-validator approval system for credit verification
- Dynamic pricing mechanism for credit issuers
- Transfer credits between accounts
- Retire credits to offset carbon footprint
- Verified issuer and validator system
- Track total credits issued and retired
- Full transaction history on blockchain

## Contract Functions

### Core Functions
- Issue new carbon credits (verified issuers only)
- Validate credits (requires multiple validator approvals)
- Transfer credits between accounts
- Retire credits
- Set credit prices (issuer specific)

### Administrative Functions
- Add/remove verified issuers (admin only)
- Add/remove verified validators (admin only)
- Set validation thresholds

### View Functions
- View credit balances and metadata
- Check credit prices
- View validation status
- Track total system statistics

## Credit Validation System

The system implements a multi-validator approval process:
1. Issuers propose new credits
2. Multiple validators must approve the credits
3. Credits are minted only after reaching validation threshold
4. Each validator can only validate once per issuer

## Dynamic Pricing

- Each issuer can set custom prices for their credits
- Prices can be updated as market conditions change
- Price history is tracked on-chain

## Getting Started

1. Install Clarinet
2. Clone this repository
3. Run `clarinet test` to execute the test suite
4. Deploy to testnet/mainnet using Clarinet
