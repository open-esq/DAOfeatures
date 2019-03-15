pragma solidity >=0.4.21 <0.6.0;

import "@daostack/arc/contracts/universalSchemes/UniversalScheme.sol";
import "@daostack/arc/contracts/votingMachines/VotingMachineCallbacks.sol";
import "@daostack/infra/contracts/votingMachines/IntVoteInterface.sol";
import "@daostack/infra/contracts/votingMachines/VotingMachineCallbacksInterface.sol";
import "./FeeCollector.sol";

/**
 * @title A universal scheme for letting organizations manage a registrar of assets
 * @dev The ResourceRegistryScheme has a registry of assets for each organization.
 *      The organizations can through a vote register allowing them to add/remove and sort items in the registry.
 */
contract ResourceRegistryScheme is UniversalScheme, VotingMachineCallbacks, ProposalExecuteInterface, FeeCollector {

  event AddResourceProposal (
    address indexed _avatar,
    bytes32 indexed _proposalId,
    address indexed _intVoteInterface,
    string _resource,
    string _descriptionHash
  );

  event RemoveResourceProposal (
    address indexed _avatar,
    bytes32 indexed _proposalId,
    address indexed _intVoteInterface,
    string _resource,
    string _descriptionHash
  );

  event ProposalExecuted(address indexed _avatar, bytes32 indexed _proposalId, int256 _param);
  event ProposalDeleted(address indexed _avatar, bytes32 indexed _proposalId);
  // a SchemeProposal is a  proposal to add or remove a scheme to/from the an organization
  struct ResourceProposal {
    string resource; // resource identifier (url | ipfshash / ens domain | address)
    bool addResource; // true: add a res, false: remove a res.
    string _descriptionHash;
  }

  // A mapping from the organization (Avatar) address to the saved data of the organization:
  mapping(address=>mapping(bytes32=>SchemeProposal)) public organizationsProposals;

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
    ResourceProposal memory proposal = organizationsProposals[address(avatar)][_proposalId];
    require(proposal.res != string(0));
    delete organizationsProposals[address(avatar)][_proposalId];
    emit ProposalDeleted(address(avatar), _proposalId);

    if (_param == 1) {

      // Define controller and get the params:
      ControllerInterface controller = ControllerInterface(avatar.owner());

      // Add a resource:
      if (proposal.addResource) {
        //require(controller.registerResource;
      }
      // Remove a resource:
      else {
        //require(controller.unregisterResource(proposal.scheme, address(avatar)));
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
   * @dev create a proposal to register a scheme
   * @param _avatar the address of the organization the scheme will be registered for
   * @param _resource the url of the resource to be registered
   * @param _descriptionHash proposal's description hash
   * @return a proposal Id
   * @dev NB: not only proposes the vote, but also votes for it
   */
  function proposeResource(
    Avatar _avatar,
    string _resource,
    string memory _descriptionHash
  )
  public
  returns(bytes32)
  {
    // propose
    require(_resource != string(0), "resource identifier cannot be zero");
    Parameters memory controllerParams = parameters[getParametersFromController(_avatar)];

    bytes32 proposalId = controllerParams.intVote.propose(
      2,
      controllerParams.voteRegisterParams,
      msg.sender,
      address(_avatar)
    );

    ResourceProposal memory proposal = ResourceProposal({
      resource: _resource,
      addScheme: true,
      descriptionHash: _descriptionHash
    });

    emit AddResourceProposal(
      address(_avatar),
      proposalId,
      address(controllerParams.intVote),
      _resource,
      _descriptionHash
    );

    organizationsProposals[address(_avatar)][proposalId] = proposal;
    proposalsInfo[address(controllerParams.intVote)][proposalId] = ProposalInfo({
      blockNumber:block.number,
      avatar:_avatar
    });

    return proposalId;
  }

  /**
  * @dev propose to remove a scheme for a controller
  * @param _avatar the address of the controller from which we want to remove a scheme
  * @param _scheme the address of the scheme we want to remove
  * @param _descriptionHash proposal description hash
  * NB: not only registers the proposal, but also votes for it
  function proposeToRemoveResource(Avatar _avatar, uint _index, string memory _descriptionHash)
  public
  returns(bytes32)
  {
  }
  */
}
