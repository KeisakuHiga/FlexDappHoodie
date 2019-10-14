import React, { Component } from 'react';

class DepositForm extends Component {
  state = {
    web3: null,
    rDaiInstance: this.props.rDaiInstance,
    accounts: this.props.accounts,
    hatID: this.props.hatID,
    from: '',
    to: '',
    depositAmount: 0,
  }

  handleMintRDai = async (e) => {
    e.preventDefault()
    const { addressOfRDaiContract, daiInstance } = this.props
    const { rDaiInstance, depositAmount, accounts, hatID }  = this.state
    try {
      console.log('start to transfer DAI from user to rDai contract')
      console.log(addressOfRDaiContract)
      console.log(depositAmount)
      await daiInstance.methods.transfer(addressOfRDaiContract, depositAmount).send({ from: accounts[0] })
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
    return (
      <form onSubmit={this.handleMintRDai}>
        <div className="form-group">
          <label>How much DAI will you invest?</label>
          <input 
            type="number"
            className="form-control"
            id="inputDAI"
            placeholder="DAI"
            onChange={e => this.setState({ depositAmount: e.target.value })}
          />
        </div>
        <button type="submit" className="btn btn-primary">Mint rDAI</button>
      </form>
    );
  }
}

export default DepositForm;