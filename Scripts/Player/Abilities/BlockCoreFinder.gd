class_name BlockCoreFinder extends BaseAbility

@onready var arrow: Sprite2D = $Arrow

var target_core: BlockCore

func _ready() -> void:
	super._ready()
	if GameManager.current_block_core != null:
		GameManager.current_block_core.onBlockDestroyed.connect(_on_block_found)
		set_target_core(GameManager.current_block_core)

func _on_activate() -> void:
	if !get_active_state(): return
	if target_core == null: 
		disable()
		hide()
		return

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

func set_target_core(core: BlockCore):
	target_core = core
