extends Node

var pathfinding_grid: AStarPathfinding = null
var obstacles_dirty: bool = false

func initialize_grid(map_rect: Rect2, cell_size: int = 50) -> void:
	pathfinding_grid = AStarPathfinding.new(map_rect, cell_size)
	print("PathfindingManager: Grid initialized with size %s, cell size %d" % [map_rect.size, cell_size])

## Returns a simplified path from the 'from' position to the 'to' position using the pathfinding grid.[br]
## [param from] The starting position as a Vector2[br]
## [param to] The target position as a Vector2[br]
func get_pathfinding_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	if not pathfinding_grid:
		return PackedVector2Array()
	return pathfinding_grid.get_simplified_path(from, to, 2)

## Checks if the current position is within a certain threshold of the target position.[br]
## [param current_pos] The current position as a Vector2[br]
## [param target_pos] The target position as a Vector2[br]
## [param threshold] The distance threshold to consider the target reached (default is 10.0)[br]
## [return] True if the target position is reached within the threshold, false otherwise
func is_target_position_reached(current_pos: Vector2, target_pos: Vector2, threshold: float = 10.0) -> bool:
	return current_pos.distance_to(target_pos) <= threshold

func add_obstacle(world_pos: Vector2) -> void:
	if not pathfinding_grid:
		return
	pathfinding_grid.set_world_point_solid(world_pos, true)
	obstacles_dirty = true

func add_obstacle_rect(rect: Rect2) -> void:
	if not pathfinding_grid:
		return
	var start_grid = pathfinding_grid.world_to_grid(rect.position)
	var end_grid = pathfinding_grid.world_to_grid(rect.position + rect.size)
	pathfinding_grid.set_region_solid(start_grid, end_grid, true)
	obstacles_dirty = true

func remove_obstacle(world_pos: Vector2) -> void:
	if not pathfinding_grid:
		return
	pathfinding_grid.set_world_point_solid(world_pos, false)
	obstacles_dirty = true

func clear_all_obstacles() -> void:
	if not pathfinding_grid:
		return
	pathfinding_grid.clear_all_obstacles()
	obstacles_dirty = false

func has_direct_line_of_sight(from: Vector2, to: Vector2, check_distance: float = 200.0) -> bool:
	if from.distance_to(to) < check_distance:
		return true
	return false

## Returns 
func is_pathfinding_grid_valid() -> bool:
	return pathfinding_grid and is_instance_valid(pathfinding_grid)
