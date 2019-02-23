pragma solidity >=0.4.21 <0.6.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title Collect fees, and the owner can withdraw the collected fees
*/
contract FeeCollector is Ownable {

  /**
  * @dev Throws if called without paying fees
  */
  modifier paysFee() {
    require(msg.value > gasleft(), "must pay fees to use this function");
    _;
  }

  function withdraw() public onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

}