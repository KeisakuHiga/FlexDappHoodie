import React, { Component } from 'react';

class RedeemForm extends Component {
  state = {
    web3: this.props.web3,
    hoodieInstance: this.props.hoodieInstance,
    rDaiInstance: this.props.rDaiInstance,
    accounts: this.props.accounts,
    depositedAmount: 0,
    redeemAmount: 0,
    transactionHash: null,
    approved: false,
  }

  componentDidMount = async e => {
    const { hoodieInstance, accounts } = this.state;
    const depositedAmount = await hoodieInstance.methods.users(accounts[0]).call()
      .then(user => { return user.depositedAmount })
      .catch(err => { return false })
    this.setState({ depositedAmount })
  }
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

  handleRedeemRDai = async (e) => {
    e.preventDefault()
    const { hoodieInstance, rDaiInstance, depositedAmount, redeemAmount, accounts, approved }  = this.state
    const hoodieAddress = hoodieInstance.options.address
    const balanceOfRDai = await rDaiInstance.methods.balanceOf(accounts[0]).call();
    const rDaiAllowance = await rDaiInstance.methods.allowance(accounts[0], hoodieAddress).call();
    
    // await rDaiInstance.methods.redeem(redeemAmount).send({ from: accounts[0] })
    //   .on('receipt', receipt => { this.setState({ transactionHash: receipt.transactionHash }) })
    try {
      console.log('start to redeem rDai')
      console.log('redeemAmount: ', {redeemAmount})
      console.log({depositedAmount})
      console.log({balanceOfRDai})
      console.log({address: hoodieAddress})
      if(depositedAmount - redeemAmount < 0) {
        throw({ message: 'over redeem amount' })
      } else {
        if (rDaiAllowance == 0) {
          await rDaiInstance.methods.approve(hoodieAddress, balanceOfRDai).send({ from: accounts[0] })
        }
        await hoodieInstance.methods.redeemRDai(redeemAmount).send({ from: accounts[0] })
      }
    } catch (err) {
      console.log(err.message);
    }
  }

  render() {
    const { web3, transactionHash } = this.state
    return (
      <>
        <form onSubmit={this.handleRedeemRDai}>
          <div className="form-group">
            <label>How much rDAI will you redeem?</label>
            <input 
              className="form-control"
              id="inputRDAI"
              placeholder="rDAI"
              onChange={e => {
                if (!e.target.value) return
                this.setState({ redeemAmount: web3.utils.toWei(`${e.target.value}`, 'ether') })
              }}
            />
          </div>
          <button type="submit" className="btn btn-primary">Redeem rDAI</button>
        </form>
        {transactionHash ? <h3>Your rDAI was redeemed! Tx hash: {transactionHash}</h3>
          : null}
      </>
    );
  }
}

export default RedeemForm;