require("@nomicfoundation/hardhat-toolbox");
require("@cronos-labs/hardhat-cronoscan");
// require("@nomiclabs/hardhat-etherscan");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
  defaultNetwork: "goerli",
  networks: {
    localGanache: {
      url: "HTTP://127.0.0.1:7545",
      accounts: [
        `0xe7a7ef0a89bc8a34f9edee7f695432749a01cfcc846e15078bc8f50637cff94f`,
      ],
    },
    sepolia: {
      url: "https://eth-sepolia.g.alchemy.com/v2/eq6bQsyP-i78-bOQQBfApcuVr7l1h-T6",
      accounts: [
        `0xf60f6718573e07f07c581e34922294749fd2f32ac9b45018af8414031a951856`,
      ],
    },
    tCore: {
      url: "https://rpc.test.btcs.network",
      accounts: [
        `0xf60f6718573e07f07c581e34922294749fd2f32ac9b45018af8414031a951856`,
      ],
      chainId: 1115,
    },
    cronos: {
      url: "https://evm-t3.cronos.org/",
      accounts: [
        "0xe7a7ef0a89bc8a34f9edee7f695432749a01cfcc846e15078bc8f50637cff94f",
      ],
      chainId: 338,
      gasPrice: 5000000000000,
    },
  },
  etherscan: {
    apiKey: "VNFI4XEZBXSTYZWANUM2BQ1MR4DQR9TXFX",
  },
  // etherscan: {
  //   apiKey: {
  //     cronosTestnet: "8J3Y23JRYHXV5A5D4QMT4AP2FVE72JN3NA",
  //   },
  // },
};

// 0x027E7D412479504f7CF71ac12719374A367185f5- contract for sepolia testnet (ERC20)
// 0xeB6a89A19523C869D1cE7CFf5627fb3908939656 - contract for sepolia testnet (NFT)
