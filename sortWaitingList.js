 // OFF CHAIN BACKEND LOGIC
    // update nextInLine to be the person who has deposited the next most
    // update mostDeposited to be equal to the deposit of nextInLine
    // uint256 _max = 0;
    // address _next = address(0);

    // for (uint256 i = 0; i < waitingList.length; i++) {
    //   if (
    //       users[waitingList[i]].rNumber == roundNumber &&
    //       users[waitingList[i]].isWaiting &&
    //       _max < users[waitingList[i]].depositedAmount
    //     )
    //     {
    //       _max = users[waitingList[i]].depositedAmount;
    //       _next = waitingList[i];
    //     } else {
    //       _max = users[waitingList[i]].depositedAmount;
    //       _next = waitingList[i];
    //     }
    // }
    // mostDeposited = _max;
    // nextInLine = _next;
    // hoodieReceivers++;

    // // update round number here
    // if (hoodieReceivers == waitingList.length) {
    //   roundNumber++;
    //   hoodieReceivers = 0;
    //   emit NewRoundStarted(roundNumber);

    //   // find the next receiver in the new round
    //   for (uint i = 0; i < waitingList.length; i++) {
    //     if (
    //         users[waitingList[i]].rNumber == roundNumber &&
    //         users[waitingList[i]].isWaiting &&
    //         _max < users[waitingList[i]].depositedAmount
    //       )
    //       {
    //         _max = users[waitingList[i]].depositedAmount;
    //         _next = waitingList[i];
    //       } else {
    //         _max = users[waitingList[i]].depositedAmount;
    //         _next = waitingList[i];
    //       }
    //   }
    //   mostDeposited = _max;
    //   nextInLine = _next;
    //   hoodieReceivers++;
    // }