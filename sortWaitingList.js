// OFF CHAIN BACKEND LOGIC
// update nextInLine to be the person who has deposited the next most
// update mostDeposited to be equal to the deposit of nextInLine
const sortWaitingList = async () => {
	let max = 0;
	let next = 0;
	let user;
	const hoodieInstance // should be defined using web3
	const waitingList = await hoodieInstance.methods.getWaitingList().call()

	for (let i = 0; i < waitingList.length; i++) {
		depositedAmount = await hoodieInstance.methods.users(waitingList[i]).call()
			.on(user => {return user.depositedAmount})

	}
}

    for (uint256 i = 0; i < waitingList.length; i++) {
      if (
          users[waitingList[i]].rNumber == roundNumber &&
          users[waitingList[i]].isWaiting &&
          _max < users[waitingList[i]].depositedAmount
        )
        {
          _max = users[waitingList[i]].depositedAmount;
          _next = waitingList[i];
        } else {
          _max = users[waitingList[i]].depositedAmount;
          _next = waitingList[i];
        }
    }
    mostDeposited = _max;
    nextInLine = _next;
    hoodieReceivers++;

    // // update round number here
    if (hoodieReceivers == waitingList.length) {
      roundNumber++;
      hoodieReceivers = 0;
      emit NewRoundStarted(roundNumber);

      // find the next receiver in the new round
      for (uint i = 0; i < waitingList.length; i++) {
        if (
            users[waitingList[i]].rNumber == roundNumber &&
            users[waitingList[i]].isWaiting &&
            _max < users[waitingList[i]].depositedAmount
          )
          {
            _max = users[waitingList[i]].depositedAmount;
            _next = waitingList[i];
          } else {
            _max = users[waitingList[i]].depositedAmount;
            _next = waitingList[i];
          }
      }
      mostDeposited = _max;
      nextInLine = _next;
      hoodieReceivers++;
    }