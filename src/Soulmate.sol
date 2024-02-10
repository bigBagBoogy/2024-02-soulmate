// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {ERC721} from "@solmate/tokens/ERC721.sol";

/// @title Soulmate Soulbound NFT.
/// @author n0kto
/// @notice A Soulbound NFT sharing by soulmates.
contract Soulmate is ERC721 {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error Soulmate__alreadyHaveASoulmate(address soulmate);
    error Soulmate__SoulboundTokenCannotBeTransfered();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    string[4] niceWords = ["sweetheart", "darling", "my dear", "honey"];

    mapping(uint256 id => address[2] owners) private idToOwners; // token ID => [soulmate1, soulmate2] id / [0, 1] so, id#14[0] = soulmate1, id#14[1] = soulmate2
    mapping(uint256 id => uint256 timestamp) public idToCreationTimestamp;
    mapping(address soulmate1 => address soulmate2) public soulmateOf;
    mapping(address owner => uint256 id) public ownerToId; // 1 address to an id (which should be the same as the id we get from the idToOwners mapping)

    mapping(address owner => bool isDivorced) private divorced;

    mapping(uint256 id => string) public sharedSpace;

    // @audit this var seem suspicious. is this the ID of the marriage?
    uint256 private nextID; // starts off at 0

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event MessageWrittenInSharedSpace(uint256 indexed id, string message);

    event SoulmateIsWaiting(address indexed soulmate);

    event SoulmateAreReunited(address indexed soulmate1, address indexed soulmate2, uint256 indexed tokenId);

    event CoupleHasDivorced(address indexed soulmate1, address indexed soulmate2);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor() ERC721("Soulmate", "SLMT") {}

    /// @notice Used to mint a token when soulmates are reunited.
    /// @notice Soulmates are reunited every time a second people try to mint the same ID.
    /// @return ID of the minted NFT.
    function mintSoulmateToken() public returns (uint256) {
        // Check if people already have a soulmate, which means already have a token
        address soulmate = soulmateOf[msg.sender]; // get the soulmate of msg.sender.
        if (soulmate != address(0)) {
            // if this does not return 0, then msg.sender already has a soulmate
            revert Soulmate__alreadyHaveASoulmate(soulmate);
        }
        //   this block is about filling the soulmates array [2]
        // the first time (odd) we go straight here. We write into existance:
        // also, the second time, we go here, provided it's not the first user calling this again.
        address soulmate1 = idToOwners[nextID][0]; // ? / 0 / [0] =>  0 / 0 / 0 ,  so first time soulmate1 = 0.... the 2nd time:  ? / 0 / [0] =>  0x123userOne / 0 / [0]   odd
        address soulmate2 = idToOwners[nextID][1]; // ? / 0 / 1 =>  0 / 0 / 0 ,  so first time soulmate2 = 0.... the 2nd time:  ? / 0 / [1] =>  0x456usertwo / 0 / [1] even
        //
        //
        // this will run for the first user (odd) // the second time soulmate1 = 0x123userOne
        if (soulmate1 == address(0)) {
            idToOwners[nextID][0] = msg.sender; // will put the address of the user in the first slot of the array [0], remember that it's an array of 2 soulmates!
            // so now we have an array of soulmates, with in index 0 the first soulmate and id = 0
            ownerToId[msg.sender] = nextID; // here we map the owner to the ID (this is a personal thing) msg.sender = current user's address, nextID = 0 (initial value)
            emit SoulmateIsWaiting(msg.sender);

            // this will be skipped the first time, and we'll go staring to the return. the nextID will not be increased, cuz that's the 2nd time in the `else if` block
        } else if (soulmate2 == address(0)) {
            idToOwners[nextID][1] = msg.sender; // second user gets put in slot 2 of the soulmates array
            // Once 2 soulmates are reunited, the token is minted
            // Map the soulmate's address to the ID
            ownerToId[msg.sender] = nextID; // msg.sender = current user's address, nextID = 0 (initial value) (this is the personal thing again)

            soulmateOf[msg.sender] = soulmate1; // this seems redundant
            soulmateOf[soulmate1] = msg.sender; //  @audit written: this seems redundant and can be removed to save gas.

            idToCreationTimestamp[nextID] = block.timestamp; // map the ID to the timestamp

            emit SoulmateAreReunited(soulmate1, soulmate2, nextID); // address user1, address user2, 0
            emit MessageWrittenInSharedSpace(nextID, "Soulmate are reuniting");

            _mint(msg.sender, nextID++); // only here nextID is increased
        }

        return ownerToId[msg.sender]; // first time returns 0
    }

    /// @dev will be added after audit.
    /// @dev Since it is only used by wallets, it won't create any edge case.
    function tokenURI(uint256) public pure override returns (string memory) {
        // To do
        return "";
    }

    /// @notice Override of transferFrom to prevent any transfer.
    function transferFrom(address, address, uint256) public pure override {
        // Soulbound token cannot be transfered
        // Having a soulmate is for life !
        revert Soulmate__SoulboundTokenCannotBeTransfered();
    }

    /// @notice Allows any soulmates with the same NFT ID to write in a shared space on blockchain.
    /// @param message The message to write in the shared space.
    function writeMessageInSharedSpace(string calldata message) external {
        uint256 id = ownerToId[msg.sender];
        sharedSpace[id] = message;
        emit MessageWrittenInSharedSpace(id, message);
    }

    /// @notice Allows any soulmates with the same NFT ID to read in a shared space on blockchain.
    function readMessageInSharedSpace() external view returns (string memory) {
        // Add a little touch of romantism
        return string.concat(sharedSpace[ownerToId[msg.sender]], ", ", niceWords[block.timestamp % niceWords.length]);
    }

    /// @notice Cancel possibily for 2 lovers to collect LoveToken from the airdrop.
    function getDivorced() public {
        address soulmate2 = soulmateOf[msg.sender];
        divorced[msg.sender] = true;
        divorced[soulmateOf[msg.sender]] = true;
        emit CoupleHasDivorced(msg.sender, soulmate2);
    }

    function isDivorced() public view returns (bool) {
        return divorced[msg.sender];
    }

    function totalSupply() external view returns (uint256) {
        return nextID;
    }

    function totalSouls() external view returns (uint256) {
        return nextID * 2;
        // @audit this seems to not count the single soulmates.
        // when there are 3 users the id is still 1, then totalSouls is 3
        // q what happens when there's divorse?
    }
}
