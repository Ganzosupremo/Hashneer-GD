class_name LevelSelectorButton extends TweenableButton

@export_category("Level Params")
## The level to load when the button is pressed.
@export var levelto_load: PackedScene

@export_category("Quadrant Builder")
@export var quadrant_size: int = 100
@export var grid_size: Vector2 = Vector2(10, 5)
@export var colpol_texture: Texture2D
@export var quadrants_initial_health: float = 100
@export var drop_rate_multiplier: float = 1.5
@export var hit_sound_effect: SoundEffectDetails

@export_category("Fracture Delaunay (Block Core)")
@export var cuts: int = 100
@export var min_area: float = 100.0

var builder_args: QuadrantBuilderArgs
# This index is set on the Level Selector Scene
var level_index: int = 0

func _ready() -> void:
	Utils.copy_properties(self, animation_component)
	self.pressed.connect(on_button_pressed)
	self.button_down.connect(_on_button_down)
	self.button_up.connect(_on_button_up)
	self.mouse_entered.connect(_on_mouse_entered)

func init_builder_args() -> void:
	builder_args = QuadrantBuilderArgs.new()
	self.builder_args.level_index = self.level_index
	self.builder_args.quadrant_size = self.quadrant_size
	self.builder_args.grid_size = self.grid_size
	
	self.builder_args.quadrant_texture = self.colpol_texture
	self.builder_args.initial_health = self.quadrants_initial_health
	self.builder_args.drop_rate_multiplier = self.drop_rate_multiplier
	self.builder_args.hit_sound = self.hit_sound_effect
	
	self.builder_args.block_core_cuts_delaunay = cuts
	self.builder_args.block_core_cut_min_area = min_area

func on_button_pressed() -> void:
	GameManager.current_builder_args = self.builder_args
	GameManager.current_level = level_index
	SceneManager.switch_scene_with_packed(levelto_load)
