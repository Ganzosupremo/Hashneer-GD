class_name Boss extends BaseEnemy

signal target_pos_reached(pos: Vector3)

func _ready() -> void:
	super._ready()
	target_pos_reached.connect(_on_target_pos_reached)


func kill(natural_death: bool = false) -> void:
	Died.emit(self, position, natural_death)
	hide()
	if !natural_death:
		random_drops.spawn_drops(1)
		await _sound_effect_component.set_and_play_sound(sound_on_dead)
	queue_free()

func _on_target_pos_reached(_pos: Vector3) -> void:
	# Set a new target position when the current one is reached
	if target_pos.z == 0.0:
		setNewTargetPos()
