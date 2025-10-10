class_name RandomDrops
extends ItemDropsNode
## Holds a drops table to spawn scenes into the game by calling spawn_drops

## Defines what scenes can drop and what the base odds
## for each individual scene dropping are
@export var drops_table : DropsTable

## Handles placing objects into the game world
@export var scene_spawner : SceneSpawner2D

func _ready() -> void:
	_validate()

## Generates an array of drops from the drops_table
## and then uses the scene_spawner to place them into the scene
func spawn_drops(p_drop_rolls : int, p_odds_multiplier : float = 1.0) -> Node:
	var drops_to_spawn : Array[Resource] = []
	var generator = DropsGenerator.new(drops_table, p_odds_multiplier)
	
	for roll in p_drop_rolls:
		var generated = generator.generate_drops()
		drops_to_spawn.append_array(generated)

	for drop in drops_to_spawn:
		var packed_scene: PackedScene = load(drop.drop_path)
		return scene_spawner.spawn(packed_scene)
	return null

func _validate():
	if drops_table == null:
		DebugLogger.warn("No drops_table defined at %s" % get_path())
		
	if scene_spawner == null:
		DebugLogger.warn("No scene spawner defined at %s" % get_path())


func get_scene_spawner() -> SceneSpawner2D:
	return scene_spawner
