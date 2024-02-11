// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {ILoveToken} from "./ILoveToken.sol";

interface IVault {
    function vaultInitialize() external view returns (bool);
    // `ILoveToken loveToken` means must be called by `ILoveToken`. manager is the argument
    function initVault(ILoveToken loveToken, address manager) external;
}
