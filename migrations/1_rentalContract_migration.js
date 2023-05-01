const rentalContract = artifacts.require("rentalContract");

module.exports = function (deployer) {
  deployer.deploy(rentalContract, "Public", "Notary", "id1", 1);
};
