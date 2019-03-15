pragma solidity >=0.4.21 <0.6.0;

import "@daostack/arc/contracts/UniversalSchemes/UniversalScheme.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title An mirror contract for a Token Bonding Curve.
 * @dev Allow people to buy/sell from the curve simply sending ether/tokens to an address
 */
contract MirrorContractTBC {
    Avatar public organization; // The organization address (the avatar)
    SimpleTBC public simpleTBC;  // The TBC contract address
    /**
    * @dev Constructor, setting the organization and TBC scheme.
    * @param _organization The organization's avatar.
    * @param _simpleTBC The TBC Scheme.
    */
    constructor(Avatar _organization, SimpleTBC _simpleTBC) public {
        organization = _organization;
        simpleTBC = _simpleTBC;
    }

    /**
    * @dev Fallback function, when ether is sent it will buy from the TBC.
    * The ether will be returned if the buy is failed.
    */
    function () external payable {
        // Not to waste gas, if no value.
        require(msg.value != 0);

        // Return ether if couldn't buy.
        require(simpleTBC.buy.value(msg.value)(organization, msg.sender) != 0);
    }

    // TODO: find way to include a fallback for receiving the DAO's token
    // ERC 677?
    // would we need to create a new token as part of this scheme or would this be compatible with DaoToken?
    // this would be a lot easier as user just sends token or ether to the TBC without making any contract calls

}


/**
 * @title SimpleTBC scheme.
 * @dev A universal scheme to allow organizations to open a simple Token Bonding Curve
 */
contract SimpleTBC is UniversalScheme {
    using SafeMath for uint;

    // Struct holding the data for each organization
    struct Organization {
        bytes32 paramsHash; // Save the parameters approved by the org to open the TBC, so reuse of TBC will not change.
        address mirrorContractTBC; // Avatar is a contract for users that want to send ether without calling a function.
        uint poolBalance;
    }

    // A mapping from hashes to parameters (use to store a particular configuration on the controller)
    struct Parameters {
        uint price; // Price represents Tokens per 1 Eth
        uint startBlock;
        address payable beneficiary; // all funds received will be transferred to this address.
    }

    // A mapping from the organization (Avatar) address to the saved data of the organization:
    mapping(address=>Organization) public organizationsTBCInfo;

    mapping(bytes32=>Parameters) public parameters;

    //event DonationReceived(address indexed organization, address indexed _donor, uint _incomingEther, uint indexed _tokensAmount);
    event CurveBuy(
        address indexed organization,
        address indexed _buyer,
        uint256 _incomingEther,
        uint256 _tokensAmount,
        uint256 indexed when
    );
    event CurveSeller(
        address indexed organization,
        address indexed _seller,
        uint256 _incomingTokens,
        uint256 _etherAmount,
        uint256 indexed when
    );


    /**
    * @dev Hash the parameters, save them if necessary, and return the hash value
    * @param _price  represents Tokens per 1 Eth
    * @param _startBlock  TBC start block
    * @param _beneficiary the TBC ether beneficiary
    * @return bytes32 -the params hash
    */
    function setParameters(
        uint _price,
        uint _startBlock,
        address _beneficiary
    )
        public
        returns(bytes32)
    {
        bytes32 paramsHash = getParametersHash(
            _price,
            _startBlock,
            _beneficiary
        );
        // if (parameters[paramsHash].cap == 0) {
        //     parameters[paramsHash] = Parameters({
        //         cap: _cap,
        //         price: _price,
        //         startBlock: _startBlock,
        //         beneficiary:_beneficiary,
        //     });
        // }
        return paramsHash;
    }

    /**
    * @dev Hash the parameters and return the hash value
    * @param _price  represents Tokens per 1 Eth
    * @param _startBlock  TBC start block
    * @param _beneficiary the TBC ether beneficiary
    * @return bytes32 -the params hash
    */
      function getParametersHash(
        uint _price,
        uint _startBlock,
        address _beneficiary
    )
        public
        pure
        returns(bytes32)
   {
        return (keccak256(
            abi.encodePacked(
            _price,
            _startBlock,
            _beneficiary
        )));
    }

    /**
     * @dev start an TBC
     * @param _avatar The Avatar's of the organization
     */
    function start(Avatar _avatar) public {
        require(!isActive(_avatar));
        Organization memory org;
        org.paramsHash = getParametersFromController(_avatar);
        org.mirrorContractTBC = address(new MirrorContractTBC(_avatar, this));
        organizationsTBCInfo[address(_avatar)] = org;
    }

    /**
     * @dev Check is an TBC is active. Active TBC:
     * 1. The organization is registered.
     * 2. The current block isn't smaller then the "startBlock"
     * @param _avatar The Avatar's of the organization
     * @return bool which represents a successful of the function
     */
    function isActive(Avatar _avatar) public view returns(bool) {
        Organization memory org = organizationsTBCInfo[address(_avatar)];
        Parameters memory params = parameters[org.paramsHash];
        return block.number > params.startBlock;
    }



    // /**
    //  * @dev Donating ethers to get tokens.
    //  * @param _avatar The Avatar's of the organization.
    //  * @param _buyer The buyer's address - which will receive the TBC's tokens.
    //  * @return uint256 number of tokens minted for the donation.
    //  */
    function buy (Avatar _avatar, address _buyer) public payable returns (uint256){
        Organization memory org = organizationsTBCInfo[address(_avatar)];
        Parameters memory params = parameters[org.paramsHash];

        // Check TBC is active:
        require(isActive(_avatar));

        uint incomingEther = msg.value;

        //uint tokens = calculateBuyReturn(totalSupply, poolBalance, reserveRatio, incomingEther);
        uint tokens = 0;

        // Update total raised, call event and return amount of tokens bought:
        organizationsTBCInfo[address(_avatar)].poolBalance += incomingEther;
        // Send ether to the defined address:
        params.beneficiary.transfer(incomingEther);

        require(ControllerInterface(_avatar.owner()).mintTokens(tokens, _buyer,address(_avatar)));

        emit CurveBuy(address(_avatar), _buyer, incomingEther, tokens, now);
        return tokens;

    }

    // function sell(uint256 tokens) public returns (uint256){

    // };

    function calculateBuyReturn(
      uint256 _totalSupply,
      uint256 _poolBalance,
      uint256 _reserveRatio,
      uint256 _amount
    ) public pure returns (uint256){
        return 0;
    }

    function calculateSellReturn(
      uint256 _totalSupply,
      uint256 _poolBalance,
      uint256 _reserveRatio,
      uint256 _amount
    ) public pure returns (uint256){
        return 0;
    }

    // function marketCap() public view returns (uint256 theMarketCap) {

    // };


}
