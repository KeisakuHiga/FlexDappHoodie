import React, { Component } from "react";
import HoodieToken from "./contracts/HoodieToken.json";
import DaiAbi from "./contracts/DaiAbi.json";
import RDaiAbi from "./contracts/RDaiAbi.json";
import getWeb3 from "./utils/getWeb3";
import DepositForm from "./components/DepositForm";
import ApproveRDai from "./components/ApproveRDai";
import "./App.css";
import BigNumber from "big-number";

class App extends Component {
  state = {
    web3: null,
    accounts: null,
    hoodieInstance: null,
    daiInstance: null,
    rDaiInstance: null,

    name: '',
    symbol: '',
    standard: '',
    totalSupply: 0,
    balanceOf: 0,
    owner: null,
    hatID: null,
    balanceOfDai: 0,
    amountOfRDai: 0,
    addressOfRDaiContract: null,

    userApprovedRDai: null,
    spender: null,
  };

  componentDidMount = async () => {
    try {
      // Get network provider and web3 instance.
      const web3 = await getWeb3();

      // Use web3 to get the user's accounts.
      const accounts = await web3.eth.getAccounts();

      const networkId = await web3.eth.net.getId();
      // Get contract instance.
      const HoodieDeployedNetwork = HoodieToken.networks[networkId];
      const hoodieInstance = new web3.eth.Contract(
        HoodieToken.abi,
        HoodieDeployedNetwork && HoodieDeployedNetwork.address,
        );
        console.log(hoodieInstance)
        
      // Create DAI contract instance.
      const daiABI = DaiAbi;
      const addressOfDaiContract = '0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa';
      const daiInstance = new web3.eth.Contract(daiABI, addressOfDaiContract);
        
      // Create DAI contract instance.
      const rDaiABI = RDaiAbi;
      const addressOfRDaiContract = '0xb0C72645268E95696f5b6F40aa5b12E1eBdc8a5A';
      const rDaiInstance = new web3.eth.Contract(rDaiABI, addressOfRDaiContract);
      // Set web3, accounts, and contract to the state, and then proceed with an
      // example of interacting with the contract's methods.
      this.setState({ web3, accounts, hoodieInstance, daiInstance, rDaiInstance, addressOfRDaiContract }, this.getBasicInfo);
    } catch (error) {
      // Catch any errors for any of the above operations.
      alert(
        `Failed to load web3, accounts, or contract. Check console for details.`,
      );
      console.error(error);
    }
  };

  getBasicInfo = async () => {
    const { web3, accounts, hoodieInstance, daiInstance, rDaiInstance } = this.state;
    const contract = hoodieInstance.methods;
    const dai = daiInstance.methods;
    const rDai = rDaiInstance.methods;
    const name = await contract.name().call();
    const owner = await contract.owner().call();
    const symbol = await contract.symbol().call();
    const totalSupply = await contract.totalSupply().call();
    const balanceOf = await contract.balanceOf(accounts[0]).call();
    const hatID = await contract.hatID().call();
    // const balanceOfDai = await web3.utils.fromWei(`${await dai.balanceOf(accounts[0]).call()}`, 'Ether');
    // const balanceOfRDai = await web3.utils.fromWei(`${await rDai.balanceOf(accounts[0]).call()}`, 'Ether');
    const balanceOfDai = await dai.balanceOf(accounts[0]).call();
    const balanceOfRDai = await rDai.balanceOf(accounts[0]).call();
    console.log(balanceOfRDai)
    this.setState({ name, owner, symbol, totalSupply, balanceOf, hatID, balanceOfDai, balanceOfRDai, });
  };

  handleApprove = async (e) => {
    e.preventDefault()
    const { daiInstance, accounts, addressOfRDaiContract, balanceOfDai }  = this.state
    // const BNMax = new BigNumber(2).pow(256).minus(1)
    try {
      await daiInstance.methods.approve(addressOfRDaiContract, balanceOfDai).send({ from: accounts[0] });
      this.setState({ userApprovedRDai: true })
      const allowance = await daiInstance.methods.allowance(accounts[0], addressOfRDaiContract).call()
      console.log(allowance)
      
    } catch (err) {
      console.log(err.message)
    }
  }

  render() {
    const { web3, accounts, hoodieInstance, daiInstance, name, owner, symbol, totalSupply, balanceOf, hatID, balanceOfDai, userApprovedRDai, rDaiInstance, addressOfRDaiContract } = this.state
    if (!web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }
    return (
      <div className="App">
        <div>
          <h1>Welcome to {name} dapp! Get {symbol} and exchange it with Flex Dapps' Hoodie!</h1>
          <h3>Hoodie token's total supply is {totalSupply}</h3>
          <h3>You have {balanceOf} FDH now</h3>
          <p>Owner is {owner}</p>
          <p>Hat ID is {hatID}</p>
          <p>Your DAI balance is {balanceOfDai}</p>

        </div>
        {userApprovedRDai ? 
          <DepositForm 
            web3={web3}
            daiInstance={daiInstance}
            rDaiInstance={rDaiInstance}
            addressOfRDaiContract={addressOfRDaiContract}
            accounts={accounts}
            hatID={hatID} /> :
          <ApproveRDai 
            web3={web3}
            daiInstance={daiInstance}
            hoodieInstance={hoodieInstance}
            accounts={accounts}
            userApprovedRDai={userApprovedRDai}
            handleApprove={this.handleApprove} />
        }
      </div>
    );
  }
}

export default App;
