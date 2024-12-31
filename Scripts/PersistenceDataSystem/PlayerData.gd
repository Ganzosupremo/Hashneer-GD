## Container to save the player data to disk
class_name PlayerSaveData extends Resource

@export var speed: float
@export var max_health: float
@export var current_weapon: WeaponDetails
@export var player_details: PlayerDetails
@export var saved_weapons_array: Array = []

func _init(_speed: float = 0.0, _health: float = 0.0, _current_weapon = WeaponDetails.new(), _weapons_array: Array = [],_player_details: PlayerDetails = PlayerDetails.new()) -> void:
	self.speed = _speed
	self.max_health = _health
	self.current_weapon = _current_weapon
	self.saved_weapons_array = _weapons_array
	self.player_details = _player_details
