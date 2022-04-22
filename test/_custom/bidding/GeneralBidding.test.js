const { BN } = require("openzeppelin-test-helpers");
const { expect } = require("chai");
const ProxyAdmin = artifacts.require("ProxyAdmin");
const Proxy = artifacts.require("GeneralBidding");
const GeneralBiddingV1 = artifacts.require("GeneralBiddingV1");
const GeneralKIP17Minimized = artifacts.require("GeneralKIP17Minimized");

// account0 -> 생성자

contract("GeneralBiddingV1", function (accounts) {
  beforeEach(async function () {
    const totalSupply = 4000;
    const maxBidPerTx = 10;
    const maxBidPerAddress = 10;

    // 두개의 로직 컨트랙트 배포
    this.proxyAdmin = await ProxyAdmin.new();
    this.logic1 = await GeneralBiddingV1.new({ from: accounts[0] });
    this.logic2 = await GeneralBiddingV1.new({ from: accounts[0] });
    await this.logic1.initialize();
    await this.logic2.initialize();
    // 프록시 컨트랙트 배포
    const proxy_ = await Proxy.new(totalSupply, maxBidPerAddress, maxBidPerTx, this.logic1.address, this.proxyAdmin.address, { from: accounts[0] });
    await this.proxyAdmin.upgrade(proxy_.address, this.logic1.address, { from: accounts[0] });

    this.proxy = await GeneralBiddingV1.at(proxy_.address, { from: accounts[0] });
  });

  it("Full scenario", async function () {
    // 화리 참여자 등록
    await this.proxy.seedWhiteList([accounts[1]], [10], { from: accounts[0] });
    // 화리 참여자 비딩
    const result = await this.proxy.bid(1, { from: accounts[1] });
    const wins = await this.proxy.getWinAddresses();

    this.NFT1 = await GeneralKIP17Minimized.new("NFT1", "NFT1", 10, 10000, 100, 100, { from: accounts[0] });
    this.NFT2 = await GeneralKIP17Minimized.new("NFT2", "NFT2", 10, 10000, 100, 100, { from: accounts[0] });

    const startTimestamp = Math.floor(Date.now() / 1000) - 1000;
    const endTimestamp = Math.floor(Date.now() / 1000) + 86000;
    await this.NFT1.startPublicSale("1234", "100000000000000000", startTimestamp, endTimestamp, 1000, { from: accounts[0] });
    await this.NFT2.startPublicSale("1234", "100000000000000000", startTimestamp, endTimestamp, 1000, { from: accounts[0] });

    await this.NFT1.publicSaleMint(1, "1234", { from: accounts[2], value: "100000000000000000" });
    await this.NFT2.publicSaleMint(1, "1234", { from: accounts[2], value: "100000000000000000" });

    console.log("owner: ", await this.proxy.owner());
    console.log("account0: ", await accounts[0]);
    await this.proxy.setPartnerNFT([this.NFT1.address, this.NFT2.address], [1, 1], { from: accounts[0] });

    await this.proxy.bid(1, { from: accounts[2] });
    let remains = await this.proxy._remains();

    expect(remains).to.be.bignumber.equal(new BN(4000 - 2));

    await this.proxyAdmin.upgrade(this.proxy.address, this.logic2.address, { from: accounts[0] });
    await this.proxy.bid(9, { from: accounts[2] });
    remains = await this.proxy._remains();
    expect(remains).to.be.bignumber.equal(new BN(4000 - 11));

    await this.proxy.withdrawMoney({ from: accounts[0] });
    const balance = await web3.eth.getBalance(this.proxy.address);
    console.log({ balance });
    expect(Number(balance)).to.be.equal(0);
  });
});
