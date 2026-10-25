# Hashneer

Hashneer is a Godot 4 project focused on Bitcoin themed gameplay. Players mine blocks to obtain Bitcoin while using fiat currency and upgrades to fight enemies. The economy is influenced by inflation and deflation mechanics that adjust prices and mining rewards.

## Gameplay Overview
- **Bitcoin mining**: The `Timechain` (`BitcoinNetwork.gd`) simulates mining blocks. Each mined block grants a Bitcoin subsidy which is sent to the player's wallet.
- **Upgrades**: Upgrades are defined in `Scripts/SkillsTree` and can be purchased with fiat or Bitcoin. Costs scale with inflation or deflation, encouraging strategic spending.
- **Halving**: Every block pays a subsidy that starts at 50 BTC and halves every 2 blocks. Bitcoin prices only drop 25% per halving, so new coins get scarcer while the coins you hold buy more.
- **Inflation**: The `FED.gd` node inflates fiat prices on every block, 4% per block plus 2% more after each halving. Fiat drops only grow with the square root of inflation, so saving in fiat always loses value.
- **Mining farm**: Buy CPU, GPU and ASIC miners with fiat. Their hashrate earns Bitcoin transaction fees over time, also while the game is closed (up to 8 hours), and makes the AI miner slower to find the block. Fees come from the network, so they never add to the coin supply.
- **Epochs (prestige)**: Once every block is mined you can start a new epoch. Everything resets except your HODL points (the square root of the BTC you held), which permanently boost hashrate and fiat drops.
- **Achievements**: Goals like mining your first block, surviving a halving or owning 10% of the network.
- **Exchange**: In the skill tree you can trade fiat for Bitcoin and back, with a 5% fee. The BTC price rises with inflation and with every halving.

## Project Structure
- **Scenes/** – All `.tscn` scenes used by the game. Subfolders include game modes, player, enemies, UI and more.
- **Scripts/** – Core gameplay code written in GDScript. Contains managers, Bitcoin network logic, skill tree code and utilities.
- **Resources/** – Data assets such as stats, upgrades and audio streams used throughout the project.

## Building and Running
1. Install [Godot 4.4](https://godotengine.org/) or later.
2. Open this repository in Godot (`project.godot`).
3. Press <kbd>F5</kbd> or use `godot4 --path .` to run.
4. To build an export, configure the provided `export_presets.cfg` and use Godot's export dialog.

### Architecture Notes
- `GameManager.gd` handles level selection, saving progress and references to important nodes.
- `BitcoinWallet.gd` tracks fiat and Bitcoin balances and converts between them.
- `BitcoinNetwork.gd` stores the blockchain, issues subsidies and computes a deflation multiplier from the current halving.
- `FED.gd` manages fiat supply and multiplies total inflation after each halving.
- Upgrade data (`UpgradeData.gd`) adjusts cost using inflation and deflation multipliers.

This repository uses the MIT License (see `LICENSE`).
