extends Node2D
class_name FireWeapon

signal fire_weapon(has_fired: bool, fired_previous_frame: bool)

@export var fire_rate: float = 0.25
@export var bullet_scene: PackedScene
@onready var bullet_spawn_position : Marker2D = %BulletFirePosition
@onready var player: PlayerController = $".."

var fire_rate_cooldown_timer: float = 0.0
var current_weapon: WeaponDetails

#func _ready() -> void:
#	player = $".."
##	current_weapon = player.active_weapon.current_weapon
#	await get_tree().process_frame
##	current_weapon = player.active_weapon.get_current_weapon()

func _process(delta: float) -> void:
	fire_rate_cooldown_timer -= delta

func _enter_tree() -> void:
	fire_weapon.connect(on_fire_weapon)

func _exit_tree() -> void:
	fire_weapon.disconnect(on_fire_weapon)

func on_fire_weapon(_has_fired:bool, _fired_previous_frame: bool) -> void:
	weapon_fire()

func weapon_fire() -> void:
	if ready_to_fire():
		current_weapon = player.active_weapon.get_current_weapon()
		player.camera.shake(current_weapon.shake_strength, current_weapon.shake_decay)
		fire_ammo()
		reset_cooldown_timer()

func fire_ammo() -> void:
	var ammo: AmmoDetails = player.active_weapon.get_current_ammo()
	fire_ammo_async(ammo)

func fire_ammo_async(ammo: AmmoDetails):
	var ammo_counter: int = 0
	
	var bullets_per_shoot: int = randi_range(ammo.bullets_per_shoot_min, ammo.bullets_per_shoot_max)
	var spawn_interval: float = 0.0
	
	if bullets_per_shoot > 1:
		spawn_interval = randf_range(ammo.bullet_spawn_interval_min, ammo.bullet_spawn_interval_max)
	else:
		spawn_interval = 0.0
	
	while ammo_counter < bullets_per_shoot:
		ammo_counter += 1
		var bullet: BulletC = bullet_scene.instantiate()
		owner.owner.add_child(bullet)
		bullet.init_bullet(ammo)
		
		var spread_angle = randf_range(-current_weapon.spread_min, current_weapon.spread_max)
		var bullet_direction = global_position.direction_to(get_global_mouse_position()).rotated(spread_angle)
		bullet.set_bullet_direction(bullet_direction)
		
		bullet.transform = bullet_spawn_position.global_transform
		
		await get_tree().create_timer(spawn_interval).timeout
	
	#for sound effects	

func ready_to_fire() -> bool:
	if fire_rate_cooldown_timer >= 0.0:
		return false
	
	return true

func reset_cooldown_timer() -> void:
	fire_rate_cooldown_timer = current_weapon.fire_rate

