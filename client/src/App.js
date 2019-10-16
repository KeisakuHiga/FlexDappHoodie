import React, { Component } from "react";
import HoodieToken from "./contracts/HoodieToken.json";
import DaiAbi from "./contracts/DaiAbi.json";
import RDaiAbi from "./contracts/RDaiAbi.json";
import getWeb3 from "./utils/getWeb3";
import DepositForm from "./components/DepositForm";
import RedeemForm from "./components/RedeemForm";
import TransferRDaiForm from "./components/TransferRDaiForm";
import Approve from "./components/Approve";
import PayInterest from "./components/PayInterest";
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
    balanceOfRDai: 0,
    balanceOfDaiHoodie: 0,
    balanceOfRDaiHoodie: 0,
    addressOfRDaiContract: null,

    userApproved: null,
    allowance: 0,
    allowanceRDai: 0,
    spender: null,
    interestPayableOf: 0,
    waitingList: [],

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
    // hoodie
    const contract = hoodieInstance.methods;
    const hoodieAddress = hoodieInstance.options.address;
    const name = await contract.name().call();
    const owner = await contract.owner().call();
    const symbol = await contract.symbol().call();
    const totalSupply = await contract.totalSupply().call();
    const balanceOf = await contract.balanceOf(accounts[0]).call();
    const hatID = await contract.hatID().call();
    const waitingList = await contract.getWaitingList().call();
    // dai
    const dai = daiInstance.methods;
    const balanceOfDai = await dai.balanceOf(accounts[0]).call();
    const balanceOfDaiHoodie = await dai.balanceOf(hoodieAddress).call();
    const allowance = await dai.allowance(accounts[0], hoodieInstance.options.address).call()
    const allowanceRDai = await dai.allowance(hoodieInstance.options.address, rDaiInstance.options.address).call()
    // rDai
    const rDai = rDaiInstance.methods;
    const balanceOfRDaiHoodie = await rDai.balanceOf(hoodieAddress).call();
    const balanceOfRDai = await rDai.balanceOf(accounts[0]).call();
    const interestPayableOf = await rDai.interestPayableOf(owner).call();
    console.log(web3.utils.fromWei(interestPayableOf, 'ether'))
    // const interestPayableOf = await rDai.interestPayableOf('0x93438172245D2c0e2dd511659A1518210e52AF9c').call();
    // console.log(web3.utils.fromWei(interestPayableOf, 'ether'))

    this.setState({ name, owner, symbol, totalSupply, balanceOf, hatID, balanceOfDai, 
      balanceOfRDai, interestPayableOf, allowance, balanceOfDaiHoodie, hoodieAddress, 
      balanceOfRDaiHoodie, allowanceRDai, waitingList, 
    });
  };

  handleApprove = async (e) => {
    e.preventDefault()
    const { hoodieInstance, daiInstance, accounts, balanceOfDai }  = this.state
    // const BNMax = new BigNumber(2).pow(256).minus(1)
    const hoodieAddress = hoodieInstance.options.address
    try {
      await daiInstance.methods.approve(hoodieAddress, balanceOfDai).send({ from: accounts[0] });
      this.setState({ userApproved: true })
      const allowance = await daiInstance.methods.allowance(accounts[0], hoodieAddress).call()
      console.log(allowance)
      
    } catch (err) {
      console.log(err.message)
    }
  }

  render() {
    const { web3, accounts, hoodieInstance, daiInstance, name, owner, symbol, totalSupply,
            balanceOf, hatID, balanceOfDai, balanceOfRDai, userApproved, rDaiInstance, addressOfRDaiContract,
            interestPayableOf, allowance, balanceOfDaiHoodie, hoodieAddress, balanceOfRDaiHoodie, allowanceRDai, 
            waitingList, 
          } = this.state
    if (!web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }

    return (
      <div className="App">
        <div>
          <h1>Welcome to {name} dapp!</h1>
          <h1>Get {symbol} and exchange it with Flex Dapps' Hoodie!</h1>
          <h3>Hoodie token's total supply is {web3.utils.fromWei(`${totalSupply}`, 'ether')}</h3>
          <h3>You have {web3.utils.fromWei(`${balanceOf}`, 'ether')} FDH now</h3>
          <p>Owner is {owner}</p>
          <p>Hat ID is {hatID}</p>
          <p>Your DAI balance is {web3.utils.fromWei(`${balanceOfDai}`, 'ether')}</p>
          <p>Your rDAI balance is {web3.utils.fromWei(`${balanceOfRDai}`, 'ether')}</p>

          <br />

          <h4>Allowance is {web3.utils.fromWei(`${allowance}`, 'ether')}</h4>
          <Approve 
            web3={web3}
            daiInstance={daiInstance}
            hoodieInstance={hoodieInstance}
            accounts={accounts}
            userApproved={userApproved}
            handleApprove={this.handleApprove}
          />

          <br />

          <p>interestPayableOf=> {web3.utils.fromWei(`${interestPayableOf}`, 'ether')}</p>

          <br />

          <h3>Info of Hoodie DApp</h3>
          <p>Hoddie address: {hoodieAddress}</p>
          <p>DAI amount: {web3.utils.fromWei(`${balanceOfDaiHoodie}`, 'ether')}</p>
          <p>rDAI amount: {web3.utils.fromWei(`${balanceOfRDaiHoodie}`, 'ether')}</p>
          <p>allowanceRDai: {web3.utils.fromWei(`${allowanceRDai}`, 'ether')}</p>
          <p>Waiting List: {waitingList}</p>
        </div>

        <br />

        <DepositForm 
          web3={web3}
          hoodieInstance={hoodieInstance}
          daiInstance={daiInstance}
          rDaiInstance={rDaiInstance}
          addressOfRDaiContract={addressOfRDaiContract}
          accounts={accounts}
          hatID={hatID}
        />

        <br />

        <RedeemForm
          web3={web3}
          rDaiInstance={rDaiInstance}
          accounts={accounts}
        />

        <br />
        
        <TransferRDaiForm
          web3={web3}
          rDaiInstance={rDaiInstance}
          accounts={accounts}
        />

        <br />
        
        <PayInterest
          web3={web3}
          rDaiInstance={rDaiInstance}
          accounts={accounts}
        />
      </div>
    );
  }
}

export default App;
