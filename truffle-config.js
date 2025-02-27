// Custom Data Starts
const NAMHOON_accessKeyId = "KASK82CE37A0GKII4P3HHWX6"; // support@indinity.co
const NAMHOON_secretAccessKey = "6UjyrBLdp7JtLBVdjxOaIrmxEltNKOdsQzxomNMe";
// Custom Data Ends
/**
 * Use this file to configure your truffle project. It's seeded with some
 * common settings for different networks and features like migrations,
 * compilation and testing. Uncomment the ones you need or modify
 * them to suit your project as necessary.
 *
 * More information about configuration can be found at:
 *
 * truffleframework.com/docs/advanced/configuration
 *
 * To deploy via Infura you'll need a wallet provider (like @truffle/hdwallet-provider)
 * to sign your transactions before they're sent to a remote public node. Infura accounts
 * are available for free at: infura.io/register.
 *
 * You'll also need a mnemonic - the twelve word phrase the wallet uses to generate
 * public/private key pairs. If you're publishing your code to GitHub make sure you load this
 * phrase from a file you've .gitignored so it doesn't accidentally become public.
 *
 */

// const HDWalletProvider = require('@truffle/hdwallet-provider');
// const infuraKey = "fj4jll3k.....";
//
const fs = require("fs");
const path = require("path");
const Caver = require("caver-js");
// const mnemonic = fs.readFileSync(".secret").toString().trim();

const accessKeyId = NAMHOON_accessKeyId;
const secretAccessKey = NAMHOON_secretAccessKey;

const HDWalletProvider = require("truffle-hdwallet-provider-klaytn");
const privateKey = "0x123";
const cypressPrivateKey = "0x456";

const NAMHOON_TEST_WALLET = "0x23072A209e8519e515D11b0E49e15770F9c812Df";
const NAMHOON_TEST_WALLET_PK = "0x1df474073516dc32bfe911894b8a47e8951805c0bfd64bafbcd9f3747d45abd5";

module.exports = {
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */

  networks: {
    // Useful for testing. The `development` name is special - truffle uses it by default
    // if it's defined here and no other network is specified at the command line.
    // You should run a client (like ganache-cli, geth or parity) in a separate terminal
    // tab if you use this network and you must also set the `host`, `port` and `network_id`
    // options below to some value.
    //
    // for ganache
    development: {
      host: "127.0.0.1", // Localhost (default: none)
      port: 8545, // Standard Ethereum port (default: none)
      network_id: "*", // Any network (default: none)
      gas: 80000000,
    },
    klaytn: {
      provider: () => {
        const pks = JSON.parse(fs.readFileSync(path.resolve(__dirname) + "/privateKeys.js"));

        return new HDWalletProvider(pks, "http://localhost:8551", 0, pks.length);
      },
      network_id: "203", //Klaytn baobab testnet's network id
      gas: "8500000",
      gasPrice: null,
    },
    kasBaobab: {
      provider: () => {
        const option = {
          headers: [
            { name: "Authorization", value: "Basic " + Buffer.from(accessKeyId + ":" + secretAccessKey).toString("base64") },
            { name: "x-chain-id", value: "1001" },
          ],
          keepAlive: false,
        };
        return new HDWalletProvider(NAMHOON_TEST_WALLET_PK, new Caver.providers.HttpProvider("https://node-api.klaytnapi.com/v1/klaytn", option));
      },
      network_id: "1001", //Klaytn baobab testnet's network id
      gas: "8500000",
      gasPrice: "750000000000",
    },
    kasCypress: {
      provider: () => {
        const option = {
          headers: [
            { name: "Authorization", value: "Basic " + Buffer.from(accessKeyId + ":" + secretAccessKey).toString("base64") },
            { name: "x-chain-id", value: "8217" },
          ],
          keepAlive: false,
        };
        return new HDWalletProvider(cypressPrivateKey, new Caver.providers.HttpProvider("https://node-api.klaytnapi.com/v1/klaytn", option));
      },
      network_id: "8217", //Klaytn baobab testnet's network id
      gas: "8500000",
      gasPrice: "750000000000",
    },
    baobab: {
      provider: () => {
        return new HDWalletProvider(privateKey, "http://your.baobab.en:8551");
      },
      network_id: "1001", //Klaytn baobab testnet's network id
      gas: "8500000",
      gasPrice: null,
    },
    cypress: {
      provider: () => {
        return new HDWalletProvider(privateKey, "http://your.cypress.en:8551");
      },
      network_id: "8217", //Klaytn mainnet's network id
      gas: "8500000",
      gasPrice: null,
    },

    // development: {
    //  host: "127.0.0.1",     // Localhost (default: none)
    //  port: 8545,            // Standard Ethereum port (default: none)
    //  network_id: "*",       // Any network (default: none)
    // },

    // Another network with more advanced options...
    // advanced: {
    // port: 8777,             // Custom port
    // network_id: 1342,       // Custom network
    // gas: 8500000,           // Gas sent with each transaction (default: ~6700000)
    // gasPrice: 20000000000,  // 20 gwei (in wei) (default: 100 gwei)
    // from: <address>,        // Account to send txs from (default: accounts[0])
    // websockets: true        // Enable EventEmitter interface for web3 (default: false)
    // },

    // Useful for deploying to a public network.
    // NB: It's important to wrap the provider as a function.
    // ropsten: {
    // provider: () => new HDWalletProvider(mnemonic, `https://ropsten.infura.io/v3/YOUR-PROJECT-ID`),
    // network_id: 3,       // Ropsten's id
    // gas: 5500000,        // Ropsten has a lower block limit than mainnet
    // confirmations: 2,    // # of confs to wait between deployments. (default: 0)
    // timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
    // skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    // },

    // Useful for private networks
    // private: {
    // provider: () => new HDWalletProvider(mnemonic, `https://network.io`),
    // network_id: 2111,   // This network is yours, in the cloud.
    // production: true    // Treats this network as if it was a public net. (default: false)
    // }
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.5.6", // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {
        // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200,
        },
        evmVersion: "constantinople",
      },
    },
  },
  plugins: ["truffle-contract-size"],
};
