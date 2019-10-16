import React, { Component } from 'react';

class RedeemForm extends Component {
  state = {
    web3: this.props.web3,
    rDaiInstance: this.props.rDaiInstance,
    accounts: this.props.accounts,
    redeemAmount: 0,
    transactionHash: null,
  }

  handleRedeemRDai = async (e) => {
    e.preventDefault()
    const { rDaiInstance, redeemAmount, accounts }  = this.state
    try {
      console.log('start to redeem rDai')
      console.log('redeemAmount: ', redeemAmount)
      await rDaiInstance.methods.redeem(redeemAmount).send({ from: accounts[0] })
        .on('receipt', receipt => {
          this.setState({ transactionHash: receipt.transactionHash })
        })

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