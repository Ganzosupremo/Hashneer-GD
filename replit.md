# Hasheneer - Bitcoin Themed Godot Game

## Project Overview
Hasheneer is a Godot 4.4 game project focused on Bitcoin-themed gameplay. Players mine blocks to obtain Bitcoin while using fiat currency and upgrades to fight enemies. The game features polygon destruction mechanics, an economic system with inflation/deflation, and various game modes.

## Project Status
**Status:** Partially Configured - Missing Critical Dependency

### What's Working
- ✅ Godot 4.4.1 engine installed
- ✅ Project structure intact
- ✅ Most assets and scripts present
- ✅ Workflow configured for VNC display

### Critical Issue
**Missing Addon:** `polygon_fracture`

The project requires a custom polygon fracturing addon that provides:
- `PolygonLib` class for polygon manipulation
- `PolygonFracture` class for polygon fracturing
- `PoolFracture.gd` script
- `CutShapeVisualizer.gd` script  
- `ShardFracture.gd` script

This addon is **essential** for the game's core mechanics (destructible terrain, shield effects, enemy damage visualization, etc.) but was not included in the GitHub repository.

### Missing Files
Located at `res://addons/polygon_fracture/`:
- `PoolFracture.gd`
- `CutShapeVisualizer.gd`
- `ShardFracture.gd`
- Related polygon fracturing library

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

However, the game will show script errors and fail to load properly without the polygon_fracture addon.

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

## Known Limitations

1. **Cannot run without polygon_fracture addon** - Core gameplay mechanics depend on it
2. **Missing textures** - Some texture files are referenced but import files may be outdated
3. **Audio imports** - Some audio files need reimporting in Godot editor
4. **Theme resources** - Custom theme references missing textures

## Resolution Steps

To make this project fully functional, you would need to:

1. **Find or create the polygon_fracture addon:**
   - Search for existing Godot 4 polygon fracturing addons
   - Port an existing polygon fracturing solution
   - Create custom implementation of PolygonLib and PolygonFracture classes

2. **Import all resources:**
   - Open project in Godot editor to regenerate .godot/imported/ files
   - Verify all textures, audio, and fonts are properly imported

3. **Test game modes:**
   - Verify Mining Game Mode works
   - Test Unlimited Waves Game Mode
   - Check skill tree and upgrade systems

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
