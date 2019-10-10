pragma solidity 0.5.8;

contract ICErc20 {
    address public underlying;

    // external
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    // function liquidateBorrow(address borrower, uint repayAmount, CToken cTokenCollateral) external returns (uint);

    // internal
    function getCashPrior() internal view returns (uint);
    // function checkTransferIn(address from, uint amount) internal view returns (Error);
    // function doTransferIn(address from, uint amount) internal returns (Error);
    // function doTransferOut(address payable to, uint amount) internal returns (Error);
}