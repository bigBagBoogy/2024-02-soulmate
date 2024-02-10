// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {console2} from "forge-std/Test.sol";

import {BaseTest} from "./BaseTest.t.sol";

contract AirdropTest is BaseTest {
    function test_WellInitialized() public {
        assertTrue(loveToken.allowance(address(airdropVault), address(airdropContract)) == 500_000_000 ether);
    }

    function test_Claim() public {
        _mintOneTokenForBothSoulmates();

        // Not enough day in relationship
        vm.prank(soulmate1);
        vm.expectRevert();
        airdropContract.claim();

        vm.warp(block.timestamp + 200 days + 1 seconds);

        vm.prank(soulmate1);
        airdropContract.claim();

        assertTrue(loveToken.balanceOf(soulmate1) == 200 ether);

        vm.prank(soulmate2);
        airdropContract.claim();

        assertTrue(loveToken.balanceOf(soulmate2) == 200 ether);
    }

    function test_claim() public {
        _mintOneTokenForBothSoulmates();
        vm.warp(1 days + 1 seconds);
        vm.prank(soulmate1);
        airdropContract.claim(); // should have 1 love token
        // vm.warp(2 days + 1 seconds);
        vm.prank(soulmate2);
        airdropContract.claim(); // should have 1 love token also?
        console2.log(loveToken.balanceOf(soulmate1));
        console2.log(loveToken.balanceOf(soulmate2));
        vm.warp(2 days + 1 seconds);
        vm.prank(soulmate2);
        airdropContract.claim(); // should have 2 love tokens
        console2.log(loveToken.balanceOf(soulmate1));
        console2.log(loveToken.balanceOf(soulmate2));

        // conclusion: the love tokens are personal to each soulmate
        // the only thing they share is the ERC721 token id
    }
    //the reason why you only see one value being passed is that Foundry only prints the last trace of the fuzz runs by default. This is to avoid cluttering the console output with too many traces. The test is wel degelijk run 256 times!

    function test_claimFuzz(uint256 fuzzedInputTime) public {
        // Bound the input to be between 1 and 1000000 seconds
        fuzzedInputTime = bound(fuzzedInputTime, 86401, 1000000000);
        console2.log(fuzzedInputTime);
        _mintOneTokenForBothSoulmates();
        vm.warp(fuzzedInputTime);
        vm.prank(soulmate1);
        airdropContract.claim();

        // calculate the amount of love tokens that should be minted
        uint256 calculatedAmount = ((fuzzedInputTime + 1) / 86400) * 1e18; // = days in the relationship
        // no more tokens than (time + 1) / 86400 == amount of days in "marriage"
        assertLe(loveToken.balanceOf(soulmate1), calculatedAmount);
    }
} // 15 broke the test ???
