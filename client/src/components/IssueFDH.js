import React, { Component } from 'react';

class IssueFDH extends Component {
  state = {
    hoodieInstance: this.props.hoodieInstance,
    accounts: this.props.accounts,
    generatedInterestAmt: this.props.generatedInterestAmt,
    txHash: null,
  }

  handleIssueFDH = async (e) => {
    e.preventDefault()
    const { accounts, hoodieInstance, generatedInterestAmt } = this.state;
    // check whether or not the generated interest amount reached 20 rDAI
    // if true, invoke issueFDH
    // if(generatedInterestAmt >= 20 * 10 ** 18) {
      if(generatedInterestAmt >= 0) {
        try {
          await hoodieInstance.methods.issueFDH().send({ from: accounts[0] })
            .on('transactionHash', hash => {
              this.setState({ txHash: hash })
              console.log('Tx Hash: ' + hash)
            })
        } catch (err) {
          console.log(err.message);
        }
      } else {
        return;
      }
  }

  render() {
    return (
      <>
        <form onSubmit={this.handleIssueFDH}>
          <button type="submit" className="btn btn-primary">Issue FDH!</button>
        </form>
        {this.state.txHash ? <h3>FDH was transferred! Tx hash: {this.state.txHash}</h3>
          : null}
      </>
    );
  }
}

export default IssueFDH;