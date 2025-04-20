class_name Boss extends BaseEnemy

signal target_pos_reached(pos: Vector3)

func _ready() -> void:
	super._ready()
	target_pos_reached.connect(_on_target_pos_reached)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	pass

func _physics_process(delta: float) -> void:
	var input: Vector2 = Vector2.ZERO

	if target_pos.z == 1.0:
		var cur_target_pos: Vector2 = Vector2(target_pos.x, target_pos.y)
		var target_vec: Vector2 = cur_target_pos - global_position
		var dis : float = target_vec.length_squared()
		
		if dis > target_reached_tolerance_sq:
			input = target_vec.normalized()

	if input != Vector2.ZERO:
		var increase : Vector2 = input * getCurAccel() * delta
		linear_velocity += increase
		if linear_velocity.length_squared() > getCurMaxSpeedSq():
			linear_velocity = linear_velocity.normalized() * getCurMaxSpeed()
	else:
		var decrease : Vector2 = linear_velocity.normalized() * getCurDecel() * delta
		if decrease.length_squared() >= linear_velocity.length_squared():
			linear_velocity = Vector2.ZERO
		else:
			linear_velocity -= decrease
	
	if rotate_towards_velocity:
		global_rotation = linear_velocity.angle()
	# Handle screen wrapping - when boss goes off one side, it appears on the opposite side
	_handle_screen_wrapping()


# Handle screen wrapping - when boss goes off one side, it appears on the opposite side
func _handle_screen_wrapping() -> void:
	var viewport_rect : Rect2 = get_viewport_rect()
	var screen_width : float = viewport_rect.size.x
	var screen_height : float = viewport_rect.size.y

	position.x = wrapf(position.x, 0, screen_width)
	position.y = wrapf(position.y, 0, screen_height)

func _on_target_pos_reached(pos: Vector3) -> void:
	# Set a new target position when the current one is reached
	if target_pos.z == 0.0:
		setNewTargetPos()
	   

func _on_off_screen_notifier_screen_exited() -> void:
	pass

func _on_TargetPosTimer_timeout() -> void:
	pass

# func setNewTargetPos() -> void:
# 	var viewport_rect : Rect2 = get_viewport_rect()
# 	var screen_width : float = viewport_rect.size.x
# 	var screen_height : float = viewport_rect.size.y
# 	var border_margin : float = 10.0  # Margin from screen edges
	
# 	var current_direction : Vector2 = (Vector2(target_pos.x, target_pos.y) - global_position).normalized()
# 	var opposite_direction : Vector2 = -current_direction
	
# 	var target_edge_position : Vector2
	
# 	if abs(opposite_direction.x) > abs(opposite_direction.y):
# 		# Horizontal direction is dominant
# 		if opposite_direction.x > 0:
# 			# Moving right, target inside left portion of screen
# 			target_edge_position = Vector2(border_margin, screen_height * _rng.randf())
# 		else:
# 			# Moving left, target inside right portion of screen
# 			target_edge_position = Vector2(screen_width - border_margin, screen_height * _rng.randf())
# 	else:
# 		# Vertical direction is dominant
# 		if opposite_direction.y > 0:
# 			# Moving down, target inside top portion of screen
# 			target_edge_position = Vector2(screen_width * _rng.randf(), border_margin)
# 		else:
# 			# Moving up, target inside bottom portion of screen
# 			target_edge_position = Vector2(screen_width * _rng.randf(), screen_height - border_margin)
	
# 	# Ensure position is within screen bounds
# 	target_edge_position.x = clamp(target_edge_position.x, border_margin, screen_width - border_margin)
# 	target_edge_position.y = clamp(target_edge_position.y, border_margin, screen_height - border_margin)
	
# 	target_pos = Vector3(target_edge_position.x, target_edge_position.y, 1.0)
# 	print_debug("New Target; ", target_pos)
# 	prev_target_pos = global_position # Use current position as previous
