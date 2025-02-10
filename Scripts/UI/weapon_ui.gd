class_name WeaponStateUI extends Control

@onready var weapon_texture: TextureRect = %WeaponTexture
@onready var weapon_name: Label = %WeaponName
@onready var player: PlayerController = %Player

var _current_weapon: WeaponDetails = null

func _ready() -> void:
	_current_weapon = player.get_current_weapon()
	player.active_weapon.weapon_setted.connect(_on_weapon_setted)
	# Just call on _ready since the signal is connected to late when the player emits it
	_on_weapon_setted(_current_weapon)

func _on_weapon_setted(weapon: WeaponDetails) -> void:
	_set_active_weapon_state(weapon)

func _set_active_weapon_state(weapon: WeaponDetails) -> void:
	_set_weapon_image(weapon.weapon_texture)
	_set_weapon_name(weapon)

func _set_weapon_image(texture: Texture2D) -> void:
	weapon_texture.texture = texture

func _set_weapon_name(weapon: WeaponDetails) -> void:
	weapon_name.text = "({0}) {1}".format([weapon.weapon_list_index, weapon.weapon_name])
