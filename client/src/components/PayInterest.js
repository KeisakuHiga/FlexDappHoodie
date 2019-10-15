import React, { Component } from 'react';

class PayInterest extends Component {
  state = {
    web3: this.props.web3,
    owner: '0x2471e35F51CF54265B20cCFAc3857c2DceEf7349',
    rDaiInstance: this.props.rDaiInstance,
    accounts: this.props.accounts,
    transactionHash: null,
  }

  handlePayInterest = async (e) => {
    e.preventDefault()
    const { owner, rDaiInstance, accounts }  = this.state
    try {
      console.log('start to payInterest')
      console.log('owner: ', owner)
      await rDaiInstance.methods.payInterest(owner).send({ from: accounts[0] })
        .on('receipt', receipt => {
          this.setState({ transactionHash: receipt.transactionHash})
        })

    } catch (err) {
      console.log(err.message);
    }
  }

  render() {
    const { owner, transactionHash } = this.state
    return (
      <>
        <form onSubmit={this.handlePayInterest}>
          <button type="submit" className="btn btn-primary">PayInterest!</button>
        </form>
        {transactionHash ? <h3>The generated interest was given to {owner}! Tx hash: {transactionHash}</h3>
          : null}
      </>
    );
  }
}

export default PayInterest;