class_name HealerEnemy extends BaseEnemy

@export var heal_radius: float = 250.0
@export var heal_interval: float = 2.0
@export var heal_amount_range: Vector2 = Vector2(10.0, 20.0)
@export var flee_distance: float = 300.0
@export var heal_color: Color = Color(0.3, 1.0, 0.3)

var _heal_timer: Timer
var _original_color: Color

func _ready() -> void:
	super._ready()
	_original_color = color_default
	_heal_timer = Timer.new()
	add_child(_heal_timer)
	_heal_timer.wait_time = heal_interval
	_heal_timer.timeout.connect(_on_heal_timer_timeout)
	_heal_timer.start()

func _physics_process(delta: float) -> void:
	if isKnockbackActive(): 
		return
	
	_handle_screen_wrapping()
	var input: Vector2 = Vector2.ZERO
	
	if target and !is_player_dead:
		var to_target = target.global_position - global_position
		var distance = to_target.length()
		
		if distance < flee_distance:
			input = -to_target.normalized()
	
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

func _on_heal_timer_timeout() -> void:
	_heal_nearby_enemies()

func _heal_nearby_enemies() -> void:
	var enemies_holder = get_tree().get_first_node_in_group("EnemiesHolder")
	if not enemies_holder:
		return
	
	var healed_any = false
	for enemy in enemies_holder.get_children():
		if enemy == self or not enemy is BaseEnemy:
			continue
		
		if global_position.distance_to(enemy.global_position) <= heal_radius:
			var heal_amount = randf_range(heal_amount_range.x, heal_amount_range.y)
			if enemy.has_method("heal"):
				enemy.heal(heal_amount)
				healed_any = true
	
	if healed_any:
		var tween = create_tween()
		tween.tween_property(self, "modulate", heal_color, 0.2)
		tween.tween_property(self, "modulate", Color.WHITE, 0.2)
