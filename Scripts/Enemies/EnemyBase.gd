class_name BaseEnemy extends RigidBody2D

# MIT License
# -----------------------------------------------------------------------
#                       This file is part of:                           
#                     GODOT Polygon 2D Fracture                         
#           https://github.com/SoloByte/godot-polygon2d-fracture          
# -----------------------------------------------------------------------
# Copyright (c) 2021 David Grueneis
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

signal Died(ref, pos: Vector2)
signal Damaged(enemy: Node2D, pos: Vector2, shape: PackedVector2Array, color: Color, fade_speed: float)
signal Fractured(enemy: Node2D, fracture_shard: Dictionary, new_mass: float, color: Color, fracture_force: float, p: float)

@export_category("General")
@export var advanced_regeneration: bool = false
@export var invincible_time: float = 0.5
@export var color_default: Color = Color.ANTIQUE_WHITE
## 1.0 = no change. 2.0 means twice as fast over. 0.5 means takes longer twice as much
@export_range(0.0, 2.0, 0.5, "or_greater") var knockback_resistance_base: float = 1.0 

@export_category("Fracture")
## shape_area < start_area * shape_area_percent -> shape will be fractured
@export_range(0.0, 1.0, 0.1, "or_greater") var shape_area_percent : float = 0.25 
@export var fractures: int = 2
@export var fracture_force: float = 200.0

@export_category("Collision")
@export var collision_damage := Vector2(5, 10)
@export var collision_knockback_force: float = 10000
@export var collision_knockback_time: float = 0.15

@export_category("Targeting")
@export var find_new_target_pos_tolerance: float = 50.0
@export var target_reached_tolerance: float = 10.0
@export var target_pos_interval_range := Vector2(0.5, 1.5)
@export var keep_distance_range := Vector2.ZERO

#export(int) var score_points : int = 25
@export_category("Movement")
@export var rotate_towards_velocity: bool = false
@export var max_speed: float = 250.0
@export var accel: float = 1000.0
@export var decel: float = 1500.0

@export_category("Audio")
@export var sound_on_hurt: SoundEffectDetails
@export var sound_on_dead: SoundEffectDetails
@export var sound_on_heal: SoundEffectDetails


@export_category("Visuals")
@export_group("Shape")
@export var polygon_shape: Constants.PolygonShape

@export_group("Circular Shape", "cir_")
@export var cir_radius: float = 0.0
@export var cir_smoothing : int = 1 # (int, 0, 5, 1)

@export_group("Rectangle Shape", "rectangle_")
@export var rectangle_size : Vector2 = Vector2.ZERO
@export var rectangle_local_center: Vector2 = Vector2.ZERO

@export_group("Beam Shape", "beam_")
@export var beam_dir : Vector2 = Vector2.ZERO
@export var beam_distance : float = 0
@export var beam_start_width : float = 0
@export var beam_end_width : float = 0
@export var beam_start_point_local: Vector2 = Vector2.ZERO

@export_group("Super Ellipse and Super Shape Common Vars", "s_")
@export var s_p_number : int = 0
@export var s_a : float = 0
@export var s_b : float = 0
@export var s_start_angle_deg : float = 0.0
@export var s_max_angle_deg : float = 360.0
@export var s_offset := Vector2.ZERO

@export_group("Super Ellipse Shape", "e_")
@export var e_n : float = 0

@export_group("Super Shape", "")
@export_range(0.0, 30.0, 0.05) var min_m: float = 0.0
@export_range(0.0, 30.0, 0.05) var m: float = 20.0
@export_range(0.0, 1.0, 0.05) var min_n1: float = 0
@export_range(0.0, 1.0, 0.05) var n1 : float = 0
@export_range(0.0, 1.0, 0.05) var min_n2: float = 0
@export_range(0.0, 1.0, 0.05) var n2 : float = 0
@export_range(0.0, 1.0, 0.05) var min_n3: float = 0
@export_range(0.0, 1.0, 0.05) var n3 : float = 0


