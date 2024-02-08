// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {ISoulmate} from "./interface/ISoulmate.sol";
import {ILoveToken} from "./interface/ILoveToken.sol";
import {IVault} from "./interface/IVault.sol";

/// @title Airdrop Contract for LoveToken.
/// @author n0kto
contract Airdrop {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error Airdrop__CoupleIsDivorced();
    error Airdrop__PreviousTokenAlreadyClaimed();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 public constant daysInSecond = 3600 * 24; // e correct = 86400 seconds

    ILoveToken public immutable loveToken;
    ISoulmate public immutable soulmateContract;
    IVault public immutable airdropVault;

    // e how many tokens have been claimed by this couple:
    mapping(address owner => uint256 alreadyClaimed) private _claimedBy;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event TokenClaimed(address indexed user, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(ILoveToken _loveToken, ISoulmate _soulmateContract, IVault _airdropVault) {
        loveToken = _loveToken;
        soulmateContract = _soulmateContract;
        airdropVault = _airdropVault;
    }

    // Both partners of a couple can claim their token every day.
    // Financiary dependency is important in a couple.

    /// @notice Claim tokens. Every person who has a Soulmate NFT token can claim 1 LoveToken per day.
    function claim() public {
        // No LoveToken for people who don't love their soulmates anymore.
        if (soulmateContract.isDivorced()) revert Airdrop__CoupleIsDivorced();

        // Calculating since how long soulmates are reunited
        uint256 numberOfDaysInCouple = (
            block.timestamp - soulmateContract.idToCreationTimestamp(soulmateContract.ownerToId(msg.sender))
        ) / daysInSecond;
        // q is this calculation correct? what if this is 0.8?

        uint256 amountAlreadyClaimed = _claimedBy[msg.sender];

        if (amountAlreadyClaimed >= numberOfDaysInCouple * 10 ** loveToken.decimals()) {
            revert Airdrop__PreviousTokenAlreadyClaimed();
        }

        uint256 tokenAmountToDistribute = (numberOfDaysInCouple * 10 ** loveToken.decimals()) - amountAlreadyClaimed;

        // Dust collector
        // @audit it seems that when the loveToken amount to distribute is bigger than the balance of the airdrop vault, we'll change tokenAmountToDistribute and set
        // it to the balance of the airdrop vault.
        if (tokenAmountToDistribute >= loveToken.balanceOf(address(airdropVault))) {
            tokenAmountToDistribute = loveToken.balanceOf(address(airdropVault));
        }
        _claimedBy[msg.sender] += tokenAmountToDistribute;

        emit TokenClaimed(msg.sender, tokenAmountToDistribute);

        loveToken.transferFrom(address(airdropVault), msg.sender, tokenAmountToDistribute);
    }
}
