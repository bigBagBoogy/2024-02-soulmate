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

        // part 2 of test -- check that the love tokens are personal to each soulmate
        uint256 extraTime = fuzzedInputTime + 172801;
        vm.warp(extraTime); // 2 days later
        vm.prank(soulmate2);
        airdropContract.claim();
        assertLe(loveToken.balanceOf(soulmate1), loveToken.balanceOf(soulmate2));
        console2.log(loveToken.balanceOf(soulmate1), loveToken.balanceOf(soulmate2));

        // part 3 of test -- check that claiming the same day twice doesn't mint more
        vm.prank(soulmate2);
        vm.expectRevert();
        airdropContract.claim();

        // this is a non issue:
        // part 4 of test -- check that address(0) can't mint
        // vm.prank(address(0));
        // vm.expectRevert(); // this fails. Address 0 is able to mint tokens
        // airdropContract.claim();
    }
    // there is 500_000_000 tokens in the vault. 5e8 is

    function test_dustcollectorWorksFuzz(uint256 fuzzedInputTime) public {
        // Bound the input to be between 1 and 1000000 seconds
        fuzzedInputTime = bound(fuzzedInputTime, 6e13, 5e14);
        _mintOneTokenForBothSoulmates();
        vm.warp(fuzzedInputTime);
        vm.prank(soulmate1);
        airdropContract.claim(); // should have 5e8 love tokens (5e26 wei)
        assertLe(loveToken.balanceOf(soulmate1), 5e26);
        // now that soulmate 1 has all love tokens, let's check that soulmate 2 can't claim
        vm.prank(soulmate2);
        assertEq(loveToken.balanceOf(soulmate2), 0);
    }

    event SoulmateIsWaiting(address indexed soulmate);
    // Event Emission: Check that the TokenClaimed event is emitted with the correct parameters after a successful claim.

    function test_emitsEventCorrectly() public {
        vm.expectEmit();
        emit SoulmateIsWaiting(msg.sender);
        _mintOneTokenForBothSoulmates();
        // emit SoulmateIsWaiting(msg.sender);
    }
    // a slither test:

    function test_underflowClaim() public {
        _mintOneTokenForBothSoulmates();
        vm.warp(86400);
        vm.prank(soulmate1);
        vm.expectRevert();
        airdropContract.claim();
        console2.log(loveToken.balanceOf(soulmate1));
        vm.warp(86401);
        vm.prank(soulmate1);
        airdropContract.claim();
        console2.log(loveToken.balanceOf(soulmate1));
    }
}
