# Staking smart contracts

Solidity contracts for BEP20-style tokens and staking on BNB Smart Chain (BSC). This repository contains interfaces, token implementations, and staking pools intended for deployment in a controlled environment after review and testing.

## Contents

| File | Description |
|------|-------------|
| `IBEP20.sol` | BEP20 interface |
| `TOKEN.sol` | Token contract (Solidity ≥ 0.5.5) |
| `BSC_Token.sol` | BSC-oriented token implementation |
| `ERC20_Fountain.sol` | ERC20-related logic |
| `TOKEN_staking_BSC.sol` | Staking contract for BSC |
| `QUAI_staking.sol` | Staking contract (QUAI) |

Primary contracts target **Solidity ^0.7.5**; `TOKEN.sol` uses **≥ 0.5.5**.

## Development

- Compile and test with your toolchain of choice (e.g. [Hardhat](https://hardhat.org/) or [Foundry](https://book.getfoundry.sh/)).
- Configure networks, keys, and deployment scripts outside this repository as appropriate for your setup.

## Security

Smart contracts handle value. **Do not deploy to mainnet without professional audits, thorough tests, and operational procedures.** This code is provided as-is; use at your own risk.

## License

See SPDX license identifiers in individual source files (e.g. AGPL-3.0-or-later where noted).

## Contact

**Telegram:** [@igor_moondev](https://t.me/igor_moondev)

For collaboration, deployment questions, or security-related inquiries, reach out on Telegram.
