@abstract
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

signal Died(ref: BaseEnemy, pos: Vector2, natural_death: bool)
signal Damaged(enemy: BaseEnemy, pos: Vector2, shape: PackedVector2Array, color: Color, fade_speed: float)
signal Fractured(enemy: BaseEnemy, fracture_shard: Dictionary, new_mass: float, color: Color, fracture_force: float, p: float)

@export_category("Main Event Bus")
@export var main_event_bus: MainEventBus

@export_category("General")
## Seconds the enemy ignores hits after being cut. 0 = every hit cuts and fractures.
@export var invincible_time: float = 0.0
@export var color_default: Color = Color.ANTIQUE_WHITE
## 1.0 = no change. 2.0 means twice as fast over. 0.5 means takes longer twice as much
@export_range(0.0, 2.0, 0.5, "or_greater") var knockback_resistance_base: float = 1.0
@export var shield: ShieldComponent

@export_category("Fracture")
## shape_area < start_area * shape_area_percent -> shape will be fractured
@export_range(0.0, 1.0, 0.01, "or_greater") var shape_area_percent : float = 0.25
@export var fractures: int = 2
@export var fracture_force: float = 200.0
## Cut pieces and fracture shards smaller than this (px²) are not spawned. Kept small so weak
## bullets (shotgun pellets, minigun) still throw shards.
@export var shard_min_area: float = 12.0

@export_category("Collision")
@export var collision_damage := Vector2(10, 20)
@export var collision_knockback_force: float = 10000
@export var collision_knockback_time: float = 0.15

@export_category("Targeting")
@export var target: Node2D = null
## Go after the player. Off, the enemy roams towards random points past the map edges.
@export var chase_player: bool = true
## While chasing the player, stop closing in below this distance (shooters keep their range). 0 = no limit.
@export var chase_stop_distance: float = 0.0
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

@export_group("Flocking Behavior")
@export var use_flocking: bool = true
@export var separation_radius: float = 100.0
@export var separation_weight: float = 1.5
@export var alignment_radius: float = 150.0
@export var alignment_weight: float = 0.3
@export var cohesion_radius: float = 200.0
@export var cohesion_weight: float = 0.5
@export var max_neighbors_check: int = 20

@export_group("Pathfinding")
## Steer along a path from the [NavigationServer2D]. Off, the enemy flies straight at its target.
@export var use_pathfinding: bool = true
## Seconds between path queries (each enemy starts at a random offset to spread them out).
@export_range(0.1, 2.0, 0.05) var path_recalc_interval: float = 0.5
## Query a new path early when the target moved this far from where the last path ended.
@export_range(50.0, 500.0, 10.0) var path_recalc_distance_threshold: float = 100.0

@export_category("Audio and VFX")
@export var sound_on_hurt: SoundEffectDetails
@export var sound_on_dead: SoundEffectDetails
@export var sound_on_heal: SoundEffectDetails
@export var hit_vfx: VFXEffectProperties
@export var death_vfx: VFXEffectProperties

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

@onready var find_new_target_pos_tolerance_sq : float = find_new_target_pos_tolerance * find_new_target_pos_tolerance
@onready var target_reached_tolerance_sq : float = target_reached_tolerance * target_reached_tolerance
@onready var max_speed_sq : float = max_speed * max_speed
@onready var _col_polygon: CollisionPolygon2D = $CollisionPolygon2D
@onready var _polygon: Polygon2D = $Shape3D/Polygon2D
@onready var _line: Line2D = $Shape3D/Line2D
@onready var _drop_poly: Polygon2D = $DropPoly
@onready var _origin_poly: Polygon2D = $OriginPoly
@onready var _health_component: FractureBodyHealthComponent = $FractureBodyHealthComponent
@onready var _off_screen_notifier: VisibleOnScreenNotifier2D = $OffScreenNotifier
@onready var random_drops: RandomDrops = $RandomDrops

@onready var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
@onready var _target_pos_timer: Timer= $TargetPositionTimer
@onready var _poly_fracture: PolygonFracture = PolygonFracture.new()
@onready var _hit_flash_poly: Polygon2D = $FlashPoly
@onready var _hit_flash_anim_player: AnimationPlayer = $AnimationPlayer
@onready var _invincible_timer: Timer = $InvincibleTimer

