// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTStaking is Ownable, IERC721Receiver, ERC721Holder {
    using SafeERC20 for IERC20;
    IERC20 immutable rewardToken;

    // uint256 constant DAY_IN_SECONDS = 86400; // 24 hours in seconds
    uint256 constant DAY_IN_SECONDS = 60 seconds;

    struct StakingInfo {
        uint256 dailyReward;
        uint256 accumulatedReward;
        uint256 lastClaimTime;
        bool isStaked;
        bool isHardStaked;
    }

    mapping(address => mapping(address => mapping(uint256 => StakingInfo)))
        public CrazzzyMonsters;

    struct RewardData {
        uint256 tokenId;
        uint256 rewardRatio;
    }

    mapping(address => RewardData[]) public collectionRewards;

    event SoftStake(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 reward
    );
    event HardStake(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 reward
    );
    event UnlockNFT(address indexed owner, uint256 indexed tokenId);
    event ClaimReward(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 reward
    );

    constructor(address _token) Ownable(msg.sender) {
        rewardToken = IERC20(_token);
    }

    function initializeRewards(
        address[] memory collectors,
        uint256[][] memory tokenIds,
        uint256[][] memory rewardRatios
    ) external onlyOwner {
        require(
            collectors.length == tokenIds.length &&
                tokenIds.length == rewardRatios.length,
            "Arrays length mismatch"
        );

        for (uint256 i = 0; i < collectors.length; i++) {
            address collector = collectors[i];

            for (uint256 j = 0; j < tokenIds[i].length; j++) {
                uint256 tokenId = tokenIds[i][j];
                uint256 rewardRatio = rewardRatios[i][j];

                collectionRewards[collector].push(
                    RewardData(tokenId, rewardRatio)
                );
            }
        }
    }

    function hardStakeNFT(address collection, uint256 tokenId) external {
        require(
            !_isStaked(collection, msg.sender, tokenId),
            "NFT is already staked"
        );
        // Ensure that the collector has initialized rewards
        require(
            collectionRewards[collection].length > 0,
            "No rewards initialized for the collection"
        );

        // Ensure that the provided tokenId is valid
        require(tokenId > 0, "Invalid tokenId");

        // Check if the provided tokenId is allowed for staking by the collection
        uint256 rewardRatio = getRewardRatio(collection, tokenId);
        require(
            rewardRatio > 0,
            "Token not allowed for staking by the collection"
        );

        CrazzzyMonsters[collection][msg.sender][tokenId].isHardStaked = true;
        uint256 reward = _calculateHardStakingReward(collection, tokenId);
        uint256 multiplier = _getMultiplier(collection, tokenId);
        _updateStakingInfo(collection, tokenId, reward, true);
        IERC721(collection).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            ""
        );
        emit HardStake(msg.sender, tokenId, reward * multiplier);
    }

    function softStakeNFT(address collection, uint256 tokenId) external {
        require(
            !_isStaked(collection, msg.sender, tokenId),
            "NFT is already staked"
        );
        // Ensure that the collector has initialized rewards
        require(
            collectionRewards[collection].length > 0,
            "No rewards initialized for the collection"
        );

        // Ensure that the provided tokenId is valid
        require(tokenId > 0, "Invalid tokenId");

        // Check if the provided tokenId is allowed for staking by the collection
        uint256 rewardRatio = getRewardRatio(collection, tokenId);
        require(
            rewardRatio > 0,
            "Token not allowed for staking by the collection"
        );

        uint256 reward = _calculateSoftStakingReward(collection, tokenId);
        uint256 multiplier = _getMultiplier(collection, tokenId);
        _updateStakingInfo(collection, tokenId, reward, true);
        emit SoftStake(msg.sender, tokenId, reward * multiplier);
    }

    function claimReward(address collection, uint256 _tokenId) external {
        StakingInfo storage stakingInfo = CrazzzyMonsters[collection][
            msg.sender
        ][_tokenId];
        require(
            _isStaked(collection, msg.sender, _tokenId),
            "NFT is not staked"
        );
        uint256 interval = block.timestamp - stakingInfo.lastClaimTime;
        require(interval >= 30 seconds, "last claimed time less than 24 hours");
        uint256 reward = _calculateAccumulatedReward(collection, _tokenId);
        stakingInfo.lastClaimTime = block.timestamp;
        stakingInfo.accumulatedReward = 0; // Set accumulated reward to 0 after claiming
        stakingInfo.dailyReward = reward;
        rewardToken.safeTransfer(msg.sender, reward);
        emit ClaimReward(msg.sender, _tokenId, reward);
    }

    function unstakeNFT(address collection, uint256 _tokenId) external {
        require(
            _isStaked(collection, msg.sender, _tokenId),
            "NFT is not staked"
        );
        if (CrazzzyMonsters[collection][msg.sender][_tokenId].isHardStaked) {
            IERC721(collection).safeTransferFrom(
                address(this),
                msg.sender,
                _tokenId,
                ""
            );
        }
        CrazzzyMonsters[collection][msg.sender][_tokenId].isStaked = false;
        emit UnlockNFT(msg.sender, _tokenId);
    }

    function _isStaked(
        address collection,
        address _owner,
        uint256 _tokenId
    ) internal view returns (bool) {
        return CrazzzyMonsters[collection][_owner][_tokenId].isStaked;
    }

    function _calculateAccumulatedReward(
        address collection,
        uint256 _tokenId
    ) internal view returns (uint256) {
        StakingInfo storage stakingInfo = CrazzzyMonsters[collection][
            msg.sender
        ][_tokenId];
        uint256 elapsedTime = block.timestamp - stakingInfo.lastClaimTime;
        uint256 dailyReward = (stakingInfo.dailyReward * elapsedTime) /
            DAY_IN_SECONDS;
        uint256 accumulatedReward = stakingInfo.accumulatedReward + dailyReward;
        return accumulatedReward;
    }

    function _calculateHardStakingReward(
        address _collection,
        uint256 _tokenId
    ) internal view returns (uint256) {
        // require(_rank >= 1 && _rank <= 10000, "Invalid rank");
        return getRewardRatio(_collection, _tokenId) * 3;
    }

    function _calculateSoftStakingReward(
        address _collection,
        uint256 _tokenId
    ) internal view returns (uint256) {
        // require(_rank >= 1 && _rank <= 10000, "Invalid rank");
        return getRewardRatio(_collection, _tokenId);
    }

    function getRewardRatio(
        address _collection,
        uint256 tokenId
    ) public view returns (uint256) {
        for (uint256 i = 0; i < collectionRewards[_collection].length; i++) {
            if (collectionRewards[_collection][i].tokenId == tokenId) {
                return collectionRewards[_collection][i].rewardRatio;
            }
        }
        return 0;
    }

    function _getMultiplier(
        address collection,
        uint256 _tokenId
    ) public view returns (uint256) {
        if (CrazzzyMonsters[collection][msg.sender][_tokenId].isHardStaked) {
            return 3;
        } else {
            return 1;
        }
    }

    function _updateStakingInfo(
        address collection,
        uint256 _tokenId,
        uint256 _reward,
        bool _hardStaked
    ) internal {
        CrazzzyMonsters[collection][msg.sender][_tokenId] = StakingInfo({
            dailyReward: _reward,
            accumulatedReward: _reward,
            lastClaimTime: block.timestamp,
            isStaked: true,
            isHardStaked: _hardStaked
        });
    }
}
