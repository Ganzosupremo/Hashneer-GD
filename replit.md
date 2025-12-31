# Hasheneer - Bitcoin Themed Godot Game

## Overview
Hasheneer is a Godot 4.4 game project centered around Bitcoin-themed gameplay. Players mine blocks to acquire Bitcoin, utilizing fiat currency and upgrades to combat enemies. The game incorporates polygon destruction mechanics, a dynamic economic system with inflation and deflation, and diverse game modes. The project's vision is to deliver an engaging experience that combines resource management, combat, and an evolving in-game economy within a unique Bitcoin-inspired universe.

## User Preferences
I prefer detailed explanations.
Do not make changes to the folder `Z`.
Do not make changes to the file `Y`.

## System Architecture

### UI/UX Decisions
- **Backgrounds:** UI backgrounds feature falling "hash blocks," enhanced gold/orange Bitcoin colors, and subtle blockchain pulse effects. Game backgrounds use a unified animated grid with multi-octave noise, designed to be clean and non-distracting.
- **Game Feel:** Implemented smooth, responsive steer-based movement, camera trauma system (screen shake with directional kick and weapon recoil), hitstop/freeze frames, muzzle flash lighting, speed-based footstep cadence with animations, and weapon kickback.

### Technical Implementations
- **Engine:** Godot 4.4.1 stable, OpenGL3 rendering driver, X11 display driver for VNC.
- **Core Systems:**
    - **Modular Component System:** Replaced monolithic structures with a modular design, including `FractureManager` (centralized destruction), `MiningWorldGenerator` (terrain generation with BFS-based ore clustering), `MapGeometry` (spatial utilities), `BorderSystem` (unified border generation), and `MiningDepthConfig` (data-driven ore spawn weights).
    - **Ore System:** 9 ore types with depth-based spawning, unique properties, and visual differentiation. Ore vein clustering uses a BFS algorithm for natural distribution.
    - **Ore Inventory:** `OreInventory` autoload tracks collected ores, their counts, and depth-adjusted values.
    - **A* Pathfinding:** Grid-based A* pathfinding (50x50 cells) for enemies with obstacle avoidance and smart path recalculation.
    - **Enemy AI:** Flocking behavior (separation, alignment, cohesion) for natural swarm movement, compatible with A* pathfinding.
    - **Weapon System:** Multiple weapons with upgrades, integrated with the new `FractureManager`.
    - **Bitcoin Network System:** `BitcoinNetwork.gd` simulates blockchain mining, `BitcoinWallet.gd` tracks balances, and `FED.gd` manages fiat supply and inflation.

### Feature Specifications
- **Mining Mode:** Players mine blocks to obtain Bitcoin. Features include depth-based ore distribution, ore pickup, and inventory management. Future phases include AI miners, depth management, mining tools, player mechanics, and a shop system.
- **Unlimited Waves (Brotato-style survival):** Large 3000x3000 arena, intelligent enemy movement with flocking, dynamic enemy cap management with distance-based despawn, escalating boss system (bosses scale until Bitcoin is found), and wave progression based on total enemies removed.
- **Enemy Variety:** 13 distinct enemy types, including FastDart, Tank, Exploding, Splitter, Sniper, Teleporter, Healer, and Spinner enemies, each with unique behaviors.
- **Tunable Game Feel Parameters:** Key movement (acceleration, deceleration, turn, brake), camera effects (trauma decay, recoil decay), and footsteps (base step interval) are configurable via `Constants.gd`.

### System Design Choices
- **Project Structure:** Organized into `Scenes/`, `Scripts/`, `Resources/`, `Textures/`, `Audio/`, `Shaders/`, and `addons/`.
- **Autoloaded Singletons:** Extensive use of singletons (e.g., `GameManager`, `AudioManager`, `OreInventory`, `PathfindingManager`) for global access and management.
- **Save System:** Integrated for persistent player progress.
- **Custom Theme and Fonts:** Configured for a consistent visual style.
- **Rendering:** Uses OpenGL3 and X11 display driver for VNC compatibility.

## External Dependencies

- **Godot Addons:**
    - `item_drops`: For item dropping and pickup mechanics.
    - `save_system`: Provides save/load functionality.
    - `godot-git-plugin`: For Git integration within the editor.
- **Polygon Fracture Addon (Partial):** `PolygonLib.gd` and `PolygonFracture.gd` are present and working for polygon utility functions and main fracture logic. However, `PoolFracture.gd`, `CutShapeVisualizer.gd`, and `ShardFracture.gd` are missing and critical for the addon's full functionality.