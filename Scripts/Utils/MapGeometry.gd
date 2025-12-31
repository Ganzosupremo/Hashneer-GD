class_name MapGeometry extends RefCounted
## Utility class for map geometry calculations.
##
## Provides static methods for bounds calculation, shape checks, and grid coordinate helpers.
## Used by world generators and other systems that need spatial calculations.

## Calculate the bounding rectangle from a list of positions and quadrant size.
## [param positions]: Array of Vector2 positions.
## [param quadrant_size]: Size of each quadrant.
## [param include_buffer]: Whether to add buffer space around bounds.
## [param buffer_ratio]: Ratio of buffer to add (0.5 = 50% of largest dimension).
## [return]: Rect2 representing the bounds.
static func calculate_bounds_from_positions(positions: Array, quadrant_size: Vector2i, include_buffer: bool = false, buffer_ratio: float = 0.5) -> Rect2:
	if positions.is_empty():
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	
	var min_x: float = INF
	var max_x: float = -INF
	var min_y: float = INF
	var max_y: float = -INF
	
	for pos in positions:
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x + quadrant_size.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y + quadrant_size.y)
	
	var level_width: float = max_x - min_x
	var level_height: float = max_y - min_y
	
	if not include_buffer:
		return Rect2(Vector2(min_x, min_y), Vector2(level_width, level_height))
	
	var buffer: float = max(level_width, level_height) * buffer_ratio
	return Rect2(
		Vector2(min_x - buffer, min_y - buffer),
		Vector2(level_width + buffer * 2, level_height + buffer * 2)
	)

## Calculate the center of a grid.
## [param grid_size]: Size of the grid in cells.
## [param quadrant_size]: Size of each quadrant.
## [return]: Vector2 representing the grid center.
static func calculate_grid_center(grid_size: Vector2i, quadrant_size: Vector2i) -> Vector2:
	return Vector2(
		grid_size.x * quadrant_size.x / 2.0,
		grid_size.y * quadrant_size.y / 2.0
	)

## Check if a cell is within a specified shape.
## [param cell]: The cell coordinates to check.
## [param grid_size]: Size of the grid.
## [param quadrant_size]: Size of each quadrant.
## [param map_shape]: The shape type from Constants.MapShape.
## [return]: True if the cell is within the shape.
static func is_cell_in_shape(cell: Vector2i, grid_size: Vector2i, quadrant_size: Vector2i, map_shape: Constants.MapShape) -> bool:
	var grid_center: Vector2 = calculate_grid_center(grid_size, quadrant_size)
	var cell_center: Vector2 = (Vector2(cell) + Vector2(0.5, 0.5)) * Vector2(quadrant_size)
	
	match map_shape:
		Constants.MapShape.Circle:
			var radius: float = min(grid_size.x, grid_size.y) * quadrant_size.x / 2.0
			return cell_center.distance_to(grid_center) <= radius
		Constants.MapShape.Diamond:
			var rx: float = grid_size.x * quadrant_size.x / 2.0
			var ry: float = grid_size.y * quadrant_size.y / 2.0
			return abs(cell_center.x - grid_center.x) / rx + abs(cell_center.y - grid_center.y) / ry <= 1.0
		Constants.MapShape.Cross:
			var mid_x: float = grid_size.x / 2.0
			var mid_y: float = grid_size.y / 2.0
			var thickness: int = max(1, int(min(grid_size.x, grid_size.y) * 0.25))
			return abs(cell.x + 0.5 - mid_x) <= thickness or abs(cell.y + 0.5 - mid_y) <= thickness
		Constants.MapShape.Ring:
			var radius_outer: float = min(grid_size.x, grid_size.y) * quadrant_size.x / 2.0
			var radius_inner: float = radius_outer * 0.5
			var distance: float = cell_center.distance_to(grid_center)
			return distance <= radius_outer and distance >= radius_inner
		Constants.MapShape.LShape:
			var thickness: int = max(1, int(min(grid_size.x, grid_size.y) * 0.3))
			return cell.x < thickness or cell.y >= grid_size.y - thickness
		_:
			return true

