# Chillar Stablecoin

An experimental ETH-backed stablecoin system with a depositor-funded collateral buffer. Users mint and burn `STC` against ETH at a price provided by an on-chain Oracle, while liquidity providers deposit ETH to absorb deficits and earn fee-backed upside through `DPC` (DepositorCoin).

## What this is

- **Stablecoin core**: `STC` is minted by sending ETH, and burned to redeem ETH at the Oracle price.
- **Collateral buffer**: depositors add ETH to cover deficits and receive `DPC` representing a claim on the surplus.
- **Fee flow**: mint and burn fees stay in the contract and increase surplus for `DPC` holders.
- **Manual Oracle**: price is updated by an owner address (intended for testing / prototyping).

## Contracts

- `contracts/StableCoin.sol` — `STC` mint/burn logic, fee accounting, collateral buffer entry/exit.
- `contracts/DepositorCoin.sol` — `DPC` ERC20 minted/burned by `StableCoin` as the buffer share token.
- `contracts/Oracle.sol` — owner-updated ETH price feed.
- `contracts/WadLib.sol` — 18-decimal fixed-point math helpers.
- `contracts/ERC20.sol` — a minimal `Chillar` ERC20 token contract (not used by `StableCoin`).

## System flow

### Mint `STC`
1. User sends ETH to `StableCoin.mint()`.
2. If there are existing depositors, a fee (percentage of ETH) is retained in the contract.
3. `STC` minted equals `msg.value * oraclePrice` (in USD units; see decimals note below).

### Burn `STC`
1. User calls `StableCoin.burn(amount)`.
2. Contract verifies there is no deficit.
3. User receives ETH based on `amount / oraclePrice`, minus a fee if depositors exist.

### Deposit collateral buffer
- `depositCollateralBuffer()` is used to cover a deficit and establish (or grow) surplus.
- On first recapitalization, a 10% initial collateral ratio is enforced and a new `DPC` token is deployed.
- Subsequent deposits mint `DPC` proportional to current surplus.

### Withdraw collateral buffer
- `withdrawCollateralBuffer()` burns `DPC` and returns ETH based on the depositor share of surplus.

## Units and decimals

- `WadLib` and token supplies assume **18 decimals**.
- The Oracle price should be provided in the same 18-decimal USD-per-ETH units to keep calculations consistent (e.g., $1,500 = `1500e18`).

## Local development

### Requirements

- Node.js (LTS recommended)
- npm

### Install

```bash
npm install
```

### Compile

```bash
npx hardhat compile
```

### Start a local chain

```bash
npx hardhat node
```

## Deployment (example flow)

The repo includes a sample deploy script, but it does not yet wire the StableCoin system. A typical local flow:

1. Deploy `Oracle`.
2. Set the ETH price on the Oracle.
3. Deploy `StableCoin` with the Oracle address and a fee percentage.
4. Interact via Hardhat console or a custom script.

Example (Hardhat console):

```bash
npx hardhat console --network localhost
```

```javascript
const Oracle = await ethers.getContractFactory("Oracle");
const oracle = await Oracle.deploy();
await oracle.deployed();
await oracle.setPrice(1500n * 10n ** 18n); // $1,500 with 18 decimals

const StableCoin = await ethers.getContractFactory("StableCoin");
const stc = await StableCoin.deploy(1, oracle.address); // 1% fee
await stc.deployed();

// Mint 1 ETH worth of STC
await stc.mint({ value: ethers.utils.parseEther("1") });
```

## Project layout

- `contracts/` — Solidity contracts.
- `scripts/` — deployment scripts (currently a sample).
- `test/` — tests (currently the Hardhat default sample).

## Status and notes

- Tests and deploy script are placeholders from the Hardhat template and need to be updated for `StableCoin`.
- The system is experimental and not audited. Do not use in production or with real funds.

## License

ISC (see `package.json`).
