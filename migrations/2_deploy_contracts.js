var SimpleStorage = artifacts.require("./SimpleStorage.sol");
var Fundraiser = artifacts.require("./Fundraiser.sol");

module.exports = function(deployer) {
  deployer.deploy(Fundraiser);
  // deployer.link(SimpleStorage, Fundraiser);
};
