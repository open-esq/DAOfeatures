const migration = require("../migration.json")
const DaoJson = require("../.daostack/dao.json")
const TokenRegistry = artifacts.require("TokenRegistryScheme")

const networkId = "private"
const token = "0x18774772fc4F6EA5fd5010c78C08De97a5c7088A"

contract("Token Registry test", async accounts => {
  const { avatar, tokenRegisterParamsHash } = DaoJson
  const { AbsoluteVote: absoluteVote } = migration[networkId].base

  it("check parameters", async () => {
    const tokenRegInstance = await TokenRegistry.deployed()
    var parameters = await tokenRegInstance.parameters(tokenRegisterParamsHash)
    assert.equal(parameters[2], absoluteVote)
  })

  it("it should be possible to propose a new token", async () => {
    const tokenRegInstance = await TokenRegistry.deployed()
    const sender = accounts[0]
    console.log("Avatar address: " + avatar)
    const tx = await tokenRegInstance.proposeToken(avatar, token, {
      from: sender,
      gas: "6700000",
      value: "6700001",
    })
    assert.isNotNull(tx)
  })
})