var cur_area : float = 0.0
var start_area : float = 0.0
var target = null
var target_pos := Vector3.ZERO
var prev_target_pos := Vector2.ZERO
var knockback_resistance : float = 1.0
var knockback_timer : float = 0.0
var start_poly : PackedVector2Array
var total_frame_heal_amount : float = 0.0
var regeneration_timer : Timer = null
var regeneration_started : bool = false
var polygon_restorer : PolygonRestorer = null

@onready var find_new_target_pos_tolerance_sq : float = find_new_target_pos_tolerance * find_new_target_pos_tolerance
@onready var target_reached_tolerance_sq : float = target_reached_tolerance * target_reached_tolerance
@onready var max_speed_sq : float = max_speed * max_speed
@onready var _col_polygon: CollisionPolygon2D = $CollisionPolygon2D
@onready var _polygon: Polygon2D = $Shape3D/Polygon2D
@onready var _line: Line2D = $Shape3D/Line2D
@onready var _drop_poly: Polygon2D = $DropPoly
@onready var _origin_poly: Polygon2D = $OriginPoly
@onready var _health_component: FractureBodyHealthComponent = $FractureBodyHealthComponent
@onready var _sound_effect_component: SoundEffectComponent = $SoundEffectComponent
@onready var _off_screen_notifier: VisibleOnScreenNotifier2D = $OffScreenNotifier
@onready var random_drops: RandomDrops = $RandomDrops

@onready var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
@onready var _target_pos_timer: Timer= $TargetPositionTimer
@onready var _poly_fracture: PolygonFracture = PolygonFracture.new()
@onready var _hit_flash_poly: Polygon2D = $FlashPoly
@onready var _hit_flash_anim_player: AnimationPlayer = $AnimationPlayer
@onready var _invincible_timer: Timer = $InvincibleTimer


func _ready() -> void:
	_rng.randomize()
	
	var new_polygon : PackedVector2Array = _createPolygonShape()
	start_poly = new_polygon
	setPolygon(start_poly)
	_off_screen_notifier.rect = getPolygonRect()
	
	cur_area = start_area
	_health_component.set_max_health(start_area)
	
	if  !_health_component.has_advanced_regeneration():
		polygon_restorer = PolygonRestorer.new()
		polygon_restorer.addShape(_polygon.get_polygon(), start_area)
	
	applyColor(color_default)
	_hit_flash_poly.visible = false
	
	_origin_poly.set_polygon(_polygon.get_polygon())
	_drop_poly.set_polygon(_polygon.get_polygon())
	_drop_poly.modulate.a = lerp(0.2, 0.7, 1.0 - getHealthPercent())
	
	if _health_component.regeneration_interval_range != Vector2.ZERO:
		regeneration_timer = _health_component.create_regeneration_timer()
		regeneration_timer.timeout.connect(on_regeneration_timer_timeout)
	
	# setTarget(null)
	setNewTargetPos()

func _draw() -> void:
	draw_rect(_off_screen_notifier.rect, Color.BLUE, false, 2.0)

