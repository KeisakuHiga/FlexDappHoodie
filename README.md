# Hoodie DApp overview
This dapp was built by Keisaku Higa while his internship at [Flex Dapps](https://flexdapps.com/about). This dapp's smart contract utilizes [rToken contract](https://github.com/decentral-ee/rtoken-contracts) and [Compound](https://github.com/compound-finance) so that the users can deposit their DAI into this dapp to earn interest from Compound protocol. The generated interest will be transferred to Flex Dapps' account using rTokenContract. After the generated interest amount reaches the certain level, Flex Dapps will issue their original hoodies to users who deposited DAI into this dapp.

## How this dapp works
![](./docs/dappsImage.png)
## Waiting list
### Case1 - When there is no waiting user
A user will be given the 1st position in the waiting list

### Case2 - When there is more than 1 user
A user will be given the last position in the waiting list

### Case3 - When a user’s deposited amount becomes below than the minimum deposit amount
A user will be removed from the waiting list

### Case4 - When an existing user who is not in the waiting list tops up their deposit and the amount reaches the minimum amount
A user will be added into the waiting list and given the last position

### Case5 - After issuing a hoodie to the 1st position user
The user will be given the last position and the 2nd position user will be the next recipient

### Case6 - When the 1st position user redeems their rDAI and becomes out of the waiting list before the generated interest amount reaches the hoodie cost
The 2nd position user will be the next recipient

### Case7 - When the generated interest amount reaches the hoodie cost but there is no waiting user
No one receives a hoodie and the generated interest amount will be transferred to Flex Dapps’ rDAI account

## Dapp's functionalities
* Users can change their rDAI hat to the dapp’s one before using
* Users can approve of the dapp transferring their DAI to Compound
* Users can mint rDAI through the dapp
* Users can redeem their rDAI and the DAI they deposited will be given back to them
* The generated interest will be redirected to the Flex Dapps’ rDAI account for the hoodie cost
* Hoodie will be given to the 1st position user automatically when the generated interest amount has reached the cost

## Dapp's tech stack
* Solidity      -> a smart contract programming language
* OpenZeppelin  -> a library for writing smart contracts
* web3.js       -> a collection of libraries to interact with a local or remote ethereum node using a HTTP or IPC connection
* Truffle       -> a development tool for DApps
* MetaMask      -> a browser extension that lets you run DApps without being part of the ethereum network as a ethereum node
* Node.js       -> a Javascript runtime for building server-side or desktop applications


