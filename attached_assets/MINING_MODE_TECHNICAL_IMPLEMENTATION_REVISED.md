# Mining Game Mode - Technical Implementation Guide (REVISED)

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Implementation Phases](#implementation-phases)
3. [Phase 1: QuadrantBuilder + Ore System](#phase-1-quadrantbuilder--ore-system)
4. [Phase 2: AI Miners + Depth Management](#phase-2-ai-miners--depth-management)
5. [Phase 3: Mining Tools + Player Mechanics](#phase-3-mining-tools--player-mechanics)
6. [Phase 4: Shop System + Upgrades](#phase-4-shop-system--upgrades)
7. [Phase 5: UI/UX + Polish](#phase-5-uiux--polish)

---

## Architecture Overview

### System Dependencies
```
MiningGameMode (new)
├── QuadrantBuilder (existing - modified)
├── BlockCore (existing - modified)
├── MiningToolComponent (new - adapted from FireWeaponComponent)
├── OreInventory (new autoload)
├── DepthManager (new autoload)
├── UpgradeManager (new autoload)
├── AIMiner (new entity)
├── BitcoinNetwork (existing - hooks)
├── EconomicEventsManager (existing - hooks)
├── ItemDropsSystem (existing - extended)
└── MainEventBus (existing - new signals)
```

### Data Flow
```
Player mines ore → QuadrantBuilder fractures → Ore drops spawn → 
Auto-collect (ItemDropsBus) → OreInventory tracks → 
Return to surface → Shop sells ores → Fiat earned → Buy upgrades → 
Find Bitcoin → Level Complete

AI Miners mine in parallel → DepthManager tracks progress → 
Warnings trigger → If AI finds Bitcoin → Game Over
```

---

## Implementation Phases

### Phase 1: QuadrantBuilder + Ore System (CURRENT FOCUS)
**Goal**: Get ore-based terrain generation working
- Ore spawning based on depth layers
- Ore pickups and inventory
- Ore vein clustering

### Phase 2: AI Miners + Depth Management
**Goal**: Add competition pressure
- AI miner entities that mine downward
- Depth tracking and progress comparison
- Victory/defeat conditions

### Phase 3: Mining Tools + Player Mechanics  
**Goal**: Replace shooting with mining
- Mining tool component (1x1, 2x2, 3x3 areas)
- Tool upgrades and switching
- Explosive charges

### Phase 4: Shop System + Upgrades
**Goal**: Economy and progression
- Surface return mechanic
- Shop UI for selling ores and buying upgrades
- Temporary vs permanent upgrades

### Phase 5: UI/UX + Polish
**Goal**: Full experience
- HUD with depth comparison
- Random events
- Audio progression
- Combo system

---

## Phase 1: QuadrantBuilder + Ore System

### 1.1 Resource Definitions

**File**: `Scripts/Resources/OreDetails.gd` (ALREADY CREATED)

```gdscript
class_name OreDetails extends Resource
## Resource defining ore properties for mining game mode

enum OreType {
    DIRT,           # No value, filler
    COAL,           # Common, low value
    IRON,           # Common, medium value
    COPPER,         # Uncommon
    SILVER,         # Uncommon
    GOLD,           # Rare
    EMERALD,        # Very Rare
    DIAMOND,        # Very Rare
    BITCOIN_ORE     # Ultra Rare - the objective
}

@export_category("Ore Identity")
@export var ore_type: OreType = OreType.DIRT
@export var ore_name: String = "Unknown Ore"
@export var ore_description: String = ""

@export_category("Ore Visuals")
@export var ore_color: Color = Color.WHITE
@export var texture: Texture2D
@export var normal_texture: Texture2D
@export var pickup_texture: Texture2D
@export var particle_color: Color = Color.WHITE

@export_category("Ore Properties")
## Base fiat value when sold in shop
@export var base_value: float = 0.0
## Multiplier for value at deeper layers (value *= depth_multiplier * depth_layer)
@export var depth_multiplier: float = 1.0
## Health multiplier for blocks containing this ore
@export var health_multiplier: float = 1.0
## Spawn weight (higher = more common)
@export var spawn_weight: float = 1.0

@export_category("Audio")
@export var mining_sound: SoundEffectDetails
@export var pickup_sound: SoundEffectDetails

## Calculate final value based on depth
func get_value_at_depth(depth: int) -> float:
    return base_value * (1.0 + (depth * depth_multiplier))
```

**Create 9 ore resource files** in `Resources/Ores/`:

| Ore Type | Base Value | Health Mult | Depth Mult | Ore Color |
|----------|------------|-------------|------------|-----------|
| Dirt | 0 | 1.0 | 0.0 | Gray |
| Coal | 5 | 1.2 | 0.05 | Dark Gray |
| Iron | 10 | 1.5 | 0.08 | Silver |
| Copper | 15 | 1.6 | 0.10 | Orange |
| Silver | 25 | 1.8 | 0.12 | Light Gray |
| Gold | 50 | 2.0 | 0.15 | Yellow |
| Emerald | 75 | 2.2 | 0.18 | Green |
| Diamond | 100 | 2.5 | 0.20 | Cyan |
| Bitcoin | 0 | 3.0 | 0.0 | Orange/Gold |

---

### 1.2 QuadrantBuilder Modifications

**File**: `Scripts/QuadrantTerrain/QuadrantBuilder.gd`

**Add new exports** (ALREADY ADDED):
```gdscript
@export_category("Mining Mode")
@export var mining_mode_enabled: bool = false
@export var ore_resources: Dictionary = {}  # Map OreType enum → OreDetails resource
```

**Modified _initialize_grid_of_blocks()**:
```gdscript
func _initialize_grid_of_blocks(initial_health: float) -> void:
    _quadrant_positions.clear()
    var vein_pending: Dictionary = {}  # Cells that should become specific ore types
    
    for i in range(grid_size.x):
        for j in range(grid_size.y):
            var cell: Vector2i = Vector2i(i, j)
            if not _is_cell_in_shape(cell):
                continue
            
            var block: FracturableStaticBody2D = _static_body_template.instantiate()
            _quadrant_nodes.add_child(block)
            
            # Determine ore type
            var ore_type: OreDetails.OreType
            if vein_pending.has(cell):
                # Cell is part of a vein
                ore_type = vein_pending[cell]
            else:
                # Normal weighted random
                ore_type = _determine_ore_type(j)
                
                # Apply vein bonus if valuable ore
                if ore_type != OreDetails.OreType.DIRT:
                    _apply_vein_bonus(cell, ore_type, vein_pending)
            
            var ore_data: OreDetails = _get_ore_resource(ore_type)
            
            # Set block properties
            block.rectangle_size = Vector2(quadrant_size.x, quadrant_size.y)
            block.placed_in_level = true
            var pos = Vector2(i * quadrant_size.x, j * quadrant_size.y)
            block.position = pos
            _quadrant_positions.append(pos)
            
            # Use ore-specific health and texture
            var ore_health = initial_health * ore_data.health_multiplier
            block.setFractureBody(ore_health, ore_data.texture, builder_args.normal_texture)
            block.self_modulate = ore_data.ore_color
            
            # Store ore metadata for drop spawning
            block.set_meta("ore_type", ore_type)
            block.set_meta("ore_data", ore_data)
            block.set_meta("depth_layer", int((float(j) / grid_size.y) * 20.0))
```

**New helper methods**:
```gdscript
## Determine ore type based on Y position (depth layer)
func _determine_ore_type(y_grid_position: int) -> OreDetails.OreType:
    var depth_layer = int((float(y_grid_position) / grid_size.y) * 20.0)
    var weights = _get_spawn_weights_for_depth(depth_layer)
    return _weighted_random_ore(weights)

## Get ore spawn weights for depth layer
func _get_spawn_weights_for_depth(depth: int) -> Dictionary:
    if depth <= 5:
        return {
            OreDetails.OreType.DIRT: 0.80,
            OreDetails.OreType.COAL: 0.15,
            OreDetails.OreType.IRON: 0.05
        }
    elif depth <= 10:
        return {
            OreDetails.OreType.DIRT: 0.60,
            OreDetails.OreType.COAL: 0.20,
            OreDetails.OreType.IRON: 0.10,
            OreDetails.OreType.COPPER: 0.05,
            OreDetails.OreType.SILVER: 0.05
        }
    elif depth <= 15:
        return {
            OreDetails.OreType.DIRT: 0.50,
            OreDetails.OreType.COAL: 0.15,
            OreDetails.OreType.IRON: 0.15,
            OreDetails.OreType.GOLD: 0.10,
            OreDetails.OreType.EMERALD: 0.05,
            OreDetails.OreType.DIAMOND: 0.05
        }
    else:  # 16-20 (Bitcoin zone)
        return {
            OreDetails.OreType.DIRT: 0.40,
            OreDetails.OreType.IRON: 0.20,
            OreDetails.OreType.GOLD: 0.15,
            OreDetails.OreType.DIAMOND: 0.10,
            OreDetails.OreType.SILVER: 0.14,
            OreDetails.OreType.BITCOIN_ORE: 0.01
        }

## Weighted random ore selection
func _weighted_random_ore(weights: Dictionary) -> OreDetails.OreType:
    var total_weight = 0.0
    for weight in weights.values():
        total_weight += weight
    
    var rand_value = _rng.randf() * total_weight
    var cumulative = 0.0
    
    for ore_type in weights.keys():
        cumulative += weights[ore_type]
        if rand_value <= cumulative:
            return ore_type
    
    return OreDetails.OreType.DIRT

## Apply vein bonus to nearby cells (40% chance in 3x3 radius)
func _apply_vein_bonus(center: Vector2i, ore_type: OreDetails.OreType, vein_dict: Dictionary) -> void:
    for x in range(-1, 2):
        for y in range(-1, 2):
            if x == 0 and y == 0:
                continue  # Skip center
            
            var neighbor = center + Vector2i(x, y)
            
            # Check if in bounds
            if neighbor.x < 0 or neighbor.x >= grid_size.x:
                continue
            if neighbor.y < 0 or neighbor.y >= grid_size.y:
                continue
            
            # 40% chance to propagate
            if _rng.randf() < 0.4:
                vein_dict[neighbor] = ore_type

## Get ore resource from type
func _get_ore_resource(ore_type: OreDetails.OreType) -> OreDetails:
    if ore_resources.has(ore_type):
        return ore_resources[ore_type]
    
    # Fallback dirt ore
    var fallback = OreDetails.new()
    fallback.ore_type = OreDetails.OreType.DIRT
    fallback.ore_name = "Dirt"
    fallback.health_multiplier = 1.0
    fallback.ore_color = Color.GRAY
    return fallback
```

**Modified fracture method**:
```gdscript
func fracture_quadrant_on_collision(pos: Vector2, other_body: FracturableStaticBody2D, 
                                     bullet_launch_velocity: float = 410.0, 
                                     bullet_damage: float = 25.0, 
                                     bullet_speed: float = 500.0) -> void:
    var p = bullet_launch_velocity / bullet_speed
    var cut_shape: PackedVector2Array = _polygon_fracture.generateRandomPolygon(
        Vector2(100, 50) * p, Vector2(8, 32), Vector2.ZERO
    )
    _spawn_cut_visualizers(pos, cut_shape, 10.0)
    
    if !other_body.take_damage(bullet_damage):
        return
    
    if _fracture_disabled: return
    _fracture_disabled = true
    _cut_polygons(other_body, pos, cut_shape, 45.0, 10.0)
    
    # NEW: Spawn ore drops instead of currency drops in mining mode
    if mining_mode_enabled and other_body.has_meta("ore_type"):
        var ore_type = other_body.get_meta("ore_type")
        var ore_data = other_body.get_meta("ore_data")
        var depth = other_body.get_meta("depth_layer")
        _spawn_ore_drop(other_body.global_position, ore_type, ore_data, depth)
    else:
        other_body.random_drops.spawn_drops(1)  # Original behavior
    
    set_deferred("_fracture_disabled", false)

## NEW: Spawn ore pickup
func _spawn_ore_drop(position: Vector2, ore_type: OreDetails.OreType, 
                     ore_data: OreDetails, depth: int) -> void:
    if ore_type == OreDetails.OreType.DIRT:
        return  # No drops for dirt
    
    # Instantiate ore pickup
    var ore_pickup_scene = preload("res://Scenes/Pickups/OrePickup.tscn")
    var ore_pickup = ore_pickup_scene.instantiate()
    ore_pickup.global_position = position
    ore_pickup.ore_type = ore_type
    ore_pickup.ore_value = ore_data.get_value_at_depth(depth)
    ore_pickup.ore_texture = ore_data.pickup_texture
    ore_pickup.ore_data = ore_data
    get_tree().current_scene.add_child(ore_pickup)
```

---

### 1.3 Ore Pickup System

**New File**: `Scripts/Resources/OrePickupResource.gd`

```gdscript
class_name OrePickupResource extends Resource
## Pickup resource for ore items

@export var ore_type: OreDetails.OreType = OreDetails.OreType.DIRT
@export var ore_value: float = 0.0
@export var depth_found: int = 0
@export var auto_collect: bool = true
@export var magnet_radius: float = 100.0
```

**New File**: `Scenes/Pickups/OrePickup.tscn` and `Scripts/Pickups/OrePickup.gd`

```gdscript
class_name OrePickup extends Area2D
## Ore pickup that auto-collects when player is nearby

signal ore_collected(ore_type: OreDetails.OreType, value: float)

var ore_type: OreDetails.OreType = OreDetails.OreType.DIRT
var ore_value: float = 0.0
var ore_texture: Texture2D
var ore_data: OreDetails

@onready var sprite: Sprite2D = $Sprite2D
@onready var collect_radius: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
    # Set visual
    if ore_texture:
        sprite.texture = ore_texture
    
    # Set color from ore data
    if ore_data:
        sprite.modulate = ore_data.ore_color
    
    # Connect to player
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("Player"):
        _collect()

func _collect() -> void:
    # Add to inventory
    OreInventory.add_ore(ore_type, ore_value)
    
    # Play sound
    if ore_data and ore_data.pickup_sound:
        AudioManager.create_2d_audio_at_location(
            global_position,
            ore_data.pickup_sound.sound_type,
            ore_data.pickup_sound.destination_audio_bus
        )
    
    # Emit signal
    ore_collected.emit(ore_type, ore_value)
    
    # Remove pickup
    queue_free()
```

---

### 1.4 Ore Inventory System

**New File**: `Scripts/Autoload/OreInventory.gd`

```gdscript
extends Node
## Singleton that tracks collected ores

signal ore_added(ore_type: OreDetails.OreType, value: float)
signal ore_removed(ore_type: OreDetails.OreType, amount: int)
signal inventory_cleared()

## Dictionary mapping OreType → {count: int, total_value: float}
var _ores: Dictionary = {}

func _ready() -> void:
    _reset_inventory()

## Add ore to inventory
func add_ore(ore_type: OreDetails.OreType, value: float) -> void:
    if not _ores.has(ore_type):
        _ores[ore_type] = {"count": 0, "total_value": 0.0}
    
    _ores[ore_type]["count"] += 1
    _ores[ore_type]["total_value"] += value
    ore_added.emit(ore_type, value)

## Get ore count by type
func get_ore_count(ore_type: OreDetails.OreType) -> int:
    if _ores.has(ore_type):
        return _ores[ore_type]["count"]
    return 0

## Get total value of specific ore type
func get_ore_value(ore_type: OreDetails.OreType) -> float:
    if _ores.has(ore_type):
        return _ores[ore_type]["total_value"]
    return 0.0

## Get total value of all ores
func get_total_value() -> float:
    var total = 0.0
    for ore_data in _ores.values():
        total += ore_data["total_value"]
    return total

## Get all ores data
func get_all_ores() -> Dictionary:
    return _ores.duplicate()

## Clear all ores (when selling at shop)
func clear_inventory() -> void:
    _ores.clear()
    _reset_inventory()
    inventory_cleared.emit()

## Remove specific amount of ore
func remove_ore(ore_type: OreDetails.OreType, amount: int) -> bool:
    if not _ores.has(ore_type):
        return false
    
    if _ores[ore_type]["count"] < amount:
        return false
    
    _ores[ore_type]["count"] -= amount
    if _ores[ore_type]["count"] <= 0:
        _ores.erase(ore_type)
    
    ore_removed.emit(ore_type, amount)
    return true

func _reset_inventory() -> void:
    for ore_type in OreDetails.OreType.values():
        _ores[ore_type] = {"count": 0, "total_value": 0.0}
```

---

## Phase 2: AI Miners + Depth Management

### 2.1 AI Miner Entity

**New File**: `Scripts/Enemies/AIMiner.gd`

```gdscript
class_name AIMiner extends CharacterBody2D
## AI competitor that mines downward toward Bitcoin

signal depth_changed(new_depth: int)
signal bitcoin_found(miner_name: String)

@export var miner_name: String = "Satoshi AI"
@export var base_speed: float = 100.0
@export var personality: Personality = Personality.BALANCED

enum Personality {
    BALANCED,        # Satoshi AI: consistent pace
    FAST_ERRATIC,    # Hash Hunter: fast but makes mistakes
    LATE_GAME        # Block Breaker: slow start, fast finish
}

var current_depth: int = 0
var target_depth: int = 20
var speed_multiplier: float = 1.0
var is_mining: bool = true
var quadrant_builder: QuadrantBuilder

@onready var sprite: Sprite2D = $Sprite2D
@onready var mining_timer: Timer = $MiningTimer

func _ready() -> void:
    quadrant_builder = get_tree().get_first_node_in_group("QuadrantBuilder")
    sprite.modulate.a = 0.5  # Semi-transparent
    
    # Set personality-specific behavior
    _apply_personality()
    
    # Start mining
    mining_timer.timeout.connect(_mine_block)
    mining_timer.start()

func _apply_personality() -> void:
    match personality:
        Personality.BALANCED:
            mining_timer.wait_time = 2.0  # Consistent 2s per block
        Personality.FAST_ERRATIC:
            mining_timer.wait_time = 1.5  # Faster but...
            # Occasionally backtrack (handled in _mine_block)
        Personality.LATE_GAME:
            mining_timer.wait_time = 3.0  # Slow initially
            # Speeds up at depth 11+ (handled in _physics_process)

func _physics_process(delta: float) -> void:
    # Late game personality acceleration
    if personality == Personality.LATE_GAME and current_depth >= 11:
        mining_timer.wait_time = 1.0  # Fast at deep levels
    
    # Apply depth manager speed adjustments
    if DepthManager:
        speed_multiplier = DepthManager.get_ai_speed_multiplier()

func _mine_block() -> void:
    if not is_mining:
        return
    
    # Fast erratic personality: 10% chance to waste time
    if personality == Personality.FAST_ERRATIC and randf() < 0.1:
        return  # Miss this cycle
    
    # Mine downward
    current_depth += 1
    depth_changed.emit(current_depth)
    
    # Update position visually
    global_position.y += 50  # Move down in world
    
    # Check if reached Bitcoin zone
    if current_depth >= 16:
        _check_for_bitcoin()
    
    # Check if won
    if current_depth >= target_depth:
        _ai_victory()

func _check_for_bitcoin() -> void:
    # 1% chance per block in Bitcoin zone
    if randf() < 0.01:
        bitcoin_found.emit(miner_name)
        _ai_victory()

func _ai_victory() -> void:
    is_mining = false
    mining_timer.stop()
    # Trigger game over
    MainEventBus.ai_found_bitcoin.emit(miner_name)

func set_speed_multiplier(multiplier: float) -> void:
    speed_multiplier = clamp(multiplier, 0.5, 1.5)
    mining_timer.wait_time /= speed_multiplier
```

---

### 2.2 Depth Manager

**New File**: `Scripts/Autoload/DepthManager.gd`

```gdscript
extends Node
## Singleton that tracks player and AI mining depths

signal player_depth_changed(new_depth: int)
signal ai_progress_warning(stage: int, message: String)  # stage: 30/60/85
signal player_advantage(layers_ahead: int)
signal player_behind(layers_behind: int)

const MAX_DEPTH: int = 20
const BITCOIN_DEPTH_START: int = 16

var player_depth: int = 0
var ai_miners: Array[AIMiner] = []
var deepest_ai_depth: int = 0

var ai_base_speed_mult: float = 1.0  # Set by game level
var rubber_band_active: bool = false

func _ready() -> void:
    pass

## Register AI miner
func register_ai_miner(ai: AIMiner) -> void:
    ai_miners.append(ai)
    ai.depth_changed.connect(_on_ai_depth_changed)
    ai.bitcoin_found.connect(_on_ai_bitcoin_found)

## Update player depth (called by player movement or mining)
func set_player_depth(depth: int) -> void:
    player_depth = clampi(depth, 0, MAX_DEPTH)
    player_depth_changed.emit(player_depth)
    _check_rubber_banding()
    _check_progress_warnings()

## Get AI speed multiplier (for rubber-banding)
func get_ai_speed_multiplier() -> float:
    var base_mult = ai_base_speed_mult
    
    if rubber_band_active:
        var depth_diff = player_depth - deepest_ai_depth
        
        # Player is 5+ layers behind: slow AI by 15%
        if depth_diff <= -5:
            return base_mult * 0.85
        
        # Player is 5+ layers ahead: speed AI by 15%
        elif depth_diff >= 5:
            return base_mult * 1.15
    
    return base_mult

## Set AI base speed from game level difficulty
func set_ai_difficulty(level: int) -> void:
    # Level 1 = 70%, increases 10% per level, capped at 130%
    var difficulty_mult = 0.7 + (level * 0.1)
    ai_base_speed_mult = clamp(difficulty_mult, 0.7, 1.3)

func _on_ai_depth_changed(new_depth: int) -> void:
    # Track deepest AI
    if new_depth > deepest_ai_depth:
        deepest_ai_depth = new_depth

func _on_ai_bitcoin_found(miner_name: String) -> void:
    # AI won - game over
    print("AI Victory: %s found Bitcoin!" % miner_name)

func _check_rubber_banding() -> void:
    var depth_diff = player_depth - deepest_ai_depth
    
    if depth_diff <= -5:
        player_behind.emit(abs(depth_diff))
    elif depth_diff >= 5:
        player_advantage.emit(depth_diff)

func _check_progress_warnings() -> void:
    var ai_progress = float(deepest_ai_depth) / MAX_DEPTH
    
    if ai_progress >= 0.85:
        ai_progress_warning.emit(85, "💀 CRITICAL: Competitors near Bitcoin!")
    elif ai_progress >= 0.60:
        ai_progress_warning.emit(60, "🚨 URGENT: AI at depth %d!" % deepest_ai_depth)
    elif ai_progress >= 0.30:
        ai_progress_warning.emit(30, "⚠️ Competitors catching up!")

## Get player progress as percentage
func get_player_progress() -> float:
    return float(player_depth) / MAX_DEPTH

## Get AI progress as percentage
func get_ai_progress() -> float:
    return float(deepest_ai_depth) / MAX_DEPTH

## Check if player reached Bitcoin zone
func is_player_in_bitcoin_zone() -> bool:
    return player_depth >= BITCOIN_DEPTH_START

## Check if AI reached Bitcoin zone
func is_ai_in_bitcoin_zone() -> bool:
    return deepest_ai_depth >= BITCOIN_DEPTH_START
```

---

### 2.3 Bitcoin Victory Detection

Add to `MainEventBus.gd`:
```gdscript
signal bitcoin_collected_by_player()
signal ai_found_bitcoin(miner_name: String)
```

In `OrePickup.gd`, modify `_collect()`:
```gdscript
func _collect() -> void:
    # Check if Bitcoin
    if ore_type == OreDetails.OreType.BITCOIN_ORE:
        MainEventBus.bitcoin_collected_by_player.emit()
        # Trigger level complete
        MainEventBus.level_completed.emit()
    
    # Add to inventory
    OreInventory.add_ore(ore_type, ore_value)
    
    # ... rest of function
```

---

## Phase 3: Mining Tools + Player Mechanics

### 3.1 Mining Tool Resource

**New File**: `Scripts/Resources/MiningToolDetails.gd`

```gdscript
class_name MiningToolDetails extends Resource
## Resource defining mining tool properties

@export_category("Tool Identity")
@export var tool_name: String = "Basic Pickaxe"
@export var tool_texture: Texture2D
@export var tool_icon: Texture2D

@export_category("Mining Properties")
## Mining area radius (1x1 = 50, 2x2 = 100, 3x3 = 150)
@export var mining_radius: float = 50.0
## Damage dealt to ore blocks
@export var damage: float = 25.0
## Cooldown between swings (seconds)
@export var swing_cooldown: float = 0.5
## Mining power (affects fracture size)
@export var mining_power: float = 410.0

@export_category("Effects")
@export var swing_sound: SoundEffectDetails
@export var swing_effect: VFXEffectProperties

@export_category("Special Abilities")
@export var reveals_nearby_ores: bool = false
@export var ore_reveal_radius: float = 0.0
```

---

### 3.2 Mining Tool Component

**New File**: `Scripts/Components/MiningToolComponent.gd`

```gdscript
class_name MiningToolComponent extends Node2D
## Handles mining tool mechanics (adapted from FireWeaponComponent)

signal tool_used(target_position: Vector2)

@export var active_tool_component: ActiveMiningToolComponent

@onready var tool_swing_position: Marker2D = %ToolSwingPosition

var swing_cooldown_timer: float = 0.0
var current_tool: MiningToolDetails
var quadrant_builder: QuadrantBuilder

func _ready() -> void:
    quadrant_builder = get_tree().get_first_node_in_group("QuadrantBuilder")
    tool_used.connect(_on_tool_used)

func _process(delta: float) -> void:
    swing_cooldown_timer -= delta

func _on_tool_used(target_position: Vector2) -> void:
    if !ready_to_swing():
        return
    
    current_tool = active_tool_component.get_current_tool()
    
    # Perform mining
    _mine_area(target_position)
    reset_cooldown_timer()

func ready_to_swing() -> bool:
    return swing_cooldown_timer <= 0.0

func reset_cooldown_timer() -> void:
    swing_cooldown_timer = current_tool.swing_cooldown

func _mine_area(target_position: Vector2) -> void:
    # Get all quadrants in mining area
    var mining_area = CircleShape2D.new()
    mining_area.radius = current_tool.mining_radius
    
    var space_state = get_world_2d().direct_space_state
    var query = PhysicsShapeQueryParameters2D.new()
    query.shape = mining_area
    query.transform = Transform2D(0, target_position)
    query.collide_with_areas = false
    query.collide_with_bodies = true
    
    var results = space_state.intersect_shape(query)
    
    for result in results:
        var body = result.collider
        if body is FracturableStaticBody2D:
            # Deal mining damage
            quadrant_builder.fracture_quadrant_on_collision(
                target_position, 
                body, 
                current_tool.mining_power,
                current_tool.damage,
                100.0
            )
    
    # Play mining sound & VFX
    AudioManager.create_2d_audio_at_location(
        target_position, 
        current_tool.swing_sound.sound_type, 
        current_tool.swing_sound.destination_audio_bus
    )
    GameManager.vfx_manager.spawn_effect(
        VFXManager.EffectType.MINING_IMPACT, 
        Transform2D(0, target_position), 
        current_tool.swing_effect
    )
```

---

## Phase 4: Shop System + Upgrades

### 4.1 Shop UI Scene

**New File**: `Scenes/UI/MiningShop.tscn` and `Scripts/UI/MiningShop.gd`

```gdscript
class_name MiningShop extends Control
## Shop UI for selling ores and buying upgrades

signal shop_closed()

@onready var ore_sell_panel: VBoxContainer = %OreSellPanel
@onready var upgrade_buy_panel: VBoxContainer = %UpgradeBuyPanel
@onready var fiat_label: Label = %FiatLabel
@onready var sell_all_button: Button = %SellAllButton

var current_fiat: float = 0.0

func _ready() -> void:
    sell_all_button.pressed.connect(_on_sell_all_pressed)
    _update_ore_display()
    _update_upgrade_display()

func _update_ore_display() -> void:
    # Clear existing
    for child in ore_sell_panel.get_children():
        child.queue_free()
    
    # Display each ore type
    var all_ores = OreInventory.get_all_ores()
    for ore_type in all_ores.keys():
        var ore_data = all_ores[ore_type]
        if ore_data["count"] <= 0:
            continue
        
        var ore_row = _create_ore_row(ore_type, ore_data["count"], ore_data["total_value"])
        ore_sell_panel.add_child(ore_row)

func _create_ore_row(ore_type: OreDetails.OreType, count: int, value: float) -> HBoxContainer:
    var row = HBoxContainer.new()
    
    # Ore icon
    var icon = TextureRect.new()
    # icon.texture = get_ore_texture(ore_type)
    icon.custom_minimum_size = Vector2(32, 32)
    row.add_child(icon)
    
    # Ore name + count
    var name_label = Label.new()
    name_label.text = "%s x%d" % [OreDetails.OreType.keys()[ore_type], count]
    row.add_child(name_label)
    
    # Value
    var value_label = Label.new()
    value_label.text = "%.0f $" % value
    row.add_child(value_label)
    
    return row

func _on_sell_all_pressed() -> void:
    # Get total value
    var total_value = OreInventory.get_total_value()
    
    # Add to fiat
    BitcoinWallet.add_currency(Constants.CurrencyType.FIAT, total_value)
    
    # Clear inventory
    OreInventory.clear_inventory()
    
    # Update display
    _update_ore_display()
    _update_fiat_display()

func _update_fiat_display() -> void:
    fiat_label.text = "Fiat: %.0f $" % BitcoinWallet.get_currency_amount(Constants.CurrencyType.FIAT)

func _update_upgrade_display() -> void:
    # Populate upgrade buttons from UpgradeManager
    pass
```

---

### 4.2 Upgrade Manager

**New File**: `Scripts/Autoload/UpgradeManager.gd`

```gdscript
extends Node
## Manages shop upgrades (temporary and permanent)

signal upgrade_purchased(upgrade_id: String)
signal upgrade_applied(upgrade_id: String)
signal temporary_upgrades_cleared()

var active_upgrades: Dictionary = {}  # upgrade_id → ShopUpgrade
var permanent_upgrades: Array[String] = []  # Persists on victory

func purchase_upgrade(upgrade: ShopUpgrade) -> bool:
    # Check if can afford
    var fiat = BitcoinWallet.get_currency_amount(Constants.CurrencyType.FIAT)
    if fiat < upgrade.cost:
        return false
    
    # Deduct cost
    BitcoinWallet.remove_currency(Constants.CurrencyType.FIAT, upgrade.cost)
    
    # Apply upgrade
    active_upgrades[upgrade.upgrade_id] = upgrade
    _apply_upgrade_effect(upgrade)
    
    upgrade_purchased.emit(upgrade.upgrade_id)
    return true

func _apply_upgrade_effect(upgrade: ShopUpgrade) -> void:
    match upgrade.upgrade_type:
        ShopUpgrade.UpgradeType.SPEED_BOOST:
            # Increase player speed
            pass
        ShopUpgrade.UpgradeType.FORTUNE_MULTIPLIER:
            # Apply value multiplier to future ore drops
            pass
        ShopUpgrade.UpgradeType.AUTO_SELLER:
            # Enable auto-sell on ore pickup
            pass
        # ... etc

func clear_temporary_upgrades() -> void:
    # Called on defeat
    for upgrade_id in active_upgrades.keys():
        var upgrade = active_upgrades[upgrade_id]
        if not upgrade.is_permanent:
            active_upgrades.erase(upgrade_id)
    
    temporary_upgrades_cleared.emit()

func save_permanent_upgrades() -> void:
    # Called on victory
    for upgrade_id in active_upgrades.keys():
        var upgrade = active_upgrades[upgrade_id]
        if upgrade.is_permanent and not permanent_upgrades.has(upgrade_id):
            permanent_upgrades.append(upgrade_id)
```

**New File**: `Scripts/Resources/ShopUpgrade.gd`

```gdscript
class_name ShopUpgrade extends Resource
## Defines a shop upgrade

enum UpgradeType {
    SPEED_BOOST,
    FORTUNE_MULTIPLIER,
    AUTO_SELLER,
    SABOTAGE_KIT,
    ORE_SCANNER,
    BETTER_PICKAXE,
    BACKPACK_UPGRADE,
    TOOL_SPEED
}

@export var upgrade_id: String = ""
@export var upgrade_name: String = ""
@export var description: String = ""
@export var cost: float = 100.0
@export var upgrade_type: UpgradeType
@export var is_permanent: bool = false
@export var effect_value: float = 1.0  # Multiplier or amount
```

---

## Phase 5: UI/UX + Polish

### 5.1 Mining HUD

**New File**: `Scenes/UI/MiningHUD.tscn` and `Scripts/UI/MiningHUD.gd`

```gdscript
class_name MiningHUD extends CanvasLayer
## Main HUD for mining game mode

@onready var depth_bar: ProgressBar = %DepthComparisonBar
@onready var player_depth_label: Label = %PlayerDepthLabel
@onready var ai_depth_label: Label = %AIDepthLabel
@onready var ore_counter: Label = %OreCounter
@onready var fiat_label: Label = %FiatLabel
@onready var warning_label: Label = %WarningLabel

func _ready() -> void:
    DepthManager.player_depth_changed.connect(_on_player_depth_changed)
    DepthManager.ai_progress_warning.connect(_on_ai_warning)
    OreInventory.ore_added.connect(_on_ore_added)

func _on_player_depth_changed(depth: int) -> void:
    player_depth_label.text = "Player: %d/20" % depth
    _update_depth_bar()

func _update_depth_bar() -> void:
    var player_progress = DepthManager.get_player_progress()
    var ai_progress = DepthManager.get_ai_progress()
    
    # Visual comparison
    depth_bar.value = player_progress * 100
    # Draw AI progress differently (overlay or second bar)

func _on_ai_warning(stage: int, message: String) -> void:
    warning_label.text = message
    warning_label.modulate = Color.RED if stage >= 85 else Color.ORANGE
    
    # Flash animation
    var tween = create_tween()
    tween.tween_property(warning_label, "modulate:a", 1.0, 0.2)
    tween.tween_interval(1.0)
    tween.tween_property(warning_label, "modulate:a", 0.0, 0.5)

func _on_ore_added(ore_type: OreDetails.OreType, value: float) -> void:
    var total_ores = 0
    for ore_data in OreInventory.get_all_ores().values():
        total_ores += ore_data["count"]
    
    ore_counter.text = "Ores: %d" % total_ores
```

---

### 5.2 Random Events

**New File**: `Scripts/Systems/RandomEventsManager.gd`

```gdscript
extends Node
## Manages random mining events

signal cave_in_triggered(position: Vector2)
signal ore_rush_started()
signal ore_rush_ended()
signal lucky_streak_started()

var active_event: String = ""
var event_timer: Timer

func _ready() -> void:
    event_timer = Timer.new()
    add_child(event_timer)
    event_timer.timeout.connect(_check_random_event)
    event_timer.wait_time = 30.0  # Check every 30s
    event_timer.start()

func _check_random_event() -> void:
    if active_event != "":
        return  # Max 1 event at a time
    
    var rand = randf()
    
    # Cave-in: 5% chance
    if rand < 0.05:
        _trigger_cave_in()
    # Ore Rush: 10% chance (checked every 60s)
    elif rand < 0.15 and event_timer.wait_time >= 60.0:
        _trigger_ore_rush()
    # Lucky Streak: 3% chance (checked every 45s)
    elif rand < 0.18:
        _trigger_lucky_streak()

func _trigger_cave_in() -> void:
    active_event = "cave_in"
    # Collapse random quadrants
    cave_in_triggered.emit(Vector2.ZERO)
    # Clear after instant effect
    await get_tree().create_timer(1.0).timeout
    active_event = ""

func _trigger_ore_rush() -> void:
    active_event = "ore_rush"
    ore_rush_started.emit()
    # 30 second duration
    await get_tree().create_timer(30.0).timeout
    ore_rush_ended.emit()
    active_event = ""

func _trigger_lucky_streak() -> void:
    active_event = "lucky_streak"
    lucky_streak_started.emit()
    # Lasts for next 5 ores
    active_event = ""
```

---

### 5.3 Combo System

Add to `OreInventory.gd`:
```gdscript
var last_ore_type: OreDetails.OreType = OreDetails.OreType.DIRT
var combo_count: int = 0
var combo_multiplier: float = 1.0

func add_ore(ore_type: OreDetails.OreType, value: float) -> void:
    # Check combo
    if ore_type == last_ore_type and ore_type != OreDetails.OreType.DIRT:
        combo_count += 1
        
        # Update multiplier
        if combo_count >= 10:
            combo_multiplier = 3.0
        elif combo_count >= 5:
            combo_multiplier = 2.0
        elif combo_count >= 3:
            combo_multiplier = 1.5
    else:
        # Reset combo
        combo_count = 1
        combo_multiplier = 1.0
        last_ore_type = ore_type
    
    # Apply multiplier to value
    value *= combo_multiplier
    
    # Rest of original function...
```

---

## Testing & Validation

### Phase 1 Testing Checklist
- [ ] Ore blocks spawn with correct distribution at each depth layer
- [ ] Ore health multipliers work (Diamond harder than Dirt)
- [ ] Ore pickups spawn when blocks destroyed
- [ ] Ore pickups auto-collect when player touches them
- [ ] OreInventory tracks ores correctly
- [ ] Ore veins create clusters (40% propagation visible)

### Phase 2 Testing Checklist
- [ ] AI miners spawn and mine downward
- [ ] AI personalities behave distinctly
- [ ] DepthManager tracks player and AI depths correctly
- [ ] Rubber-banding adjusts AI speed based on depth difference
- [ ] Victory triggers when player collects Bitcoin
- [ ] Defeat triggers when AI collects Bitcoin
- [ ] Progress warnings appear at 30%, 60%, 85%

### Phase 3 Testing Checklist
- [ ] Mining tools work (1x1, 2x2, 3x3 areas)
- [ ] Tool cooldowns function correctly
- [ ] Explosive charges destroy large areas
- [ ] Diamond Drill reveals nearby ores
- [ ] Player can switch tools

### Phase 4 Testing Checklist
- [ ] Surface return mechanic works
- [ ] Shop UI displays ores correctly
- [ ] Selling ores adds fiat to wallet
- [ ] Temporary upgrades apply effects
- [ ] Permanent upgrades persist on victory
- [ ] All upgrades clear on defeat (except permanent)

### Phase 5 Testing Checklist
- [ ] HUD shows accurate depth comparison
- [ ] Ore counter updates in real-time
- [ ] AI warnings appear at correct thresholds
- [ ] Random events trigger at correct rates
- [ ] Combo system multiplies values correctly
- [ ] Audio progression matches depth layers
- [ ] Bitcoin proximity ping plays at depth 11-15

---

## Summary

This comprehensive guide provides complete technical specifications for all 5 implementation phases. While **Phase 1 is the current focus**, all systems are documented here for future implementation.

**Phase 1 deliverables** will give you a working ore-based terrain generation system with depth-based spawning, ore pickups, and inventory tracking - a solid foundation for the full mining experience.
