import React, { Component } from 'react';

class Approve extends Component {

  render() { 
    return (
      <form onSubmit={this.props.handleApprove}>
        <button type="submit" className="btn btn-primary">Approve</button>
      </form>
    );
  }
}

export default Approve;