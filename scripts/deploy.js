// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const FN = ethers.FixedNumber;
const BN = ethers.BigNumber.from;
const DECIMALS = BN("10").pow("18"); // @todo move to constants

async function setupInitState() {
  const [deployer] = await ethers.getSigners();
  const accountsList = [
    "0x0Ba4E7bfb5cDc3c1a06E0722bC8286B7B7D39d5d",
    "0x00000000219ab540356cBB839Cbe05303d7705Fa",
    "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
    "0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8",
    "0xDA9dfA130Df4dE4673b89022EE50ff26f6EA73Cf",
    "0x0716a17FBAeE714f1E6aB0f9d59edbC5f09815C0",

    "0xF977814e90dA44bFA03b6295A0616a897441aceC",
    "0x8315177aB297bA92A06054cE80a67Ed4DBd7ed3a",
    "0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503",
    "0xE92d1A43df510F82C66382592a047d288f85226f",
  ];

  const accounts = accountsList.map((address) => ({ address }));
  console.log("Deploying contracts with the account:", deployer.address);

  // Contracts are deployed using the first signer/account by default

  const HybridHiveCoreFactory = await ethers.getContractFactory(
    "HybridHiveCore"
  );
  const HybridHiveCore = await HybridHiveCoreFactory.deploy();
  console.log("HybridHive Core Address", HybridHiveCore.address);

  const AggregatorOperatorFactory = await ethers.getContractFactory(
    "AggregatorOperatorMock"
  );
  const AggregatorOperator = await AggregatorOperatorFactory.deploy();
  console.log("Aggregator Operator Address", AggregatorOperator.address);

  const TokenOperatorFactory = await ethers.getContractFactory(
    "TokenOperatorMock"
  );
  const TokenOperator = await TokenOperatorFactory.attach(
    "0xBb4DA5a8E64Af87167d2A552a79E1619eF08969D"
  ); //deploy();

  let txWaitBuffer = await AggregatorOperator.setCoreAddress(
    HybridHiveCore.address
  );
  await txWaitBuffer.wait();

  txWaitBuffer = await TokenOperator.setCoreAddress(HybridHiveCore.address);
  await txWaitBuffer.wait();

  console.log("Token Operator Address", TokenOperator.address);
  // @todo replace with generator

  // create Token[1]
  txWaitBuffer = await HybridHiveCore.createToken(
    "Goblin Gold Token", // _tokenName
    "GGT", // _tokenSymbol
    "", // _tokenURI
    TokenOperator.address, // _tokenOperator
    0, // _parentAggregator
    [deployer.address, accounts[0].address], // _tokenHolders
    [1500, 500] // _holderBalances
  );
  await txWaitBuffer.wait();

  // create Token[2]
  txWaitBuffer = await HybridHiveCore.createToken(
    "Elvish Silver Token", // _tokenName
    "EST", // _tokenSymbol
    "", // _tokenURI
    TokenOperator.address, // _tokenOperator
    0, // _parentAggregator
    [accounts[1].address, accounts[2].address], // _tokenHolders
    [1400, 600] // _holderBalances
  );
  await txWaitBuffer.wait();

  // create Token[3]
  txWaitBuffer = await HybridHiveCore.createToken(
    "Human Bronze Token", // _tokenName
    "HBT", // _tokenSymbol
    "", // _tokenURI
    TokenOperator.address, // _tokenOperator
    0, // _parentAggregator
    [accounts[3].address], // _tokenHolders
    [500] // _holderBalances
  );
  await txWaitBuffer.wait();
  console.log("execution point 1");

  // create Token[4]
  txWaitBuffer = await HybridHiveCore.createToken(
    "Dragon Copper Token", // _tokenName
    "DCT", // _tokenSymbol
    "", // _tokenURI
    TokenOperator.address, // _tokenOperator
    0, // _parentAggregator
    [accounts[4].address, accounts[5].address], // _tokenHolders
    [999, 666] // _holderBalances
  );
  await txWaitBuffer.wait();

  // create Token[5]
  txWaitBuffer = await HybridHiveCore.createToken(
    "Troll Platinum Token", // _tokenName
    "TPT", // _tokenSymbol
    "", // _tokenURI
    TokenOperator.address, // _tokenOperator
    0, // _parentAggregator
    [accounts[6].address, accounts[7].address, accounts[0].address], // _tokenHolders
    [300, 200, 500] // _holderBalances
  );
  await txWaitBuffer.wait();

  // create Token[6]
  txWaitBuffer = await HybridHiveCore.createToken(
    "Dwarven Diamond Token", // _tokenName
    "DDT", // _tokenSymbol
    "", // _tokenURI
    TokenOperator.address, // _tokenOperator
    0, // _parentAggregator
    [accounts[8].address, deployer.address], // _tokenHolders
    [150, 150] // _holderBalances
  );
  await txWaitBuffer.wait();

  // create Ag[1]
  txWaitBuffer = await HybridHiveCore.createAggregator(
    "Goblin & Elvish Treasury", // _aggregatorName
    "GEKT", // _aggregatorSymbol
    "", // _aggregatorURI
    AggregatorOperator.address, // _aggregatorOperator
    0, // _parentAggregator
    1, // _aggregatedEntityType 1 - token, 2 aggregator
    [1, 2], // _aggregatedEntities
    [DECIMALS.mul(2).div(3), DECIMALS.div(3)] // _aggregatedEntitiesWeights
  );
  await txWaitBuffer.wait();

  // connect tokens to the aggregator

  txWaitBuffer = await TokenOperator.updateParentAggregator(1, 1);
  await txWaitBuffer.wait();
  txWaitBuffer = await TokenOperator.updateParentAggregator(2, 1);
  await txWaitBuffer.wait();

  // @todo attach token to upper aggregator

  // create Ag[2]
  txWaitBuffer = await HybridHiveCore.createAggregator(
    "Human Treasury", // _aggregatorName
    "HT", // _aggregatorSymbol
    "", // _aggregatorURI
    AggregatorOperator.address, // _aggregatorOperator
    0, // _parentAggregator
    1,
    [3], // _aggregatedEntities
    [DECIMALS] // _aggregatedEntitiesWeights
  );
  await txWaitBuffer.wait();

  txWaitBuffer = await TokenOperator.updateParentAggregator(3, 2);
  await txWaitBuffer.wait();
  console.log("execution point 3");

  // create Ag[3]
  txWaitBuffer = await HybridHiveCore.createAggregator(
    "Dragon & Troll Treasury", // _aggregatorName
    "DTT", // _aggregatorSymbol
    "", // _aggregatorURI
    AggregatorOperator.address, // _aggregatorOperator
    0, // _parentAggregator
    1,
    [4, 5], // _aggregatedEntities
    [DECIMALS.div(2), DECIMALS.div(2)] // _aggregatedEntitiesWeights
  );
  await txWaitBuffer.wait();

  txWaitBuffer = await TokenOperator.updateParentAggregator(4, 3);
  await txWaitBuffer.wait();
  txWaitBuffer = await TokenOperator.updateParentAggregator(5, 3);
  await txWaitBuffer.wait();

  // create Ag[4]
  txWaitBuffer = await HybridHiveCore.createAggregator(
    "Dwarven Treasury", // _aggregatorName
    "DT", // _aggregatorSymbol
    "", // _aggregatorURI
    AggregatorOperator.address, // _aggregatorOperator
    0, // _parentAggregator
    1,
    [6], // _aggregatedEntities
    [DECIMALS] // _aggregatedEntitiesWeights
  );
  await txWaitBuffer.wait();

  txWaitBuffer = await TokenOperator.updateParentAggregator(6, 4);
  await txWaitBuffer.wait();
  console.log("execution point 4");

  // create Ag[5]
  txWaitBuffer = await HybridHiveCore.createAggregator(
    "Bright Kingdom", // _aggregatorName
    "BK", // _aggregatorSymbol
    "", // _aggregatorURI
    AggregatorOperator.address, // _aggregatorOperator
    0, // _parentAggregator
    2,
    [1, 2], // _aggregatedEntities
    [DECIMALS.div(2), DECIMALS.div(2)] // _aggregatedEntitiesWeights
  );
  await txWaitBuffer.wait();

  txWaitBuffer = await AggregatorOperator.updateParentAggregator(1, 5);
  await txWaitBuffer.wait();
  txWaitBuffer = await AggregatorOperator.updateParentAggregator(2, 5);
  await txWaitBuffer.wait();

  // create Ag[6]
  txWaitBuffer = await HybridHiveCore.createAggregator(
    "Dark Kingdom", // _aggregatorName
    "DK", // _aggregatorSymbol
    "", // _aggregatorURI
    AggregatorOperator.address, // _aggregatorOperator
    0, // _parentAggregator
    2,
    [3, 4], // _aggregatedEntities
    [DECIMALS.mul(3).div(4), DECIMALS.div(4)] // _aggregatedEntitiesWeights
  );
  await txWaitBuffer.wait();

  txWaitBuffer = await AggregatorOperator.updateParentAggregator(3, 6);
  await txWaitBuffer.wait();
  txWaitBuffer = await AggregatorOperator.updateParentAggregator(4, 6);
  await txWaitBuffer.wait();

  // create Ag[7]
  txWaitBuffer = await HybridHiveCore.createAggregator(
    "Magic World", // _aggregatorName
    "MW", // _aggregatorSymbol
    "", // _aggregatorURI
    AggregatorOperator.address, // _aggregatorOperator
    0, // _parentAggregator
    2,
    [5, 6], // _aggregatedEntities
    [DECIMALS.mul(3).div(5), DECIMALS.mul(2).div(5)] // _aggregatedEntitiesWeights
  );
  await txWaitBuffer.wait();

  txWaitBuffer = await AggregatorOperator.updateParentAggregator(5, 7);
  await txWaitBuffer.wait();
  txWaitBuffer = await AggregatorOperator.updateParentAggregator(6, 7);
  await txWaitBuffer.wait();

  console.log("execution point 5");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
setupInitState().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
