class_name LaunchForceSceneSpawner2D
extends SceneSpawner2D
## Adds a force to every rigidbody spawned by the spawner

## The amount of force that will be applied as an immediate impulse to the spawned Rigidbody2D
@export_range(0, 100000, 50, "or_greater") var force = 15000.0

## The base direction that the scene spawner will try to launch
@export var direction = Vector2(0, -1)

## The spread that the angle can vary rom the base direction
@export_range(0, 360.0, .25) var angle_spread = 45.0

func spawn(p_packed_scene : PackedScene) -> Node:
	DebugLogger.info("Spawning drops from ", self.name)
	var instance : RigidBody2D = p_packed_scene.instantiate()
	spawn_parent.call_deferred("add_child", instance)
	instance.global_position = global_position
	add_force(instance)

	## Send signal after adding child to tree
	var event = SpawnEvent.new(self, instance)
	spawned.emit(event)
	item_drops_bus.emit_item_spawned(event)
	
	return instance

func add_force(p_rigid_body_2d : RigidBody2D):
	var rotation_degress = randf_range(-angle_spread / 2, angle_spread / 2)
	var rotation_rads = deg_to_rad(rotation_degress)
	var rotated_direction = direction.rotated(rotation_rads)
	var instant_force : Vector2 = rotated_direction * force
	p_rigid_body_2d.apply_force(instant_force)