var cur_area : float = 0.0
var start_area : float = 0.0
var target_pos := Vector3.ZERO
var prev_target_pos := Vector2.ZERO
var knockback_resistance : float = 1.0
var knockback_timer : float = 0.0
var start_poly : PackedVector2Array
var total_frame_heal_amount : float = 0.0
var regeneration_timer : Timer = null
var regeneration_started : bool = false
var polygon_restorer : PolygonRestorer = null
var spawn_timestamp : int = 0
var drops_count : int = 0
var is_player_dead: bool = false

var desired_velocity: Vector2 = Vector2.ZERO


## Pathfinding: the last queried path and the point the enemy is heading to
var path_recalc_timer: float = 0.0
var last_pathfinding_target_pos: Vector2 = Vector2.ZERO
var _nav_path: PackedVector2Array = PackedVector2Array()
var _nav_path_index: int = 0


func _ready() -> void:
	var new_polygon : PackedVector2Array = _createPolygonShape()
	# The shape formulas only estimate the area (a spiky super shape is much smaller than PI*a*b),
	# so use the real one. Health, death threshold and shard masses all depend on it.
	start_area = PolygonLib.getPolygonArea(new_polygon)
	start_poly = new_polygon
	setPolygon(start_poly)
	GameManager.get_player().get_health_node().zero_health.connect(_on_player_health_zero)
	spawn_timestamp = Time.get_ticks_msec()
	_rng.randomize()
																													
	cur_area = start_area
	_health_component.set_max_health(start_area)
																
	if !_health_component.has_advanced_regeneration():
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
				
	call_deferred("_setup_navigation_agent")

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

func _physics_process(delta):
	if isKnockbackActive(): return
	_handle_screen_wrapping()
	var input: Vector2 = Vector2.ZERO
				
	if target_pos.z == 1.0:
		if hasTarget():
			setTargetPosition(target.global_position)
				
		var cur_target_pos: Vector2 = Vector2(target_pos.x, target_pos.y)
								
		if chase_stop_distance > 0.0 and hasTarget() and global_position.distance_squared_to(cur_target_pos) < chase_stop_distance * chase_stop_distance:
			pass # Close enough: hold position (input stays zero, so it slows down)
		elif use_pathfinding:
			input = _get_path_direction(delta, cur_target_pos)
		else:
			input = _get_direct_direction(cur_target_pos)

		if use_flocking and input != Vector2.ZERO:
			var flocking_force = _calculate_flocking_force()
			input = (input + flocking_force).normalized()
				
	# Setting velocity towards target.
	desired_velocity = input * max_speed
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

## Follows a path queried from the navigation map every [member path_recalc_interval] seconds.
## The NavigationAgent2D used before re-queried its path inside get_next_path_position() almost
## every physics frame (the target always moves and flocking/knockback push the enemy off the
## path), which cost ~0.6 ms per enemy and made 20 enemies lag.
func _get_path_direction(delta: float, target_position: Vector2) -> Vector2:
	path_recalc_timer -= delta
	var target_moved: bool = last_pathfinding_target_pos.distance_squared_to(target_position) > path_recalc_distance_threshold * path_recalc_distance_threshold
	if path_recalc_timer <= 0.0 or target_moved:
		path_recalc_timer = path_recalc_interval
		last_pathfinding_target_pos = target_position
		_nav_path = NavigationServer2D.map_get_path(get_world_2d().navigation_map, global_position, target_position, true)
		_nav_path_index = 1 # Point 0 is the enemy position
	# Skip the points already reached
	while _nav_path_index < _nav_path.size() and global_position.distance_squared_to(_nav_path[_nav_path_index]) < target_reached_tolerance_sq:
		_nav_path_index += 1
	# Last point reached, no path (map not synced yet) or the target is outside the navigation region: go straight.
	if _nav_path_index >= _nav_path.size() - 1:
		return _get_direct_direction(target_position)
	return global_position.direction_to(_nav_path[_nav_path_index])

func _get_direct_direction(target_position: Vector2) -> Vector2:
	var target_vec: Vector2 = target_position - global_position
	if target_vec.length_squared() > target_reached_tolerance_sq:
		return target_vec.normalized()
	return Vector2.ZERO

func _processKnockbackTimer(delta : float) -> void:
	if knockback_timer > 0.0:
		knockback_timer -= delta * knockback_resistance
		if knockback_timer <= 0.0:
			knockback_timer = 0.0

