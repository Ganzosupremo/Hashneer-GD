# Mining Game Mode - Technical Implementation Guide

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Core Systems Integration](#core-systems-integration)
3. [Implementation Phases](#implementation-phases)
4. [Detailed Component Specifications](#detailed-component-specifications)
5. [Testing & Validation](#testing--validation)

---

## Architecture Overview

### System Dependencies
```
MiningGameMode (new)
├── QuadrantBuilder (existing - modified)
├── BlockCore (existing - modified)
├── FireWeaponComponent → MiningToolComponent (new - adapted)
├── CurrencyInventory (existing - extended)
├── BitcoinNetwork (existing - hooks)
├── EconomicEventsManager (existing - hooks)
├── ItemDropsSystem (existing - extended)
└── MainEventBus (existing - new signals)
```

### Data Flow
```
Player mines ore → QuadrantBuilder fractures → Ore drops spawn → 
Auto-collect (ItemDropsBus) → Inventory tracks → 
Shop allows selling → Fiat earned → Buy upgrades → 
Find Bitcoin → Level Complete
```

---

## Core Systems Integration

### 1. QuadrantBuilder Adaptation

**File**: `Scripts/QuadrantTerrain/QuadrantBuilder.gd`

**Current Function**: Spawns destructible terrain quadrants with health-based fracturing

**Required Modifications**:

```gdscript
# Add to QuadrantBuilder class

## New ore-based properties
@export_category("Mining Mode")
@export var mining_mode_enabled: bool = false
@export var current_depth_layer: int = 0  # 0-20
@export var ore_spawn_weights: Dictionary = {}  # Populated from LevelBuilderArgs

## Modified initialization
func _initialize_grid_of_blocks(initial_health: float) -> void:
    _quadrant_positions.clear()
    for i in range(grid_size.x):
        for j in range(grid_size.y):
            var cell: Vector2i = Vector2i(i, j)
            if not _is_cell_in_shape(cell):
                continue
            
            var block: FracturableStaticBody2D = _static_body_template.instantiate()
            _quadrant_nodes.add_child(block)
            
            # NEW: Determine ore type based on depth
            var ore_type: OreDetails.OreType = _determine_ore_type(j)
            var ore_data: OreDetails = _get_ore_resource(ore_type)
            
            # Set block properties based on ore type
            block.rectangle_size = Vector2(builder_args.quadrant_size, builder_args.quadrant_size)
            block.placed_in_level = true
            var pos = Vector2(i * quadrant_size.x, j * quadrant_size.y)
            block.position = pos
            _quadrant_positions.append(pos)
            
            # NEW: Use ore-specific health and texture
            var ore_health = initial_health * ore_data.health_multiplier
            block.setFractureBody(ore_health, ore_data.texture, builder_args.normal_texture)
            block.self_modulate = ore_data.ore_color
            
            # Store ore metadata for drop spawning
            block.set_meta("ore_type", ore_type)
            block.set_meta("ore_data", ore_data)

## NEW: Determine ore type based on depth layer
func _determine_ore_type(y_grid_position: int) -> OreDetails.OreType:
    # Calculate depth layer (0-20) based on Y position
    var depth_layer = int((float(y_grid_position) / grid_size.y) * 20.0)
    
    # Get spawn weights for this depth
    var weights = _get_spawn_weights_for_depth(depth_layer)
    
    # Weighted random selection
    return _weighted_random_ore(weights)

## NEW: Get ore spawn weights based on depth layer
func _get_spawn_weights_for_depth(depth: int) -> Dictionary:
    # Returns dictionary like {"DIRT": 0.8, "COAL": 0.15, "IRON": 0.05}
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

## NEW: Weighted random selection
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
    
    return OreDetails.OreType.DIRT  # Fallback
```

**Modified Fracture Method**:
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
    
    # NEW: Spawn ore drops instead of currency drops
    if mining_mode_enabled and other_body.has_meta("ore_type"):
        var ore_type = other_body.get_meta("ore_type")
        var ore_data = other_body.get_meta("ore_data")
        _spawn_ore_drop(other_body.global_position, ore_type, ore_data)
    else:
        other_body.random_drops.spawn_drops(1)  # Original behavior
    
    set_deferred("_fracture_disabled", false)

## NEW: Spawn ore pickup
func _spawn_ore_drop(position: Vector2, ore_type: OreDetails.OreType, ore_data: OreDetails) -> void:
    if ore_type == OreDetails.OreType.DIRT:
        return  # No drops for dirt
    
    var ore_pickup = ore_pickup_scene.instantiate()
    ore_pickup.global_position = position
    ore_pickup.ore_type = ore_type
    ore_pickup.ore_value = ore_data.base_value
    ore_pickup.ore_texture = ore_data.pickup_texture
    get_tree().current_scene.add_child(ore_pickup)
```

---

### 2. Resource Definitions

**New File**: `Scripts/Resources/OreDetails.gd`

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

**New File**: `Scripts/Resources/OrePickupResource.gd`

```gdscript
class_name OrePickupResource extends Resource
## Pickup resource for ore items

@export var ore_type: OreDetails.OreType
@export var ore_value: float
@export var auto_collect: bool = true
@export var magnet_radius: float = 100.0
```

---

### 3. Mining Tool System (Weapon Adaptation)

**File**: `Scripts/Components/MiningToolComponent.gd` (adapted from FireWeaponComponent)

```gdscript
class_name MiningToolComponent extends Node2D
## Handles mining tool mechanics (adapted from FireWeaponComponent)

signal tool_used(tool_data: MiningToolDetails, target_position: Vector2)

@export var active_tool_component: ActiveMiningToolComponent
@export var use_stamina: bool = true
@export var stamina_cost_per_swing: float = 10.0

@onready var tool_swing_position: Marker2D = %ToolSwingPosition
@onready var player_stamina: StaminaComponent = %Stamina

var swing_cooldown_timer: float = 0.0
var current_tool: MiningToolDetails
var quadrant_builder: QuadrantBuilder

func _ready() -> void:
    quadrant_builder = get_tree().get_first_node_in_group("QuadrantBuilder")
    tool_used.connect(on_tool_used)

func _process(delta: float) -> void:
    swing_cooldown_timer -= delta

func on_tool_used(has_swung: bool, target_position: Vector2) -> void:
    if !has_swung or !ready_to_swing():
        return
    
    current_tool = active_tool_component.get_current_tool()
    
    # Check stamina
    if use_stamina and !player_stamina.has_stamina(stamina_cost_per_swing):
        AudioManager.create_audio(SoundEffectDetails.SoundEffectType.NO_STAMINA, 
                                   AudioManager.DestinationAudioBus.SFX)
        return
    
    # Consume stamina
    if use_stamina:
        player_stamina.consume_stamina(stamina_cost_per_swing)
    
    # Perform mining
    _mine_area(target_position)
    reset_cooldown_timer()

func ready_to_swing() -> bool:
    return swing_cooldown_timer <= 0.0

func reset_cooldown_timer() -> void:
    swing_cooldown_timer = current_tool.swing_cooldown

func _mine_area(target_position: Vector2) -> void:
    # Get all quadrants in mining area
    var mining_radius = current_tool.mining_radius
    var mining_area = CircleShape2D.new()
    mining_area.radius = mining_radius
    
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
    AudioManager.create_2d_audio_at_location(target_position, current_tool.swing_sound.sound_type, 
                                             current_tool.swing_sound.destination_audio_bus)
    GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.MINING_IMPACT, 
                                          Transform2D(0, target_position), 
                                          current_tool.swing_effect)
```

**New File**: `Scripts/Resources/MiningToolDetails.gd`

```gdscript
class_name MiningToolDetails extends Resource
## Resource defining mining tool properties

@export_category("Tool Identity")
@export var tool_name: String = "Basic Pickaxe"
@export var tool_texture: Texture2D
@export var tool_icon: Texture2D

@export_category("Mining Properties")
## Number of blocks that can be mined in one swing (1x1, 2x2, 3x3)
@export var mining_area_size: Vector2i = Vector2i(1, 1)
## Radius of mining area in pixels
@export var mining_radius: float = 50.0
## Mining damage per swing
@export var damage: float = 25.0
## Mining power (affects fracture strength)
@export var mining_power: float = 410.0
## Cooldown between swings
@export var swing_cooldown: float = 0.5

@export_category("Stamina")
@export var stamina_cost: float = 10.0

@export_category("Effects")
@export var swing_sound: SoundEffectDetails
@export var swing_effect: VFXEffectProperties

@export_category("Special Abilities")
## Reveals ore types in nearby blocks
@export var has_ore_scanner: bool = false
@export var scanner_radius: float = 0.0

@export_category("Shop Data")
@export var is_permanent: bool = false  # Lost on level failure?
@export var shop_cost: float = 100.0
@export var shop_currency: Constants.CurrencyType = Constants.CurrencyType.FIAT
```

---

### 4. Stamina System

**New File**: `Scripts/Components/StaminaComponent.gd`

```gdscript
class_name StaminaComponent extends Node
## Manages player stamina for mining actions

signal stamina_changed(current: float, max: float)
signal stamina_depleted()
signal stamina_regenerated()

@export var max_stamina: float = 100.0
@export var regen_rate: float = 10.0  # Per second
@export var regen_delay: float = 1.0  # Delay before regen starts

var current_stamina: float = 100.0
var _regen_timer: float = 0.0

func _ready() -> void:
    current_stamina = max_stamina

func _process(delta: float) -> void:
    if current_stamina < max_stamina:
        _regen_timer += delta
        
        if _regen_timer >= regen_delay:
            current_stamina = min(current_stamina + (regen_rate * delta), max_stamina)
            stamina_changed.emit(current_stamina, max_stamina)
            
            if current_stamina >= max_stamina:
                stamina_regenerated.emit()

func has_stamina(amount: float) -> bool:
    return current_stamina >= amount

func consume_stamina(amount: float) -> bool:
    if current_stamina >= amount:
        current_stamina -= amount
        _regen_timer = 0.0  # Reset regen delay
        stamina_changed.emit(current_stamina, max_stamina)
        
        if current_stamina <= 0:
            stamina_depleted.emit()
        
        return true
    return false

func add_stamina(amount: float) -> void:
    current_stamina = min(current_stamina + amount, max_stamina)
    stamina_changed.emit(current_stamina, max_stamina)

func set_max_stamina(new_max: float) -> void:
    max_stamina = new_max
    current_stamina = min(current_stamina, max_stamina)
    stamina_changed.emit(current_stamina, max_stamina)
```

---

### 5. Ore Inventory System

**File**: `Scripts/Player/OreInventory.gd` (extends CurrencyInventory pattern)

```gdscript
class_name OreInventory extends Node
## Tracks collected ores during mining session
## Not implemented in this example, but item stacking can be added.
## For example the inventory has 24 slots and each slot can hold 64 ## items of one Ore.

signal ore_collected(ore_type: OreDetails.OreType, total_count: int)
signal ore_sold(ore_type: OreDetails.OreType, amount_sold: int, fiat_earned: float)
signal inventory_full()

@export var max_inventory_size: int = 100
@export var auto_sell_enabled: bool = false

var _ore_counts: Dictionary = {}  # {OreType: int}
var _total_ore_count: int = 0

func _ready() -> void:
    _initialize_inventory()

func _initialize_inventory() -> void:
    for ore_type in OreDetails.OreType.values():
        _ore_counts[ore_type] = 0

func add_ore(ore_type: OreDetails.OreType, amount: int = 1) -> bool:
    if _total_ore_count >= max_inventory_size:
        inventory_full.emit()
        return false
    
    _ore_counts[ore_type] += amount
    _total_ore_count += amount
    ore_collected.emit(ore_type, _ore_counts[ore_type])
    
    if auto_sell_enabled:
        sell_ore(ore_type, amount)
    
    return true

func sell_ore(ore_type: OreDetails.OreType, amount: int = -1) -> float:
    if amount == -1:
        amount = _ore_counts[ore_type]
    
    amount = min(amount, _ore_counts[ore_type])
    if amount <= 0:
        return 0.0
    
    var ore_data = _get_ore_data(ore_type)
    var depth_layer = MiningGameManager.get_current_depth_layer()
    var value_per_ore = ore_data.get_value_at_depth(depth_layer)
    var total_fiat = value_per_ore * amount
    
    # Apply economic event modifiers
    total_fiat *= EconomicEventsManager.get_ore_price_multiplier()
    
    _ore_counts[ore_type] -= amount
    _total_ore_count -= amount
    
    # Add to wallet
    BitcoinNetwork.wallet.add_fiat(total_fiat)
    
    ore_sold.emit(ore_type, amount, total_fiat)
    return total_fiat

func sell_all_ores() -> float:
    var total_fiat = 0.0
    for ore_type in _ore_counts.keys():
        total_fiat += sell_ore(ore_type)
    return total_fiat

func get_ore_count(ore_type: OreDetails.OreType) -> int:
    return _ore_counts.get(ore_type, 0)

func get_total_ore_count() -> int:
    return _total_ore_count

func get_inventory_space_remaining() -> int:
    return max_inventory_size - _total_ore_count
```

---

### 6. AI Competitor System

**New File**: `Scripts/MiningMode/AICompetitor.gd`

```gdscript
class_name MiningAICompetitor extends Node
## Simulates AI miners competing to find Bitcoin

signal progress_updated(competitor_name: String, progress_percent: float)
signal milestone_reached(competitor_name: String, depth: int)
signal competitor_won(competitor_name: String)

@export var competitor_name: String = "Satoshi AI"
@export var base_mining_speed: float = 1.0  # Depth layers per second
@export var difficulty_scaling: float = 0.1  # Speed increase per game level

var _current_depth: float = 0.0
var _target_depth: float = 20.0  # Bitcoin zone
var _mining_active: bool = false
var _level_multiplier: float = 1.0

func _ready() -> void:
    _level_multiplier = 1.0 + (GameManager.get_level_index() * difficulty_scaling)

func start_mining() -> void:
    _mining_active = true
    _current_depth = 0.0

func stop_mining() -> void:
    _mining_active = false

func _process(delta: float) -> void:
    if not _mining_active:
        return
    
    # Apply rubber-banding
    var speed_modifier = _calculate_speed_modifier()
    var effective_speed = base_mining_speed * _level_multiplier * speed_modifier
    
    _current_depth += effective_speed * delta
    
    var progress_percent = (_current_depth / _target_depth) * 100.0
    progress_updated.emit(competitor_name, progress_percent)
    
    # Check milestones
    var depth_layer = int(_current_depth)
    if depth_layer % 5 == 0 and depth_layer > 0:
        milestone_reached.emit(competitor_name, depth_layer)
    
    # Check if reached Bitcoin zone and found it
    if _current_depth >= _target_depth:
        _check_bitcoin_discovery()

func _calculate_speed_modifier() -> float:
    var player_depth = MiningGameManager.get_player_depth()
    var depth_difference = _current_depth - player_depth
    
    # Rubber-banding logic
    if depth_difference > 5.0:  # AI way ahead
        return 0.7  # Slow down 30%
    elif depth_difference < -5.0:  # Player way ahead
        return 1.2  # Speed up 20%
    else:
        return 1.0  # Normal speed

func _check_bitcoin_discovery() -> void:
    # Random chance to find Bitcoin once in zone
    var discovery_chance = 0.02  # 2% per frame in zone
    if randf() < discovery_chance:
        competitor_won.emit(competitor_name)
        _mining_active = false

func get_progress_percent() -> float:
    return (_current_depth / _target_depth) * 100.0
```

**New File**: `Scripts/MiningMode/AICompetitorManager.gd`

```gdscript
class_name AICompetitorManager extends Node
## Manages multiple AI competitors

@export var competitor_names: Array[String] = ["Satoshi AI", "Hash Hunter", "Block Breaker"]
@export var base_mining_speed: float = 0.5

var _competitors: Array[MiningAICompetitor] = []

func _ready() -> void:
    _initialize_competitors()

func _initialize_competitors() -> void:
    for comp_name in competitor_names:
        var competitor = MiningAICompetitor.new()
        competitor.competitor_name = comp_name
        competitor.base_mining_speed = base_mining_speed
        competitor.progress_updated.connect(_on_competitor_progress)
        competitor.milestone_reached.connect(_on_competitor_milestone)
        competitor.competitor_won.connect(_on_competitor_won)
        add_child(competitor)
        _competitors.append(competitor)

func start_all_competitors() -> void:
    for competitor in _competitors:
        competitor.start_mining()

func stop_all_competitors() -> void:
    for competitor in _competitors:
        competitor.stop_mining()

func _on_competitor_progress(comp_name: String, progress: float) -> void:
    # Update UI progress bars
    MiningGameUI.update_competitor_progress(comp_name, progress)

func _on_competitor_milestone(comp_name: String, depth: int) -> void:
    # Show notification
    NotificationManager.show_notification("%s reached depth %d!" % [comp_name, depth])
    AudioManager.create_audio(SoundEffectDetails.SoundEffectType.AI_MILESTONE, 
                               AudioManager.DestinationAudioBus.SFX)

func _on_competitor_won(comp_name: String) -> void:
    stop_all_competitors()
    MiningGameManager.ai_competitor_won(comp_name)

func get_leading_competitor() -> Dictionary:
    var leading = {"name": "", "progress": 0.0}
    for competitor in _competitors:
        var progress = competitor.get_progress_percent()
        if progress > leading.progress:
            leading.name = competitor.competitor_name
            leading.progress = progress
    return leading
```

---

### 7. Level Shop System

**New File**: `Scripts/MiningMode/MiningShop.gd`

```gdscript
class_name MiningShop extends Control
## Shop for mining upgrades during gameplay

signal upgrade_purchased(upgrade_id: String, is_permanent: bool)

@export var shop_items: Array[ShopItemData] = []

var _permanent_items: Array[ShopItemData] = []
var _temporary_items: Array[ShopItemData] = []

func _ready() -> void:
    _categorize_shop_items()
    _populate_shop_ui()

func _categorize_shop_items() -> void:
    for item in shop_items:
        if item.is_permanent:
            _permanent_items.append(item)
        else:
            _temporary_items.append(item)

func purchase_item(item: ShopItemData) -> bool:
    if not BitcoinNetwork.wallet.can_afford_fiat(item.cost):
        NotificationManager.show_notification("Not enough Fiat!")
        return false
    
    BitcoinNetwork.wallet.spend_fiat(item.cost)
    _apply_upgrade(item)
    upgrade_purchased.emit(item.item_id, item.is_permanent)
    
    # Mark as purchased
    item.purchased_this_session = true
    _refresh_shop_ui()
    
    return true

func _apply_upgrade(item: ShopItemData) -> void:
    match item.upgrade_type:
        ShopItemData.UpgradeType.MINING_TOOL:
            PlayerStatsManager.equip_mining_tool(item.tool_data)
        ShopItemData.UpgradeType.STAMINA_MAX:
            GameManager.player.stamina.set_max_stamina(
                GameManager.player.stamina.max_stamina + item.upgrade_value
            )
        ShopItemData.UpgradeType.STAMINA_REGEN:
            GameManager.player.stamina.regen_rate += item.upgrade_value
        ShopItemData.UpgradeType.BACKPACK_SIZE:
            GameManager.player.ore_inventory.max_inventory_size += int(item.upgrade_value)
        ShopItemData.UpgradeType.FORTUNE_MULTIPLIER:
            MiningGameManager.add_fortune_multiplier(item.upgrade_value)
        ShopItemData.UpgradeType.AUTO_SELLER:
            GameManager.player.ore_inventory.auto_sell_enabled = true
        ShopItemData.UpgradeType.AI_SLOW:
            MiningGameManager.slow_ai_competitors(item.upgrade_value, item.duration)

func reset_temporary_items() -> void:
    for item in _temporary_items:
        item.purchased_this_session = false
    _refresh_shop_ui()

func clear_purchased_permanents() -> void:
    for item in _permanent_items:
        item.purchased_this_session = false
```

**New File**: `Scripts/Resources/ShopItemData.gd`

```gdscript
class_name ShopItemData extends Resource
## Data for shop upgrades

enum UpgradeType {
    MINING_TOOL,
    STAMINA_MAX,
    STAMINA_REGEN,
    BACKPACK_SIZE,
    FORTUNE_MULTIPLIER,
    AUTO_SELLER,
    AI_SLOW,
    ORE_SCANNER
}

@export var item_id: String
@export var item_name: String
@export var item_description: String
@export var item_icon: Texture2D
@export var upgrade_type: UpgradeType
@export var cost: float
@export var is_permanent: bool = false
@export var upgrade_value: float = 0.0
@export var duration: float = 0.0  # For temporary effects
@export var tool_data: MiningToolDetails  # For tool upgrades

var purchased_this_session: bool = false
```

---

### 8. Main Game Mode Controller

**New File**: `Scripts/MiningGameMode.gd` (extends existing pattern)

```gdscript
extends Node2D
class_name MiningGameModeController

@export var level_args: LevelBuilderArgs
@export var main_event_bus: MainEventBus
@export var music: MusicDetails

@onready var _quadrant_builder: QuadrantBuilder = %QuadrantBuilder
@onready var _ai_competitor_manager: AICompetitorManager = %AICompetitorManager
@onready var _mining_shop: MiningShop = %MiningShop
@onready var _mining_hud: MiningHUD = %MiningHUD

var _fortune_multiplier: float = 1.0
var _player_depth_layer: int = 0

func _ready() -> void:
    AudioManager.change_music_clip(music)
    level_args = GameManager.get_level_args()
    
    # Enable mining mode on QuadrantBuilder
    _quadrant_builder.mining_mode_enabled = true
    
    # Start AI competitors
    _ai_competitor_manager.start_all_competitors()
    
    # Connect signals
    GameManager.player.ore_inventory.ore_collected.connect(_on_ore_collected)
    main_event_bus.level_completed.connect(_on_level_completed)

func _process(_delta: float) -> void:
    _update_player_depth()
    _check_bitcoin_found()

func _update_player_depth() -> void:
    var player_y = GameManager.player.global_position.y
    var grid_height = _quadrant_builder.grid_size.y * _quadrant_builder.quadrant_size.y
    _player_depth_layer = int((player_y / grid_height) * 20.0)
    _mining_hud.update_depth_display(_player_depth_layer)

func _check_bitcoin_found() -> void:
    if GameManager.player.ore_inventory.get_ore_count(OreDetails.OreType.BITCOIN_ORE) > 0:
        _complete_level_victory()

func _complete_level_victory() -> void:
    _ai_competitor_manager.stop_all_competitors()
    
    # Calculate bonuses
    var ai_progress = _ai_competitor_manager.get_leading_competitor().progress
    var is_perfect_run = ai_progress < 50.0
    
    # Award bonuses
    if is_perfect_run:
        var bonus = 500.0 * (1.0 + GameManager.get_level_index())
        BitcoinNetwork.wallet.add_fiat(bonus)
        NotificationManager.show_notification("Perfect Run Bonus! +%.2f Fiat" % bonus)
    
    main_event_bus.emit_level_completed(Constants.ERROR_200)

func ai_competitor_won(comp_name: String) -> void:
    NotificationManager.show_notification("%s found the Bitcoin first!" % comp_name)
    AudioManager.create_audio(SoundEffectDetails.SoundEffectType.LEVEL_FAILED, 
                               AudioManager.DestinationAudioBus.SFX)
    
    # Sell remaining ores
    var fiat_earned = GameManager.player.ore_inventory.sell_all_ores()
    
    # Clear shop upgrades
    _mining_shop.reset_temporary_items()
    _mining_shop.clear_purchased_permanents()
    
    main_event_bus.emit_level_completed(Constants.ERROR_401)

func slow_ai_competitors(slow_amount: float, duration: float) -> void:
    for competitor in _ai_competitor_manager._competitors:
        competitor.base_mining_speed *= (1.0 - slow_amount)
    
    await get_tree().create_timer(duration).timeout
    
    for competitor in _ai_competitor_manager._competitors:
        competitor.base_mining_speed /= (1.0 - slow_amount)

func add_fortune_multiplier(multiplier: float) -> void:
    _fortune_multiplier += multiplier

func get_player_depth() -> int:
    return _player_depth_layer

func _on_ore_collected(ore_type: OreDetails.OreType, total_count: int) -> void:
    _mining_hud.update_ore_count(ore_type, total_count)
    
    # Special audio for rare ores
    if ore_type in [OreDetails.OreType.GOLD, OreDetails.OreType.EMERALD, 
                     OreDetails.OreType.DIAMOND, OreDetails.OreType.BITCOIN_ORE]:
        AudioManager.create_audio(SoundEffectDetails.SoundEffectType.RARE_ORE_FOUND, 
                                   AudioManager.DestinationAudioBus.SFX)

func _on_level_completed(_args: MainEventBus.LevelCompletedArgs) -> void:
    _ai_competitor_manager.stop_all_competitors()
```

---

## Implementation Phases

### Phase 1: Core Foundation (Week 1-2)
**Goal**: Get basic ore mining working

1. **Create Ore Resource System**
   - [ ] Create `OreDetails.gd` resource
   - [ ] Create 9 ore type resources (Dirt → Bitcoin)
   - [ ] Design ore textures/colors
   - [ ] Set up ore spawn weights

2. **Modify QuadrantBuilder**
   - [ ] Add `mining_mode_enabled` flag
   - [ ] Implement `_determine_ore_type()` 
   - [ ] Implement `_get_spawn_weights_for_depth()`
   - [ ] Modify `_initialize_grid_of_blocks()` for ore metadata
   - [ ] Test depth-based ore spawning

3. **Create Ore Pickup System**
   - [ ] Create `OrePickupResource.gd`
   - [ ] Create ore pickup scene with auto-collect
   - [ ] Modify `fracture_quadrant_on_collision()` to spawn ore drops
   - [ ] Test ore drops on block destruction

4. **Create Ore Inventory**
   - [ ] Create `OreInventory.gd` component
   - [ ] Implement `add_ore()`, `sell_ore()`, `sell_all_ores()`
   - [ ] Add to Player scene
   - [ ] Test ore collection and selling

**Testing Checkpoint**: Player can mine blocks of different ore types, collect ores automatically, and see them in inventory

---

### Phase 2: Mining Tools & Stamina (Week 2-3)

1. **Stamina System**
   - [ ] Create `StaminaComponent.gd`
   - [ ] Add to Player scene
   - [ ] Create stamina UI bar
   - [ ] Test stamina consumption and regeneration

2. **Mining Tool System**
   - [ ] Create `MiningToolDetails.gd` resource
   - [ ] Create 4 tool types (Pickaxe, Iron Drill, Diamond Drill, Explosives)
   - [ ] Create `MiningToolComponent.gd` (adapt FireWeaponComponent)
   - [ ] Create `ActiveMiningToolComponent.gd` (adapt ActiveWeaponComponent)
   - [ ] Implement area-based mining (1x1, 2x2, 3x3)

3. **Player Integration**
   - [ ] Replace weapon firing with mining tool usage
   - [ ] Connect stamina to mining actions
   - [ ] Add tool switching controls
   - [ ] Test different mining areas

**Testing Checkpoint**: Player uses different mining tools with stamina costs, can switch tools, and mines different area sizes

---

### Phase 3: AI Competitors (Week 3-4)

1. **AI Competitor System**
   - [ ] Create `AICompetitor.gd`
   - [ ] Implement depth progression logic
   - [ ] Create `AICompetitorManager.gd`
   - [ ] Add 3 AI competitors with different names

2. **AI Behavior**
   - [ ] Implement rubber-banding speed modifier
   - [ ] Add milestone notifications
   - [ ] Implement Bitcoin discovery chance
   - [ ] Test AI pacing

3. **Competition UI**
   - [ ] Create AI progress bars
   - [ ] Add depth comparison display
   - [ ] Implement warning messages
   - [ ] Add notification popups

**Testing Checkpoint**: AI competitors mine alongside player, progress bars update, player receives warnings, AI can win

---

### Phase 4: Shop System (Week 4-5)

1. **Shop Data Structure**
   - [ ] Create `ShopItemData.gd`
   - [ ] Define all shop items (tools, upgrades, consumables)
   - [ ] Create shop item resources

2. **Shop UI**
   - [ ] Create `MiningShop.gd` scene
   - [ ] Design shop layout (permanent vs temporary tabs)
   - [ ] Implement purchase logic
   - [ ] Add cost display and currency checking

3. **Shop Upgrades**
   - [ ] Implement stamina upgrades
   - [ ] Implement backpack size upgrades
   - [ ] Implement Fortune Multiplier
   - [ ] Implement Auto-Seller
   - [ ] Implement AI slowdown sabotage

4. **Shop Persistence**
   - [ ] Save permanent upgrades on victory
   - [ ] Clear upgrades on defeat
   - [ ] Test upgrade carry-over between levels

**Testing Checkpoint**: Shop opens, player can buy upgrades, permanent upgrades persist, temporary upgrades reset

---

### Phase 5: Game Mode Integration (Week 5-6)

1. **Mining Game Mode Controller**
   - [ ] Create `MiningGameMode.gd` scene
   - [ ] Integrate QuadrantBuilder
   - [ ] Add AI Competitor Manager
   - [ ] Add Shop system

2. **HUD & UI**
   - [ ] Create `MiningHUD.gd`
   - [ ] Add ore counter display
   - [ ] Add depth indicator
   - [ ] Add AI progress comparison
   - [ ] Add stamina bar

3. **Win/Loss Conditions**
   - [ ] Implement Bitcoin found → Victory
   - [ ] Implement AI finds Bitcoin → Defeat
   - [ ] Create victory screen
   - [ ] Create defeat screen
   - [ ] Calculate bonuses (speed, perfect run, collection)

4. **Level Progression**
   - [ ] Connect to level select
   - [ ] Implement difficulty scaling across game levels
   - [ ] Test level progression flow

**Testing Checkpoint**: Full mining game mode playable from start to finish with all systems integrated

---

### Phase 6: Polish & Balance (Week 6-7)

1. **Audio**
   - [ ] Add unique mining sounds per ore type
   - [ ] Add rare ore "ding" sound
   - [ ] Implement dynamic music (calm → urgent)
   - [ ] Add AI milestone audio stings

2. **Visual Effects**
   - [ ] Ore-specific particle effects
   - [ ] Mining impact VFX
   - [ ] Bitcoin discovery celebration VFX
   - [ ] AI milestone screen shake

3. **Balance Tuning**
   - [ ] Adjust ore spawn rates per depth
   - [ ] Balance tool damage/costs
   - [ ] Tune AI mining speed
   - [ ] Balance shop prices
   - [ ] Adjust stamina costs/regen

4. **Special Features**
   - [ ] Implement ore vein system (clustered spawns)
   - [ ] Add random events (ore rush, cave-ins)
   - [ ] Create ore scanner tool ability
   - [ ] Add combo system for consecutive same-ore mining

**Testing Checkpoint**: Game feels polished, balanced, and fun to play repeatedly

---

## Testing & Validation

### Unit Tests
```gdscript
# test_ore_spawning.gd
func test_depth_layer_spawn_weights():
    var builder = QuadrantBuilder.new()
    
    # Test surface layer (0-5)
    var weights_surface = builder._get_spawn_weights_for_depth(3)
    assert(weights_surface[OreDetails.OreType.DIRT] == 0.80)
    assert(weights_surface[OreDetails.OreType.COAL] == 0.15)
    
    # Test Bitcoin zone (16-20)
    var weights_bitcoin = builder._get_spawn_weights_for_depth(18)
    assert(weights_bitcoin.has(OreDetails.OreType.BITCOIN_ORE))
    assert(weights_bitcoin[OreDetails.OreType.BITCOIN_ORE] == 0.01)

# test_ai_competitors.gd
func test_rubber_banding():
    var ai = MiningAICompetitor.new()
    ai._current_depth = 15.0
    
    # Player way behind
    MiningGameManager._player_depth_layer = 5
    var modifier_slow = ai._calculate_speed_modifier()
    assert(modifier_slow < 1.0, "AI should slow when ahead")
    
    # Player way ahead
    MiningGameManager._player_depth_layer = 18
    var modifier_fast = ai._calculate_speed_modifier()
    assert(modifier_fast > 1.0, "AI should speed up when behind")
```

### Integration Tests
1. **Full Game Loop Test**
   - Start mining mode
   - Mine down to depth 15
   - Collect various ores
   - Purchase shop upgrade
   - Find Bitcoin
   - Complete level
   - Verify upgrade persists

2. **AI Competition Test**
   - Start mining slowly
   - Verify AI speeds up
   - Verify AI slows down when player catches up
   - Let AI win
   - Verify defeat screen shows

3. **Shop Persistence Test**
   - Buy permanent upgrade
   - Complete level successfully
   - Start next level
   - Verify upgrade still active
   - Lose level
   - Verify upgrade cleared

---

## Performance Considerations

### Optimization Targets
- **Ore Pickup Pool**: Reuse pickup instances (max 200 active)
- **AI Update Rate**: Update every 0.1s instead of every frame
- **Inventory Updates**: Batch UI updates (every 0.5s)
- **Quadrant Culling**: Only process visible quadrants

### Memory Management
```gdscript
# OrePickup pooling
class_name OrePickupPool extends Node

var _pool: Array[OrePickup] = []
var _active_pickups: Array[OrePickup] = []
const MAX_POOL_SIZE = 200

func get_pickup() -> OrePickup:
    if _pool.is_empty():
        if _active_pickups.size() >= MAX_POOL_SIZE:
            return null  # Pool exhausted
        return OrePickup.new()
    return _pool.pop_back()

func return_pickup(pickup: OrePickup) -> void:
    _active_pickups.erase(pickup)
    _pool.append(pickup)
    pickup.hide()
```

---

## Constants & Enums

**Add to `Scripts/Utils/Constants.gd`**:
```gdscript
enum MiningToolType {
    BASIC_PICKAXE,
    IRON_DRILL,
    DIAMOND_DRILL,
    EXPLOSIVE_CHARGE
}

# Add to existing ERROR codes
const ERROR_401 = "Code 401: AI Competitor found the Bitcoin first!"

# Mining mode constants
const MINING_MAX_DEPTH_LAYERS: int = 20
const MINING_BITCOIN_ZONE_START: int = 16
```

---

## File Structure Summary

```
Scripts/
├── MiningMode/
│   ├── MiningGameMode.gd (main controller)
│   ├── AICompetitor.gd
│   ├── AICompetitorManager.gd
│   ├── MiningShop.gd
│   └── MiningHUD.gd
├── Components/
│   ├── MiningToolComponent.gd (adapted from FireWeaponComponent)
│   ├── ActiveMiningToolComponent.gd
│   ├── StaminaComponent.gd
│   └── OreInventory.gd
├── Resources/
│   ├── OreDetails.gd
│   ├── OrePickupResource.gd
│   ├── MiningToolDetails.gd
│   └── ShopItemData.gd
└── QuadrantTerrain/
    └── QuadrantBuilder.gd (modified)

Resources/
└── Mining/
    ├── Ores/
    │   ├── Dirt.tres
    │   ├── Coal.tres
    │   ├── Iron.tres
    │   ├── Copper.tres
    │   ├── Silver.tres
    │   ├── Gold.tres
    │   ├── Emerald.tres
    │   ├── Diamond.tres
    │   └── BitcoinOre.tres
    ├── Tools/
    │   ├── BasicPickaxe.tres
    │   ├── IronDrill.tres
    │   ├── DiamondDrill.tres
    │   └── ExplosiveCharge.tres
    └── ShopItems/
        └── [various shop item .tres files]

Scenes/
└── MiningMode/
    ├── MiningGameMode.tscn
    ├── MiningShop.tscn
    ├── MiningHUD.tscn
    ├── OrePickup.tscn
    └── AICompetitorUI.tscn
```

---

## Next Steps After Implementation

1. **Playtesting**
   - Internal testing for balance
   - Difficulty curve validation
   - Shop pricing adjustments

2. **Additional Features** (Post-MVP)
   - Ore vein system for clustered spawns
   - Random events (ore rush, cave-ins)
   - Leaderboards for fastest Bitcoin finds
   - Daily challenges

3. **Integration with Existing Systems**
   - Link shop purchases to skill tree
   - Economic events affect ore prices
   - Bitcoin network integration for mining Bitcoin ore

---

**End of Technical Implementation Guide**
