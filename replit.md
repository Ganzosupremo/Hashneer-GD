# Hasheneer - Bitcoin Themed Godot Game

## Project Overview
Hasheneer is a Godot 4.4 game project focused on Bitcoin-themed gameplay. Players mine blocks to obtain Bitcoin while using fiat currency and upgrades to fight enemies. The game features polygon destruction mechanics, an economic system with inflation/deflation, and various game modes.

## Project Status
**Status:** ⚠️ Game Feel Improvements Complete - Polygon Fracture Addon Incomplete

### What's Working
- ✅ Godot 4.4.1 engine installed
- ✅ Project structure intact
- ✅ All assets and scripts present
- ✅ Workflow configured for VNC display
- ✅ Game feel improvements fully implemented (Oct 1, 2025)
- ❌ Polygon fracture addon missing core files (PoolFracture.gd, CutShapeVisualizer.gd, ShardFracture.gd)

### Recent Improvements (Oct 1-2, 2025)

#### Game Feel Improvements (Oct 1, 2025)
All "game juice" features successfully implemented:
- **Steer-based movement** - Smooth responsive controls with separate accel/decel/turn constants
- **Camera trauma system** - Screen shake with directional kick and weapon recoil
- **Hitstop/freeze frames** - Time dilation on hits (0.06s at 0.3 timescale)
- **Muzzle flash lighting** - Dynamic Light2D flicker on weapon fire
- **Footstep cadence** - Speed-based step timing with directional squash/stretch animations
- **Weapon kickback** - Player velocity recoil on firing
- **Bug fixes** - UserSettings.gd Vector2i.split() error, FireWeapon.gd tab/space indentation

#### Visual Polish - Background Enhancements (Oct 2, 2025)
Enhanced all backgrounds with Bitcoin-themed styling:
- **UI Backgrounds** - Added falling "hash blocks" effect, enhanced gold/orange Bitcoin colors, subtle blockchain pulse
  - Applied to Main Menu and Save Slot Selector
  - Shader: `Shaders/UIBackgroundShader.gdshader`
- **Game Backgrounds** - Unified subtle animated background with moving grid and multi-octave noise
  - Applied to Mining Mode and Unlimited Waves Mode
  - Shader: `Shaders/GameBackgroundUnified.gdshader`
  - Clean, non-distracting design that complements gameplay

#### Tunable Game Feel Parameters (Scripts/Utils/Constants.gd)
```gdscript
# Movement
Player_Acceleration = 2500      # Speed when starting to move
Player_Deceleration = 3000      # Speed when stopping
Player_Turn_Accel = 3500        # Speed when changing direction
Player_Brake_Accel = 4000       # Emergency stop speed

# Camera Effects
trauma_decay_rate = 3.0         # How fast shake fades
recoil_decay_rate = 8.0         # How fast recoil recovers

# Footsteps
base_step_interval = 0.45       # Time between steps at full speed
```

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

## Known Issues

### ⚠️ Critical: Polygon Fracture Addon Incomplete
The `polygon_fracture` addon is missing three core files that prevent the game from loading:
- `addons/polygon_fracture/PoolFracture.gd` - Pool management for fracture objects
- `addons/polygon_fracture/CutShapeVisualizer.gd` - Debug visualization for cuts
- `addons/polygon_fracture/ShardFracture.gd` - Individual shard fracture logic

**Impact:** Game cannot start until these files are provided or the addon is replaced.

**Partial addon files present:**
- ✅ `PolygonLib.gd` - Polygon utility functions (working)
- ✅ `PolygonFracture.gd` - Main fracture logic (working)

### Other Notes
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
October 2, 2025
