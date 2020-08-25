const CompleteFinancingContract = artifacts.require("CompleteFinancingContract");

module.exports = function(deployer) {
  deployer.deploy(CompleteFinancingContract);
};