func _createPolygonShape() -> PackedVector2Array:
	match polygon_shape:
		Constants.PolygonShape.Circular:
			mass = cir_radius
			start_area = PI * cir_radius * cir_radius
			return PolygonLib.createCirclePolygon(cir_radius, cir_smoothing)
		Constants.PolygonShape.Rectangular:
			mass = rectangle_size.x * rectangle_size.y
			start_area = rectangle_size.x * rectangle_size.y
			return PolygonLib.createRectanglePolygon(rectangle_size, rectangle_local_center)
		Constants.PolygonShape.Beam:
			mass = beam_distance * beam_start_width
			start_area = beam_distance * beam_start_width
			return PolygonLib.createBeamPolygon(beam_dir, beam_distance, beam_start_width, beam_end_width, beam_start_point_local)
		Constants.PolygonShape.SuperEllipse:
			mass = s_a * s_b
			start_area = PI * s_a * s_b
			return PolygonLib.createSuperEllipsePolygon(s_p_number, s_a, s_b, e_n, s_start_angle_deg, s_max_angle_deg)
		Constants.PolygonShape.SuperShape:
			mass = s_a * s_b
			start_area = PI * s_a * s_b
			return PolygonLib.createSupershape2DPolygon(s_p_number, s_a, s_b, _rng.randf_range(min_m, m), _rng.randf_range(min_n1, n1), _rng.randf_range(min_n2, n2), _rng.randf_range(min_n3, n3), s_start_angle_deg, s_max_angle_deg)
		_:
			return PackedVector2Array([])

func _process(delta: float) -> void:
	_processKnockbackTimer(delta)

func _processKnockbackTimer(delta : float) -> void:
	if knockback_timer > 0.0:
		knockback_timer -= delta * knockback_resistance
		if knockback_timer <= 0.0:
			knockback_timer = 0.0

# Change later, the enemy will not integrate any forces
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if isKnockbackActive(): return


	if state.get_contact_count() > 0:
		var collisions : Dictionary = {}
		#filtering the collisions
		for i in range(state.get_contact_count()):
			var id = state.get_contact_collider_id(i)
			if collisions.has(id):
				var shape = state.get_contact_collider_shape(i)
				collisions[id].shapes.append(shape)
			else:
				var body = state.get_contact_collider_object(i)
				var shape = state.get_contact_collider_shape(i)
				var pos = state.get_contact_collider_position(i)
				collisions[id] = {"body" : body, "shapes" : [shape], "pos" : pos}
		
		
		# Set target if not set
		# var count : int = collisions.values().size()
		# if target == null and count > 0:
		# 	if count == 1:
		# 		setTarget(collisions.values()[0].body)
		# 	else:
		# 		var rand_index : int = _rng.randi_range(0, count - 1)
		# 		setTarget(collisions.values()[rand_index].body)
		
		
		for col in collisions.values():
			if col.body is RigidBody2D:
				if col.body.has_method("damage"):
					var force : Vector2 = (col.body.global_position - global_position).normalized() * collision_knockback_force
					col.body.call_deferred("damage", collision_damage, col.pos, force, collision_knockback_time, self, getCurColor())
		
	var input: Vector2 = Vector2.ZERO
	
	# if target and is_instance_valid(target): 
	# 	if find_new_target_pos_tolerance > 0.0:
	# 		var dis : float = (prev_target_pos - target.global_position).length_squared()
	# 		if dis > find_new_target_pos_tolerance_sq:
	# 			setNewTargetPos()
	
	if target_pos.z == 1.0:
		var cur_target_pos: Vector2 = Vector2(target_pos.x, target_pos.y)
		var target_vec: Vector2 = cur_target_pos - global_position
		var dis : float = target_vec.length_squared()
		
		if dis > target_reached_tolerance_sq:
			input = target_vec.normalized()
	
	# Setting velocity towards target
	if input != Vector2.ZERO:
		var increase : Vector2 = input * getCurAccel() * state.step
		state.linear_velocity += increase
		if state.linear_velocity.length_squared() > getCurMaxSpeedSq():
			state.linear_velocity = state.linear_velocity.normalized() * getCurMaxSpeed()
	else:
		var decrease : Vector2 = linear_velocity.normalized() * getCurDecel() * state.step
		if decrease.length_squared() >= state.linear_velocity.length_squared():
			state.linear_velocity = Vector2.ZERO
		else:
			state.linear_velocity -= decrease
	
	if rotate_towards_velocity:
		global_rotation = state.linear_velocity.angle()

func applyColor(color : Color) -> void:
	_polygon.modulate = color
	_line.modulate = color
	_origin_poly.modulate = color

