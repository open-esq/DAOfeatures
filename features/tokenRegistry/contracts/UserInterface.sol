
pragma solidity >=0.4.21 <0.6.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title Manages the user interface for a feature
 * @dev Manages the UI that is connected to a DAOfeature.
 *      The owner of the schema can push new versions of the UI at any
 *      time, while organizations can choose to update to the new UI.
*/
contract UserInterface is Ownable {

  string[] uiHash;

  // A mapping from the organization (Avatar) address to the active user interface the organization is using:
  mapping(address=>uint) public organizationUi;

  function addNewUi(string memory newUiHash) public onlyOwner {
    uiHash.push(newUiHash);
  }

  function proposeUpdateUi(address _avatar, uint uiVersion)
  public
  payable
  returns(bytes32)
  {
    require(uiVersion <= uiHash.length, "the UI version must be pusblished");
    //TODO  and also, the execution of the proposal has to be handled
  }

  function getUi(address _avatar) public returns(uint) {
    return organizationUi[_avatar];
  }
}
