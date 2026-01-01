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

var _world_generator_scene: PackedScene = preload("res://Scenes/MiningGameMode/MiningWorldGenerator.tscn")
var _world_generator: MiningWorldGenerator
var _fracture_manager: PackedScene = preload("res://Scenes/FracturableTerrain/FractureManager.tscn")
var _builder_args: WorldGenArgs
var _terrain_block_template: PackedScene = preload("res://Scenes/MiningGameMode/TerrainBlock.tscn")

func _ready() -> void:
        AudioManager.change_music_clip(music)
        _builder_args = GameManager.get_level_args()
                
        if not _builder_args:
                push_warning("MiningGameMode: No level args found, using exported defaults")
                _builder_args = WorldGenArgs.new()
                _builder_args.quadrant_size = quadrant_size.x
                _builder_args.grid_size = grid_size
                _builder_args.initial_health = 100.0
        else:
                if _builder_args.grid_size.x <= 0 or _builder_args.grid_size.y <= 0:
                        push_warning("MiningGameMode: Level args has invalid grid_size, using exported defaults")
                        _builder_args.grid_size = grid_size
                if _builder_args.quadrant_size <= 0:
                        push_warning("MiningGameMode: Level args has invalid quadrant_size, using exported defaults")
                        _builder_args.quadrant_size = quadrant_size.x
                                
        _setup_fracture_manager()
        _setup_world_generator()
        _generate_world()
        #_setup_camera_limits()
        _position_player()

func _setup_fracture_manager() -> void:
        var fracture_manager_ins: FractureManager = _fracture_manager.instantiate()
        add_child(fracture_manager_ins)
        fracture_manager_ins.add_to_group("FractureManager")

                #await fracture_manager_ins.ready

        fracture_manager_ins.fracture_body_color = fracture_body_color
        fracture_manager_ins.pool_cut_visualizer = _pool_cut_visualizer
        fracture_manager_ins.pool_fracture_shards = _pool_fracture_shards
        fracture_manager_ins.pool_fracture_bodies = _pool_fracture_bodies
        fracture_manager_ins.rigid_bodies_parent = _rigid_bodies_parent
        fracture_manager_ins.terrain_block_template = _terrain_block_template
        fracture_manager_ins.mining_mode_enabled = true
        fracture_manager_ins.digital_ambiance = _digital_ambiance
        fracture_manager_ins.initialize(_builder_args.initial_health)
                                
        _quadrant_nodes.modulate = fracture_manager_ins.get_fracture_color()
                                
        GameManager.set_fracture_manager(fracture_manager_ins)

func _setup_world_generator() -> void:
        _world_generator = _world_generator_scene.instantiate()
        add_child(_world_generator)
                #await _world_generator_scene.ready
        
        _world_generator.quadrant_size = Vector2i(_builder_args.quadrant_size, _builder_args.quadrant_size)
        _world_generator.grid_size = _builder_args.grid_size
        _world_generator.terrain_block_template = _terrain_block_template
        _world_generator.quadrant_nodes_parent = _quadrant_nodes
        _world_generator.shop_layer = _shop_layer
        _world_generator.digital_ambiance = _digital_ambiance
        _world_generator.ores_dictionary = ores_dictionary
                                
        if depth_config:
                _world_generator.depth_config = depth_config

func _generate_world() -> void:
        _quadrant_nodes.position = Vector2.ZERO
        _rigid_bodies_parent.position = Vector2.ZERO
                                
        _world_generator.generate_world(_builder_args)
                
func _setup_camera_limits() -> void:
        var map_bounds: Rect2 = _world_generator.get_map_bounds()
        if map_bounds.size == Vector2.ZERO:
                return
                                
        var camera: AdvanceCamera = $AdvancedCamera
        if camera:
                camera.limit_left = int(map_bounds.position.x)
                camera.limit_right = int(map_bounds.end.x)
                camera.limit_top = int(map_bounds.position.y)
                camera.limit_bottom = int(map_bounds.end.y)

func _position_player() -> void:
        var spawn_x: int = int(_builder_args.grid_size.x / 2)
        var surface_y: int = _world_generator.get_surface_height_at(spawn_x)
        var spawn_pos: Vector2 = Vector2(
                spawn_x * _builder_args.quadrant_size + _builder_args.quadrant_size / 2,
                (surface_y - 2) * _builder_args.quadrant_size + _builder_args.quadrant_size / 2
        )
        _player.global_position = spawn_pos

func _on_terminate_button_pressed() -> void:
        GameManager.emit_level_completed(Constants.ERROR_210)
