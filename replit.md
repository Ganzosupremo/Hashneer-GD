# Hasheneer - Bitcoin Themed Godot Game

## Project Overview
Hasheneer is a Godot 4.4 game project focused on Bitcoin-themed gameplay. Players mine blocks to obtain Bitcoin while using fiat currency and upgrades to fight enemies. The game features polygon destruction mechanics, an economic system with inflation/deflation, and various game modes.

## Project Status
**Status:** ✅ Fully Configured and Running

### What's Working
- ✅ Godot 4.4.1 engine installed
- ✅ Project structure intact
- ✅ All assets and scripts present
- ✅ Workflow configured for VNC display
- ✅ Polygon fracture addon installed and functioning
- ✅ Game loads and runs successfully

## Project Structure
- **Scenes/** - All `.tscn` scenes (game modes, player, enemies, UI, etc.)
- **Scripts/** - Core gameplay code in GDScript (managers, Bitcoin network, skill tree, utilities)
- **Resources/** - Data assets (stats, upgrades, audio streams)
- **Textures/** - Visual assets (sprites, UI elements, VFX)
- **Audio/** - Sound effects and music
- **Shaders/** - Custom shader effects
- **addons/** - Godot plugins (item_drops, save_system, godot-git-plugin)

## Technical Setup

### Engine
- Godot 4.4.1 stable
- OpenGL3 rendering driver
- X11 display driver for VNC

### Dependencies
- **Installed:** godot_4 (Nix package)
- **Working Addons:**
  - item_drops - Item dropping and pickup system
  - save_system - Save/load functionality
  - godot-git-plugin - Git integration

### Configuration
- Main scene: `res://Scenes/UI/MainMenu.tscn`
- Custom user directory: "Nigga_pls"
- Forward Plus rendering
- No default gravity (2D top-down game)

## Running the Project

The project is configured with a workflow that launches Godot in VNC mode:
```bash
godot4 --path . --rendering-driver opengl3 --display-driver x11
```

The game runs in VNC display which can be accessed through the Replit interface.

## Architecture Notes

### Bitcoin Network System
- `BitcoinNetwork.gd` - Simulates blockchain mining
- `BitcoinWallet.gd` - Tracks fiat and Bitcoin balances
- `FED.gd` - Manages fiat supply and inflation
- Economic events affect prices and rewards

### Gameplay Systems
- **Quadrant Terrain** - Destructible polygon-based terrain (requires polygon_fracture)
- **Skill Tree** - Player progression with Bitcoin/fiat costs
- **Weapon System** - Multiple weapons with upgrades
- **Enemy AI** - Various enemy types with different behaviors

### Game Modes
- Mining Mode - Focus on mining Bitcoin blocks
- Unlimited Waves - Endless enemy waves survival mode

## Known Notes

- Some UID warnings in logs are expected and harmless (Godot falls back to text paths automatically)
- Git plugin GDExtension has compatibility warnings but doesn't affect gameplay
- OpenGLES rendering mode is used for VNC compatibility (some advanced features disabled)

## Development Notes

- Project uses Godot 4.4 features
- Custom theme and fonts configured
- Extensive use of autoloaded singletons (GameManager, AudioManager, etc.)
- Save system integrated for persistent progress
- Git integration available through godot-git-plugin

## Export Presets

The project includes export configurations for:
- Windows Desktop
- macOS
- Web (HTML5)

## Last Updated
October 1, 2025
