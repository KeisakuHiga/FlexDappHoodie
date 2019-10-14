import React, { Component } from 'react';

class DepositForm extends Component {
  state = {
    web3: null,
    hoodieInstance: this.props.hoodieInstance,
    accounts: this.props.accounts,
    from: '',
    to: '',
    depositAmount: 0,
  }

  componentDidMount = () => {
    const { hoodieInstance, accounts, web3 } = this.props;
    web3.eth.getBlock("latest", false, (error, result) => {
      if(error) {
        console.log(error.message);
      }
      console.log(result.gasLimit)
    });
    this.setState({ hoodieInstance, accounts, web3 });
  }

  handleSubmit = async (e) => {
    e.preventDefault()
    const { hoodieInstance, depositAmount, accounts }  = this.state
    // const depositAmountNumber = parseInt(depositAmount, 10);
    const depositAmountNumber = depositAmount;
    try {
      const result = await hoodieInstance.methods
                      .deposit(depositAmountNumber)
                      .send(
                        {
                          from: accounts[0],
                          gasLimit: "7100000"
                        }
                      );
      console.log(result)
      
    } catch (err) {
      console.log(err.message);
    }
  }

  render() {
    const { depositAmount } = this.state;
    console.log(typeof depositAmount);
    return (
      <form onSubmit={this.handleSubmit}>
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
        <button type="submit" className="btn btn-primary">Submit</button>
      </form>
    );
  }
}

export default DepositForm;