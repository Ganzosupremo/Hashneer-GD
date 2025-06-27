# Hashneer

Hashneer is a Godot 4 project focused on Bitcoin themed gameplay. Players mine blocks to obtain Bitcoin while using fiat currency and upgrades to fight enemies. The economy is influenced by inflation and deflation mechanics that adjust prices and mining rewards.

## Gameplay Overview
- **Bitcoin mining**: The `Timechain` (`BitcoinNetwork.gd`) simulates mining blocks. Each mined block grants a Bitcoin subsidy which is sent to the player's wallet.
- **Upgrades**: Upgrades are defined in `Scripts/SkillsTree` and can be purchased with fiat or Bitcoin. Costs scale with inflation or deflation, encouraging strategic spending.
- **Inflation/deflation**: The `FED.gd` node compounds inflation each halving, while `BitcoinNetwork.gd` reduces Bitcoin prices by a halving multiplier.

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
- Upgrade data (`SkillNodeData.gd`) adjusts cost using inflation and deflation multipliers.

This repository uses the MIT License (see `LICENSE`).
