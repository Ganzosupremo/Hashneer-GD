extends Resource
class_name LevelBuilderArgs
## Holds the arguments for the Level
## This is used to create the QuadrantBuilder or set the level waves parameters
@export var debug_name: String = ""
## The size of the quadrants in pixels
@export_category("Quadrant Builder Parameters")
@export var quadrant_size: int = 200
## The size of the grid in quadrants
@export var grid_size: Vector2 = Vector2(6, 6)
## Shape of the map grid
@export var map_shape: Constants.MapShape = Constants.MapShape.Square
## The texture used to draw the quadrants
@export var quadrant_texture: Texture2D
## The texture used to draw the quadrants when they are fractured
@export var normal_texture: Texture2D
## Sound effect to play when the quadrant is fractured
@export var hit_sound: SoundEffectDetails

## The initial health of the quadrants
@export var initial_health: float = 50.0
## The drop rate of the fiat resource
@export var fiat_drop_rate_factor: float = 1.0
## The index of the level
var level_index: int = 0

@export_category("Block Core Parameters")
## The amount of cuts to make in the block core
## This is used to determine how many cuts to make in the block core
## The cuts are made using the Delaunay triangulation algorithm
@export var block_core_cuts_delaunay: int = 200
## The minimum area of the cuts in pixels
## This is used to determine if the cut is valid or not
## If the area is too small, the cut will be ignored.
@export var block_core_cut_min_area: float = 100.0

@export_category("Wave Levels Parameters")
## The time between each wave
@export var spawn_time: float = 5.0
## The amount of enemies to spawn per wave
@export var spawn_count: int = 5
## This is used to determine how many drops the enemies will drop
@export var enemy_drops_count: int = 5
## This value will exponentially multiply the damage of the enemies
@export var enemy_damage_multiplier: float = 1.3
## The drops table used to determine the type of enemies to spawn
## for each level
@export var enemies_drop_table: DropsTable
## The drops table used to determine the boss type
## for each level
@export var boss_drop_table: DropsTable

func _init() -> void:
	pass


func get_initial_quadrant_health() -> float:
	return initial_health
