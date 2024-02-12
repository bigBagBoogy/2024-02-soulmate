// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

interface ILoveToken {
    function decimals() external returns (uint8);
    // should return (bool)
    function approve(address to, uint256 amount) external; // no return value
    // should return (bool)
    function transfer(address to, uint256 amount) external; // no return value
    // should return (bool)
    function transferFrom(address from, address to, uint256 amount) external; // no return value

    function balanceOf(address user) external returns (uint256 balance);

    function claim() external;
    // q is this manager initialized in a constructor anywhere?
    // q is there a risk of a race condition here?
    function initVault(address manager) external;
}
