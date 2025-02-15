class_name BlockCoreFinder extends BaseAbility

@onready var arrow: Sprite2D = $Arrow
@onready var timer: Timer = $Timer


var target_core: BlockCore
var orbit_angle: float = 0.0
var orbit_radius: float = 50.0
var orbit_speed: float = 2.0

func _ready() -> void:
	super._ready()
	timer.wait_time = ability_cooldown
	timer.timeout.connect(activate)
	timer.start()
	GameManager.current_block_core.destroyed.connect(_on_block_found)
	set_target_core(GameManager.current_block_core)

func _process(_delta):
	super._process(_delta)

func _on_activate() -> void:
	if target_core == null: return

	var target_position = target_core.global_position
	var direction = target_position - global_position
	var angle = direction.angle()

	# Tween the rotation of the arrow to point towards the target core
	var t: Tween = GameManager.init_tween()
	t.tween_property(self, "rotation", angle, 0.5).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_IN_OUT)

	if angle > PI/2 or angle < -PI/2:
		arrow.scale = Vector2(1, -1)
	else:
		arrow.scale = Vector2(1, 1)

func _on_block_found() -> void:
	active = false
	timer.stop()

func set_target_core(core: BlockCore):
	target_core = core
