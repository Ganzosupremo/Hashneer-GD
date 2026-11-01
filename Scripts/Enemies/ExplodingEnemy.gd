class_name ExplodingEnemy extends BaseEnemy
## Kamikaze: walks up to the player and lights its fuse once close. It keeps creeping in while
## the fuse burns (pulsing faster, with its blast radius drawn), then blows itself up.
## Killing it also sets it off, so don't finish it off at point blank.

@export var explosion_radius: float = 150.0
@export var explosion_damage_range: Vector2 = Vector2(30.0, 50.0)
@export var explosion_color: Color = Color(1.0, 0.5, 0.0)
@export var pulse_speed: float = 3.0
## Distance to the player that lights the fuse.
@export var fuse_trigger_distance: float = 120.0
@export var fuse_time: float = 1.0
## Speed while the fuse burns.
@export var fuse_speed_scale: float = 0.45

var _pulse_time: float = 0.0
var _fuse_left: float = -1.0
var _exploded: bool = false

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	var lit: bool = _fuse_left >= 0.0
	_pulse_time += delta * pulse_speed * (5.0 if lit else 1.0)
	var pulse = (sin(_pulse_time) + 1.0) * 0.5
	var current_color = color_default.lerp(explosion_color, pulse * (1.0 if lit else 0.5))
	applyColor(current_color)
	if lit:
		queue_redraw()

func _get_movement_input(delta: float) -> Vector2:
	var threat: Node2D = get_threat()
	if threat == null:
		return super._get_movement_input(delta)
	if _fuse_left >= 0.0:
		_fuse_left -= delta
		if _fuse_left < 0.0:
			_detonate()
			return Vector2.ZERO
		move_speed_scale = fuse_speed_scale
		return global_position.direction_to(threat.global_position)
	if global_position.distance_squared_to(threat.global_position) < fuse_trigger_distance * fuse_trigger_distance:
		_fuse_left = fuse_time
	return super._get_movement_input(delta)

## Blows itself up: no loot and no kill for the player (counts as a despawn).
func _detonate() -> void:
	if isDead() or _exploded:
		return
	_explode()
	_health_component.set_current_health(0.0)
	kill(true)

func kill(natural_death: bool = false) -> void:
	if !natural_death:
		_explode()
	super.kill(natural_death)

func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	var player = GameManager.get_player()
	if player and !is_player_dead and global_position.distance_to(player.global_position) <= explosion_radius:
		deal_damage_to_player(explosion_damage_range, true)
	
	if death_vfx:
		GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.ENEMY_DEATH, Transform2D(0.0, global_position), death_vfx)
	var camera: AdvanceCamera = GameManager.get_main_camera()
	if camera:
		camera.shake_with_preset(Constants.ShakeMagnitude.Small)

func _draw() -> void:
	if _fuse_left < 0.0 or _exploded:
		return
	var t: float = 1.0 - _fuse_left / maxf(fuse_time, 0.001)
	draw_circle(Vector2.ZERO, explosion_radius, Color(explosion_color, 0.08 + 0.17 * t))
	draw_arc(Vector2.ZERO, explosion_radius, 0.0, TAU, 40, Color(explosion_color, 0.7), 2.0)
