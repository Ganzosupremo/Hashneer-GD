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
    - **Modular Component System:** Replaced monolithic structures with a modular design, including `FractureManager` (centralized destruction), `MiningWorldGenerator` (Minecraft-style 2D procedural terrain), `MapGeometry` (spatial utilities), `BorderSystem` (unified border generation), and `MiningDepthConfig` (data-driven ore spawn weights).
    - **Mining World Generation (Minecraft-style 2D):**
        - **Surface Generation:** FastNoiseLite simplex noise creates rolling hills with configurable amplitude and base height.
        - **Cave System:** Secondary FastNoiseLite layer carves procedural caves below the dirt layer with depth-adjusted density.
        - **Layered Geology:** AIR (sky), DIRT (surface layer), STONE (subsurface), DEEP_STONE (60%+ depth), BEDROCK (indestructible floor), SHOP_WALL (underground chamber).
        - **Border System:** Left/right columns and bottom row are indestructible (fracturable=false, infinite health, no drops/shards).
        - **Shop Chamber:** Underground chamber carved into stone layer with indestructible walls (SHOP_WALL layer). Chamber is centered horizontally with configurable width, height, and depth. ShopLayer positions platforms and spawn points inside the chamber.
        - **Coordinate Convention:** Block.position uses center (for polygon rendering), _quadrant_positions uses top-left (for bounds calculation), signals emit top-left (for downstream consumers).
    - **Ore System:** 9 ore types with depth-based spawning in STONE/DEEP_STONE layers only. Ore vein clustering uses BFS algorithm for natural distribution.
    - **Ore Inventory:** `OreInventory` autoload tracks collected ores, their counts, and depth-adjusted values.
    - **A* Pathfinding:** Grid-based A* pathfinding (50x50 cells) for enemies with obstacle avoidance and smart path recalculation.
    - **Enemy AI:** Flocking behavior (separation, alignment, cohesion) for natural swarm movement, compatible with A* pathfinding.
    - **Weapon System:** Multiple weapons with upgrades, integrated with the new `FractureManager`.
    - **Bitcoin Network System:** `BitcoinNetwork.gd` simulates blockchain mining, `BitcoinWallet.gd` tracks balances, and `FED.gd` manages fiat supply and inflation.

### Feature Specifications
- **Mining Mode:** Minecraft-style 2D mining with procedural terrain generation. Features include:
    - Rolling hill surface terrain using FastNoiseLite
    - Procedural cave systems carved below the dirt layer
    - Layered geology (dirt surface, stone, deep stone, bedrock)
    - Depth-based ore distribution in stone layers only
    - BFS ore vein clustering for natural ore deposits
    - Indestructible world boundaries (side walls and bedrock floor)
    - **Underground Shop Chamber:** Integrated structure carved into stone layer with indestructible bronze-colored walls, containing shop platform and spawn points. Configurable via shop_chamber_width, shop_chamber_height, shop_chamber_depth_ratio.
    - Future phases include AI miners, mining tools, and shop inventory system.
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