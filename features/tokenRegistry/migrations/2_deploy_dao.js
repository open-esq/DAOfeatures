const readWriteFiles = require("../lib/readWriteFile")
const migration = require("../migration.json")

const Avatar = artifacts.require("@daostack/arc/Avatar.sol")
const Controller = artifacts.require("@daostack/arc/Controller.sol")
const DaoCreator = artifacts.require("@daostack/arc/DaoCreator.sol")
const AbsoluteVote = artifacts.require("@daostack/arc/AbsoluteVote.sol")

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
  console.log("start")
  const accounts = await web3.eth.getAccounts((err, res) => res)
  console.log(accounts)

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

  const daoCreatorInst = await DaoCreator.at(
    migration[networkId].base.DaoCreator
  )

  const absoluteVoteInst = await AbsoluteVote.at(
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
    { gas: GAS_LIMIT }
  )

  const avatarInst = await Avatar.at(returnedParams.logs[0].args._avatar)

  console.log("here1")
  await deployer.deploy(
    TokenRegistryScheme,
    avatarInst.address,
    100000,
    1,
    0,
    500,
    50
  )
  console.log("here2")

  const tokenRegistrySchemeAddress = (await TokenRegistryScheme.deployed())
    .address

  console.log("here3")
  const tokenRegistryInstance = await TokenRegistryScheme.deployed()

  console.log("here4")
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

  const tokenRegisterParams = await tokenRegistryInstance.getParametersHash(
    voteParametersHash,
    voteParametersHash,
    absoluteVoteInst.address
  )

  console.log("avatarInst.address: " + avatarInst.address)
  console.log("tokenRegistryInstance.address: " + tokenRegistryInstance.address)
  console.log("tokenRegisterParams: " + tokenRegisterParams)

  const schemesArray = [tokenRegistryInstance.address]
  const paramsArray = [tokenRegisterParams]
  const permissionArray = ["0x0000001F"]

  console.log("OWNER " + (await avatarInst.owner.call()))

  // set the DAO's initial schmes:
  await daoCreatorInst.setSchemes(
    avatarInst.address,
    schemesArray,
    paramsArray,
    permissionArray,
    "metaData"
  )
  console.log("schemes set")

  const dao = {
    Avatar: avatarInst.address,
  }

  readWriteFiles.storeData(dao, "tmp/dao.json")

  console.log("Avatar address: " + avatarInst.address)
  console.log("Your Token Registry DAO was deployed successfuly!")
}
