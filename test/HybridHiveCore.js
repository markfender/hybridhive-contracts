const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const BN = ethers.BigNumber;
describe("HybridHiveCore", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function setupInitState() {
    // Contracts are deployed using the first signer/account by default
    const [owner, ...accounts] = await ethers.getSigners();

    const HybridHiveCoreFactory = await ethers.getContractFactory(
      "HybridHiveCore"
    );
    const HybridHiveCore = await HybridHiveCoreFactory.deploy();

    const AggregatorOperatorFactory = await ethers.getContractFactory(
      "AggregatorOperatorMock"
    );
    const AggregatorOperator = await AggregatorOperatorFactory.deploy();
    await AggregatorOperator.setCoreAddress(HybridHiveCore.address);

    const TokenOperatorFactory = await ethers.getContractFactory(
      "TokenOperatorMock"
    );
    const TokenOperator = await TokenOperatorFactory.deploy();
    await TokenOperator.setCoreAddress(HybridHiveCore.address);

    // @todo replace with generator

    {
      // create Token[1]
      await HybridHiveCore.createToken(
        "Token[1]", // _tokenName
        "TKN[1]", // _tokenSymbol
        "", // _tokenURI
        TokenOperator.address, // _tokenOperator
        0, // _parentAggregator
        [owner.address, accounts[0].address], // _tokenHolders
        [1500, 500] // _holderBalances
      );

      // create Token[2]
      await HybridHiveCore.createToken(
        "Token[2]", // _tokenName
        "TKN[2]", // _tokenSymbol
        "", // _tokenURI
        TokenOperator.address, // _tokenOperator
        0, // _parentAggregator
        [accounts[1].address, accounts[2].address], // _tokenHolders
        [1400, 600] // _holderBalances
      );

      // create Token[3]
      await HybridHiveCore.createToken(
        "Token[3]", // _tokenName
        "TKN[3]", // _tokenSymbol
        "", // _tokenURI
        TokenOperator.address, // _tokenOperator
        0, // _parentAggregator
        [accounts[3].address], // _tokenHolders
        [500] // _holderBalances
      );

      // create Token[4]
      await HybridHiveCore.createToken(
        "Token[4]", // _tokenName
        "TKN[4]", // _tokenSymbol
        "", // _tokenURI
        TokenOperator.address, // _tokenOperator
        0, // _parentAggregator
        [accounts[4].address, accounts[5].address], // _tokenHolders
        [999, 666] // _holderBalances
      );

      // create Token[5]
      await HybridHiveCore.createToken(
        "Token[5]", // _tokenName
        "TKN[5]", // _tokenSymbol
        "", // _tokenURI
        TokenOperator.address, // _tokenOperator
        0, // _parentAggregator
        [accounts[6].address, accounts[7].address], // _tokenHolders
        [300, 200] // _holderBalances
      );

      // create Token[6]
      await HybridHiveCore.createToken(
        "Token[6]", // _tokenName
        "TKN[6]", // _tokenSymbol
        "", // _tokenURI
        TokenOperator.address, // _tokenOperator
        0, // _parentAggregator
        [accounts[8].address], // _tokenHolders
        [300] // _holderBalances
      );
    }

    {
      // create Ag[1]
      await HybridHiveCore.createAggregator(
        "Ag[1]", // _aggregatorName
        "AG[1]", // _aggregatorSymbol
        "", // _aggregatorURI
        AggregatorOperator.address, // _aggregatorOperator
        0, // _parentAggregator
        1, // _aggregatedEntityType 1 - token, 2 aggregator
        [1, 2], // _aggregatedEntities
        [66666666, 33333334] // _aggregatedEntitiesWeights
      );
      // connect tokens to the aggregator
      await TokenOperator.updateParentAggregator(1, 1);
      await TokenOperator.updateParentAggregator(2, 1);

      // @todo attach token to upper aggregator

      // create Ag[2]
      await HybridHiveCore.createAggregator(
        "Ag[2]", // _aggregatorName
        "AG[2]", // _aggregatorSymbol
        "", // _aggregatorURI
        AggregatorOperator.address, // _aggregatorOperator
        0, // _parentAggregator
        1,
        [3], // _aggregatedEntities
        [100000000] // _aggregatedEntitiesWeights
      );
      await TokenOperator.updateParentAggregator(3, 2);

      // create Ag[3]
      await HybridHiveCore.createAggregator(
        "Ag[3]", // _aggregatorName
        "AG[3]", // _aggregatorSymbol
        "", // _aggregatorURI
        AggregatorOperator.address, // _aggregatorOperator
        0, // _parentAggregator
        1,
        [4, 5], // _aggregatedEntities
        [50000000, 50000000] // _aggregatedEntitiesWeights
      );
      await TokenOperator.updateParentAggregator(4, 3);
      await TokenOperator.updateParentAggregator(5, 3);

      // create Ag[4]
      await HybridHiveCore.createAggregator(
        "Ag[4]", // _aggregatorName
        "AG[4]", // _aggregatorSymbol
        "", // _aggregatorURI
        AggregatorOperator.address, // _aggregatorOperator
        0, // _parentAggregator
        1,
        [6], // _aggregatedEntities
        [100000000] // _aggregatedEntitiesWeights
      );
      await TokenOperator.updateParentAggregator(6, 4);

      // create Ag[5]
      await HybridHiveCore.createAggregator(
        "Ag[5]", // _aggregatorName
        "AG[5]", // _aggregatorSymbol
        "", // _aggregatorURI
        AggregatorOperator.address, // _aggregatorOperator
        0, // _parentAggregator
        2,
        [1, 2], // _aggregatedEntities
        [50000000, 50000000] // _aggregatedEntitiesWeights
      );
      await AggregatorOperator.updateParentAggregator(1, 5);
      await AggregatorOperator.updateParentAggregator(2, 5);

      // create Ag[6]
      await HybridHiveCore.createAggregator(
        "Ag[6]", // _aggregatorName
        "AG[6]", // _aggregatorSymbol
        "", // _aggregatorURI
        AggregatorOperator.address, // _aggregatorOperator
        0, // _parentAggregator
        2,
        [3, 4], // _aggregatedEntities
        [75000000, 25000000] // _aggregatedEntitiesWeights
      );
      await AggregatorOperator.updateParentAggregator(3, 6);
      await AggregatorOperator.updateParentAggregator(4, 6);

      // create Ag[7]
      await HybridHiveCore.createAggregator(
        "Ag[7]", // _aggregatorName
        "AG[7]", // _aggregatorSymbol
        "", // _aggregatorURI
        AggregatorOperator.address, // _aggregatorOperator
        0, // _parentAggregator
        2,
        [5, 6], // _aggregatedEntities
        [60000000, 40000000] // _aggregatedEntitiesWeights
      );
      await AggregatorOperator.updateParentAggregator(5, 7);
      await AggregatorOperator.updateParentAggregator(6, 7);
    }

    /* schema to setup as an initial state
    Ag[7]
      Ag[5] 60%
        Ag[1] 30%
          Token[1] 20%
            account[0] 15% 1500  owner
            account[1] 5% 500
          Token[2] 10%
            account[2] 7% 1400
            account[3] 3% 600
        Ag[2] 30%
          Token[3]30%
            account[4] 30% 500
      Ag[6]40%
        Ag[3] 30%
          Token[4] 15%
            account[5] 9% 999
            account[6] 6% 666
          Token[5] 15%
            account[7] 10% 300
            account[8] 5% 200
        Ag[4] 10%
          Token[6] 10%
            account[9] 10% 300
    */

    return { HybridHiveCore, owner, accounts };
  }

  describe("Deployment", function () {
    it("Should get user token balance correctly", async function () {
      const { HybridHiveCore, owner, accounts } = await loadFixture(
        setupInitState
      );

      expect(await HybridHiveCore.getTokenBalance(1, owner.address)).to.equal(
        1500
      );
    });

    it("Should properly calculate global token share", async function () {
      const { HybridHiveCore, owner, accounts } = await loadFixture(
        setupInitState
      );

      expect(await HybridHiveCore.getGlobalTokenShare(7, 1, 1500)).to.equal(
        14999999
      );
    });

    it("Should properly calculate global aggregator share", async function () {
      const { HybridHiveCore, owner, accounts } = await loadFixture(
        setupInitState
      );

      expect(await HybridHiveCore.getGlobalAggregatorShare(6, 3)).to.equal(
        75000000
      );
      expect(await HybridHiveCore.getGlobalAggregatorShare(7, 1)).to.equal(
        30000000
      );
      expect(await HybridHiveCore.getGlobalAggregatorShare(7, 6)).to.equal(
        40000000
      );
      expect(await HybridHiveCore.getGlobalAggregatorShare(7, 4)).to.equal(
        10000000
      );
    });

    it("Should properly convert global share into spesific tokens amount", async function () {
      const { HybridHiveCore, owner, accounts } = await loadFixture(
        setupInitState
      );

      expect(
        await HybridHiveCore.getTokensAmountFromShare(7, 1, 10000000) // 10% DENOMINATOR equals 100%
      ).to.equal(1000);

      expect(
        await HybridHiveCore.getTokensAmountFromShare(7, 2, 3000000)
      ).to.equal(600);

      expect(
        await HybridHiveCore.getTokensAmountFromShare(7, 3, 3000000)
      ).to.equal(50);
    });

    it("Should properly get root aggregator in the network", async function () {
      const { HybridHiveCore, owner, accounts } = await loadFixture(
        setupInitState
      );

      expect(await HybridHiveCore.getRootAggregator(3)).to.equal(7);
    });

    it("Should properly commit the global transfer", async function () {
      const { HybridHiveCore, owner, accounts } = await loadFixture(
        setupInitState
      );
      //await HybridHiveCore._addSubEnitiesShare(5, 1, 5000000);
      /*await HybridHiveCore.globalTransfer(
        1,
        5,
        owner.address,
        accounts[6].address,
        500
      );*/
    });
  });
});
