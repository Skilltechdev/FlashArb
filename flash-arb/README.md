# Clarity Flash Arb Protocol

A decentralized flash loan protocol built on Stacks blockchain that enables users to execute arbitrage trades across different DEXs using borrowed funds without collateral.

The Flash Arb Protocol provides a secure and efficient way to execute flash loans for arbitrage opportunities. Users can borrow tokens, perform trades across different DEXs, and repay the loan within the same transaction.

## Features

- **Flash Loans**: Borrow tokens without collateral
- **Multi-DEX Support**: Execute trades across different DEX platforms
- **Whitelisting System**: Secure protocol with whitelisted DEXs and tokens
- **Dynamic Fee Structure**: Configurable fee rates with safety bounds
- **Emergency Controls**: Admin pause functionality for risk management
- **Safety Mechanisms**: Built-in checks for loan repayment and permissions

## Contract Details

### Core Functions

1. `execute-flash-loan`: Main function for executing flash loans
   - Parameters:
     - `token`: SIP-010 compliant token to borrow
     - `amount`: Amount to borrow
     - `dex-1`: First DEX for trading
     - `dex-2`: Second DEX for trading
     - `swap-data`: Optional data for custom swap logic

2. Administrative Functions:
   - `set-fee-rate`: Update the protocol fee rate
   - `set-paused`: Emergency pause mechanism
   - `whitelist-dex`: Add DEX to whitelist
   - `whitelist-token`: Add token to whitelist

### Error Codes

- `ERR-NOT-AUTHORIZED (u100)`: Unauthorized access
- `ERR-PAUSED (u101)`: Contract is paused
- `ERR-DEX-NOT-WHITELISTED (u102)`: DEX not in whitelist
- `ERR-TOKEN-NOT-WHITELISTED (u103)`: Token not in whitelist
- `ERR-INSUFFICIENT-REPAYMENT (u104)`: Loan not repaid
- `ERR-INVALID-FEE-RATE (u105)`: Fee rate out of bounds
- `ERR-ALREADY-WHITELISTED (u106)`: Entity already whitelisted

## Usage

### Prerequisites

- Stacks wallet with STX for transaction fees
- Access to whitelisted tokens and DEXs

### Example Usage

```clarity
;; Execute a flash loan
(contract-call? .flash-arb-v1 execute-flash-loan
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.token-x
    u1000000
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.dex-1
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.dex-2
    none)
```

## Security Considerations

1. **Atomic Execution**: All operations must complete successfully, or the entire transaction reverts
2. **Whitelisting**: Only approved DEXs and tokens can be used
3. **Fee Limits**: Maximum fee rate capped at 10%
4. **Access Control**: Administrative functions restricted to contract owner
5. **Input Validation**: Comprehensive checks on all user inputs

## Development

### Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/clarity-flash-arb.git
```

2. Install dependencies:
```bash
npm install
```

### Testing

Run the test suite:
```bash
clarinet test
```
## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request