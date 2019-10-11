import React, { Component } from 'react';

class DepositForm extends Component {
  state = {
    hoodieInstance: this.props.hoodieInstance,
    accounts: this.props.accounts,
    from: '',
    to: '',
    depositAmount: 0,
  }

  handleSubmit = async (e) => {
    e.preventDefault()
    const { depositAmount }  = this.state
    const { hoodieInstance, accounts } = this.props
    const result = await hoodieInstance.methods.deposit(depositAmount).send({ from: accounts[0]});
    console.log(result)
  }

  render() { 
    return (
      <form onSubmit={this.handleSubmit}>
        <div className="form-group">
          <label>How much DAI will you invest</label>
          <input 
            type="number"
            className="form-control"
            id="inputDAI"
            placeholder="DAI"
            onChange={e => this.setState({ mintAmount: e.target.value })}
          />
          {/* <label>Who do you want transfer to?</label>
          <input 
            type="text"
            className="form-control"
            id="inputAddressTo"
            placeholder="Input recipient's address"
            onChange={e => this.setState({ to: e.target.value })}
          /> */}
        </div>
        <button type="submit" className="btn btn-primary">Submit</button>
      </form>
    );
  }
}

export default DepositForm;