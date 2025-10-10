extends Node

var pathfinding_grid: AStarPathfinding = null
var obstacles_dirty: bool = false

func initialize_grid(map_rect: Rect2, cell_size: int = 50) -> void:
	pathfinding_grid = AStarPathfinding.new(map_rect, cell_size)
	print("PathfindingManager: Grid initialized with size %s, cell size %d" % [map_rect.size, cell_size])

func get_pathfinding_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	if not pathfinding_grid:
		return PackedVector2Array()
	return pathfinding_grid.get_simplified_path(from, to, 2)

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
