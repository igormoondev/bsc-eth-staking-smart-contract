// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TOKEN_Staking is Ownable {
    using SafeMath for uint256;

    address public constant TOKEN = ""; //token to stake

    //STAKING PARAMETERS
    uint256 public constant stakingPeriod = 30 days; //period over which tokens are locked after staking
    uint256 public stakingEnd; //point after which staking rewards cease to accumulate
    uint256 public rewardRate = 14; //14% linear return per staking period
    uint256 public totalStaked; //sum of all user stakes
    uint256 public maxTotalStaked = 58e23; //5.8 million tokens
    uint256 public minStaked = 1e21; //1000 tokens. min staked per user

    //STAKING MAPPINGS
    mapping(address => uint256) public stakedTokens; //amount of tokens that address has staked
    mapping(address => uint256) public lastStaked; //last time at which address staked, deposited, or "rolled over" their position by calling updateStake directly
    mapping(address => uint256) public totalEarnedTokens; //total tokens earned through staking by each user

    constructor() {
        stakingEnd = (block.timestamp + 180 days);
    }

    //STAKING FUNCTIONS
    function deposit(uint256 amountTokens) external {
        require(
            (stakedTokens[msg.sender] >= minStaked ||
                amountTokens >= minStaked),
            "deposit: must exceed minimum stake"
        );
        require(
            totalStaked + amountTokens <= maxTotalStaked,
            "deposit: amount would exceed max stake. call updateStake to claim dividends"
        );
        updateStake();
        IERC20(TOKEN).transferFrom(msg.sender, address(this), amountTokens);
        stakedTokens[msg.sender] += amountTokens;
        totalStaked += amountTokens;
    }

    function updateStake() public {
        uint256 stakedUntil = min(block.timestamp, stakingEnd);
        uint256 periodStaked = stakedUntil.sub(lastStaked[msg.sender]);
        uint256 dividends;
        //linear rewards up to stakingPeriod
        if (periodStaked < stakingPeriod) {
            dividends = periodStaked
                .mul(stakedTokens[msg.sender])
                .mul(rewardRate)
                .div(stakingPeriod)
                .div(100);
        } else {
            dividends = stakedTokens[msg.sender].mul(rewardRate).div(100);
        }
        //update lastStaked time for msg.sender -- user cannot unstake until end of another stakingPeriod
        lastStaked[msg.sender] = stakedUntil;
        //withdraw dividends for user if rolling over dividends would exceed staking cap, else stake the dividends automatically
        if (totalStaked + dividends > maxTotalStaked) {
            IERC20(TOKEN).transfer(msg.sender, dividends);
            totalEarnedTokens[msg.sender] += dividends;
        } else {
            stakedTokens[msg.sender] += dividends;
            totalStaked += dividends;
            totalEarnedTokens[msg.sender] += dividends;
        }
    }

    function withdrawDividends() external {
        uint256 stakedUntil = min(block.timestamp, stakingEnd);
        uint256 periodStaked = stakedUntil.sub(lastStaked[msg.sender]);
        uint256 dividends;
        //linear rewards up to stakingPeriod
        if (periodStaked < stakingPeriod) {
            dividends = periodStaked
                .mul(stakedTokens[msg.sender])
                .mul(rewardRate)
                .div(stakingPeriod)
                .div(100);
        } else {
            dividends = stakedTokens[msg.sender].mul(rewardRate).div(100);
        }
        //update lastStaked time for msg.sender -- user cannot unstake until end of another stakingPeriod
        lastStaked[msg.sender] = stakedUntil;
        //withdraw dividends for user
        IERC20(TOKEN).transfer(msg.sender, dividends);
        totalEarnedTokens[msg.sender] += dividends;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function unstake() external {
        uint256 timeSinceStake = (block.timestamp).sub(lastStaked[msg.sender]);
        require(
            timeSinceStake >= stakingPeriod || block.timestamp > stakingEnd,
            "unstake: staking period for user still ongoing"
        );
        updateStake();
        uint256 toTransfer = stakedTokens[msg.sender];
        stakedTokens[msg.sender] = 0;
        IERC20(TOKEN).transfer(msg.sender, toTransfer);
        totalStaked = totalStaked.sub(toTransfer);
    }

    function getPendingDivs(address user) external view returns (uint256) {
        uint256 stakedUntil = min(block.timestamp, stakingEnd);
        uint256 periodStaked = stakedUntil.sub(lastStaked[user]);
        uint256 dividends;
        //linear rewards up to stakingPeriod
        if (periodStaked < stakingPeriod) {
            dividends = periodStaked
                .mul(stakedTokens[user])
                .mul(rewardRate)
                .div(stakingPeriod)
                .div(100);
        } else {
            dividends = stakedTokens[user].mul(rewardRate).div(100);
        }
        return (dividends);
    }

    //OWNER ONLY FUNCTIONS
    function updateMinStake(uint256 newMinStake) external onlyOwner() {
        minStaked = newMinStake;
    }

    function updateStakingEnd(uint256 newStakingEnd) external onlyOwner() {
        require(
            newStakingEnd >= block.timestamp,
            "updateStakingEnd: newStakingEnd must be in future"
        );
        stakingEnd = newStakingEnd;
    }

    function updateRewardRate(uint256 newRewardRate) external onlyOwner() {
        require(newRewardRate <= 100, "what are you, crazy?");
        rewardRate = newRewardRate;
    }

    function updateMaxTotalStaked(uint256 newMaxTotalStaked)
        external
        onlyOwner()
    {
        maxTotalStaked = newMaxTotalStaked;
    }

    //allows owner to recover ERC20 tokens for users when they are mistakenly sent to contract
    function recoverTokens(
        address tokenAddress,
        address dest,
        uint256 amountTokens
    ) external onlyOwner() {
        require(
            tokenAddress != TOKEN,
            "recoverTokens: cannot move staked token"
        );
        IERC20(tokenAddress).transfer(dest, amountTokens);
    }

    //allows owner to reclaim any tokens not distributed during staking
    function recoverTOKEN() external onlyOwner() {
        require(
            block.timestamp >= (stakingEnd + 30 days),
            "recoverTOKEN: too early"
        );
        uint256 amountToSend = IERC20(TOKEN).balanceOf(address(this));
        IERC20(TOKEN).transfer(msg.sender, amountToSend);
    }
}
