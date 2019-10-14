import React, { Component } from 'react';

class ApproveDai extends Component {

  render() { 
    return (
      <form onSubmit={this.props.handleApprove}>
        <button type="submit" className="btn btn-primary">Approve</button>
      </form>
    );
  }
}

export default ApproveDai;