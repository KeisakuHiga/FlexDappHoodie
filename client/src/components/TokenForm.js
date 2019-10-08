import React from 'react';

const TokenForm = () => {
  return (
    <form>
      <div className="form-group">
        <label htmlFor="exampleInputEmail1">How much DAI will you invest</label>
        <input type="number" className="form-control" id="inputDAI" placeholder="DAI" />
      </div>
      <button type="submit" className="btn btn-primary">Submit</button>
    </form>
  );
}

export default TokenForm;