func damage(damage_to_apply : Vector2, point : Vector2, knockback_force : Vector2, knockback_time : float, damage_dealer: Node2D, damage_color : Color) -> Dictionary:
	if isDead(): 
		return {"percent_cut" : 0.0, "dead" : true}
	
	if isInvincible():
		_hit_flash_anim_player.play("invincible-hit-flash")
		return {"percent_cut" : 0.0, "dead" : false} 
	
	# setTarget(damage_dealer)
	
	var percent_cut : float = 0.0
	var cut_shape : PackedVector2Array = _poly_fracture.generateRandomPolygon(damage_to_apply, Vector2(21,72), Vector2.ZERO)
	var cut_shape_area : float = PolygonLib.getPolygonArea(cut_shape)
	Damaged.emit(self, point, cut_shape, damage_color, 5.0)
#	spawnShapeVisualizer(point, 0.0, cut_shape, damage_color, 1.0)
	var fracture_info : Dictionary = _poly_fracture.cutFracture(_polygon.get_polygon(), cut_shape, get_global_transform(), Transform2D(0.0, point), start_area * shape_area_percent, 200, 50, fractures)
	
	var p : float = cut_shape_area / cur_area
	for fracture in fracture_info.fractures:
		for shard in fracture:
			Fractured.emit(self, shard, mass * (shard.area / cur_area), getCurColor(), fracture_force, p)
#			spawnFractureBody(shard, mass * (shard.area / cur_area), p)
	
	
	if _health_component.is_dead() or not fracture_info or not fracture_info.shapes or fracture_info.shapes.size() <= 0:
		_sound_effect_component.set_and_play_sound(sound_on_dead)
		
		if hasRegeneration():
			_health_component.change_regeneration_state(false)
			_health_component.stop_regeneration_timer()
		
		_health_component.set_current_health(0.0)
		call_deferred("kill")
		percent_cut = 1.0
		cur_area = 0.0
	else:
		var cur_shape: Dictionary
		var biggest_area : float = -1
		for shape in fracture_info.shapes:
			if shape.area > biggest_area:
				biggest_area = shape.area
				cur_shape = shape
		
		if polygon_restorer:
			polygon_restorer.addShape(cur_shape.shape, cur_shape.area)
		setPolygon(cur_shape.shape)
		
#		SoundServer.play2D("hurt", global_position, "blob", 1.0, SoundServer.OVERRIDE_BEHAVIOUR.OLDEST, -1)
		_sound_effect_component.set_and_play_sound(sound_on_hurt)
		if _rng.randf() > 0.1:
			apply_central_impulse(knockback_force)
			knockback_timer = knockback_time
		
		percent_cut = cur_shape.area / cur_area
		cur_area = cur_shape.area
		 
		_hit_flash_anim_player.play("hit-flash")
		_health_component.set_current_health(cur_shape.area)
		_drop_poly.modulate.a = lerp(0.2, 0.7, 1.0 - getHealthPercent())
		
		_invincible_timer.start(invincible_time)
		if hasRegeneration() and canRegenerate():
			_health_component.regenerate(self)
			
	return {"percent_cut" : percent_cut , "dead" : isDead()}

func kill() -> void:
	# _sound_effect_component.finished.connect(_on_dead_sound_finished)
#	SoundServer.play2D("die", global_position, "blob", 1.0, SoundServer.OVERRIDE_BEHAVIOUR.OLDEST, -1)
	Died.emit(self, global_position)
	random_drops.spawn_drops(randi_range(1, 4), 1.5)
	hide()
	await _sound_effect_component.set_and_play_sound(sound_on_dead)
	queue_free()

