extends Node2D
## Mining Game Mode controller that orchestrates world generation and fracturing.
##
## This script coordinates the MiningWorldGenerator, FractureManager, and other
## components to create the mining gameplay experience.

@export_category("Level Configuration")
@export var music: MusicDetails

@export_category("World Generation")
@export var quadrant_size: Vector2i = Vector2i(25, 25)
@export var grid_size: Vector2i = Vector2i(32, 32)
@export var shop_layer_height: float = 500.0
@export var generate_borders: bool = true

@export_category("Mining Configuration")
@export var depth_config: MiningDepthConfig
@export var ores_dictionary: Dictionary = {
        OreDetails.OreType.DIRT: preload("res://Resources/Ores/Dirt.tres"),
        OreDetails.OreType.COAL: preload("res://Resources/Ores/Coal.tres"),
        OreDetails.OreType.IRON: preload("res://Resources/Ores/Iron.tres"),
        OreDetails.OreType.COPPER: preload("res://Resources/Ores/Copper.tres"),
        OreDetails.OreType.SILVER: preload("res://Resources/Ores/Silver.tres"),
        OreDetails.OreType.GOLD: preload("res://Resources/Ores/Gold.tres"),
        OreDetails.OreType.DIAMOND: preload("res://Resources/Ores/Diamond.tres"),
        OreDetails.OreType.EMERALD: preload("res://Resources/Ores/Emerald.tres"),
        OreDetails.OreType.BITCOIN_ORE: preload("res://Resources/Ores/Bitcoin.tres")
}

@export_category("Fracture Settings")
@export var fracture_body_color: Color = Color.WHITE

@onready var player_bullets_pool: PoolFracture = $PlayerBulletsPool
@onready var _shop_layer: ShopLayer = %ShopLayer
@onready var _world_borders: WorldBorders = %WorldBorders
@onready var _digital_ambiance: DigitalAmbiance = %DigitalAmbience
@onready var _quadrant_nodes: Node2D = %Quadrants
@onready var _rigid_bodies_parent: Node2D = %RigidBodiesParent
@onready var _player: PlayerController = %Player
@onready var _pool_cut_visualizer: PoolFracture = $PoolFractureCutVisualizer
@onready var _pool_fracture_shards: PoolFracture = $PoolFractureShards
@onready var _pool_fracture_bodies: PoolFracture = $Pool_FractureBodies

var _world_generator: MiningWorldGenerator
var _fracture_manager: FractureManager
var _builder_args: LevelBuilderArgs
var _terrain_block_template: PackedScene = preload("res://Scenes/MiningGameModeTerrainBlock/TerrainBlock.tscn")

func _ready() -> void:
        AudioManager.change_music_clip(music)
        _builder_args = GameManager.get_level_args()
        
        await _setup_fracture_manager()
        await _setup_world_generator()
        _generate_world()
        _setup_camera_limits()
        _position_player()

func _setup_fracture_manager() -> void:
        _fracture_manager = FractureManager.new()
        _fracture_manager.name = "FractureManager"
        add_child(_fracture_manager)
        _fracture_manager.add_to_group("FractureManager")
        
        await _fracture_manager.ready
        
        _fracture_manager.fracture_body_color = fracture_body_color
        _fracture_manager.pool_cut_visualizer = _pool_cut_visualizer
        _fracture_manager.pool_fracture_shards = _pool_fracture_shards
        _fracture_manager.pool_fracture_bodies = _pool_fracture_bodies
        _fracture_manager.rigid_bodies_parent = _rigid_bodies_parent
        _fracture_manager.terrain_block_template = _terrain_block_template
        _fracture_manager.mining_mode_enabled = true
        _fracture_manager.digital_ambiance = _digital_ambiance
        _fracture_manager.initialize(_builder_args.initial_health)
        
        _quadrant_nodes.modulate = _fracture_manager.get_fracture_color()
        
        GameManager.set_fracture_manager(_fracture_manager)

func _setup_world_generator() -> void:
        _world_generator = MiningWorldGenerator.new()
        _world_generator.name = "MiningWorldGenerator"
        add_child(_world_generator)
        
        await _world_generator.ready
        
        _world_generator.quadrant_size = Vector2i(_builder_args.quadrant_size, _builder_args.quadrant_size)
        _world_generator.grid_size = _builder_args.grid_size
        _world_generator.terrain_block_template = _terrain_block_template
        _world_generator.quadrant_nodes_parent = _quadrant_nodes
        _world_generator.shop_layer = _shop_layer
        _world_generator.world_borders = _world_borders
        _world_generator.digital_ambiance = _digital_ambiance
        _world_generator.shop_layer_height = shop_layer_height
        _world_generator.ores_dictionary = ores_dictionary
        
        if depth_config:
                _world_generator.depth_config = depth_config

func _generate_world() -> void:
        _quadrant_nodes.position = Vector2.ZERO
        _rigid_bodies_parent.position = Vector2.ZERO
        
        _world_generator.generate_world(_builder_args)

func _setup_camera_limits() -> void:
        if not _world_borders:
                return
        
        var mining_bounds: Rect2 = _world_borders.get_mining_bounds()
        var shop_bounds: Rect2 = _world_borders.get_shop_layer_bounds()
        
        var camera: AdvanceCamera = $AdvancedCamera
        if camera:
                camera.limit_left = int(mining_bounds.position.x)
                camera.limit_right = int(mining_bounds.end.x)
                camera.limit_top = int(shop_bounds.position.y)
                camera.limit_bottom = int(mining_bounds.end.y)

func _position_player() -> void:
        if _shop_layer:
                _player.global_position = _shop_layer.get_player_spawn_position()

func _on_terminate_button_pressed() -> void:
        GameManager.emit_level_completed(Constants.ERROR_210)
