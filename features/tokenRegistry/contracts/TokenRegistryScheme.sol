pragma solidity >=0.4.21 <0.6.0;

import "@daostack/arc/contracts/universalSchemes/UniversalScheme.sol";
import "@daostack/arc/contracts/votingMachines/VotingMachineCallbacks.sol";
import "./FeeCollector.sol";

/**
 * @title A universal scheme for letting organizations manage a registrar of tokens
 * @dev The TokenRegistryScheme has a registry of tokens for each organization.
 *      The organizations can through a vote register and unregister tokens in the registry.
*/
contract TokenRegistryScheme is UniversalScheme, VotingMachineCallbacks, ProposalExecuteInterface, FeeCollector {

  event NewTokenProposal(
    address indexed _avatar,
    bytes32 indexed _proposalId,
    address indexed _intVoteInterface,
    address _token
  );

  event RemoveTokenProposal(
    address indexed _avatar,
    bytes32 indexed _proposalId,
    address indexed _intVoteInterface,
    address _token
  );

  // a TokenProposal is a  proposal to add or remove a token to/from an organization's token registry
  struct TokenProposal {
    address token; // used when adding tokens
    bool addToken; // true: add a token, false: remove a token.
    uint removeIndex; // used when removing tokens // TODO: fix
  }
  
  event ProposalExecuted(address indexed _avatar, bytes32 indexed _proposalId, int256 _param);
  event ProposalDeleted(address indexed _avatar, bytes32 indexed _proposalId);

  event TokenAdded(address indexed _avatar, address token); // TODO: should this be seperate?
  event TokenRemoved(address indexed _avatar, address token);

  // A mapping from hashes to parameters (use to store a particular configuration on the controller)
  struct Parameters {
    bytes32 voteRegisterParams;
    bytes32 voteRemoveParams;
    IntVoteInterface intVote;
  }

  mapping(bytes32=>Parameters) public parameters;

  // A mapping from the organization (Avatar) address to the active tokenProposals of the organization:
  mapping(address=>mapping(bytes32=>TokenProposal)) public organizationsProposals;

  // A mapping from the organization (Avatar) address to the token registry of the organization:
  mapping(address=>address[]) public organizationsTokenRegistry;

  function getProposal(address avatar, bytes32 proposalId) public view returns (address, bool, uint) {
    TokenProposal memory proposal = organizationsProposals[avatar][proposalId];
    return (proposal.token, proposal.addToken, proposal.removeIndex);
  }

  /**
    * @dev create a proposal to register a token
    * @param _avatar the address of the organization the token will be registered for
    * @param _token the address of the token to be registered
    * @return a proposal Id
    * @dev NB: not only proposes the vote, but also votes for it
    */
  function proposeToken(
    Avatar _avatar,
    address _token
  )
  public
  payable
  paysFee
  returns(bytes32)
  {
    // propose
    require(_token != address(0), "token cannot be the zero address");
    Parameters memory controllerParams = parameters[getParametersFromController(_avatar)];

    bytes32 proposalId = controllerParams.intVote.propose(
      2,
      controllerParams.voteRegisterParams,
      msg.sender,
      address(_avatar)
    );

    TokenProposal memory proposal = TokenProposal({
      token: _token,
      addToken: true,
      removeIndex: 0 // TODO: fix
    });
    emit NewTokenProposal(
      address(_avatar),
      proposalId,
      address(controllerParams.intVote),
      _token
    );
    organizationsProposals[address(_avatar)][proposalId] = proposal;
    proposalsInfo[address(controllerParams.intVote)][proposalId] = ProposalInfo({
      blockNumber:block.number,
      avatar:_avatar
    });
    return proposalId;
  }

  /**
    * @dev propose to remove a token for a registry
    * @param _avatar the address of the organization where we want to remove the token from the registry
    * @param _index the index of the token we want to remove
    * NB: not only registers the proposal, but also votes for it
    */
  function proposeToRemoveToken(Avatar _avatar, uint _index) // TODO: is it good to pass only index?
  public
  payable
  paysFee
  returns(bytes32)
  {
    bytes32 paramsHash = getParametersFromController(_avatar);
    Parameters memory params = parameters[paramsHash];

    IntVoteInterface intVote = params.intVote;
    bytes32 proposalId = intVote.propose(2, params.voteRemoveParams, msg.sender, address(_avatar));
    organizationsProposals[address(_avatar)][proposalId].removeIndex = _index;
    emit RemoveTokenProposal(address(_avatar), proposalId, address(intVote), organizationsTokenRegistry[address(_avatar)][_index]);
    proposalsInfo[address(params.intVote)][proposalId] = ProposalInfo({
      blockNumber:block.number,
      avatar:_avatar
    });
    return proposalId;
  }

  /**
   * @dev execution of proposals, can only be called by the voting machine in which the vote is held.
   * @param _proposalId the ID of the voting in the voting machine
   * @param _param a parameter of the voting result, 1 yes and 2 is no.
   */
  function executeProposal(bytes32 _proposalId, int256 _param) external onlyVotingMachine(_proposalId) returns(bool) {
    Avatar avatar = proposalsInfo[msg.sender][_proposalId].avatar;
    TokenProposal memory proposal = organizationsProposals[address(avatar)][_proposalId];
    require(proposal.token != address(0), "token cannot be the zero address");
    delete organizationsProposals[address(avatar)][_proposalId];
    emit ProposalDeleted(address(avatar), _proposalId);
    if (_param == 1) {

      // Add a token
      if (proposal.addToken) {
        organizationsTokenRegistry[address(avatar)].push(proposal.token); // TODO: is this safe? (re-entry)
        emit TokenAdded(address(avatar), proposal.token);
      }
      // Remove a token
      if (!proposal.addToken) {
        // TODO: we will have gaps in the registry. Is that okay?
        address token = organizationsTokenRegistry[address(avatar)][proposal.removeIndex];
        delete organizationsTokenRegistry[address(avatar)][proposal.removeIndex];
        emit TokenRemoved(address(avatar), token);
      }
    }
    emit ProposalExecuted(address(avatar), _proposalId, _param);
    return true;
  }
}