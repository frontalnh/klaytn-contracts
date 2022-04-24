var GeneralBidding = artifacts.require("GeneralBidding");
var generalBiddingV1 = artifacts.require("GeneralBiddingV1");
var ProxyAdmin = artifacts.require("ProxyAdmin");

module.exports = async function (deployer) {
  const totalSupply = 4000;
  const maxBidPerAddress = 10;
  const maxBidPerTx = 10;
  await deployer.deploy(generalBiddingV1);
  await deployer.deploy(ProxyAdmin);
  const proxyAdmin = await ProxyAdmin.deployed();
  const result = await generalBiddingV1.deployed();
  const _logic = result.address;
  const _admin = proxyAdmin.address;
  await deployer.deploy(GeneralBidding, totalSupply, maxBidPerAddress, maxBidPerTx, _logic, _admin);
  const generalBidding = await GeneralBidding.deployed();
};