## Applies healing to the enemy and manages related visual effects
## @param heal_amount The amount of health to restore
## @return void
func heal(heal_amount : float) -> void:
	if !canBeHealed(): return
	
	# Fully healed
	if getHealthPercent() > _health_component.heal_treshold:
		setPolygon(start_poly)
		cur_area = start_area
		_health_component.heal(start_area)
		_hit_flash_anim_player.play("heal")
		_sound_effect_component.set_and_play_sound(sound_on_heal)
		_drop_poly.modulate.a = lerp(0.2, 0.7, 1.0 - getHealthPercent())
		
		if !hasRegeneration(): return
		
		_health_component.change_regeneration_state(false)
		_health_component.stop_regeneration_timer()
		applyColor(color_default)
	# Start healing
	else:
		if total_frame_heal_amount == 0.0:
			call_deferred("restore")
		total_frame_heal_amount += heal_amount
		_health_component.heal(heal_amount)

## Restores health to the enemy by rebuilding its polygon shape
##
## This function handles healing/restoration by either:
## - Retrieving a previously saved polygon shape from polygon_restorer
## - Calculating a restored polygon based on the total_frame_heal_amount
##
## The function also manages visual feedback, regeneration timers, and
## determines if the entity should be fully healed based on heal_treshold.
##
## Returns: void
func restore() -> void:
	if total_frame_heal_amount < 0.0: return
	
	var poly : PackedVector2Array
	var area : float = 0.0
	if polygon_restorer:
		var shape_entry : Dictionary = polygon_restorer.popLast()
		poly = shape_entry.shape
		area = shape_entry.area
	else:
		poly = PolygonLib.restorePolygon(_polygon.get_polygon(), start_poly, total_frame_heal_amount)
		area = PolygonLib.getPolygonArea(poly)
	
	if area / start_area > _health_component.heal_treshold:
		cur_area = start_area
		setPolygon(start_poly)
		_health_component.set_current_health(start_area)
	else:
		cur_area = area
		setPolygon(poly)
		_health_component.set_current_health(area)
	
	_hit_flash_anim_player.play("heal")
	_sound_effect_component.set_and_play_sound(sound_on_heal)
	_drop_poly.modulate.a = lerp(0.2, 0.7, 1.0 - getHealthPercent())
	
	if hasRegeneration():
		if getHealthPercent() < 1.0 and canRegenerate():
			var rand_time : float = _rng.randf_range(abs(_health_component.regeneration_interval_range.x), abs(_health_component.regeneration_interval_range.y))
			_health_component.start_regeneration_timer(rand_time)
		else:
			_health_component.change_regeneration_state(false)
			applyColor(color_default)
		
	total_frame_heal_amount = 0.0

#region Boolean functions

func canBeHealed() -> bool:
	return _health_component.can_be_healed()

func hasTarget() -> bool:
	return target != null

func hasRegeneration() -> bool:
	return _health_component.has_regeneration()

func canRegenerate() -> bool:
	return _health_component.can_regenerate()

func isRegenerating() -> bool:
	return _health_component.is_regenerating()

func isInvincible() -> bool:
	return not _invincible_timer.is_stopped()

func isDead() -> bool:
	# return cur_area <= 0.0
	return _health_component.is_dead()

func isKnockbackActive() -> bool:
	return knockback_timer > 0.0

#endregion

#region Setters

## DEPRECATED
func setTarget(new_target) -> void:
	target = new_target
#	if target and is_instance_valid(target):
	startTargetPosTimer(target_pos_interval_range.x, target_pos_interval_range.y)
	setNewTargetPos()

