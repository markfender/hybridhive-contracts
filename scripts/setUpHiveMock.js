// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function setupInitState() {
  const [deployer] = await ethers.getSigners();
  const accounts = [
    "0x0Ba4E7bfb5cDc3c1a06E0722bC8286B7B7D39d5d",
    "0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8",
    "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045",
    "0xDA9dfA130Df4dE4673b89022EE50ff26f6EA73Cf",
    "0x0716a17FBAeE714f1E6aB0f9d59edbC5f09815C0",

    "0xF977814e90dA44bFA03b6295A0616a897441aceC",
    "0x8315177aB297bA92A06054cE80a67Ed4DBd7ed3a",
    "0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503",
    "0xE92d1A43df510F82C66382592a047d288f85226f",
  ];
  console.log("Deploying contracts with the account:", deployer.address);

  // Contracts are deployed using the first signer/account by default

  const HybridHiveCoreFactory = await ethers.getContractFactory(
    "HybridHiveCore"
  );
  const HybridHiveCore = await HybridHiveCoreFactory.attach(
    "0x48970e9366E603eF443B07180075237aC4426ac4"
  );
  console.log("HybridHive Core Address", HybridHiveCore.address);

  const AggregatorOperatorFactory = await ethers.getContractFactory(
    "AggregatorOperatorMock"
  );
  const AggregatorOperator = await AggregatorOperatorFactory.attach(
    "0x27135087F16Ca2015573cB1A9Debd0F17e728Ae1"
  );
  console.log("Aggregator Operator Address", AggregatorOperator.address);

  const TokenOperatorFactory = await ethers.getContractFactory(
    "TokenOperatorMock"
  );
  const TokenOperator = await TokenOperatorFactory.attach(
    "0x813465223045bE053904f1c1E10BBCf7d3348894"
  );

  console.log("Token Operator Address", TokenOperator.address);
  // @todo replace with generator
  let txWaitBuffer;
  {
    // create Token[1]
    txWaitBuffer = await HybridHiveCore.createToken(
      "Token[1]", // _tokenName
      "TKN[1]", // _tokenSymbol
      "", // _tokenURI
      TokenOperator.address, // _tokenOperator
      0, // _parentAggregator
      [deployer.address, accounts[0]], // _tokenHolders
      [1500, 500] // _holderBalances
    );
    txWaitBuffer.wait();
    console.log("token 1 created");
    // create Token[2]
    txWaitBuffer = await HybridHiveCore.createToken(
      "Token[2]", // _tokenName
      "TKN[2]", // _tokenSymbol
      "", // _tokenURI
      TokenOperator.address, // _tokenOperator
      0, // _parentAggregator
      [accounts[1], accounts[2]], // _tokenHolders
      [1400, 600] // _holderBalances
    );
    await txWaitBuffer.wait();
    console.log("token 2 created");
    // create Token[3]
    txWaitBuffer = await HybridHiveCore.createToken(
      "Token[3]", // _tokenName
      "TKN[3]", // _tokenSymbol
      "", // _tokenURI
      TokenOperator.address, // _tokenOperator
      0, // _parentAggregator
      [accounts[3]], // _tokenHolders
      [500] // _holderBalances
    );
    await txWaitBuffer.wait();
    console.log("token 3 created");
    // create Token[4]
    txWaitBuffer = await HybridHiveCore.createToken(
      "Token[4]", // _tokenName
      "TKN[4]", // _tokenSymbol
      "", // _tokenURI
      TokenOperator.address, // _tokenOperator
      0, // _parentAggregator
      [accounts[4], accounts[5]], // _tokenHolders
      [999, 666] // _holderBalances
    );
    await txWaitBuffer.wait();
    console.log("token 4 created");

    // create Token[5]
    txWaitBuffer = await HybridHiveCore.createToken(
      "Token[5]", // _tokenName
      "TKN[5]", // _tokenSymbol
      "", // _tokenURI
      TokenOperator.address, // _tokenOperator
      0, // _parentAggregator
      [accounts[6], accounts[7]], // _tokenHolders
      [300, 200] // _holderBalances
    );
    await txWaitBuffer.wait();
    console.log("token 5 created");

    // create Token[6]
    txWaitBuffer = await HybridHiveCore.createToken(
      "Token[6]", // _tokenName
      "TKN[6]", // _tokenSymbol
      "", // _tokenURI
      TokenOperator.address, // _tokenOperator
      0, // _parentAggregator
      [accounts[8]], // _tokenHolders
      [300] // _holderBalances
    );
    await txWaitBuffer.wait();
    console.log("token 6 created");
  }

  {
    // create Ag[1]
    txWaitBuffer = await HybridHiveCore.createAggregator(
      "Ag[1]", // _aggregatorName
      "AG[1]", // _aggregatorSymbol
      "", // _aggregatorURI
      AggregatorOperator.address, // _aggregatorOperator
      0, // _parentAggregator
      1, // _aggregatedEntityType 1 - token, 2 aggregator
      [1, 2], // _aggregatedEntities
      [66666666, 33333334] // _aggregatedEntitiesWeights
    );
    await txWaitBuffer.wait();
    console.log("aggregator 1 created");
    // connect tokens to the aggregator
    txWaitBuffer = await TokenOperator.updateParentAggregator(1, 1);
    await txWaitBuffer.wait();
    txWaitBuffer = await TokenOperator.updateParentAggregator(2, 1);
    await txWaitBuffer.wait();

    // @todo attach token to upper aggregator

    // create Ag[2]
    txWaitBuffer = await HybridHiveCore.createAggregator(
      "Ag[2]", // _aggregatorName
      "AG[2]", // _aggregatorSymbol
      "", // _aggregatorURI
      AggregatorOperator.address, // _aggregatorOperator
      0, // _parentAggregator
      1,
      [3], // _aggregatedEntities
      [100000000] // _aggregatedEntitiesWeights
    );
    await txWaitBuffer.wait();
    console.log("aggregator 2 created");
    txWaitBuffer = await TokenOperator.updateParentAggregator(3, 2);
    await txWaitBuffer.wait();

    // create Ag[3]
    txWaitBuffer = await HybridHiveCore.createAggregator(
      "Ag[3]", // _aggregatorName
      "AG[3]", // _aggregatorSymbol
      "", // _aggregatorURI
      AggregatorOperator.address, // _aggregatorOperator
      0, // _parentAggregator
      1,
      [4, 5], // _aggregatedEntities
      [50000000, 50000000] // _aggregatedEntitiesWeights
    );
    await txWaitBuffer.wait();
    console.log("aggregator 3 created");

    txWaitBuffer = await TokenOperator.updateParentAggregator(4, 3);
    await txWaitBuffer.wait();
    txWaitBuffer = await TokenOperator.updateParentAggregator(5, 3);
    await txWaitBuffer.wait();

    // create Ag[4]
    txWaitBuffer = await HybridHiveCore.createAggregator(
      "Ag[4]", // _aggregatorName
      "AG[4]", // _aggregatorSymbol
      "", // _aggregatorURI
      AggregatorOperator.address, // _aggregatorOperator
      0, // _parentAggregator
      1,
      [6], // _aggregatedEntities
      [100000000] // _aggregatedEntitiesWeights
    );
    await txWaitBuffer.wait();
    console.log("aggregator 4 created");

    txWaitBuffer = await TokenOperator.updateParentAggregator(6, 4);
    await txWaitBuffer.wait();

    // create Ag[5]
    txWaitBuffer = await HybridHiveCore.createAggregator(
      "Ag[5]", // _aggregatorName
      "AG[5]", // _aggregatorSymbol
      "", // _aggregatorURI
      AggregatorOperator.address, // _aggregatorOperator
      0, // _parentAggregator
      2,
      [1, 2], // _aggregatedEntities
      [50000000, 50000000] // _aggregatedEntitiesWeights
    );
    await txWaitBuffer.wait();
    console.log("aggregator 5 created");

    txWaitBuffer = await AggregatorOperator.updateParentAggregator(1, 5);
    await txWaitBuffer.wait();
    txWaitBuffer = await AggregatorOperator.updateParentAggregator(2, 5);
    await txWaitBuffer.wait();

    // create Ag[6]
    txWaitBuffer = await HybridHiveCore.createAggregator(
      "Ag[6]", // _aggregatorName
      "AG[6]", // _aggregatorSymbol
      "", // _aggregatorURI
      AggregatorOperator.address, // _aggregatorOperator
      0, // _parentAggregator
      2,
      [3, 4], // _aggregatedEntities
      [75000000, 25000000] // _aggregatedEntitiesWeights
    );
    await txWaitBuffer.wait();
    console.log("aggregator 6 created");
    txWaitBuffer = await AggregatorOperator.updateParentAggregator(3, 6);
    await txWaitBuffer.wait();
    txWaitBuffer = await AggregatorOperator.updateParentAggregator(4, 6);
    await txWaitBuffer.wait();

    // create Ag[7]
    txWaitBuffer = await HybridHiveCore.createAggregator(
      "Ag[7]", // _aggregatorName
      "AG[7]", // _aggregatorSymbol
      "", // _aggregatorURI
      AggregatorOperator.address, // _aggregatorOperator
      0, // _parentAggregator
      2,
      [5, 6], // _aggregatedEntities
      [60000000, 40000000] // _aggregatedEntitiesWeights
    );
    await txWaitBuffer.wait();
    console.log("aggregator 7 created");
    txWaitBuffer = await AggregatorOperator.updateParentAggregator(5, 7);
    await txWaitBuffer.wait();
    txWaitBuffer = await AggregatorOperator.updateParentAggregator(6, 7);
    await txWaitBuffer.wait();
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
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
setupInitState().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
