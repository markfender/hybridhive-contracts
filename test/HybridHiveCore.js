const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const FN = ethers.FixedNumber;
const BN = ethers.BigNumber.from;
const DECIMALS = BN("10").pow("18"); // @todo move to constants

function toPercentageString(value) {
  return FN.fromValue(value.toString(), 18).round(17).toString();
}

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

    // @todo replace with loop

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
        [DECIMALS.mul(2).div(3), DECIMALS.div(3)] // _aggregatedEntitiesWeights
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
        [DECIMALS] // _aggregatedEntitiesWeights
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
        [DECIMALS.div(2), DECIMALS.div(2)] // _aggregatedEntitiesWeights
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
        [DECIMALS] // _aggregatedEntitiesWeights
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
        [DECIMALS.div(2), DECIMALS.div(2)] // _aggregatedEntitiesWeights
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
        [DECIMALS.mul(3).div(4), DECIMALS.div(4)] // _aggregatedEntitiesWeights
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
        [DECIMALS.mul(3).div(5), DECIMALS.mul(2).div(5)] // _aggregatedEntitiesWeights
      );
      await AggregatorOperator.updateParentAggregator(5, 7);
      await AggregatorOperator.updateParentAggregator(6, 7);
    }

    /* schema to setup as an initial state
    Ag[7]
      Ag[5] 60%
        Ag[1] 30%
          Token[1] 20% 2000
            account[owner] 15% 1500  owner
            account[0] 5% 500
          Token[2] 10%
            account[1] 7% 1400
            account[2] 3% 600
        Ag[2] 30%
          Token[3]30%
            account[3] 30% 500
      Ag[6]40%
        Ag[3] 30%
          Token[4] 15%
            account[4] 9% 999
            account[5] 6% 666
          Token[5] 15%
            account[6] 9% 300
            account[7] 6% 200
        Ag[4] 10%
          Token[6] 10%
            account[8] 10% 300

    */
    /*
    Ag[7]
      Ag[5] 55%
        Ag[1] 25%
          Token[1] 15% 5000
            account[owner] 10% 1000  owner
            account[0] 5% 500
          Token[2] 10%
            account[1] 7% 1400
            account[2] 3% 600
        Ag[2] 30%
          Token[3]30%
            account[3] 30% 500
      Ag[6]45%
        Ag[3] 35%
          Token[4] 15%
            account[4] 9% 999
            account[5] 6% 666
          Token[5] 20%
            account[6] 14% 300
            account[7] 6% 200
        Ag[4] 10%
          Token[6] 10%
            account[8] 10% 300
    */

    return { HybridHiveCore, owner, accounts };
  }

  describe("HibridHive Getters", function () {
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
      let result = await HybridHiveCore.getGlobalValueShare(7, 1, 1, 1500);

      expect(toPercentageString(result)).to.equal("0.15");

      result = await HybridHiveCore.getGlobalValueShare(
        7,
        2,
        1,
        DECIMALS.div(10)
      );

      expect(toPercentageString(result)).to.equal("0.03");
    });

    it("Should properly calculate global aggregator share", async function () {
      const { HybridHiveCore, owner, accounts } = await loadFixture(
        setupInitState
      );

      expect(
        toPercentageString(await HybridHiveCore.getGlobalAggregatorShare(6, 3))
      ).to.equal("0.75");

      expect(
        toPercentageString(await HybridHiveCore.getGlobalAggregatorShare(7, 1))
      ).to.equal("0.3");

      expect(
        toPercentageString(await HybridHiveCore.getGlobalAggregatorShare(7, 6))
      ).to.equal("0.4");

      expect(
        toPercentageString(await HybridHiveCore.getGlobalAggregatorShare(7, 4))
      ).to.equal("0.1");
    });

    it("Should properly convert global share into spesific tokens amount", async function () {
      const { HybridHiveCore, owner, accounts } = await loadFixture(
        setupInitState
      );

      expect(
        await HybridHiveCore.getAbsoluteAmountFromShare(
          7,
          1,
          1,
          DECIMALS.div(10)
        )
      ).to.equal("1000");

      expect(
        await HybridHiveCore.getAbsoluteAmountFromShare(
          7,
          1,
          2,
          DECIMALS.mul(3).div(100)
        )
      ).to.equal("600");

      expect(
        await HybridHiveCore.getAbsoluteAmountFromShare(
          7,
          1,
          3,
          DECIMALS.mul(3).div(100)
        )
      ).to.equal("50");
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
      async function logNetworkTree(rootAggregator, space, globalRoot) {
        const str = new Array(space + 1).join("-");

        if (!globalRoot) globalRoot = rootAggregator;
        let subEntities = await HybridHiveCore.getAggregatorSubEntities(
          rootAggregator
        );
        const aggregatorParent = await HybridHiveCore.getAggregatorParent(
          rootAggregator
        );
        if (aggregatorParent == 0)
          console.log(rootAggregator, ` - global share 100%`);

        for (entityId of subEntities[1]) {
          if (subEntities[0] == 2) {
            const shareOfEntity = await HybridHiveCore.getGlobalAggregatorShare(
              globalRoot,
              entityId
            );
            const totalSupply = await HybridHiveCore.getTotalSupply(
              subEntities[0],
              entityId
            );
            console.log(
              str,
              entityId,
              ` - global share: ${shareOfEntity} (${totalSupply})`
            );

            await logNetworkTree(entityId, space + 2, globalRoot);
          } else {
            const totalSupply = await HybridHiveCore.getTotalSupply(
              subEntities[0],
              entityId
            );
            const shareOfEntity = await HybridHiveCore.getGlobalValueShare(
              globalRoot,
              1,
              entityId,
              totalSupply
            );
            console.log(
              "---- ",
              entityId,
              ` - global share: ${shareOfEntity}  (${totalSupply})`
            );
          }
        }
      }

      async function logAccountGlobalBalance(accountAddress, tokenId) {
        const getUsetBalance = await HybridHiveCore.getTokenBalance(
          tokenId,
          accountAddress
        );
        const globalTokenShare = await HybridHiveCore.getGlobalValueShare(
          7,
          1,
          tokenId,
          getUsetBalance
        );
        console.log(accountAddress, getUsetBalance, globalTokenShare);
      }

      await logAccountGlobalBalance(owner.address, 1);
      await logAccountGlobalBalance(accounts[6].address, 5);
      //await logNetworkTree(7, 0);

      let tx = await HybridHiveCore.globalTransfer(
        1,
        5,
        owner.address,
        accounts[6].address,
        500
      );
      tx.wait();
      tx = await HybridHiveCore.connect(accounts[6]).globalTransfer(
        5,
        1,
        accounts[6].address,
        owner.address,
        166
      );
      tx.wait();

      //await logNetworkTree(7, 0);

      await logAccountGlobalBalance(owner.address, 1);
      await logAccountGlobalBalance(accounts[6].address, 5);
    });
  });
});
