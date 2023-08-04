## Foundry-Demo

This is a demostration of Foundry capabilities and Solidity smart contract features.

Check Solidity contracts under `src` folder.

Each of those contracts is targeted at a specific Solidity feature and/or Foundry feature.

Each of those contracts has a corresponding test file under `test` folder, with a few exceptions if the test file is not written yet or that feature is not important enough.

Each test file describes scenarios for the contract's operation.

You can find many script names in package.json file.

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Installation

Install Foundry according to doc: https://book.getfoundry.sh/getting-started/installation

```
curl -L https://foundry.paradigm.xyz | bash
```

To install dependencies used in this repo: `make install`

To clean then install: `make all`

To build: `make build`
https://book.getfoundry.sh/getting-started/installation
To run test: `forge test --match-path test/Counter.t.sol -vv`

## Environment Variables

Implement the .env file and run `source .env` before you run any package.json script that requires environment variables.

Make `.env` file from `.env.example`.

Then fill out the following in that .env file:

```
MAINNET_RPC_URL=
SEPOLIA_RPC_URL=
GOERLI_RPC_URL=
ETHERSCAN_API_KEY=
SIGNER1=
PRIVATE_KEY=
PoolAddressesProviderAaveV3Sepolia=
```

Run each package.json script via `npm run <script_name>` or `pnpm run <script_name>`

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
