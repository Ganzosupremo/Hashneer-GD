class_name Attack51Boss extends Boss
## "Ataque 51%": charging boss that, once it drops below 51% health,
## splits off clones of itself to take over the fight.

@export var clone_count: int = 2
## Size of each clone compared to the boss.
@export_range(0.2, 1.0, 0.05) var clone_size_scale: float = 0.55
## Health percent that triggers the split.
@export_range(0.0, 1.0, 0.01) var split_health_percent: float = 0.51

var is_clone: bool = false
var _has_split: bool = false

func damage(damage_to_apply: Vector2, point: Vector2, knockback_force: Vector2, knockback_time: float, damage_color: Color) -> Dictionary:
	var result: Dictionary = super.damage(damage_to_apply, point, knockback_force, knockback_time, damage_color)
	if !is_clone and !_has_split and !isDead() and getHealthPercent() < split_health_percent:
		_has_split = true
		call_deferred("_split")
	return result

func _split() -> void:
	if isDead() or scene_file_path.is_empty():
		return
	var scene: PackedScene = load(scene_file_path)
	for i in range(clone_count):
		var clone: Attack51Boss = scene.instantiate()
		clone.is_clone = true
		clone.rectangle_size = rectangle_size * clone_size_scale
		clone.charge_speed = charge_speed * 1.15
		var offset: Vector2 = Vector2.RIGHT.rotated(TAU * i / clone_count + _rng.randf()) * 120.0
		spawn_extra_enemy(clone, global_position + offset)
	if GameManager.get_main_camera():
		GameManager.get_main_camera().shake_with_preset(Constants.ShakeMagnitude.Large)

func kill(natural_death: bool = false) -> void:
	if !is_clone:
		super.kill(natural_death)
		return
	# Clones die like regular enemies: no boss loot
	Died.emit(self, global_position, natural_death)
	hide()
	GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.ENEMY_DEATH, global_transform, death_vfx)
	AudioManager.create_2d_audio_at_location(global_position, sound_on_dead.sound_type, sound_on_dead.destination_audio_bus)
	call_deferred("queue_free")
