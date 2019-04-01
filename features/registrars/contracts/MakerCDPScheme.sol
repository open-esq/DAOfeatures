pragma solidity ^0.5.0;
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract MakerCDPScheme is Ownable {
  using SafeMath for uint256;
  event CreateAndRegisterCDP(address _avatar, address _registry, uint256 _amt); // _amt in ETH collateralized

  //Hardcoded mainnet contracts...
  address public cdpRegistry;
  address public cdpTub;

  Avatar public avatar;
  address public wallet;
  mapping(address => bytes32[]) registry;
  uint256 public expTime;
  uint256 public amount;

  /**
   * @dev initialize
   * @param _avatar the avatar to own the CDP
   * @param _expTime the expiration time of the Forwarder scheme.
   * @param _amount  the amount of ETH to be collatoralized in the contract.
   * @param  _wallet the address of the wallet the DAI will be transfered to.
   *         Please note that _wallet address should be a trusted account.
   *         Normally this address should be set as the DAO's avatar address.
   */
  function initialize(
    Avatar _avatar,
    uint256 _expTime,
    uint256 _amount,
    address _wallet
  )
  external
  {
    require(avatar == Avatar(0), "can be called only one time");
    require(_avatar != Avatar(0), "avatar cannot be zero");
    require(_expTime > 0, "expiration time cannot be zero");
    require(_amount > 0, "amount of ETH locked must be greater than 0");
    avatar = _avatar;
    wallet = _wallet;
    expTime = _expTime;
    amount = _amount;

    //initialize the hardcoded contract values...we should redeploy the contract suite for testing? However it will not have locked DAI
    cdpRegistry = address('0x4678f0a6958e4d2bc4f1baf7bc52e8f3564f3fe4');
    cdpTub = address('0x448a5065aebb8e423f0896e6c5d525c040f59af3');
  }

  //Should we support interfacce methods here...maybe instead what we do is use the forwarder scheme and this contract signs the transaction from the Avatar

}

