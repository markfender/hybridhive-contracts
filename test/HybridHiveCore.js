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

      //console.log(await HybridHiveCore.getTokensInNetwork(6));

      expect(await HybridHiveCore.getTokenBalance(1, owner.address)).to.equal(
        1500
      );
    });
    /*
    it("Should set the right owner", async function () {
      const { lock, owner } = await loadFixture(setupInitState);

      expect(await lock.owner()).to.equal(owner.address);
    });

    it("Should receive and store the funds to lock", async function () {
      const { lock, lockedAmount } = await loadFixture(
        deployOneYearLockFixture
      );

      expect(await ethers.provider.getBalance(lock.address)).to.equal(
        lockedAmount
      );
    });*/
  });
  /*
  describe("Withdrawals", function () {
    describe("Validations", function () {
      it("Should revert with the right error if called too soon", async function () {
        const { lock } = await loadFixture(deployOneYearLockFixture);

        await expect(lock.withdraw()).to.be.revertedWith(
          "You can't withdraw yet"
        );
      });

      it("Should revert with the right error if called from another account", async function () {
        const { lock, unlockTime, otherAccount } = await loadFixture(
          deployOneYearLockFixture
        );

        // We can increase the time in Hardhat Network
        await time.increaseTo(unlockTime);

        // We use lock.connect() to send a transaction from another account
        await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
          "You aren't the owner"
        );
      });

      it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
        const { lock, unlockTime } = await loadFixture(
          deployOneYearLockFixture
        );

        // Transactions are sent using the first signer by default
        await time.increaseTo(unlockTime);

        await expect(lock.withdraw()).not.to.be.reverted;
      });
    });

    describe("Events", function () {
      it("Should emit an event on withdrawals", async function () {
        const { lock, unlockTime, lockedAmount } = await loadFixture(
          deployOneYearLockFixture
        );

        await time.increaseTo(unlockTime);

        await expect(lock.withdraw())
          .to.emit(lock, "Withdrawal")
          .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
      });
    });

    describe("Transfers", function () {
      it("Should transfer the funds to the owner", async function () {
        const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
          deployOneYearLockFixture
        );

        await time.increaseTo(unlockTime);

        await expect(lock.withdraw()).to.changeEtherBalances(
          [owner, lock],
          [lockedAmount, -lockedAmount]
        );
      });
    });
  });*/
});
