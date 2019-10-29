import React, { Component } from 'react';

class DepositForm extends Component {
  state = {
    depositAmount: 0,
  }

  handleMintRDai = async (e) => {
    e.preventDefault()
    const { hoodieInstance, rDaiHatId, accounts } = this.props
    const { depositAmount }  = this.state
    const contract = hoodieInstance.methods;
    const userNumber = await contract.userQueuePositions(accounts[0]).call()
    const user = await contract.users(userNumber).call()
    const isWaiting = user.isWaiting
    const daiDeposited = user.daiDeposited
    const hasDeposited = user.hasDeposited
    try {
      console.log('start to mint rDai')
      console.log("daiDeposited=> ",daiDeposited)
      console.log("rDaiHatId=> ",rDaiHatId)
      console.log("isWaiting=> ",isWaiting)
      console.log("hasDeposited=> ",hasDeposited)
      await contract.depositDai(depositAmount).send({ from: accounts[0] } )
      .on('transactionHash', hash => { console.log('Tx Hash: ' + hash) })
    } catch (err) {
      console.log(err.message);
    }
  }

  render() {
    const { web3 } = this.props
    return (
      <form onSubmit={this.handleMintRDai}>
        <div className="form-group">
          <label>How much DAI will you invest?</label>
          <input 
            type="number"
            className="form-control"
            id="inputDAI"
            placeholder="DAI"
            onChange={e => {
              if (!e.target.value) return
              const depositAmountInWei = web3.utils.toWei(e.target.value, 'ether')
              this.setState({ depositAmount: depositAmountInWei })
            }}
          />
        </div>
        <button type="submit" className="btn btn-primary">Mint rDAI</button>
      </form>
    );
  }
}

export default DepositForm;