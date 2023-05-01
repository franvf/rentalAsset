const storeContract = artifacts.require("storeContract");

module.exports = function (deployer) {
  deployer.deploy(storeContract);
};
