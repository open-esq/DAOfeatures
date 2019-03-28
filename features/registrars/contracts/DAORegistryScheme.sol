pragma solidity >=0.4.21 <0.6.0;

import "@daostack/arc/contracts/universalSchemes/UniversalScheme.sol";
import "@daostack/arc/contracts/votingMachines/VotingMachineCallbacks.sol";
import "@daostack/infra/contracts/votingMachines/IntVoteInterface.sol";
import "@daostack/infra/contracts/votingMachines/VotingMachineCallbacksInterface.sol";
import "./FeeCollector.sol";
import "./DAORegistry.sol";

/**
 * @title A universal scheme for letting organizations manage a registrar of named DAOs
 * @dev The DAORegistryScheme has a registry of DAOs for each organization.
 *      The organizations can through a vote choose to register allowing them to add/remove names inside the registry.
 */
contract DAORegistryScheme is UniversalScheme, VotingMachineCallbacks, ProposalExecuteInterface, FeeCollector {

  event AddDAOProposal (
    address indexed _avatar,
    bytes32 indexed _proposalId,
    address indexed _intVoteInterface,
    string _registryName,
    address _avatarProposed
  );

  event RemoveDAOProposal (
    address indexed _avatar,
    bytes32 indexed _proposalId,
    address indexed _intVoteInterface,
    string _registryName,
    address _avatarProposed
  );

  event ProposalExecuted(address indexed _avatar, bytes32 indexed _proposalId, int256 _param);
  event ProposalDeleted(address indexed _avatar, bytes32 indexed _proposalId);

  // a DAORegistryProposal is a proposal to add or remove a named DAO to/from an organization
  struct DAORegistryProposal {
    address avatar; //DAO address to be add or removed
    string name; // Name of the DAO that will be the reference key in the registry
    bool addDAO; // true: approve a DAO, false: unapprove the DAO
  }

  // A mapping from the organization (Avatar) address to the saved data of the organization:
  mapping(address=>mapping(bytes32=>DAORegistryProposal)) public organizationsProposals;

  // A mapping from hashes to parameters (use to store a particular configuration on the controller)
  struct Parameters {
    bytes32 voteRegisterParams;
    bytes32 voteRemoveParams;
    IntVoteInterface intVote;
  }

  mapping(bytes32=>Parameters) public parameters;

  /**
   * @dev execution of proposals, can only be called by the voting machine in which the vote is held.
   * @param _proposalId the ID of the voting in the voting machine
   * @param _param a parameter of the voting result, 1 yes and 2 is no.
   */
  function executeProposal(bytes32 _proposalId, int256 _param) external onlyVotingMachine(_proposalId) returns(bool) {
    Avatar avatar = proposalsInfo[msg.sender][_proposalId].avatar;
    DAORegistryProposal memory proposal = organizationsProposals[address(avatar)][_proposalId];

    delete organizationsProposals[address(avatar)][_proposalId];
    emit ProposalDeleted(address(avatar), _proposalId);

    if (_param == 1) {

      DAORegistry registry = DAORegistry(msg.sender); //TODO: set the scheme as the owner

      // Add a DAO:
      if (proposal.addDAO) {
        require(registry.register(address(avatar), proposal.name));
      }
      // Remove a resource:
      else {
        require(registry.unregister(address(avatar)));
      }
    }

    emit ProposalExecuted(address(avatar), _proposalId, _param);
    return true;
  }

  /**
  * @dev hash the parameters, save them if necessary, and return the hash value
  */
  function setParameters(
    bytes32 _voteRegisterParams,
    bytes32 _voteRemoveParams,
    IntVoteInterface _intVote
  ) public returns(bytes32)
  {
    bytes32 paramsHash = getParametersHash(_voteRegisterParams, _voteRemoveParams, _intVote);
    parameters[paramsHash].voteRegisterParams = _voteRegisterParams;
    parameters[paramsHash].voteRemoveParams = _voteRemoveParams;
    parameters[paramsHash].intVote = _intVote;
    return paramsHash;
  }

  function getParametersHash(
    bytes32 _voteRegisterParams,
    bytes32 _voteRemoveParams,
    IntVoteInterface _intVote
  ) public pure returns(bytes32)
  {
    return keccak256(abi.encodePacked(_voteRegisterParams, _voteRemoveParams, _intVote));
  }

  /**
  * @dev create a proposal to register a DAO with to a named registry
  * @param _avatar the address of the organization the resource will be registered for
  * @param _registryName the name of the registry to add the resource
  * @param _proposedAvatar the organization we want to add to the registry
  * @return a proposal Id
  */
  function proposeToAddDAO(
    Avatar _avatar,
    string memory _registryName,
    Avatar _proposedAvatar
  ) public returns(bytes32)
  {

    // propose
    Parameters memory controllerParams = parameters[getParametersFromController(_avatar)];

    bytes32 proposalId = controllerParams.intVote.propose(
      2,
      controllerParams.voteRegisterParams,
      msg.sender,
      address(_avatar)
    );

    DAORegistryProposal memory proposal = DAORegistryProposal({
      avatar: address(_proposedAvatar),
      name: _registryName,
      addDAO: true
    });

    emit AddDAOProposal(
      address(_avatar),
      proposalId,
      address(controllerParams.intVote),
      _registryName,
      address(_proposedAvatar)
    );

    organizationsProposals[address(_avatar)][proposalId] = proposal;
    proposalsInfo[address(controllerParams.intVote)][proposalId] = ProposalInfo({
      blockNumber:block.number,
      avatar:_avatar
    });

    return proposalId;
  }

  /**
  * @dev propose to remove a DAO inside a named registry
  * @param _avatar the address of the controller from which we want to remove a scheme
  * @param _registryName the name of the registry we want to remove from
  * @param _proposedAvatar the organization we want to remove from the registry
  */
  function proposeToRemoveResource(
    Avatar _avatar,
    string memory _registryName,
    Avatar _proposedAvatar
  ) public returns(bytes32)
  {
    bytes32 paramsHash = getParametersFromController(_avatar);
    Parameters memory params = parameters[paramsHash];

    IntVoteInterface intVote = params.intVote;
    bytes32 proposalId = intVote.propose(2, params.voteRemoveParams, msg.sender, address(_avatar));
    organizationsProposals[address(_avatar)][proposalId].addDAO = false;
    emit RemoveDAOProposal(address(_avatar), proposalId, address(intVote), _registryName, address(_proposedAvatar));
    proposalsInfo[address(params.intVote)][proposalId] = ProposalInfo({
      blockNumber: block.number,
      avatar: _avatar
    });
    return proposalId;
  }
}
