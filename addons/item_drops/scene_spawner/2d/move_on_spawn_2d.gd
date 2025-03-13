class_name SpawnMoveInitializer2D
extends Node
## Attaches a MoveOnSpawn component to scenes spawned by a SceneSpawner2D,
## enabling them to move in a direction for a set duration after instantiation.

## The spawner this script is attaching itself to the spawned signal for.
## When the spawner spawns a scene, this script will trigger by adding a MoveOnSpawn Node
## to the spawned scene.
@export var spawner: SceneSpawner2D:
	set(value):
		# Disconnect from the old spawner if it exists
		if spawner:
			spawner.spawned.disconnect(_on_spawned)
		
		spawner = value
		
		# Connect to the new spawner if it exists
		if spawner:
			spawner.spawned.connect(_on_spawned)

## Settings that describe how a SpawnMoveInitializer2D should behave.
@export var settings: SpawnMoveSettings


func _on_spawned(event: SpawnEvent) -> void:
	# Calculate direction from spawner to spawned instance
	var spawner_pos: Vector2 = event.spawner.global_position
	var instance_pos: Vector2 = event.spawned.global_position
	var move_direction: Vector2 = spawner_pos.direction_to(instance_pos).normalized()
	
	# Use a random direction if the instance spawns directly on the spawner
	if move_direction == Vector2.ZERO:
		move_direction = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()
	
	# Create and attach the MoveOnSpawn component to the spawned scene
	var move_on_spawn := MoveOnSpawn.new(event.spawned, settings, move_direction)
	event.spawned.add_child(move_on_spawn)


## A component that moves its parent node in a specified direction for a set duration.
class MoveOnSpawn:
	extends Node
	
	var node_to_move: Node2D
	var settings: SpawnMoveSettings
	var move_direction := Vector2.ZERO
	var remove_on_stop := true
	
	var moving := false:
		set(value):
			moving = value
			# Placeholder for potential collision disabling logic
			# set_deferred("collision_shape.disabled", moving)
	
	var time_since_launch := 0.0
	var start_pos := Vector2.ZERO
	var _last_sample := 0.0
	
	## Initializes the component with the node to move, movement settings, and direction.
	func _init(p_node_to_move: Node2D, p_settings: SpawnMoveSettings, p_direction: Vector2) -> void:
		node_to_move = p_node_to_move
		start_pos = node_to_move.global_position
		settings = p_settings
		move_direction = p_direction
		moving = true
	
	func _physics_process(delta: float) -> void:
		if not moving:
			return
		
		time_since_launch += delta
		
		# Calculate progress along the movement duration
		var time_progress := clampf(time_since_launch / settings.move_duration, 0.0, 1.0)
		
		# Sample the movement curve and update position
		var current_sample := settings.distance_time_curve.sample(time_progress)
		node_to_move.position += (current_sample - _last_sample) * move_direction
		_last_sample = current_sample
		
		# Stop moving and clean up when duration is reached
		if time_since_launch >= settings.move_duration:
			moving = false
			if remove_on_stop:
				queue_free()
