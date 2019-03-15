const migration = require("../migration.json")
const DaoJson = require("../.chain/dao.json")
const SimpleTBC = artifacts.require("SimpleTBC")

const networkId = "private"

contract("Simple TBC test", async accounts => {
  const { avatar, SimpleTBCParamsHash } = DaoJson
  const { AbsoluteVote: absoluteVote } = migration[networkId].base

  it("check parameters", async () => {
    const SimpleTBCInstance = await SimpleTBC.deployed()
    var parameters = await SimpleTBCInstance.parameters(SimpleTBCParamsHash)
    assert.equal(parameters[2], absoluteVote)
  })

  it("it should be possible to start a new TBC", async () => {
    const SimpleTBCInstance = await SimpleTBC.deployed()
    const sender = accounts[0]
    console.log("Avatar address: " + avatar)
    const tx = await SimpleTBCInstance.start(avatar, {
      from: sender,
      gas: "6700000",
      value: "6700001",
    })
    assert.isNotNull(tx)
  })
})
