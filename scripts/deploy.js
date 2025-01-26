const hre = require("hardhat");
const { createCollectionRewards } = require("./utils.js");

async function main() {
  const StakingContract = await hre.ethers.getContractFactory("NFTStaking");

  // const ERC721Contract = await hre.ethers.getContractFactory(
  //   "CrazzzyMonsterERC721Contract"
  // );
  // const erc721Contract = await ERC721Contract.deploy();

  // await erc721Contract.waitForDeployment();

  const ERC20Contract = await hre.ethers.getContractFactory(
    "CrazzyMonsterERC20Token"
  );
  const erc20Contract = await ERC20Contract.deploy();

  await erc20Contract.waitForDeployment();

  const stakingContract = await StakingContract.deploy(erc20Contract.target);

  await stakingContract.waitForDeployment();

  console.log(
    ` ERC20 ${erc20Contract.target} staking contract ${stakingContract.target}`
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
