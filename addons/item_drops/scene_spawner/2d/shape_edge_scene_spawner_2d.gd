class_name ShapeEdgeSceneSpawner2D
extends SceneSpawner2D
## Spawns scenes randomly along the edge of a collision shape

@export var spawn_shape : CollisionShape2D

# Amount in normalized pixels to go beyond or before the edge fpr the final spawn point
@export var edge_point_offset : int = 0

var _check_distance_multiplier = 1.25

## Checks collision between a segment line and the spawn_shape
## to see at what point they meet given a random segment end direction[br][br]
## Returns the meeting point
func get_spawn_position():
	var check_shape : Shape2D = spawn_shape.shape
	var collision_object : CollisionObject2D = spawn_shape.get_parent()
	var space_state = get_world_2d().get_direct_space_state()
	
	var segment = SegmentShape2D.new()
	var shape_box_size = spawn_shape.shape.get_rect().size
	var random_direction = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	)
	
	var segment_target_offset = shape_box_size * _check_distance_multiplier * random_direction
	
	# Draw a line through the target shape
	segment.set_a(segment_target_offset * -1)
	segment.set_b(segment_target_offset)
	var check_transform = collision_object.global_transform
	var hits_array : PackedVector2Array = spawn_shape.shape.collide_and_get_contacts(check_transform, segment, check_transform)
	
	var origin = check_transform.get_origin()
	
	for hit in hits_array:
		if hit != origin:
			## The offset from the origin where the hit occured
			var direction = origin.direction_to(hit)
			var spawn_location : Vector2 = hit + (direction * edge_point_offset)
			
			return spawn_location

	return null # Shouldn't happen
	
