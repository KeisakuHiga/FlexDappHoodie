import React, { Component } from "react";
import HoodieToken from "./contracts/HoodieToken.json";
import DaiAbi from "./contracts/DaiAbi.json";
import RDaiAbi from "./contracts/RDaiAbi.json";
import getWeb3 from "./utils/getWeb3";
import DepositForm from "./components/DepositForm";
import RedeemForm from "./components/RedeemForm";
import Approve from "./components/Approve";
import IssueFDH from "./components/IssueFDH";
import "./App.css";
import BigNumber from "big-number";

class App extends Component {
  state = {
    web3: null,
    accounts: null,
    hoodieInstance: null,
    daiInstance: null,
    rDaiInstance: null,

    owner: null,
    hatID: null,
    numOfHoodie: 0, 
    balanceOfDai: 0,
    balanceOfRDai: 0,
    addressOfRDaiContract: null,
    depositedAmount: 0,

    userApproved: null,
    allowance: 0,
    isWaiting: false,
    spender: null,
    generatedInterestAmt: 0,
    waitingUserNumber: 0,
    hoodieReceivers: 0,
    nextInLine: null,

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
      const addressOfRDaiContract = '0x6AA5c6aB94403Bdbbf74f21607D46Be631E6CcC5'; // latest
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
    const owner = await contract.owner().call();
    const hatID = await contract.hatID().call();
    const hoodieReceivers = await contract.hoodieReceivers().call();
    
    const userNumber = await contract.userNumbers(accounts[0]).call()
    const user = await contract.users(userNumber).call()
    console.log(user);
    const isWaiting = user.isWaiting
    const depositedAmount = user.depositedAmount
    
    const recipientNumber = await contract.recipientNumber().call();
    const nextInLineUser = await contract.users(recipientNumber).call()
    const nextInLine = nextInLineUser.userAddress
    
    this.setState({ hoodieAddress, owner, hatID, isWaiting, depositedAmount, 
                    hoodieReceivers, nextInLine
                  })

    // dai
    const dai = daiInstance.methods;
    const balanceOfDai = await dai.balanceOf(accounts[0]).call();
    const allowance = await dai.allowance(accounts[0], hoodieInstance.options.address).call()
    // rDai
    const rDai = rDaiInstance.methods;
    const balanceOfRDai = await rDai.balanceOf(accounts[0]).call();
    const generatedInterestAmt = await rDai.interestPayableOf(owner).call();
    console.log('generatedInterestAmt', web3.utils.fromWei(generatedInterestAmt, 'ether'))

    // const receivedSavingsOf = await rDai.receivedSavingsOf(owner).call()
    // console.log('receivedSavingsOf', web3.utils.fromWei(receivedSavingsOf, 'ether'))
    // const receivedLoanOf = await rDai.receivedLoanOf(owner).call();
    // console.log('receivedLoanOf', web3.utils.fromWei(receivedLoanOf, 'ether'))
    // console.log('difference: ', receivedSavingsOf - receivedLoanOf)
    
    this.setState({ balanceOfDai, balanceOfRDai, generatedInterestAmt, allowance, });
  };

  handleApprove = async (e) => {
    e.preventDefault()
    const { hoodieInstance, daiInstance, rDaiInstance, accounts, balanceOfDai, hatID, owner }  = this.state
    // const BNMax = new BigNumber(2).pow(256).minus(1)
    const hoodieAddress = hoodieInstance.options.address
    try {
      await daiInstance.methods.approve(hoodieAddress, balanceOfDai).send({ from: accounts[0] });
      this.setState({ userApproved: true })
      await rDaiInstance.methods.changeHat(hatID).send({ from: accounts[0] });
      // await rDaiInstance.methods.payInterest(owner).send({ from: accounts[0] });
      
      
    } catch (err) {
      console.log(err.message)
    }
  }

  render() {
    const { web3, accounts, hoodieInstance, daiInstance, owner, hatID, balanceOfDai, balanceOfRDai, userApproved,
            rDaiInstance, addressOfRDaiContract, generatedInterestAmt, allowance, hoodieAddress,
            hoodieReceivers, isWaiting, depositedAmount, numOfHoodie, nextInLine,
          } = this.state
    if (!web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }

    return (
      <div className="App">
        <div>
          <h1>Welcome to Flex Hoodie dapp!</h1>
          <h1>Deposit your DAI and get Hoodie!</h1>
          <p>Owner is {owner} and the Hat ID is {hatID}</p>
          <p>Your DAI balance is {web3.utils.fromWei(`${balanceOfDai}`, 'ether')}</p>
          <p>Your rDAI balance is {web3.utils.fromWei(`${balanceOfRDai}`, 'ether')}</p>
          <p>Your depositedAmount is {web3.utils.fromWei(`${depositedAmount}`, 'ether')}</p>
          <p>Are you waiting for FDH? => {`${isWaiting}`}</p>
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

          <p>Generated Interest Amount => { web3.utils.fromWei(`${generatedInterestAmt}`, 'ether') }</p>

          <br />

          <h3>Info of Hoodie DApp --- { hoodieAddress }</h3>
          <p>Num of hoodie receivers: { hoodieReceivers }</p>
          <p>Next receiver >>>> { nextInLine }</p>
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
          hoodieInstance={hoodieInstance}
          rDaiInstance={rDaiInstance}
          accounts={accounts}
          depositedAmount={depositedAmount}
        />

        <br />
        
        <IssueFDH
          hoodieInstance={hoodieInstance}
          accounts={accounts}
          generatedInterestAmt={generatedInterestAmt}
        />
      </div>
    );
  }
}

export default App;
