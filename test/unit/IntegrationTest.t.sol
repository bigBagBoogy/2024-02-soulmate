// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {console2} from "forge-std/Test.sol";
import {BaseTest} from "./BaseTest.t.sol";

import {Soulmate} from "../../src/Soulmate.sol";

// here I combine all contracts

contract IntegrationTest is BaseTest {
    function test_integration() public divMarMar {
        vm.prank(carol);
        airdropContract.claim();
        console2.log("carol's lovetoken balance: ", loveToken.balanceOf(carol) / 1e18);
        // assertEq(loveToken.balanceOf(carol), 1 ether);
        vm.warp(oneDay * 3);
        console2.log("time: ", block.timestamp); //time:  259200
        vm.prank(carol);
        airdropContract.claim();
        console2.log("carol's lovetoken balance: ", loveToken.balanceOf(carol) / 1e18);
        // assertEq(loveToken.balanceOf(carol), 3 ether);

        // vm.prank(carol);
        // vm.expectRevert();
        // airdropContract.claim();

        // assertTrue(loveToken.balanceOf(soulmate1) == 3 ether);
    }

    function test_theWorkingsOfTime() public {
        console2.log("time: ", block.timestamp); //time:  1
        vm.warp(1 days);
        console2.log("time: ", block.timestamp); //time:  86400
        vm.warp(1 days); // so does nothing
        console2.log("time: ", block.timestamp); //time:  86400
        vm.warp(2 days); // + 86400
        console2.log("time: ", block.timestamp); //time:  172800
        vm.warp(1 days / 2); // effectively goes back in time
        console2.log("time: ", block.timestamp); //time:  43200
    }

    function test_thresholdMintLoveTokens() public {
        vm.prank(alice);
        soulmateContract.mintSoulmateToken();
        vm.prank(bob);
        soulmateContract.mintSoulmateToken();
        vm.warp(1 days + 1 seconds); // the threshold is 86400 seconds, so can mint @ 86401
        console2.log("time: ", block.timestamp); //time:  86401
        vm.prank(bob);
        airdropContract.claim();
        vm.warp(2 days + 1 seconds);
        console2.log("time: ", block.timestamp); //time:  86401
        vm.prank(bob);
        airdropContract.claim();
    }

    ////////////////////////////////////////
    ///////////////////////////////////////
    /////////      elaborate       ////////
    ////////      modifiers         ////////
    ////////////////////////////////////////
    ////////////////////////////////////////

    modifier divMarMar() {
        uint256 oneDay = 1 days;

        vm.prank(alice);
        soulmateContract.mintSoulmateToken(); // alice = idToOwners[0]
        // uint256 indexOfUser = soulmateContract.idToOwners(alice); idToOwners = private, so this does not work. one can only get alice's index from ownerToId
        uint256 idOfalice = soulmateContract.ownerToId(alice);
        console2.log("alice has marriage id: ", idOfalice);
        console2.log("alice's friend is: ", soulmateContract.soulmateOf(alice));
        uint256 whatIsTheIdOfFriend = soulmateContract.ownerToId(soulmateContract.soulmateOf(alice));
        console2.log("alice's friend has marriage id: ", whatIsTheIdOfFriend);

        vm.prank(bob);
        soulmateContract.mintSoulmateToken(); // bob = idToOwners[1];
        uint256 idOfBob = soulmateContract.ownerToId(bob);
        console2.log("bob has marriage id: ", idOfBob);
        assertEq(idOfalice, idOfBob);
        console2.log("alice's friend is now: ", soulmateContract.soulmateOf(alice));

        vm.warp(oneDay); // bob's soulmateToken is 1 day old
        vm.roll(oneDay);

        vm.prank(carol);
        soulmateContract.mintSoulmateToken(); // carol = idToOwners[0];
        uint256 idOfCarol = soulmateContract.ownerToId(carol); // should be 1
        console2.log("carol has marriage id: ", idOfCarol);
        console2.log("carol's friend is: ", soulmateContract.soulmateOf(carol)); // now addr0
        whatIsTheIdOfFriend = soulmateContract.ownerToId(soulmateContract.soulmateOf(carol));
        console2.log("carol's friend `0` has marriage id: ", whatIsTheIdOfFriend);

        vm.prank(dave);
        soulmateContract.mintSoulmateToken(); // dave = idToOwners[1];
        uint256 idOfDave = soulmateContract.ownerToId(dave);
        console2.log("dave has marriage id: ", idOfDave);
        assertEq(idOfCarol, idOfDave);
        console2.log("carol's friend is now: ", soulmateContract.soulmateOf(carol));

        vm.warp(oneDay * 2); // dave's soulmateToken is 2 day old?
        vm.roll(oneDay * 2);

        vm.prank(eve);
        soulmateContract.mintSoulmateToken(); // eve = idToOwners[0];
        uint256 idOfEve = soulmateContract.ownerToId(eve); // should be 2
        console2.log("eve has marriage id: ", idOfEve);
        console2.log("eve's friend is: ", soulmateContract.soulmateOf(eve)); // now addr0
        whatIsTheIdOfFriend = soulmateContract.ownerToId(soulmateContract.soulmateOf(eve));
        console2.log("eve's friend `0` has marriage id: ", whatIsTheIdOfFriend);

        vm.prank(freddy);
        soulmateContract.mintSoulmateToken(); // freddy = idToOwners[1];
        uint256 idOfFreddy = soulmateContract.ownerToId(freddy);
        console2.log("freddy has marriage id: ", idOfFreddy);
        assertEq(idOfEve, idOfFreddy);
        console2.log("freddy's friend is now: ", soulmateContract.soulmateOf(freddy));

        assertEq(soulmateContract.soulmateOf(alice), bob);
        assertEq(soulmateContract.soulmateOf(bob), alice);
        assertEq(soulmateContract.soulmateOf(carol), dave);
        assertEq(soulmateContract.soulmateOf(dave), carol);
        assertEq(soulmateContract.soulmateOf(eve), freddy);
        assertEq(soulmateContract.soulmateOf(freddy), eve);
        console2.log("address 0 is soulmate of: ", soulmateContract.soulmateOf(address(0)));

        console2.log(
            "alice's soulmateToken age is now: ",
            block.timestamp - soulmateContract.idToCreationTimestamp(soulmateContract.ownerToId(alice))
        );
        vm.prank(alice);
        soulmateContract.getDivorced();
        console2.log("alice has marriage id: ", soulmateContract.ownerToId(alice));

        console2.log("alice's friend is: ", soulmateContract.soulmateOf(alice));
        vm.prank(alice);
        vm.expectRevert();
        soulmateContract.mintSoulmateToken();

        vm.startPrank(bob);
        soulmateContract.isDivorced();
        vm.stopPrank();

        vm.warp(oneDay * 3);
        vm.roll(oneDay * 3);

        console2.log(
            "alice's soulmateToken age is now: ",
            block.timestamp - soulmateContract.idToCreationTimestamp(soulmateContract.ownerToId(alice))
        );
        _;
    }
}
