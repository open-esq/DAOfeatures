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
    let test1 = await instance.proposeToken(avatar, token, {
      from: sender,
      gas: "6700000",
      value: "6700001",
    })
    //let res = await instance.proposeToken(avatar, token, {
    //  from: sender,
    //})
    //let proposalId = await instance.proposeToken(avatar, token, {
    //  from: sender,
    //  gas: "6700000",
    //  value: "6700001",
    //})
    console.log("test1: " + JSON.stringify(test1))
    //instance.getProposal(avatar, proposalId)
    assert.equal(true, true)
  })
})
