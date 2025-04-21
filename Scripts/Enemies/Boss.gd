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
