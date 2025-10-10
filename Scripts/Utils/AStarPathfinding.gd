class_name AStarPathfinding extends Node

var astar_grid: AStarGrid2D
var cell_size: int = 50
var grid_size: Vector2i
var grid_offset: Vector2

func _init(map_rect: Rect2, _cell_size: int = 50):
	cell_size = _cell_size
	grid_offset = map_rect.position
	
	grid_size = Vector2i(
		ceili(map_rect.size.x / cell_size),
		ceili(map_rect.size.y / cell_size)
	)
	
	astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(0, 0, grid_size.x, grid_size.y)
	astar_grid.cell_size = Vector2(cell_size, cell_size)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar_grid.update()

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local_pos = world_pos - grid_offset
	return Vector2i(
		int(local_pos.x / cell_size),
		int(local_pos.y / cell_size)
	)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * cell_size + cell_size / 2,
		grid_pos.y * cell_size + cell_size / 2
	) + grid_offset

func is_valid_grid_position(grid_pos: Vector2i) -> bool:
	return astar_grid.is_in_boundsv(grid_pos)

func set_point_solid(grid_pos: Vector2i, solid: bool = true) -> void:
	if is_valid_grid_position(grid_pos):
		astar_grid.set_point_solid(grid_pos, solid)

func set_world_point_solid(world_pos: Vector2, solid: bool = true) -> void:
	var grid_pos = world_to_grid(world_pos)
	set_point_solid(grid_pos, solid)

func set_region_solid(start_grid: Vector2i, end_grid: Vector2i, solid: bool = true) -> void:
	for x in range(start_grid.x, end_grid.x + 1):
		for y in range(start_grid.y, end_grid.y + 1):
			var pos = Vector2i(x, y)
			if is_valid_grid_position(pos):
				astar_grid.set_point_solid(pos, solid)

func get_pathfinding_path(from_world: Vector2, to_world: Vector2) -> PackedVector2Array:
	var from_grid = world_to_grid(from_world)
	var to_grid = world_to_grid(to_world)
	
	if not is_valid_grid_position(from_grid) or not is_valid_grid_position(to_grid):
		return PackedVector2Array()
	
	var id_path = astar_grid.get_id_path(from_grid, to_grid)
	
	if id_path.is_empty():
		return PackedVector2Array()
	
	var world_path = PackedVector2Array()
	for grid_pos in id_path:
		world_path.append(grid_to_world(grid_pos))
	
	return world_path

func get_simplified_path(from_world: Vector2, to_world: Vector2, skip_points: int = 2) -> PackedVector2Array:
	var full_path = get_pathfinding_path(from_world, to_world)
	
	if full_path.size() <= skip_points + 1:
		return full_path
	
	var simplified_path = PackedVector2Array()
	simplified_path.append(full_path[0])
	
	for i in range(skip_points, full_path.size(), skip_points):
		simplified_path.append(full_path[i])
	
	if simplified_path[-1] != full_path[-1]:
		simplified_path.append(full_path[-1])
	
	return simplified_path

func clear_all_obstacles() -> void:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			astar_grid.set_point_solid(Vector2i(x, y), false)