## Check if a point is inside a shape.
## [param point]: The point to check.
## [param grid_size]: Size of the grid.
## [param quadrant_size]: Size of each quadrant.
## [param map_shape]: The shape type from Constants.MapShape.
## [return]: True if the point is inside the shape.
static func is_point_in_shape(point: Vector2, grid_size: Vector2i, quadrant_size: Vector2i, map_shape: Constants.MapShape) -> bool:
	var grid_center: Vector2 = calculate_grid_center(grid_size, quadrant_size)
	
	match map_shape:
		Constants.MapShape.Circle:
			var radius: float = min(grid_size.x, grid_size.y) * quadrant_size.x / 2.0
			return point.distance_to(grid_center) <= radius
		Constants.MapShape.Diamond:
			var rx: float = grid_size.x * quadrant_size.x / 2.0
			var ry: float = grid_size.y * quadrant_size.y / 2.0
			return abs(point.x - grid_center.x) / rx + abs(point.y - grid_center.y) / ry <= 1.0
		Constants.MapShape.Cross:
			var mid_x: float = grid_size.x * quadrant_size.x / 2.0
			var mid_y: float = grid_size.y * quadrant_size.y / 2.0
			var thickness: float = max(quadrant_size.x, quadrant_size.y) * min(grid_size.x, grid_size.y) * 0.1
			return abs(point.x - mid_x) <= thickness or abs(point.y - mid_y) <= thickness
		Constants.MapShape.Ring:
			var radius_outer: float = min(grid_size.x, grid_size.y) * quadrant_size.x / 2.0
			var radius_inner: float = radius_outer * 0.5
			var d: float = point.distance_to(grid_center)
			return d <= radius_outer and d >= radius_inner
		Constants.MapShape.LShape:
			var thickness: float = max(quadrant_size.x, quadrant_size.y) * min(grid_size.x, grid_size.y) * 0.3
			return point.x <= thickness or point.y >= grid_size.y * quadrant_size.y - thickness
		_:
			return Rect2(Vector2.ZERO, Vector2(quadrant_size) * Vector2(grid_size)).has_point(point)

## Get a random position within a shape.
## [param grid_size]: Size of the grid.
## [param quadrant_size]: Size of each quadrant.
## [param map_shape]: The shape type from Constants.MapShape.
## [param padding]: Padding from the edges.
## [param rng]: RandomNumberGenerator instance.
## [return]: A random Vector2 position within the shape.
static func random_position_in_shape(grid_size: Vector2i, quadrant_size: Vector2i, map_shape: Constants.MapShape, padding: float, rng: RandomNumberGenerator) -> Vector2:
	var grid_center: Vector2 = calculate_grid_center(grid_size, quadrant_size)
	var min_pos: Vector2 = Vector2(padding, padding)
	var max_pos: Vector2 = Vector2(quadrant_size) * Vector2(grid_size) - Vector2(padding, padding)
	var attempts: int = 0
	
	while attempts < 50:
		var random_x: float = rng.randf_range(min_pos.x, max_pos.x)
		var random_y: float = rng.randf_range(min_pos.y, max_pos.y)
		var p: Vector2 = Vector2(random_x, random_y)
		if is_point_in_shape(p, grid_size, quadrant_size, map_shape):
			return p
		attempts += 1
	
	return grid_center

## Check if a cell is on the border of the grid (for mining mode).
## [param cell]: The cell coordinates.
## [param grid_size]: Size of the grid.
## [return]: True if the cell is on left, right, or bottom border.
static func is_border_cell(cell: Vector2i, grid_size: Vector2i) -> bool:
	return cell.x == 0 or cell.x == grid_size.x - 1 or cell.y == grid_size.y - 1

## Get all valid cells within a shape (pre-computed for efficiency).
## [param grid_size]: Size of the grid.
## [param quadrant_size]: Size of each quadrant.
## [param map_shape]: The shape type.
## [return]: Array of Vector2i cells that are within the shape.
static func get_valid_cells(grid_size: Vector2i, quadrant_size: Vector2i, map_shape: Constants.MapShape) -> Array[Vector2i]:
	var valid_cells: Array[Vector2i] = []
	for i in range(grid_size.x):
		for j in range(grid_size.y):
			var cell: Vector2i = Vector2i(i, j)
			if is_cell_in_shape(cell, grid_size, quadrant_size, map_shape):
				valid_cells.append(cell)
	return valid_cells

## Convert grid cell to world position.
## [param cell]: Grid cell coordinates.
## [param quadrant_size]: Size of each quadrant.
## [return]: World position of the cell's top-left corner.
static func cell_to_world(cell: Vector2i, quadrant_size: Vector2i) -> Vector2:
	return Vector2(cell.x * quadrant_size.x, cell.y * quadrant_size.y)

## Convert world position to grid cell.
## [param position]: World position.
## [param quadrant_size]: Size of each quadrant.
## [return]: Grid cell coordinates.
static func world_to_cell(position: Vector2, quadrant_size: Vector2i) -> Vector2i:
	return Vector2i(int(position.x / quadrant_size.x), int(position.y / quadrant_size.y))

## Calculate depth layer from Y grid position.
## [param y_position]: Y coordinate in grid.
## [param grid_height]: Total grid height.
## [param max_depth]: Maximum depth layer value.
## [return]: Depth layer (0 to max_depth).
static func calculate_depth_layer(y_position: int, grid_height: int, max_depth: int = 20) -> int:
	return int((float(y_position) / grid_height) * max_depth)
