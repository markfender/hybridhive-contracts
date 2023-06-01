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

    const TokenMockFactory = await ethers.getContractFactory("TokenMock");

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

    const createNewToken = async (tokenName, tokenSymbol, recipients) => {
      const newToken = await TokenMockFactory.deploy(tokenName, tokenSymbol, 0);
      for (recipient of recipients) {
        await newToken.mint(recipient.address, recipient.amount);
      }
      return newToken;
    };
    // @todo move to separate file
    const tokensConfig = [
      {
        name: "Token[1]",
        symbol: "TKN[1]",
        holders: [
          {
            address: owner.address,
            amount: 1500,
          },
          {
            address: accounts[0].address,
            amount: 500,
          },
        ],
      },
      {
        name: "Token[2]",
        symbol: "TKN[2]",
        holders: [
          {
            address: accounts[1].address,
            amount: 1400,
          },
          {
            address: accounts[2].address,
            amount: 600,
          },
        ],
      },
      {
        name: "Token[3]",
        symbol: "TKN[3]",
        holders: [
          {
            address: accounts[3].address,
            amount: 500,
          },
        ],
      },
      {
        name: "Token[4]",
        symbol: "TKN[4]",
        holders: [
          {
            address: accounts[4].address,
            amount: 999,
          },
          {
            address: accounts[5].address,
            amount: 666,
          },
        ],
      },
      {
        name: "Token[5]",
        symbol: "TKN[5]",
        holders: [
          {
            address: accounts[6].address,
            amount: 300,
          },
          {
            address: accounts[7].address,
            amount: 200,
          },
        ],
      },
      {
        name: "Token[6]",
        symbol: "TKN[6]",
        holders: [
          {
            address: accounts[8].address,
            amount: 300,
          },
        ],
      },
    ];

    let tokensList = [];
    for (tokenConfig of tokensConfig) {
      const newToken = await createNewToken(
        tokenConfig.name,
        tokenConfig.symbol,
        tokenConfig.holders
      );
      tokensList.push(newToken);
    }

    const createNewAggregator = async (
      aggregatorName,
      aggregatorSymbol,
      subEntitiesType,
      subEntities,
      aggregatorId
    ) => {
      const subEntitiesWeigths = subEntities.map((entity) => entity.weigth);
      let subEntitiesIds =
        subEntitiesType == 1
          ? subEntities.map((entity) =>
              BN(tokensList[entity.id - 1].address).toString()
            )
          : subEntities.map((entity) => entity.id);

      const newAggregator = await HybridHiveCore.createAggregator(
        aggregatorName, // _aggregatorName
        aggregatorSymbol, // _aggregatorSymbol
        "", // _aggregatorURI
        AggregatorOperator.address, // _aggregatorOperator
        0, // _parentAggregator
        subEntitiesType,
        subEntitiesIds, // _aggregatedEntities
        subEntitiesWeigths // _aggregatedEntitiesWeights
      );
      if (subEntitiesType == 1) {
        for (subEntity of subEntities) {
          const tokenAddress = tokensList[subEntity.id - 1].address;
          await HybridHiveCore.addTokenDetails(
            tokenAddress,
            "",
            TokenOperator.address,
            aggregatorId
          );

          await tokensList[subEntity.id - 1].transferOwnership(
            HybridHiveCore.address
          );
          await TokenOperator.approveTokenConnection(
            tokenAddress,
            aggregatorId
          );
          // update aggregator by connecting sub entities
        }
      } else if (subEntitiesType == 2) {
        for (subEntity of subEntities) {
          await AggregatorOperator.addAggregatorDetails(
            subEntity.id,
            "",
            AggregatorOperator.address,
            aggregatorId
          );
        }
      }

      return newAggregator;
    };

    // @todo move to separate file
    const aggregatorsConfig = [
      {
        name: "Aggregator[1]",
        symbol: "AG[1]",
        subEntitiesType: 1,
        subEntities: [
          {
            id: 1,
            weigth: DECIMALS.mul(2).div(3),
          },
          {
            id: 2,
            weigth: DECIMALS.div(3),
          },
        ],
      },
      {
        name: "Aggregator[2]",
        symbol: "AG[2]",
        subEntitiesType: 1,
        subEntities: [
          {
            id: 3,
            weigth: DECIMALS,
          },
        ],
      },
      {
        name: "Aggregator[3]",
        symbol: "AG[3]",
        subEntitiesType: 1,
        subEntities: [
          {
            id: 4,
            weigth: DECIMALS.div(2),
          },
          {
            id: 5,
            weigth: DECIMALS.div(2),
          },
        ],
      },
      {
        name: "Aggregator[4]",
        symbol: "AG[4]",
        subEntitiesType: 1,
        subEntities: [
          {
            id: 6,
            weigth: DECIMALS,
          },
        ],
      },
      {
        name: "Aggregator[5]",
        symbol: "AG[5]",
        subEntitiesType: 2,
        subEntities: [
          {
            id: 1,
            weigth: DECIMALS.div(2),
          },
          {
            id: 2,
            weigth: DECIMALS.div(2),
          },
        ],
      },
      {
        name: "Aggregator[6]",
        symbol: "AG[6]",
        subEntitiesType: 2,
        subEntities: [
          {
            id: 3,
            weigth: DECIMALS.mul(3).div(4),
          },
          {
            id: 4,
            weigth: DECIMALS.div(4),
          },
        ],
      },
      {
        name: "Aggregator[7]",
        symbol: "AG[7]",
        subEntitiesType: 2,
        subEntities: [
          {
            id: 5,
            weigth: DECIMALS.mul(3).div(5),
          },
          {
            id: 6,
            weigth: DECIMALS.mul(2).div(5),
          },
        ],
      },
    ];

    let aggregatorsCount = 0;
    for (aggregatorConfig of aggregatorsConfig) {
      const newAggregator = await createNewAggregator(
        aggregatorConfig.name,
        aggregatorConfig.symbol,
        aggregatorConfig.subEntitiesType,
        aggregatorConfig.subEntities,
        ++aggregatorsCount
      );
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

    return { HybridHiveCore, tokensList, owner, accounts };
  }

  describe("HibridHive Getters", function () {
    it("Should get user token balance correctly", async function () {
      const { HybridHiveCore, tokensList, owner, accounts } = await loadFixture(
        setupInitState
      );

      expect(await tokensList[0].balanceOf(owner.address)).to.equal(1500);
    });

    it("Should properly calculate global token share", async function () {
      const { HybridHiveCore, tokensList, owner, accounts } = await loadFixture(
        setupInitState
      );
      console.log(tokensList[0].address);
      let result = await HybridHiveCore[
        "getGlobalValueShare(uint256,address,uint256)"
      ](7, tokensList[0].address, 1500);

      expect(toPercentageString(result)).to.equal("0.15");

      result = await HybridHiveCore[
        "getGlobalValueShare(uint256,uint8,uint256,uint256)"
      ](7, 2, 1, DECIMALS.div(10));

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
      const { HybridHiveCore, tokensList, owner, accounts } = await loadFixture(
        setupInitState
      );

      expect(
        await HybridHiveCore[
          "getAbsoluteAmountFromShare(uint256,address,uint256)"
        ](7, tokensList[0].address, DECIMALS.div(10))
      ).to.equal("1000");

      expect(
        await HybridHiveCore[
          "getAbsoluteAmountFromShare(uint256,address,uint256)"
        ](7, tokensList[1].address, DECIMALS.mul(3).div(100))
      ).to.equal("600");

      expect(
        await HybridHiveCore[
          "getAbsoluteAmountFromShare(uint256,address,uint256)"
        ](7, tokensList[2].address, DECIMALS.mul(3).div(100))
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
