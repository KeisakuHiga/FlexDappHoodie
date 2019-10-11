const path = require("path");
const HDWalletProvider = require("truffle-hdwallet-provider");

// SHOULD USE .env
// This mnemonic is from $ ganache-cli
// accounts[0] = 0x2471e35F51CF54265B20cCFAc3857c2DceEf7349;
const mnemonic = "ghost industry evidence issue arrive sustain attend claim oven often limb work";

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
        return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/v3/38d8affd8ee14505a8485d2725bcd6df");
      },
      network_id: 4,
      gas: 4500000,
      gasPrice: 10000000000,
    },
  }
};
