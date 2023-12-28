extends Button
class_name LevelSelectorButton

@export_category("Level Params")
@export var level_index: int = 0
@export var levelto_load: PackedScene

@export_category("Quadrant Builder Necessary Params")
@export var quadrant_size: int = 100
@export var grid_size: Vector2 = Vector2(10, 5)
@export var colpol_texture: Texture2D
@export var colpol_texture_after: Texture2D
@export var quadrants_initial_health: float = 100
@export var drop_rate_multiplier: float = 1.5

var builder_args: QuadrantBuilderArgs

func _ready() -> void:
	self.pressed.connect(on_button_pressed)

func init_builder_args() -> void:
	builder_args = QuadrantBuilderArgs.new()
	self.builder_args.level_index = self.level_index
	self.builder_args.quadrant_size = self.quadrant_size
	self.builder_args.grid_size = self.grid_size
	self.builder_args.texture = self.colpol_texture
	self.builder_args.texture_after_collision = self.colpol_texture_after
	self.builder_args.initial_health = self.quadrants_initial_health
	self.builder_args.drop_rate_multiplier = self.drop_rate_multiplier

func on_button_pressed() -> void:
	GameManager.builder_args = self.builder_args
	SceneManager.switch_scene_with_packed(levelto_load, level_index)
