// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {BaseTest} from "./BaseTest.t.sol";
import {console2} from "forge-std/Test.sol";

contract StakingTest is BaseTest {
    function test_WellInitialized() public {
        assertTrue(loveToken.allowance(address(stakingVault), address(stakingContract)) == 500_000_000 ether);
    }

    function test_Deposit() public {
        uint256 balance = 100 ether;
        _giveLoveTokenToSoulmates(balance); // this is hardcoded to benefit both soulmates
        vm.startPrank(soulmate1);
        loveToken.approve(address(stakingContract), balance);
        stakingContract.deposit(balance);
        vm.stopPrank();

        assertTrue(stakingContract.userStakes(soulmate1) == balance);

        vm.startPrank(soulmate2);
        loveToken.approve(address(stakingContract), balance);
        stakingContract.deposit(balance);
        vm.stopPrank();

        assertTrue(stakingContract.userStakes(soulmate2) == balance);

        assertTrue(loveToken.balanceOf(address(stakingContract)) == balance * 2);
    }

    function test_Withdraw() public {
        uint256 balancePerSoulmates = 200 ether;
        _depositTokenToStake(balancePerSoulmates); // both have the same balance of 200
        assertTrue(loveToken.balanceOf(address(stakingContract)) == 400 ether);
        console2.log(loveToken.balanceOf(address(stakingContract)));

        // Withdraw twice to get back all the tokens
        vm.prank(soulmate1);
        stakingContract.withdraw(balancePerSoulmates / 2);
        assertTrue(loveToken.balanceOf(address(stakingContract)) == balancePerSoulmates * 2 - (balancePerSoulmates / 2));
        assertTrue(loveToken.balanceOf(soulmate1) == balancePerSoulmates / 2);

        vm.prank(soulmate1);
        stakingContract.withdraw(balancePerSoulmates / 2);
        assertTrue(loveToken.balanceOf(address(stakingContract)) == balancePerSoulmates);
        assertTrue(loveToken.balanceOf(soulmate1) == balancePerSoulmates);
    }

    function test_ClaimRewards() public {
        uint256 balancePerSoulmates = 5 ether;
        uint256 weekOfStaking = 2;
        _depositTokenToStake(balancePerSoulmates); // now staking 5
        console2.log(loveToken.balanceOf(soulmate1)); // 0
        console2.log(stakingContract.userStakes(soulmate1)); // 5
        console2.log("Maarten");

        // next block deposits 0, as it should. there's no balance.
        vm.prank(soulmate1);
        loveToken.approve(address(stakingContract), loveToken.balanceOf(soulmate1));
        stakingContract.deposit(loveToken.balanceOf(soulmate1));
        console2.log(loveToken.balanceOf(soulmate1)); // 0
        console2.log(stakingContract.userStakes(soulmate1)); // 5

        // vm.prank(soulmate1);
        // vm.expectRevert();
        // stakingContract.claimRewards();

        vm.warp(block.timestamp + weekOfStaking * 1 weeks + 1 seconds);

        vm.prank(soulmate1);
        stakingContract.claimRewards(); // staking now still the deposited 5, balance = 10
        // the deposited 5 should be withdrawn
        assertTrue(loveToken.balanceOf(soulmate1) == weekOfStaking * balancePerSoulmates);
        // 10
        console2.log(loveToken.balanceOf(soulmate1)); // 10

        vm.prank(soulmate1);
        stakingContract.withdraw(balancePerSoulmates); // = 5
        console2.log(loveToken.balanceOf(soulmate1)); // 10 + 5 = 15
        assertTrue(loveToken.balanceOf(soulmate1) == weekOfStaking * balancePerSoulmates + balancePerSoulmates);
        console2.log("final staking balance: ", stakingContract.userStakes(soulmate1)); // 0

        // now let's claim the airdrop of the 2 weeks
        vm.prank(soulmate1);
        airdropContract.claim();
        console2.log("soulmate1's lovetoken balance: ", loveToken.balanceOf(soulmate1)); // 29

        vm.prank(soulmate2);
        airdropContract.claim();
        console2.log("soulmate2's lovetoken balance: ", loveToken.balanceOf(soulmate2)); // 14
        console2.log(stakingContract.userStakes(soulmate2)); // 5
    }

    function test_Withdrawbbb() public {
        uint256 balancePerSoulmate = 123 ether;
        _depositTokenToStake(balancePerSoulmate);
        // now we have 123 + 123 = 246 tokens in the contract
    }

    // so there's `userStakes` and `balanceOf` a change in the balance of `userStakes` should result in a counterchange in `balanceOf`
    // also there is claim and withdraw. claim is for the rewards, withdraw is for the staked tokens
    function test_counterMutual() public {
        uint256 balancePerSoulmate = 10 ether;
        _depositTokenToStake(balancePerSoulmate); // both have now staked 10
        console2.log(loveToken.balanceOf(soulmate1)); // 0
        console2.log(stakingContract.userStakes(soulmate1)); // 10
    }

    function test_claimingAfter13daysBurns6daysOfStaking() public {
        _depositTokenToStake(1 ether);
        uint256 almost2weeks = 2 weeks - 1 seconds;
        console2.log("almost2weeks: ", almost2weeks); // 1209599
        vm.warp(almost2weeks); // 1209599

        vm.startPrank(soulmate1);
        console2.log("last claim: ", stakingContract.lastClaim(soulmate1));
        stakingContract.claimRewards();
        console2.log("soulmate1's lovetoken balance: ", loveToken.balanceOf(soulmate1)); // 1
        console2.log("last claim: ", stakingContract.lastClaim(soulmate1));

        vm.warp(almost2weeks + 6 days); // now the user is staking for 20+ days
        // vm.expectRevert();
        stakingContract.claimRewards(); // no, even after 20+ days the user can't claim a second token, because she minted at the "wrong" moment.
        console2.log("soulmate1's lovetoken balance: ", loveToken.balanceOf(soulmate1)); // 1
        console2.log("last claim: ", stakingContract.lastClaim(soulmate1));
    }

    // when the stakingVault only has 1 token left, then alice stakes 10,
    // is the balance now 11? And can now Bob claim 10 tokens? (alice's tokens?)
    function test_vaultAlmostEmpty() public {
        // how much is in the vault initially?
        console2.log((loveToken.balanceOf(address(stakingVault))));
        _depositTokenToStake(10 ether);
        console2.log((loveToken.balanceOf(address(stakingVault))));
    }
}