func _setup_navigation_agent() -> void:
	await get_tree().physics_frame
	# Nobody else assigns targets to spawned enemies: without this they roamed off the map edges
	# and wrapped around the screen, so they (and the boss) rarely came after the player.
	if !hasTarget():
		var player: Node2D = GameManager.get_player()
		if chase_player and player:
			setTarget(player)
		else:
			setNewRandomTargetPos()
		
	# Random offset so the enemies don't all query their paths on the same frame
	path_recalc_timer = _rng.randf_range(0.0, path_recalc_interval)
	last_pathfinding_target_pos = Vector2(target_pos.x, target_pos.y)

func _calculate_flocking_force() -> Vector2:
	if !use_flocking:
		return Vector2.ZERO
				
	var separation_force: Vector2 = Vector2.ZERO
	var alignment_force: Vector2 = Vector2.ZERO
	var cohesion_force: Vector2 = Vector2.ZERO
	var neighbor_count: int = 0
	var separation_count: int = 0
	var alignment_count: int = 0
	var cohesion_count: int = 0
				
	var parent = get_parent()
	if not parent:
		return Vector2.ZERO
																
	for i in min(parent.get_child_count(), max_neighbors_check):
		var other = parent.get_child(i)
		if other == self or not other is BaseEnemy:
			continue
																																
		var other_enemy = other as BaseEnemy
		if not is_instance_valid(other_enemy) or other_enemy.isDead():
			continue
																																
		var distance_to_neighbor = global_position.distance_to(other_enemy.global_position)
																																
		if distance_to_neighbor < separation_radius and distance_to_neighbor > 0:
			var away_vec = (global_position - other_enemy.global_position).normalized()
			separation_force += away_vec / distance_to_neighbor
			separation_count += 1
																																
		if distance_to_neighbor < alignment_radius:
			alignment_force += other_enemy.linear_velocity
			alignment_count += 1
																																
		if distance_to_neighbor < cohesion_radius:
			cohesion_force += other_enemy.global_position
			cohesion_count += 1
																																
		neighbor_count += 1
		if neighbor_count >= max_neighbors_check:
			break
																
	if separation_count > 0:
		separation_force /= separation_count
		separation_force = separation_force.normalized() * separation_weight
																
	if alignment_count > 0:
		alignment_force /= alignment_count
		alignment_force = alignment_force.normalized() * alignment_weight
																
	if cohesion_count > 0:
		cohesion_force /= cohesion_count
		cohesion_force = (cohesion_force - global_position).normalized() * cohesion_weight
																
	return separation_force + alignment_force + cohesion_force

# Handle screen wrapping - when enemy goes off one side, it appears on the opposite side
func _handle_screen_wrapping() -> void:
	var camera: Camera2D = GameManager.get_main_camera()										
	var world_map_size: Vector2 = WavesGameMode.get_world_map_rect().size
	var zoom: Vector2 = camera.zoom
	var cam_pos: Vector2 = camera.global_position
																
	# Get the current global position
	var current_position = global_position
														
	# Calculate visible world boundaries based on camera position and zoom
	var left_bound : float = cam_pos.x - (world_map_size.x / 2) / zoom.x
	var right_bound : float = cam_pos.x + (world_map_size.x / 2) / zoom.x
	var top_bound : float = cam_pos.y - (world_map_size.y / 2) / zoom.y
	var bottom_bound : float = cam_pos.y + (world_map_size.y / 2) / zoom.y
																
	current_position.x = wrapf(current_position.x, left_bound, right_bound)
	current_position.y = wrapf(current_position.y, bottom_bound, top_bound)
																
	global_position = current_position

#region Poly Fracture Functions

func applyColor(color : Color) -> void:
	_polygon.modulate = color
	_line.modulate = color
	_origin_poly.modulate = color

