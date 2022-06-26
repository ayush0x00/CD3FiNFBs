## Non Fungible Bonds

This repo contains the codebase and documentation of the NFB (Non Fungible Bonds). The code is build using the [truffle](https://trufflesuite.com) framework. The whitepaper of NFB can be found on [CinemaDraft](https://bit.ly/38oKZVP).

### Compiling the contracts

```bash
truffle compile
```

### Migrating contracts to development network

Make sure `truffle-config.js` has proper configuration for the desired network.

```bash
truffle migrate --network <network-name>
```

Replace `network-name` with the desired network according to the truffle config file.
