# LoLFantasy

**LoLFantasy** is a decentralized application (dApp) where players can create mid-laner characters, join fantasy seasons, and compete for rewards. It leverages Chainlink VRF for randomness in stat generation and includes a token-based betting system for players to predict winners in competitive seasons.

## How It Works

- **Create Mid-Laner:** Players create a mid-laner character by using Chainlink VRF to generate stats. The character will have various attributes that will influence their success in fantasy seasons.
- **Join Season:** Once a mid-laner is created, players can join the season by paying a joining fee and compete with others.
- **Compete and Win:** At the end of each season, one player is chosen as the winner based on their character's performance.
- **Betting System:** Players can bet on which character will win the season using the game's native token, LoLToken.

## Smart Contracts

The project consists of three main smart contracts:

1. **LoLFantasy.sol:** This contract manages the creation of mid-laners, season competitions, and the token betting system. It integrates with Chainlink VRF for randomness and handles rewards in the form of LoLToken and native currency.

2. **LoLToken.sol:** The ERC20 token contract that serves as the native currency of the game. It is used for placing bets and rewarding the winners.

3. **LoLNft.sol:** A non-fungible token (NFT) contract that represents ownership of unique assets within the game, such as special rewards or limited-edition characters.

## Features

- **Random Stat Generation:** Chainlink VRF ensures that mid-laner stats are generated randomly and fairly.
- **Token Betting:** Players can use LoLToken to place bets on the outcome of the season.
- **VRF Integration:** Chainlink VRF provides secure randomness for stat generation and winner selection.
- **Season Management:** The contract controls the state of the game, moving between open and calculating states during different phases of the season.
- **Fund Distribution:** Winners are rewarded with LoLToken and ETH.

## Tech Stack

- **Frontend:** React, Next.js, ethers.js
- **Smart Contracts:** Solidity (Foundry)
- **Blockchain:** Sepolia Testnet
- **Oracle:** Chainlink VRF
- **Tools:** Foundry, Alchemy

## Development & Testing

The project utilizes unit and integration tests to ensure the reliability of the smart contracts. The use of Foundry helps automate and streamline the testing process.

## Setup and Installation

To run the project locally, follow these steps:

```bash
git clone https://github.com/yourusername/lolfantasy.git
cd lolfantasy
```
