const fs = require("fs");

// Function to read a JSON file and return its content
function readJsonFile(filePath) {
  try {
    const fileContent = fs.readFileSync(filePath, "utf-8");
    return JSON.parse(fileContent);
  } catch (error) {
    console.error(`Error reading JSON file ${filePath}: ${error.message}`);
    return {};
  }
}

// Function to create the collection_rewards object from JSON files
function createCollectionRewards() {
  const collection_rewards = {};

  // Define the paths to the JSON files for each collection
  const collectionPaths = {
    "0x8f2836874DC85B81C2CF0421aF593E6E8d5DffA1": "./data/rank.json",
    "0xDdEAaE0e4A009411e32A46645AE4787550fDc804": "./data/hunterz.json",
  };

  // Loop through each collection and read its JSON file
  for (const [collectionAddress, jsonFilePath] of Object.entries(
    collectionPaths
  )) {
    const collectionData = readJsonFile(jsonFilePath);

    if (Object.keys(collectionData).length > 0) {
      collection_rewards[collectionAddress] = {};

      for (const nftId in collectionData) {
        const rank = collectionData[nftId].rank;
        const reward = calculateReward(collectionAddress, rank);
        collection_rewards[collectionAddress][nftId] = reward;
      }
    } else {
      console.log("Something went wrong");
    }
  }
  return collection_rewards;
}

// Function to calculate reward based on collection and rank
function calculateReward(collectionAddress, rank) {
  // Define reward ratios for each collection
  const rewardRatios = {
    "0x8f2836874DC85B81C2CF0421aF593E6E8d5DffA1": {
      10000: 10,
      8000: 15,
      6000: 20,
      4000: 25,
      3000: 30,
      2000: 35,
      1000: 40,
      500: 45,
      100: 50,
      60: 80,
    },
    "0xDdEAaE0e4A009411e32A46645AE4787550fDc804": {
      3000: 10,
      2199: 15,
      1499: 20,
      999: 25,
      499: 30,
      149: 40,
      30: 50,
    },
  };

  // Get the reward ratio for the given collection
  const collectionRewardRatio = rewardRatios[collectionAddress];

  // Find the appropriate reward based on rank
  let reward = 0;
  for (const thresholdRank in collectionRewardRatio) {
    if (rank <= thresholdRank) {
      reward = collectionRewardRatio[thresholdRank];
      break;
    }
  }

  return reward;
}

module.exports = { readJsonFile, createCollectionRewards };

// Create the collection_rewards object from JSON files
// const collection_rewards = createCollectionRewards();

// for (const collectorAddress in collection_rewards) {
//   const rewards = collection_rewards[collectorAddress];
//   const tokenIds = Object.keys(rewards);
//   const rewardAmounts = tokenIds.map((tokenId) => rewards[tokenId]);

//   for (let i = 0; i < tokenIds.length; i++) {
//     await stakingContract.setRewards(
//       [collectorAddress],
//       [tokenIds[i]],
//       [rewardAmounts[i]]
//     );
//   }
// }
