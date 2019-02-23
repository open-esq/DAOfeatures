const migration = require("../migration.json")

const Avatar = artifacts.require("@daostack/arc/Avatar.sol")
const Controller = artifacts.require("@daostack/arc/Controller.sol")
const DaoCreator = artifacts.require("@daostack/arc/DaoCreator.sol")
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

  const schemesArray = [tokenRegistryInstance.address]
  const paramsArray = [NULL_HASH]
  const permissionArray = ["0x00000000"]

  console.log("OWNER " + (await avatarInst.owner.call()))

  // set the DAO's initial schmes:
  await daoCreatorInst.setSchemes(
    avatarInst.address,
    schemesArray,
    paramsArray,
    permissionArray
  )

  console.log("Avatar address: " + avatarInst.address)
  console.log("Your Token Registry DAO was deployed successfuly!")
}
