// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {console2} from "forge-std/Test.sol";

import {BaseTest} from "./BaseTest.t.sol";
import {Soulmate} from "../../src/Soulmate.sol";

contract SoulmateTest is BaseTest {
    function test_MintNewToken() public {
        uint256 tokenIdMinted = 0;

        vm.prank(soulmate1);
        soulmateContract.mintSoulmateToken();

        assertTrue(soulmateContract.totalSupply() == 0);

        vm.prank(soulmate2);
        soulmateContract.mintSoulmateToken();

        assertTrue(soulmateContract.totalSupply() == 1);
        assertTrue(soulmateContract.soulmateOf(soulmate1) == soulmate2);
        assertTrue(soulmateContract.soulmateOf(soulmate2) == soulmate1);
        assertTrue(soulmateContract.ownerToId(soulmate1) == tokenIdMinted);
        assertTrue(soulmateContract.ownerToId(soulmate2) == tokenIdMinted);
    }

    function test_NoTransferPossible() public {
        _mintOneTokenForBothSoulmates();

        vm.prank(soulmate1);
        vm.expectRevert();
        soulmateContract.transferFrom(soulmate1, soulmate2, 0);
    }

    function compare(string memory str1, string memory str2) public pure returns (bool) {
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }

    function test_WriteAndReadSharedSpace() public {
        vm.prank(soulmate1);
        soulmateContract.writeMessageInSharedSpace("Buy some eggs");

        vm.prank(soulmate2);
        string memory message = soulmateContract.readMessageInSharedSpace();

        string[4] memory possibleText =
            ["Buy some eggs, sweetheart", "Buy some eggs, darling", "Buy some eggs, my dear", "Buy some eggs, honey"];
        bool found;
        for (uint256 i; i < possibleText.length; i++) {
            if (compare(possibleText[i], message)) {
                found = true;
                break;
            }
        }
        console2.log(message);
        assertTrue(found);
    }

    // Test case to ensure that transferFrom prevents any transfer
    // Test case to ensure that transferFrom prevents any transfer
    function test_TransferFromPreventsAnyTransfer() public {
        // Expect that the transferFrom function reverts
        vm.expectRevert();
        soulmateContract.transferFrom(address(this), address(0), 123);
    }

    function test_MintSoulmateToken_Success() public {
        // Ensure that a token is successfully minted for a user with no existing soulmate
        uint256 tokenId = soulmateContract.mintSoulmateToken();
        // Assert that the tokenId returned is greater than zero, indicating success
        assertGt(tokenId, 0);
    }

    function test_MintSoulmateToken_AlreadyHasSoulmate() public {
        // Set up the contract state such that the caller already has a soulmate
        vm.prank(soulmate1);
        soulmateContract.mintSoulmateToken();

        console2.log("soulmate1 has: ", soulmateContract.totalSupply());

        vm.prank(soulmate2);
        soulmateContract.mintSoulmateToken();

        console2.log("soulmate1 and 2 now have: ", soulmateContract.totalSupply(), " token");

        // Expect that calling mintSoulmateToken reverts with an error indicating the caller already has a soulmate
        vm.expectRevert();
        vm.prank(soulmate1);
        soulmateContract.mintSoulmateToken();
        // vm.expectRevert(soulmateContract.mintSoulmateToken(), "alreadyHaveASoulmate");
    }

    // function test_MintSoulmateToken_WaitingForSecondSoulmate() public {
    //     // Set up the contract state such that the caller is waiting for a second soulmate
    //     soulmateContract.idToOwners(1, 0, address(0x1)); // Assuming soulmate 1 is not 0
    //     // Call mintSoulmateToken to complete the pairing
    //     uint256 tokenId = soulmateContract.mintSoulmateToken();
    //     // Assert that the tokenId returned is greater than zero, indicating success
    //     assertGt(tokenId, 0);
    // }

    function test_getsTheRightSoulmate() public {
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
    }

    function test_getsTheRightSoulmateOf4() public {
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

        console2.log("alice's soulmateToken timestamp is: ", soulmateContract.idToCreationTimestamp(idOfalice));
        console2.log(
            "bob's soulmateToken timestamp is: ",
            soulmateContract.idToCreationTimestamp(soulmateContract.ownerToId(bob))
        );
    }

    function test_doAlotPlusTime() public {
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
        console2.log(
            "bob's soulmateToken age is now: ",
            block.timestamp - soulmateContract.idToCreationTimestamp(soulmateContract.ownerToId(bob))
        );
        console2.log(
            "carol's soulmateToken age is now: ",
            block.timestamp - soulmateContract.idToCreationTimestamp(soulmateContract.ownerToId(carol))
        );
        console2.log(
            "dave's soulmateToken age is now: ",
            block.timestamp - soulmateContract.idToCreationTimestamp(soulmateContract.ownerToId(dave))
        );
        console2.log(
            "eve's soulmateToken age is now: ",
            block.timestamp - soulmateContract.idToCreationTimestamp(soulmateContract.ownerToId(eve))
        );
        console2.log(
            "freddy's soulmateToken age is now: ",
            block.timestamp - soulmateContract.idToCreationTimestamp(soulmateContract.ownerToId(freddy))
        );
    }

    // function test_marriedCanMint() public divMarMar {
    //     vm.prank(alice);
    //     vm.expectRevert();
    //     soulmateContract.mintSoulmateToken();
    // }
    function test_singleSoulmateCanGetDivorced() public {
        vm.startPrank(soulmate1);
        soulmateContract.getDivorced();
        console2.log("divorce status is: ", soulmateContract.isDivorced());
        assertEq(soulmateContract.isDivorced(), true);
    }

    function test_hasSoulmate() public {
        makeAddr("alice");
        console2.log("alice's friend is: ", soulmateContract.soulmateOf(alice));
    }
}
