import React, { Component } from 'react';

class TransferRDaiForm extends Component {
  state = {
    web3: this.props.web3,
    rDaiInstance: this.props.rDaiInstance,
    accounts: this.props.accounts,
    destination: null,
    transferAmount: 0,
    transactionHash: null,
  }

  handleTransferRDai = async (e) => {
    e.preventDefault()
    const { rDaiInstance, destination, transferAmount, accounts }  = this.state
    try {
      console.log('start to transfer rDai')
      console.log('destination: ', destination)
      console.log('transferAmount: ', transferAmount)
      await rDaiInstance.methods.transfer(destination, transferAmount).send({ from: accounts[0] })
        .on('receipt', receipt => {
          this.setState({ transactionHash: receipt.transactionHash})
        })

    } catch (err) {
      console.log(err.message);
    }
  }

  render() {
    const { web3, transactionHash } = this.state
    return (
      <>
        <form onSubmit={this.handleTransferRDai}>
          <div className="form-group">
            <label>Who do you want transfer rDAI to?</label>
            <input
              className="form-control"
              id="inputDestination"
              placeholder="destination"
              onChange={e => this.setState({ destination: e.target.value })}
            />

            <label>How much rDAI will you transfer?</label>
            <input
              className="form-control"
              id="inputRDAI"
              placeholder="rDAI"
              onChange={e => this.setState({ transferAmount: web3.utils.toWei(`${e.target.value}`, 'ether') })}
            />
          </div>
          <button type="submit" className="btn btn-primary">Transfer rDAI</button>
        </form>
        {transactionHash ? <h3>Your rDAI was transferred! Tx hash: {transactionHash}</h3>
          : null}
      </>
    );
  }
}

export default TransferRDaiForm;