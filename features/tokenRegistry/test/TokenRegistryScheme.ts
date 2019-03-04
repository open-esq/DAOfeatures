const DAOjson = require("../tmp/dao.json")
const TokenRegistry = artifacts.require("TokenRegistryScheme")

contract("Token Registry test", async accounts => {
  it("it should be possible to propose a new token", async () => {
    const sender = accounts[0]
    const token = "0x18774772fc4F6EA5fd5010c78C08De97a5c7088A"
    const avatar = DAOjson.Avatar
    console.log("Avatar address: " + avatar)
    const instance = await TokenRegistry.deployed()
    const proposalId = await instance.proposeToken(avatar, token, {
      from: sender,
      gas: "6700000",
      value: "6700001",
    })
    assert.isNotNull(proposalId)
    //instance.getProposal(avatar, proposalId)
  })
})