func setNewTargetPos() -> void:
	var viewport_rect : Rect2 = get_viewport_rect()
	var screen_width : float = viewport_rect.size.x
	var screen_height : float = viewport_rect.size.y
	var offset: float = 200.0
	
	_rng.randomize()
	# Define possible target positions at screen edges
	var possible_target_positions : Array[Vector2] = [
		Vector2(-offset, screen_height * _rng.randf()), # Left edge
		Vector2(screen_width + offset, screen_height * _rng.randf()), # Right edge
		Vector2(screen_width * _rng.randf(), -offset), # Top edge
		Vector2(screen_width * _rng.randf(), screen_height + offset) # Bottom edge
	]
	
	# Choose a random target position
	var target_edge_position : Vector2 = possible_target_positions[_rng.randi_range(0, possible_target_positions.size() - 1)]
	
	target_pos = Vector3(target_edge_position.x, target_edge_position.y, 1.0)
	prev_target_pos = global_position # Use current position as previous


	# if not target or not is_instance_valid(target): 
	# 	prev_target_pos = Vector2.ZERO
	# 	var rand_angle : float = _rng.randf() * 2.0 * PI
	# 	var v := Vector2.RIGHT.rotated(rand_angle) * _rng.randf() * 1500
	# 	target_pos = Vector3(v.x, v.y, 1.0)
	# 	return
	# if keep_distance_range.y <= 0.0:
	# 	target_pos = Vector3(target.global_position.x, target.global_position.y, 1.0)
	# 	prev_target_pos = target.global_position
	# else:
	# 	var random_rot : float = _rng.randf_range(0, PI * 2.0)
	# 	var pos : Vector2 = target.global_position + Vector2.RIGHT.rotated(random_rot) * _rng.randf_range(keep_distance_range.x, keep_distance_range.y)
	# 	target_pos = Vector3(pos.x, pos.y, 1.0)
	# 	prev_target_pos = target.global_position

## DEPRECATED
func startTargetPosTimer(min_time : float, max_time : float) -> void:
	if max_time <= 0.0: return
	var time : float = _rng.randf_range(min_time, max_time)
	_target_pos_timer.start(time)

func setPolygon(new_polygon : PackedVector2Array, exclude_main_poly : bool = false) -> void:
	_col_polygon.call_deferred("set_polygon", new_polygon)
	
	if not exclude_main_poly:
		_polygon.set_polygon(new_polygon)
	
	_hit_flash_poly.set_polygon(new_polygon)
	new_polygon.append(new_polygon[0])
	_line.points = new_polygon

#endregion

#region Getters

func getPolygonRect() -> Rect2:
	var polygon: PackedVector2Array = _polygon.get_polygon()
	if polygon.size() == 0:
		return Rect2()
	var first_point: Vector2 = polygon[0]
	var min_x: float = first_point.x
	var min_y: float = first_point.y
	var max_x: float = first_point.x
	var max_y: float = first_point.y

	for point in polygon:
		min_x = min(min_x, point.x)
		min_y = min(min_y, point.y)
		max_x = max(max_x, point.x)
		max_y = max(max_y, point.y)
	
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)

func getCurColor() -> Color:
	return _origin_poly.modulate

func getHealthPercent() -> float:
	# if start_area == 0.0:
	# 	return 0.0
	# return cur_area / start_area
	return _health_component.get_health_percentage()

func getCurMaxSpeed() -> float:
	var factor: float = 1.0
	if isRegenerating():
		factor = 2.0
	return lerp(max_speed, max_speed * 1.2, 1.0 - getHealthPercent()) * factor

func getCurMaxSpeedSq() -> float:
	var speed : float = getCurMaxSpeed()
	return speed * speed

func getCurAccel() -> float:
	var factor :  float = 1.0
	return lerp(accel, accel * 1.3, 1.0 - getHealthPercent()) * factor

func getCurDecel() -> float:
	var factor :  float = 1.0
	return lerp(decel, decel * 1.3, 1.0 - getHealthPercent()) * factor

#endregion

func _on_TargetPosTimer_timeout() -> void:
	setNewTargetPos()
	startTargetPosTimer(target_pos_interval_range.x, target_pos_interval_range.y)

func on_regeneration_timer_timeout() -> void:
	heal(_health_component.regeneration_amount)


func _on_off_screen_notifier_screen_exited() -> void:
	await GameManager.init_timer(.8).timeout
	queue_free()
