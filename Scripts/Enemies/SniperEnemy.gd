class_name SniperEnemy extends ShooterEnemy

@export var preferred_distance: float = 400.0
@export var distance_tolerance: float = 50.0

func _physics_process(delta: float) -> void:
	if isKnockbackActive(): 
		return
	
	_handle_screen_wrapping()
	var input: Vector2 = Vector2.ZERO
	
	if target and !is_player_dead:
		var to_target = target.global_position - global_position
		var current_distance = to_target.length()
		
		if current_distance < preferred_distance - distance_tolerance:
			input = -to_target.normalized()
		elif current_distance > preferred_distance + distance_tolerance:
			input = to_target.normalized()
		else:
			var perpendicular = Vector2(-to_target.y, to_target.x).normalized()
			if randf() > 0.5:
				perpendicular = -perpendicular
			input = perpendicular * 0.3
	
	if input != Vector2.ZERO:
		var increase: Vector2 = input * getCurAccel() * delta
		linear_velocity += increase
		if linear_velocity.length_squared() > getCurMaxSpeedSq():
			linear_velocity = linear_velocity.normalized() * getCurMaxSpeed()
	else:
		var decrease: Vector2 = linear_velocity.normalized() * getCurDecel() * delta
		if decrease.length_squared() >= linear_velocity.length_squared():
			linear_velocity = Vector2.ZERO
		else:
			linear_velocity -= decrease
	
	if rotate_towards_velocity and linear_velocity.length_squared() > 1.0:
		global_rotation = linear_velocity.angle()
