---
title: Soulmate Audit Report
author: Securigor.io
date: February 12, 2024
header-includes:
  - \usepackage{titling}
  - \usepackage{graphicx}
---

\begin{titlepage}
    \centering
    \begin{figure}[h]
        \centering
        \includegraphics[width=0.5\textwidth]{logo.pdf} 
    \end{figure}
    \vspace*{2cm}
    {\Huge\bfseries Soulmate Audit Report\par}
    \vspace{1cm}
    {\Large Version 1.0\par}
    \vspace{2cm}
    {\Large\itshape Securigor.io\par}
    \vfill
    {\large \today\par}
\end{titlepage}

\maketitle

<!-- Your report starts here! -->

Prepared by: [Securigor](https://Securigor.io)
Lead Auditors:

- bigBagBoogy

# Table of Contents
- [Table of Contents](#table-of-contents)
- [Protocol Summary](#protocol-summary)
- [Disclaimer](#disclaimer)
- [Risk Classification](#risk-classification)
- [Audit Details](#audit-details)
  - [Scope](#scope)
  - [Roles](#roles)
  - [Issues found](#issues-found)
- [Findings](#findings)
  - [High](#high)
    - [\[H-1\] The ERC721.sol::\_safeMint functions The protocol uses have their `require` statements after the executing code.](#h-1-the-erc721sol_safemint-functions-the-protocol-uses-have-their-require-statements-after-the-executing-code)
  - [Medium](#medium)
    - [\[M-1\] In Staking.sol::claimRewards the user gets "cheated" out of staked time by `lastClaim[msg.sender] = block.timestamp;`.](#m-1-in-stakingsolclaimrewards-the-user-gets-cheated-out-of-staked-time-by-lastclaimmsgsender--blocktimestamp)
    - [\[M-2\] In Staking.sol, the functions `deposit`, `claimRewards` and `withdraw` all do not follow CEI. The emits of the events are after external transfers have been done.](#m-2-in-stakingsol-the-functions-deposit-claimrewards-and-withdraw-all-do-not-follow-cei-the-emits-of-the-events-are-after-external-transfers-have-been-done)
  - [Low](#low)
    - [\[L-1\] Indirect circular dependency bug](#l-1-indirect-circular-dependency-bug)
    - [\[L-2\] A user can get divorced even if not in a couple.](#l-2-a-user-can-get-divorced-even-if-not-in-a-couple)
  - [Gas](#gas)
    - [\[gas\] Redundant writing to storage](#gas-redundant-writing-to-storage)

# Protocol Summary

Audit of the Soulmate protocol, where you can mint your shared Soulbound NFT with an unknown person, and get LoveToken as a reward for staying with your soulmate. A staking contract is available to collect more love. Because if you give love, you receive more love.

# Disclaimer

The Securigor team makes all effort to find as many vulnerabilities in the code in the given time period, but holds no responsibilities for the findings provided in this document. A security audit by the team is not an endorsement of the underlying business or product. The audit was time-boxed and the review of the code was solely on the security aspects of the Solidity implementation of the contracts.

# Risk Classification

|            |        | Impact |        |     |
| ---------- | ------ | ------ | ------ | --- |
|            |        | High   | Medium | Low |
|            | High   | H      | H/M    | M   |
| Likelihood | Medium | H/M    | M      | M/L |
|            | Low    | M      | M/L    | L   |

We use the [CodeHawks](https://docs.codehawks.com/hawks-auditors/how-to-evaluate-a-finding-severity) severity matrix to determine severity. See the documentation for more details.

# Audit Details 
- Commit Hash:  main branch
## Scope 
- In Scope: Entire Protocol


## Roles
None


## Issues found

| Severity | Number of issues found |
| -------- | ---------------------- |
| High     | 1                      |
| Medium   | 2                      |
| Low      | 2                      |
| Gas      | 1                      |
| Total    | 6                      |


# Findings

## High

### [H-1] The ERC721.sol::_safeMint functions The protocol uses have their `require` statements after the executing code.

**Description:**   In the `ERC721.sol` contract, the `_safeMint` functions have their require statements placed after the execution of the _mint function. This means that the minting operation occurs before checking whether the recipient address is a smart contract or not. As a result, tokens can be minted to contracts (when to.code.length > 0), potentially leading to unexpected behavior or security vulnerabilities.

**Impact:**  This coding pattern could result in tokens being mistakenly transferred to contracts that are not intended to receive ERC721 tokens. If the recipient contract does not handle ERC721 tokens correctly, it could result in loss of tokens or unexpected behavior.

**Proof of Concept:**  
```javascript
contract MaliciousContract {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4) {
        // Malicious behavior here
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}
```

**Recommended Mitigation:**   The `require` statements should be placed before executing the _mint function to ensure that tokens are only minted to addresses that are not smart contracts or that properly handle ERC721 tokens. Here's the corrected version of the `_safeMint` function. Please follow this pattern for both `_safeMint` functions.

```javascript
function _safeMint(address to, uint256 id) internal virtual {
    require(
        to.code.length == 0 || ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") == ERC721TokenReceiver.onERC721Received.selector,
        "UNSAFE_RECIPIENT"
    );

    _mint(to, id);
}
```


## Medium

### [M-1] In Staking.sol::claimRewards the user gets "cheated" out of staked time by `lastClaim[msg.sender] = block.timestamp;`.

**Description:**  When a user claims staking rewards just shy of 2 weeks, she'll get 1 token and has the surplus time (over 1 week) reset to "0"

**Impact:**  The impact of the issue is that users claiming staking rewards just shy of two weeks (or any amount of weeks) will receive only one token, effectively losing the surplus time (over one week) as it resets to "0". This results in a loss of potential rewards for users who stake for periods just under two weeks, which may lead to dissatisfaction among users and impact the overall fairness and attractiveness of the staking mechanism.

**Proof of Concept:**   Please paste this test at the bottom in `StakingTest.t.sol` and run: ```forge test --mt test_claimingAfter13daysBurns6daysOfStaking -vvvvv```
```javascript
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
        vm.expectRevert();
        stakingContract.claimRewards(); // no, even after 20+ days the user can't claim a second token, because she minted at the "wrong" moment.
        console2.log("soulmate1's lovetoken balance: ", loveToken.balanceOf(soulmate1)); // 1
        console2.log("last claim: ", stakingContract.lastClaim(soulmate1)); 
    }
```

**Recommended Mitigation:**   Update last claim time by adding 1 week for each week staked

```diff
+   lastClaim[msg.sender] += 1 weeks * timeInWeeksSinceLastClaim; 
-   lastClaim[msg.sender] = block.timestamp;
```


### [M-2] In Staking.sol, the functions `deposit`, `claimRewards` and `withdraw` all do not follow CEI. The emits of the events are after external transfers have been done. 

**Description:**  The events in the `Staking.sol` contract are emitted after external transfers have been executed in the functions deposit, withdraw, and claimRewards. This violates the Checks-Effects-Interactions pattern, a best practice in Solidity smart contract development. According to this pattern, external calls (interactions) should be made after state changes (effects) to prevent reentrancy attacks and ensure that contract state is consistent before interacting with other contracts or external entities.

**Impact:**  Without a dApp, this protocol is no more than a couple of contracts. So inevitably there will have to be an off-chain (website) that will be listening and ***acting*** to events being emitted by the smart-contracts. 

**Proof of Concept:**  consider a scenario where a malicious contract exploits the lack of proper ordering in the deposit function. By calling the deposit function from a contract that performs a reentrancy attack, it could potentially manipulate the contract state or funds before the Deposited event is emitted, leading to unintended consequences or loss of funds for legitimate users.
***Patrick Collins*** himself validates this finding not one week ago:
https://www.linkedin.com/posts/patrickalphac_a-lot-of-people-think-its-fine-to-emit-events-activity-7160679494452715524-Ou3M?utm_source=share&utm_medium=member_desktop

**Recommended Mitigation:**  emit events before executing external transfers or interactions.

## Low

### [L-1] Indirect circular dependency bug

**Description:** The `LoveToken.sol` constructor takes `airdropVault` and `stakingVault` as arguments. They are initialized in `Airdrop.sol`, which, needs an implementation of the `ILoveToken` interface.

**Impact:** For deployment to mainnet or a testnet other than a local environment, the circular dependancies will prevent deployment of `LoveToken.sol`.

**Proof of Concept:**  The initialization of `Vault.sol's` vaults (airdropVault and stakingVault) relies on `LoveToken.sol` being deployed and providing an implementation of the `ILoveToken` interface. Therefore, `LoveToken.sol` needs to be deployed before Vault.sol can successfully initialize its vaults.

**Recommended Mitigation:**   refactoring the contracts to remove circular dependencies or redesigning the deployment process to handle dependencies more efficiently.


### [L-2] A user can get divorced even if not in a couple.

**Description:**  The Soulmate.sol::getDivorced function does not check if the caller is in a couple.
This means that if a "single" soulmate calls `getDivorced`, she will be marked as `divorced`. (from address `0` to be precise)

**Impact:**  A user can "shoot herself in the foot", perhaps unintentional. Since this is irreversible, it can be quite annoying.

**Proof of Concept:**  Please paste this test at the bottom in `SoulmateTest.t.sol` and run: ```forge test --mt test_singleSoulmateCanGetDivorced -vvvvv```
```javascript
function test_singleSoulmateCanGetDivorced() public {
        vm.startPrank(soulmate1);
        soulmateContract.getDivorced();
        console2.log("divorce status is: ", soulmateContract.isDivorced());
        assertEq(soulmateContract.isDivorced(), true);
    } 
```
**Recommended Mitigation:** add a require to check if a user is in a couple:
```diff
   function getDivorced() public {
+       require(soulmateOf[msg.sender] != address(0), "you are not in a couple");
        address soulmate2 = soulmateOf[msg.sender];
        divorced[msg.sender] = true;
        divorced[soulmateOf[msg.sender]] = true;
        emit CoupleHasDivorced(msg.sender, soulmate2);
    }
```


## Gas

### [gas] Redundant writing to storage

**Description:** in Soulmate.sol::mintSoulmateToken the `soulmateOf` mapping is updated to link 2 soulmates together with the line: `soulmateOf[msg.sender] = soulmate1;`. This effectively links them together and either one can be queried to fint the other. There is no need to do this again the "other way around".

**Impact:** 

**Proof of Concept:**

**Recommended Mitigation:**  
 
 ```diff
        soulmateOf[msg.sender] = soulmate1;
 -      soulmateOf[soulmate1] = msg.sender;
 ```