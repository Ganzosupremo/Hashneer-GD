class_name SpawnSceneAtPoint
extends SceneSpawner
## Spawns the scene at the current position

func spawn(p_packed_scene : PackedScene):
	var instance = p_packed_scene.instantiate()
	instance.global_position = spawn_point.global_position
