const readWriteFiles = require("../lib/readWriteFile")
const migration = require("../migration.json")
const truffleContract = require("truffle-contract")

const avatarContractLoader = getContractLoader(
  "../node_modules/@daostack/arc/build/contracts/Avatar.json"
)
const daoCreatorContractLoader = getContractLoader(
  "../node_modules/@daostack/arc/build/contracts/DaoCreator.json"
)
const absoluteVoteContractLoader = getContractLoader(
  "../node_modules/@daostack/arc/build/contracts/AbsoluteVote.json"
)

const TokenRegistryScheme = artifacts.require(
  "../contracts/TokenRegistryScheme.sol"
)

// Organization parameters:
const orgName = "Token Registry"
const tokenName = "RegTok"
const tokenSymbol = "RGT"
let founders
const foundersTokens = [100]
const foundersRep = [10]
const GAS_LIMIT = 5900000
const NULL_HASH =
  "0x0000000000000000000000000000000000000000000000000000000000000000"
const NULL_ADDRESS = "0x0000000000000000000000000000000000000000"
const votePrec = 50

module.exports = async function(deployer) {
  const accounts = await web3.eth.getAccounts((err, res) => res)
  let networkId

  switch (deployer.network) {
    case "ganache":
    case "development":
      founders = [accounts[0]]
      networkId = "private"
      break
    case "kovan":
    case "kovan-infura":
      networkId = "kovan"
      break
  }

  const daoCreatorInst = await daoCreatorContractLoader.at(
    migration[networkId].base.DaoCreator
  )
  const absoluteVoteInst = await absoluteVoteContractLoader.at(
    migration[networkId].base.AbsoluteVote
  )

  // Create DAO:
  const returnedParams = await daoCreatorInst.forgeOrg(
    orgName,
    tokenName,
    tokenSymbol,
    founders,
    foundersTokens, // Founders token amounts
    foundersRep, // Founders initial reputation
    migration[networkId].base.UController,
    0, // no token cap
    { gas: GAS_LIMIT, from: accounts[0] }
  )

  const avatarInst = await avatarContractLoader.at(
    returnedParams.logs[0].args._avatar
  )

  await deployer.deploy(
    TokenRegistryScheme,
    avatarInst.address,
    100000,
    1,
    0,
    500,
    50
  )

  const tokenRegistrySchemeAddress = (await TokenRegistryScheme.deployed())
    .address

  const tokenRegistryInstance = await TokenRegistryScheme.deployed()

  // Voting parameters and schemes params:
  var voteParametersHash = await absoluteVoteInst.getParametersHash(
    votePrec,
    NULL_ADDRESS
  )

  await tokenRegistryInstance.setParameters(
    voteParametersHash,
    voteParametersHash,
    absoluteVoteInst.address
  )

  const tokenRegisterParamsHash = await tokenRegistryInstance.getParametersHash(
    voteParametersHash,
    voteParametersHash,
    absoluteVoteInst.address
  )

  const schemesArray = [tokenRegistryInstance.address]
  const paramsArray = [tokenRegisterParamsHash]
  const permissionArray = ["0x0000001F"]

  console.log("OWNER " + (await avatarInst.owner.call()))

  // set the DAO's initial schmes:
  await daoCreatorInst.setSchemes(
    avatarInst.address,
    schemesArray,
    paramsArray,
    permissionArray,
    "metaData",
    { from: accounts[0] }
  )

  const dao = {
    avatar: avatarInst.address,
    tokenRegisterParamsHash,
  }

  readWriteFiles.storeData(dao, "tmp/dao.json")

  console.log("Avatar address: " + avatarInst.address)
  console.log("Your Token Registry DAO was deployed successfuly!")
}

// Helpers
function getContractLoader(jsonPath) {
  const json = require(jsonPath)
  const contractLoader = truffleContract(json)
  contractLoader.setProvider(web3.eth.currentProvider)
  return contractLoader
}
