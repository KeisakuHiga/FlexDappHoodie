import React, { Component } from 'react';

class TokenForm extends Component {
  state = {
    to: '',
    value: 0,
  }

  handleSubmit = async (e) => {
    e.preventDefault()
    const { to, value }  = this.state
    const { hoodieInstance, accounts } = this.props
    await hoodieInstance.methods.transfer(to, value).send({ from: accounts[0]});
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
            onChange={e => this.setState({ value: e.target.value })}
          />
          <label>Who do you want transfer to?</label>
          <input 
            type="text"
            className="form-control"
            id="inputAddressTo"
            placeholder="Input recipient's address"
            onChange={e => this.setState({ to: e.target.value })}
          />
        </div>
        <button type="submit" className="btn btn-primary">Submit</button>
      </form>
    );
  }
}

export default TokenForm;