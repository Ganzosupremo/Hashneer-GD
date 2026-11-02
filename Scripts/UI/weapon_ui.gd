class_name WeaponStateUI extends Control

@onready var weapon_texture: TextureRect = %WeaponTexture
@onready var weapon_name: Label = %WeaponName
@onready var weapon_slot: Label = %WeaponSlot
@onready var special_label: Label = get_node_or_null("%SpecialLabel")
@onready var active_label: Label = get_node_or_null("%ActiveLabel")
@onready var player: PlayerController = %Player

const READY_COLOR: Color = Color(0.55, 1.0, 0.6)
const ACTIVE_COLOR: Color = Color(1.0, 0.85, 0.35)
const COOLDOWN_COLOR: Color = Color(0.7, 0.7, 0.7)

var _current_weapon: WeaponDetails = null

func _ready() -> void:
	_current_weapon = player.get_current_weapon()
	player.active_weapon.weapon_setted.connect(_on_weapon_setted)
	# Just call on _ready since the signal is connected to late when the player emits it
	_on_weapon_setted(_current_weapon)

func _process(_delta: float) -> void:
	_update_special_state()
	_update_active_state()

func _on_weapon_setted(weapon: WeaponDetails) -> void:
	_current_weapon = weapon
	_set_active_weapon_state(weapon)

func _set_active_weapon_state(weapon: WeaponDetails) -> void:
	_set_weapon_image(weapon.weapon_texture)
	_set_weapon_name(weapon)
	_update_special_state()

func _set_weapon_image(texture: Texture2D) -> void:
	weapon_texture.texture = texture

func _set_weapon_name(weapon: WeaponDetails) -> void:
	weapon_name.text = "{0}".format([weapon.weapon_name])
	weapon_slot.text = "Slot {0}".format([weapon.weapon_index])

# Shows the special's name and whether it's ready, active (with seconds left) or recharging.
func _update_special_state() -> void:
	if special_label == null:
		return
	if _current_weapon == null or _current_weapon.special == null:
		special_label.hide()
		return
	special_label.show()
	var special_name: String = _current_weapon.special.special_name
	var fire_weapon: FireWeaponComponent = player.fire_weapon
	var active_left: float = fire_weapon.get_special_buff_time_left(_current_weapon)
	var cooldown_left: float = fire_weapon.get_special_cooldown_left(_current_weapon)
	if active_left > 0.0:
		special_label.text = "%s: %.1fs" % [special_name, active_left]
		special_label.modulate = ACTIVE_COLOR
	elif cooldown_left > 0.0:
		special_label.text = "%s (%.1fs)" % [special_name, cooldown_left]
		special_label.modulate = COOLDOWN_COLOR
	else:
		special_label.text = "%s: RMB" % special_name
		special_label.modulate = READY_COLOR

# Shows the equipped active ability (Q) and whether it's ready, running or recharging.
func _update_active_state() -> void:
	if active_label == null:
		return
	var ability: BaseAbility = player.active_ability
	if ability == null:
		active_label.hide()
		return
	active_label.show()
	var running_left: float = player.get_damage_boost_time_left()
	if ability is DronesAbility:
		running_left = ability.get_time_left()
	var cooldown_left: float = ability.get_cooldown_left()
	if running_left > 0.0 and ability is not PulseAbility:
		active_label.text = "%s: %.1fs" % [ability.ability_name, running_left]
		active_label.modulate = ACTIVE_COLOR
	elif cooldown_left > 0.0:
		active_label.text = "%s (%.1fs)" % [ability.ability_name, cooldown_left]
		active_label.modulate = COOLDOWN_COLOR
	else:
		active_label.text = "%s: Q" % ability.ability_name
		active_label.modulate = READY_COLOR
