import React, { Component } from 'react';

class DepositForm extends Component {
  state = {
    depositAmount: 0,
  }

  handleMintRDai = async (e) => {
    e.preventDefault()
    const { hatID,rDaiInstance, accounts } = this.props
    const { depositAmount }  = this.state
    try {
      console.log('start to mint rDai')
      console.log(depositAmount)
      console.log(hatID)
      await rDaiInstance.methods.mintWithSelectedHat(depositAmount, hatID).send({ from: accounts[0] } )
        .on('transactionHash', hash => {
          console.log('H: ' + hash)
        })
        .on('confirmation', (confirmationNumber, receipt) => {
          console.log('CN: ' + confirmationNumber)
          console.log('R: ' + receipt)
        })
        .on('receipt', receipt => {
          console.log('R: ' + receipt)
        })
    } catch (err) {
      console.log(err.message);
    }
  }

  render() {
    const { web3 } = this.props
    console.log(this.state.depositAmount)
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