## Applies damage to the enemy, handling invincibility, shield, fracture, knockback, and death.
func damage(damage_to_apply : Vector2, point : Vector2, knockback_force : Vector2, knockback_time : float, damage_color : Color) -> Dictionary:
	if isDead():
		return {"percent_cut" : 0.0, "dead" : true}
																
	if isInvincible():
		_hit_flash_anim_player.play("invincible-hit-flash")
		return {"percent_cut" : 0.0, "dead" : false}
																
																# Handle shield damage first
	var remaining_damage: Vector2 = damage_to_apply

	var percent_cut : float = 0.0
	var cut_shape : PackedVector2Array = _poly_fracture.generateRandomPolygon(
		remaining_damage,
		Vector2(15,33),
		Vector2.ZERO
		)
	var cut_shape_area : float = PolygonLib.getPolygonArea(cut_shape)
	point = _snap_hit_point_to_polygon(point)
	Damaged.emit(self, point, cut_shape, damage_color, 5.0)
	var angle: float = (-knockback_force).angle()
	GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.ENEMY_HIT, Transform2D(angle, point), hit_vfx)
	var fracture_info : Dictionary = _poly_fracture.cutFracture(_polygon.get_polygon(), cut_shape, get_global_transform(), Transform2D(0.0, point), start_area * shape_area_percent, shard_min_area, shard_min_area, fractures)
	# The cut missed the polygon (the hit point lands on the bullet, just outside the edge, and the
	# damage is applied deferred). Nothing was removed, so the enemy must not die from it.
	if not fracture_info.get("intersected", true):
		_hit_flash_anim_player.play("hit-flash")
		return {"percent_cut" : 0.0, "dead" : false}
																
	var area_ref : float = max(cur_area, 0.001)
	var p : float = cut_shape_area / area_ref
	for fracture in fracture_info.fractures:
		for shard in fracture:
			Fractured.emit(self, shard, mass * (shard.area / area_ref), getCurColor(), fracture_force, p)
																
	if _health_component.is_dead() or not fracture_info or not fracture_info.shapes or fracture_info.shapes.size() <= 0:
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
																																
		_play_sound(sound_on_hurt)
		if _rng.randf() > 0.1:
			apply_central_impulse(knockback_force)
			knockback_timer = knockback_time
																																
		percent_cut = cur_shape.area / cur_area
		cur_area = cur_shape.area
																																 
		_hit_flash_anim_player.play("hit-flash")
		_health_component.set_current_health(cur_shape.area)
		_drop_poly.modulate.a = lerp(0.2, 0.7, 1.0 - getHealthPercent())
																																
		# Timer.start(0.0) keeps the old wait_time (1 s by default), so a 0 invincible_time
		# made the enemy ignore every hit for a whole second.
		if invincible_time > 0.0:
			_invincible_timer.start(invincible_time)
		if hasRegeneration() and canRegenerate():
			_health_component.regenerate(self)

	return {"percent_cut" : percent_cut , "dead" : isDead()}

## Bullets report their own center, which sits outside the edge when they touch the enemy (and the
## damage is applied deferred, after the enemy moved). A small cut there misses the polygon, so the
## hit is moved to the closest point of the edge.
func _snap_hit_point_to_polygon(point: Vector2) -> Vector2:
	var poly: PackedVector2Array = _polygon.get_polygon()
	if poly.size() < 3: return point
	var local_point: Vector2 = to_local(point)
	if Geometry2D.is_point_in_polygon(local_point, poly): return point
	var closest: Vector2 = poly[0]
	var closest_dis: float = INF
	for i in poly.size():
		var candidate: Vector2 = Geometry2D.get_closest_point_to_segment(local_point, poly[i], poly[(i + 1) % poly.size()])
		var dis: float = candidate.distance_squared_to(local_point)
		if dis < closest_dis:
			closest_dis = dis
			closest = candidate
	return to_global(closest)

## Adds an enemy spawned by this one (minion, clone) at [param pos], so the game mode tracks it.
func spawn_extra_enemy(enemy: BaseEnemy, pos: Vector2) -> void:
	var spawner: WaveSpawner = get_tree().get_first_node_in_group("WaveSpawner")
	if spawner:
		spawner.spawn_extra_enemy(enemy, pos)
		return
	var enemies_holder: Node = get_tree().get_first_node_in_group("EnemiesHolder")
	if enemies_holder == null:
		enemy.queue_free()
		return
	enemy.global_position = pos
	enemies_holder.add_child(enemy)

## Plays [param sound] at the enemy position. Enemies without that sound stay silent.
func _play_sound(sound: SoundEffectDetails) -> void:
	if sound == null: return
	AudioManager.create_2d_audio_at_location(global_position, sound.sound_type, sound.destination_audio_bus)

