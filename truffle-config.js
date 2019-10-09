const path = require("path");
const HDWalletProvider = require("truffle-hdwallet-provider");

// This mnemonic is from $ ganache-cli
const mnemonic = "monitor script cloud bounce forward sight hope before actual panel hazard consider";

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  contracts_build_directory: path.join(__dirname, "client/src/contracts"),
  networks: {
    develop: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*"
    },
    test: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*"
    },
    // rinkeby: {
    //   provider: function() { 
    //     return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/v3/38d8affd8ee14505a8485d2725bcd6df");
    //   },
    //   network_id: 4,
    //   gas: 4500000,
    //   gasPrice: 10000000000,
    // },
  }
};
