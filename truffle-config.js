const path = require("path");
const HDWalletProvider = require("truffle-hdwallet-provider");
require('dotenv').config()

// This mnemonic is from $ ganache-cli
// accounts[0] = 0x2471e35F51CF54265B20cCFAc3857c2DceEf7349;

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  contracts_build_directory: path.join(__dirname, "client/src/contracts"),
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*"
    },
    test: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*"
    },
    rinkeby: {
      provider: function() { 
        return new HDWalletProvider(process.env.MNEMONIC, `https://rinkeby.infura.io/v3/${process.env.RINKEBY_API}`);
      },
      network_id: 4,
      gas: 4500000,
      gasPrice: 10000000000,
    },
  },
  compilers: {
    solc: {
      version: "0.5.8"
    }
  }
};
