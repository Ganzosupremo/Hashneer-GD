extends Node2D

@onready var laser_hit_effect: Node2D = $LaserBeamHitEffect
var current_direction: float = 270.0  # Start with downward direction

func _ready():
	print("Laser Beam Hit Test Scene Ready!")
	print("Controls:")
	print("- Click anywhere to spawn effect at mouse position")
	print("- Space: Play normal intensity effect")
	print("- E: Play high intensity effect") 
	print("- R: Rotate hit direction")

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_spawn_effect_at_position(get_global_mouse_position())
	
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				_play_normal_effect()
			KEY_E:
				_play_high_intensity_effect()
			KEY_R:
				_rotate_direction()

func _spawn_effect_at_position(pos: Vector2):
	if laser_hit_effect and laser_hit_effect.has_method("play_effect"):
		laser_hit_effect.global_position = pos
		laser_hit_effect.play_effect()
		print("Effect spawned at: ", pos)

func _play_normal_effect():
	if laser_hit_effect and laser_hit_effect.has_method("play_effect"):
		laser_hit_effect.global_position = get_viewport().size / 2
		laser_hit_effect.play_effect()
		print("Normal effect played")

func _play_high_intensity_effect():
	if laser_hit_effect and laser_hit_effect.has_method("play_effect_with_intensity"):
		laser_hit_effect.global_position = get_viewport().size / 2
		laser_hit_effect.play_effect_with_intensity(2.0)
		print("High intensity effect played")

func _rotate_direction():
	current_direction += 45.0
	if current_direction >= 360.0:
		current_direction = 0.0
	
	if laser_hit_effect and laser_hit_effect.has_method("set_hit_direction"):
		laser_hit_effect.set_hit_direction(current_direction)
		print("Direction set to: ", current_direction, " degrees")
