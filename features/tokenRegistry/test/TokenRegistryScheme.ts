const DAOjson = require("../tmp/dao.json")
const TokenRegistry = artifacts.require("TokenRegistryScheme")

contract("Token Registry test", async accounts => {
  it("it should be possible to propose a new token", async () => {
    //const avatar = accounts[4]
    const sender = accounts[0]
    const token = "0x18774772fc4F6EA5fd5010c78C08De97a5c7088A"
    const avatar = DAOjson.Avatar
    console.log("Avatar address: " + avatar)
    let instance = await TokenRegistry.deployed()
    console.log("TokenRegistry address: " + instance.address)
    let proposalId = await instance.proposeToken(avatar, token, {
      from: sender,
      gas: "6700000",
      value: "6700001",
    })
    console.log("proposalId: " + proposalId)
    //instance.getProposal(avatar, proposalId)
    assert.equal(true, true)
  })
})
