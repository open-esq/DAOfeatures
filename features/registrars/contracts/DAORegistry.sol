pragma solidity >=0.4.21 <0.6.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "@daostack/arc/contracts/controller/Avatar.sol";

/**
 * @title A registry of authorized DAOs to be displayed in Alchemy
 * @dev The DAORegistry has a collection of named DAOs that are allowed to be displayed in the front-end
 */
contract DAORegistry is Ownable {
  mapping(string=>bool) private registered;

  event Propose(address _avatar);
  event Register(
    address _avatar,
    string _name
  );
  event Unregister(address _avatar);

  /**
    * @dev propose to create a registry for a particular Avatar; this will interact with the scheme to create a proposal to be voted on by the DAO
    * @param _avatar the address of the organization where we want to propose to be registered
    */
  function propose(address _avatar) external returns(bytes32) {
    //Return the proposalId once there is a scheme that interacts with this registry once a proposal passes
    emit Propose(_avatar);
  }

  /**
    * @dev registers a name of a DAO to be displayed in Alchemy when a proposal passes the voting process
    * @param _avatar the address of the organization we are registering
    * @param _name the string that represents a unique name for a DAO address
    */
  function register(address _avatar, string memory _name) public onlyOwner returns(bool) {
    if (!validName(_name)) {
      registered[_name] = true;
      emit Register(_avatar, _name);
    }

    else { //If it's already registered, do nothing... return false
      return false;
    }

    return registered[_name];
  }

  /**
    * @dev emits an event showing the name of the DAO being unregistered from Alchemy after a proposal passes
    * @param _avatar the address of the organization we are unregistering
    */
  function unregister(address _avatar) public onlyOwner returns(bool) {
    emit Unregister(_avatar);
  }

  function validName(string memory _name) view internal returns (bool) {
    return registered[_name];
  }
}