func kill(system_despawn: bool = false) -> void:
	Died.emit(self, global_position, system_despawn)
	hide()
								
	GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.ENEMY_DEATH, global_transform, death_vfx)
	_play_sound(sound_on_dead)
								
	# One pickup worth drops_count instead of drops_count pickups: hundreds of loose pickups
	# (each a rigid body with a light) made long waves runs lag.
	if !system_despawn and drops_count > 0:
		var drop: Node = random_drops.spawn_drops(1)
		var pickup: Pickup2D = drop.get_node_or_null("Pickup2D") as Pickup2D if drop else null
		if pickup:
			pickup.stack_count = drops_count
	call_deferred("queue_free")

## Applies healing to the enemy and manages related visual effects
## @param heal_amount The amount of health to restore
func heal(heal_amount : float) -> void:
	if !canBeHealed(): return
																
				# Fully healed
	if getHealthPercent() > _health_component.heal_treshold:
		setPolygon(start_poly)
		cur_area = start_area
		_health_component.heal(start_area)
		_hit_flash_anim_player.play("heal")
		_play_sound(sound_on_heal)
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
																
	# The restorer stack ran out (more heals than saved shapes): that means back to the start shape.
	if poly.size() < 3 or area / start_area > _health_component.heal_treshold:
		cur_area = start_area
		setPolygon(start_poly)
		_health_component.set_current_health(start_area)
	else:
		cur_area = area
		setPolygon(poly)
		_health_component.set_current_health(area)
																
	_hit_flash_anim_player.play("heal")
	_play_sound(sound_on_heal)
	_drop_poly.modulate.a = lerp(0.2, 0.7, 1.0 - getHealthPercent())
																
	if hasRegeneration():
		if getHealthPercent() < 1.0 and canRegenerate():
			var rand_time : float = _rng.randf_range(abs(_health_component.regeneration_interval_range.x), abs(_health_component.regeneration_interval_range.y))
			_health_component.start_regeneration_timer(rand_time)
		else:
			_health_component.change_regeneration_state(false)
			applyColor(color_default)
																																
	total_frame_heal_amount = 0.0

#endregion

#region Boolean functions

func canBeHealed() -> bool:
	return _health_component.can_be_healed()

func has_active_shield() -> bool:
	return shield != null and is_instance_valid(shield) and shield.is_active()

func hasTarget() -> bool:
	return target != null and is_instance_valid(target)

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

func setTarget(new_target: Node2D) -> void:
	target = new_target
	setTargetPosition(target.global_position)
	prev_target_pos = global_position # Use current position as previous

## Sets a new target position for the enemy to move towards.[br]
## [param new_target_pos] The new target position as a Vector2
func setTargetPosition(new_target_pos: Vector2) -> void:
	target_pos = Vector3(new_target_pos.x, new_target_pos.y, 1.0)

func setNewRandomTargetPos() -> void:
	var world_rect: Rect2 = WavesGameMode.get_world_map_rect()
	var map_width : float = world_rect.size.x
	var map_height : float = world_rect.size.y
	var offset: float = 500.0
																												
	_rng.randomize()
	# Define possible target positions at screen edges
	var possible_target_positions : Array[Vector2] = [
		Vector2(-offset, map_height * _rng.randf()), # Left edge
		Vector2(map_width + offset, map_height * _rng.randf()), # Right edge
		Vector2(map_width * _rng.randf(), -offset), # Top edge
		Vector2(map_width * _rng.randf(), map_height + offset) # Bottom edge
	]
																												
	# Choose a random target position
	var target_edge_position : Vector2 = possible_target_positions[_rng.randi_range(0, possible_target_positions.size() - 1)]
																									
	target_pos = Vector3(target_edge_position.x, target_edge_position.y, 1.0)
	prev_target_pos = global_position # Use current position as previous

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
	# Close the outline on a copy: the array is shared with the caller (start_poly) and the deferred
	# collision polygon, and a repeated closing point makes its convex decomposition fail, so bullets
	# went through the enemy once it healed back to start_poly.
	var outline: PackedVector2Array = new_polygon.duplicate()
	outline.append(outline[0])
	_line.points = outline

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
																#       return 0.0
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

func getSceneSpawner() -> SceneSpawner2D:
	return random_drops.get_scene_spawner()

#endregion

func on_regeneration_timer_timeout() -> void:
	heal(_health_component.regeneration_amount)

func _on_player_health_zero() -> void:
	is_player_dead = true
