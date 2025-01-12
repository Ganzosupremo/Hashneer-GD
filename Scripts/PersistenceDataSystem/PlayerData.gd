## Container to save the player data to disk
class_name PlayerSaveData extends Resource

@export var player_details: PlayerDetails
@export var saved_weapons_array: Array = []

func _init(_speed: float = 0.0, _health: float = 0.0, _weapons_array: Array = [], _player_details: PlayerDetails = null) -> void:
	if _player_details == null:
		self.player_details = PlayerDetails.new(400.0)
	else:
		self.player_details = _player_details
	self.saved_weapons_array = _weapons_array
	self.player_details.speed = _speed
	self.player_details.max_health = _health 
