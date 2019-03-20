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
    bytes32 _registryName,
    string _resource,
    address _contractAddr,
    string _descriptionHash,
    bool _isContract
  );

  event RemoveResourceProposal (
    address indexed _avatar,
    bytes32 indexed _proposalId,
    address indexed _intVoteInterface,
    bytes32 _registryName,
    string _descriptionHash
  );

  event ProposalExecuted(address indexed _avatar, bytes32 indexed _proposalId, int256 _param);
  event ProposalDeleted(address indexed _avatar, bytes32 indexed _proposalId);

  // a ResourceProposal is a  proposal to add or remove a resource to/from an organization
  struct ResourceProposal {
    bytes32 registryName; //we use this as part of the mapping for which kind of registry we want to add to
    string resource; // resource identifier (url | ipfshash / ens domain)
    address contractAddr; // if the resource is a contract
    bool addResource; // true: add a res, false: remove a res.
    string descriptionHash;
    bool isContract;
    bool isRemoved; //should this maybe use an index instead...
  }

  struct ResourceData {
    string resource; // resource identifier (url | ipfsHash | ENS domain)
    address contractAddr; // this field is for tokens or other contracts
    string descriptionHash;
    bool isContract; // 1 == url, 2 == ipfsHash || ENS domain, 3 == address
  }

  // A mapping from the organization (Avatar) address to the saved data of the organization:
  mapping(address=>mapping(bytes32=>ResourceProposal)) public organizationsProposals;

  // A mapping from the organization (Avatar) address to the generic registries of the organization:
  // The string is the namespace of the registry
  mapping(address=>mapping(bytes32=>ResourceData[])) public organizationsGenericRegistries;

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

    if (proposal.isContract) {
      require(proposal.contractAddr != address(0));
    }

    delete organizationsProposals[address(avatar)][_proposalId];
    emit ProposalDeleted(address(avatar), _proposalId);

    if (_param == 1) {

      // Define controller and get the params:
      // ControllerInterface controller = ControllerInterface(avatar.owner()); do we need this?

      // Add a resource:
      if (proposal.addResource) {
        ResourceData memory res = ResourceData({
          resource: proposal.resource,
          contractAddr: proposal.contractAddr,
          descriptionHash: proposal.descriptionHash,
          isContract: proposal.isContract
        });

        organizationsGenericRegistries[address(avatar)][proposal.registryName].push(res); // TODO: is this safe? (re-entry)
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
  * @dev create a proposal to register a resource to named registry
  * @param _avatar the address of the organization the resource will be registered for
  * @param _registryName the name of the registry to add the resource
  * @param _resource the url of the resource to be registered
  * @param _contractAddr the address of the resource to be registered if it's a contract
  * @param _descriptionHash proposal's description hash
  * @param _isContract determines the type of resource to be stored
  * @return a proposal Id
  * @dev NB: not only proposes the vote, but also votes for it
   */
  function proposeResource(
    Avatar _avatar,
    bytes32 _registryName,
    string memory _resource,
    address _contractAddr,
    string memory _descriptionHash,
    bool _isContract
  ) public returns(bytes32)
  {
    //validate resource proposal
    if (_isContract) { // url
      require(_contractAddr != address(0), "contract address cannot be zero if typed");
    }
    else {
      require(bytes(_resource).length != 0, "resource identifier cannot be zero");
    }

    require(_registryName != bytes32(0), "registry name must be specified");
    require(bytes(_descriptionHash).length != 0, "description must be given");

    // propose
    Parameters memory controllerParams = parameters[getParametersFromController(_avatar)];

    bytes32 proposalId = controllerParams.intVote.propose(
      2,
      controllerParams.voteRegisterParams,
      msg.sender,
      address(_avatar)
    );

    ResourceProposal memory proposal = ResourceProposal({
      registryName: _registryName,
      resource: _resource,
      contractAddr: _contractAddr,
      addResource: true,
      descriptionHash: _descriptionHash,
      isContract: _isContract,
      isRemoved: false
    });

    emit AddResourceProposal(
      address(_avatar),
      proposalId,
      address(controllerParams.intVote),
      _registryName,
      _resource,
      _contractAddr,
      _descriptionHash,
      _isContract
    );

    organizationsProposals[address(_avatar)][proposalId] = proposal;
    proposalsInfo[address(controllerParams.intVote)][proposalId] = ProposalInfo({
      blockNumber:block.number,
      avatar:_avatar
    });

    return proposalId;
  }

  /**
   * @dev propose to remove a resource inside a named registry
   * @param _avatar the address of the controller from which we want to remove a scheme
   * @param _registryName the name of the registry we want to remove from
   * @param _descriptionHash proposal description hash
   * NB: not only registers the proposal, but also votes for it
   */
  function proposeToRemoveResource(
    Avatar _avatar,
    bytes32 _registryName,
    string memory _descriptionHash
  ) public returns(bytes32)
  {
    require(_registryName != bytes32(0), "registry name cannot be empty");
    bytes32 paramsHash = getParametersFromController(_avatar);
    Parameters memory params = parameters[paramsHash];

    IntVoteInterface intVote = params.intVote;
    bytes32 proposalId = intVote.propose(2, params.voteRemoveParams, msg.sender, address(_avatar));
    organizationsProposals[address(_avatar)][proposalId].isRemoved = true;
    emit RemoveResourceProposal(address(_avatar), proposalId, address(intVote), _registryName, _descriptionHash);
    proposalsInfo[address(params.intVote)][proposalId] = ProposalInfo({
      blockNumber:block.number,
      avatar:_avatar
    });
    return proposalId;
  }
}
