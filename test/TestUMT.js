const { expect } = require('chai');
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { ethers } = require('hardhat');

describe("UMT contract", function () {
    async function deployTokenFixture() {
        const Token = await ethers.getContractFactory("TestUMT");
        const [owner, addr1, addr2] = await ethers.getSigners();

        const umpToken = await Token.deploy();
        await umpToken.deployed();

        return { Token, umpToken, owner, addr1, addr2 };
    }

    describe("Deployment", function () {
        let _umpToken, _owner;
        beforeEach(async () => {
            const { umpToken, owner } = await loadFixture(deployTokenFixture);
            _umpToken = umpToken;
            _owner = owner;
        });

        it("Should set the right token name", async function () {
            expect(await _umpToken.name()).to.equal("Test Urban Miner Project 77-2");
        });
        it("Should set the right token symbol", async function () {
            expect(await _umpToken.symbol()).to.equal("TURM772");
        });
        it("Should set the right owner", async function () {
            expect(await _umpToken.owner()).to.equal(_owner.address);
        });
        it("Should have initial metadata as a default", async function () {
            expect(await _umpToken.contractURI()).to.equal("ipfs://bafkreig2ifiw5qwukd6mooiiii3zmjucdt7dkv5wrw6yzalxgg7vnhm2hi");
        });
    });

    describe("Initial mint", function () {
        let _umpToken, _owner, _totalSupply;
        beforeEach(async () => {
            const { umpToken, owner } = await loadFixture(deployTokenFixture);
            _umpToken = umpToken;
            _owner = owner;

            const totalSupply = await umpToken.totalCount();
            _totalSupply = totalSupply;
            let ids = [];
            let counts = [];
            for (let i=0; i<totalSupply; i++) {
                ids.push(i);
                counts.push(1);
            }

            await _umpToken.initialMint(ids, counts);
        });

        it("Owner should have 1 NFT of id 0 after initial minting.", async function () {
            for (let i=0; i<_totalSupply; i++) {
                expect(await _umpToken.balanceOf(_owner.address, i)).to.equal(1);
            }
        });

        it("Owner token id list should be '0, 1, 2, ... , 9'", async function () {
            const tokenIds = await _umpToken.getUserTokenIds(_owner.address);
            let expectedArray = [];
            for (let i=0; i<_totalSupply; i++) {
                expectedArray.push(ethers.BigNumber.from(i));
            }
            expect(tokenIds).to.not.deep.have.all.members([...expectedArray, ...[ethers.BigNumber.from(10)]]);
            expect(tokenIds).to.deep.have.all.members(expectedArray);
        });
    });

    describe("Metal type after setting metal types.", function () {
        it("All token ids should have right metal type after set", async function () {
            const { umpToken } = await loadFixture(deployTokenFixture);

            const totalSupply = await umpToken.totalCount();
            let ids = [];
            let counts = [];
            for (let i=0; i<totalSupply; i++) {
                ids.push(i);
                counts.push(1);
            }

            await umpToken.initialMint(ids, counts);
            await umpToken.initMetalType();

            let types = [];
            let allIds = [];
            for (let i=0; i<totalSupply; i++) {
                let typeEle = await umpToken.getMetalType(i);
                types.push(typeEle);
                allIds.push(i);
            }

            expect(types).to.deep.have.all.members([0, 1, 1, 2, 2, 2, 3, 3, 3, 3]);
        });
    });

    describe("NFT status after purchasing NFT.", async function () {
        let _umpToken, _owner, _addr1, _addr2, _addr1MetalType, _addr2MetalType;
        this.beforeEach(async () => {
            const { umpToken, owner, addr1, addr2 } = await loadFixture(deployTokenFixture);
            _umpToken = umpToken;
            _owner = owner;
            _addr1 = addr1;
            _addr2 = addr2;
           
            const totalSupply = await umpToken.totalCount();
            let ids = [];
            let counts = [];
            for (let i=0; i<totalSupply; i++) {
                ids.push(i);
                counts.push(1);
            }

            await _umpToken.initialMint(ids, counts);
            await umpToken.initMetalType();
            await umpToken.safeTransferFrom(owner.address, addr1.address, 1, 1, "0x");
            await umpToken.safeTransferFrom(owner.address, addr2.address, 0, 1, "0x");
            _addr1MetalType = await umpToken.getMetalType(1);
            _addr2MetalType = await umpToken.getMetalType(0);
        });

        it("Address1 balance should be 1 only for addr1MetalType", async function () {
            const addr1TokenBalance = await _umpToken.getUserBalance(_addr1.address);
            expect(addr1TokenBalance[_addr1MetalType]).to.equal(1);
        });

        it("Address1 balance should be 1 only for addr2MetalType", async function () {
            const addr2TokenBalance = await _umpToken.getUserBalance(_addr2.address);
            expect(addr2TokenBalance[_addr2MetalType]).to.equal(1);
        });

        it("Address1 should own NFT#1", async function () {
            expect(await _umpToken.getUserTokenIds(_addr1.address)).to.deep.have.all.members([ethers.BigNumber.from(1)]);
        });

        it("Address2 should own NFT#0", async function () {
            expect(await _umpToken.getUserTokenIds(_addr2.address)).to.not.deep.have.all.members([ethers.BigNumber.from(1)]);
            expect(await _umpToken.getUserTokenIds(_addr2.address)).to.deep.have.all.members([ethers.BigNumber.from(0)]);
        });

        it("Token uris for NFT#0, NFT#1 should be updated and uri for NFT#3 and NFT#4 should be remained.", async function () {
            const metalMetadata = [
                "ipfs://bafkreib3muqei5tjfd6bunwihl7iozjycw4ztyab5rxmo3ldkkp4xvhvdi",
                "ipfs://bafkreibp3lofjfgwcg5vzzyyg5b4flqvlitiaivo3cuwpkwu4fmwr57am4",
                "ipfs://bafkreibua7cpcwkj3rom4tjfi3a4yhunyd5acv4bxtuvldag5jzqmhb2j4",
                "ipfs://bafkreicfchzjlwaecuuld7lwakyn5oizccjbwi4cpfkcbbp42v4wlt5pai",
            ];
            const generalMetadata = "ipfs://bafkreibmre4xlda24qjpl52rwyqmfwttlxz33eklqafhytnnuohlyjctvi";

            expect(await _umpToken.uri(1)).to.equal(metalMetadata[_addr1MetalType]);
            expect(await _umpToken.uri(0)).to.equal(metalMetadata[_addr2MetalType]);
            expect(metalMetadata).to.not.includes(await _umpToken.uri(2));
            expect(await _umpToken.uri(3)).to.equal(generalMetadata);
        });
    });

    describe("Every user except owner can own max 2 NFTs", function () {
        it("Should cause a validation error when purchasing more than 2 tokens.", async function () {
            const { umpToken, owner, addr1 } = await loadFixture(deployTokenFixture);
            
            const totalSupply = await umpToken.totalCount();
            let ids = [];
            let counts = [];
            for (let i=0; i<totalSupply; i++) {
                ids.push(i);
                counts.push(1);
            }

            await umpToken.initialMint(ids, counts);
            await umpToken.initMetalType();
            await expect(umpToken.safeBatchTransferFrom(owner.address, addr1.address, [0, 1, 2], [1, 1, 1], '0x')).to.be.revertedWith("Account balance could not be bigger than 2");
        });
    });

    describe("Withdraw contract balance", function () {
        it("withdrawAll should emit WithdarwAll event with arg of contract balance.", async function () {
            const { umpToken } = await loadFixture(deployTokenFixture);

            await umpToken.deposit({ value: 1000 });
            let contractBalance = await umpToken.provider.getBalance(umpToken.address);
            expect(contractBalance).to.be.equal(1000);

            await umpToken.deposit({ value: 500 });
            contractBalance = await umpToken.provider.getBalance(umpToken.address);
            expect(contractBalance).to.be.equal(1500);

            await expect(umpToken.withdrawAll())
            .to.emit(umpToken, "WithdrawAll")
            .withArgs(1500);

            contractBalance = await umpToken.provider.getBalance(umpToken.address);
            expect(contractBalance).to.be.equal(0);
        });

        it("Owner balance should be increased after calling withdrawAll", async function () {
            const { umpToken, owner } = await loadFixture(deployTokenFixture);

            await umpToken.deposit({ value: 2000 });
            let contractBalance = await umpToken.provider.getBalance(umpToken.address);
            expect(contractBalance).to.be.equal(2000);

            await umpToken.deposit({ value: 3000 });
            contractBalance = await umpToken.provider.getBalance(umpToken.address);
            expect(contractBalance).to.be.equal(5000);

            await expect(umpToken.withdrawAll())
            .to.changeEtherBalance(owner, "5000");

            contractBalance = await umpToken.provider.getBalance(umpToken.address);
            expect(contractBalance).to.be.equal(0);
        });
    });
});