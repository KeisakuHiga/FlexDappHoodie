import React, { Component } from "react";
import HoodieToken from "./contracts/HoodieToken.json";
import getWeb3 from "./utils/getWeb3";

import TokenForm from "./components/TokenForm";
import "./App.css";

class App extends Component {
  state = {
    web3: null,
    accounts: null,
    hoodieInstance: null,

    name: '',
    symbol: '',
    standard: '',
    totalSupply: 0,
    balanceOf: 0
  };

  componentDidMount = async () => {
    try {
      // Get network provider and web3 instance.
      const web3 = await getWeb3();

      // Use web3 to get the user's accounts.
      const accounts = await web3.eth.getAccounts();

      // Get the contract instance.
      const networkId = await web3.eth.net.getId();
      const HoodieDeployedNetwork = HoodieToken.networks[networkId];
      const hoodieInstance = new web3.eth.Contract(
        HoodieToken.abi,
        HoodieDeployedNetwork && HoodieDeployedNetwork.address,
      );

      // Set web3, accounts, and contract to the state, and then proceed with an
      // example of interacting with the contract's methods.
      this.setState({ web3, accounts, hoodieInstance }, this.getBasicInfo);
    } catch (error) {
      // Catch any errors for any of the above operations.
      alert(
        `Failed to load web3, accounts, or contract. Check console for details.`,
      );
      console.error(error);
    }
  };

  getBasicInfo = async () => {
    const { accounts, hoodieInstance } = this.state;

    const name = await hoodieInstance.methods.name().call();
    const symbol = await hoodieInstance.methods.symbol().call();
    const totalSupply = await hoodieInstance.methods.totalSupply().call();
    const balanceOf = await hoodieInstance.methods.balanceOf(accounts[0]).call();

    this.setState({ name, symbol, totalSupply, balanceOf });
  };

  render() {
    const { web3, name, symbol, totalSupply, balanceOf } = this.state
    if (!web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }
    return (
      <div className="App">
        <div>
          <h1>Welcome to {name} dapp! Get {symbol} and exchange it with Flex Dapps' Hoodie!</h1>
          <h3>Hoodie token's total supply is {totalSupply}</h3>
          <h3>You have {balanceOf} HDH now</h3>
        </div>
          <TokenForm />
      </div>
    );
  }
}

export default App;
