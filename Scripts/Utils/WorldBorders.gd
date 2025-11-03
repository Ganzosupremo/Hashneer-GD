class_name WorldBorders extends Node2D
## Manages the world borders for mining game mode.
## 
## This script creates invisible borders around the mining terrain to prevent players from exiting the playable area.
## It also provides utility functions to check if a position is within the mining or shop layers.
##

@export var border_thickness: float = 50.0
@export var border_color: Color = Color(0.2, 0.2, 0.3, 1.0)  # Dark blue-gray
@export var grid_line_color: Color = Color(0.3, 0.5, 0.7, 0.3)  # Cyan tint

var _left_border: StaticBody2D
var _right_border: StaticBody2D
var _bottom_border: StaticBody2D
var _top_border: StaticBody2D

var _terrain_bounds: Rect2
var _shop_layer_height: float = 500.0

const UNFRACTURABLE_TERRAIN = preload("res://Scenes/FracturableTerrain/UnfracturableTerrainTemplate.tscn")

## Generate borders for shop layer only (mining borders are part of the grid).[br]
## [param terrain_width: float] The actual width of the terrain from grid generation.[br]
## [param terrain_height: float] The actual height of the mining terrain from grid generation.[br]
## [param shop_height: float] The height of the shop layer.
func generate_shop_layer_borders(terrain_width: float, terrain_height: float, shop_height: float) -> void:
	_shop_layer_height = shop_height
	# Store exact terrain bounds from grid generation
	_terrain_bounds = Rect2(
		Vector2.ZERO,
		Vector2(terrain_width, terrain_height)
	)
	
	# Create borders for all sides of shop layer
	_create_shop_left_border()
	_create_shop_right_border()
	_create_shop_top_border()

## Legacy method - kept for compatibility with non-mining modes
func generate_borders(grid_size: Vector2i, quadrant_size: Vector2) -> void:
	var terrain_width = grid_size.x * quadrant_size.x
	var terrain_height = grid_size.y * quadrant_size.y
	
	_terrain_bounds = Rect2(
		Vector2.ZERO,
		Vector2(terrain_width, terrain_height)
	)
	
	# Create borders
	_create_left_border()
	_create_right_border()
	_create_bottom_border()
	_create_top_border()
	
	# Create visual grid lines
	_create_grid_overlay()

## Get the shop layer bounds as a Rect2.[br]
## [return: Rect2] The shop layer bounds
func get_shop_layer_bounds() -> Rect2:
	return Rect2(
		Vector2(0, -_shop_layer_height),
		Vector2(_terrain_bounds.size.x, _shop_layer_height)
	)

## Get the mining bounds as a Rect2.[br]
## [return: Rect2] The mining bounds
func get_mining_bounds() -> Rect2:
	return _terrain_bounds

## Check if a position is within the shop layer.[br]
## [param position: Vector2] The position to check.[br]
## [return: bool] True if within shop layer, false otherwise
func is_in_shop_layer(pos: Vector2) -> bool:
	var shop_bounds = get_shop_layer_bounds()
	return shop_bounds.has_point(pos)

## Check if a position is within the mining layer.[br]
## [param position: Vector2] The position to check.[br]
## [return: bool] True if within mining layer, false otherwise
func is_in_mining_layer(pos: Vector2) -> bool:
	return _terrain_bounds.has_point(pos)

func _create_left_border() -> void:
	_left_border = StaticBody2D.new()
	_left_border.name = "LeftBorder"
	add_child(_left_border)
	
	# Collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(border_thickness, _terrain_bounds.size.y + _shop_layer_height)
	collision.shape = shape
	_left_border.add_child(collision)
	
	# Position: Directly touching left edge of terrain (no gap)
	_left_border.position = Vector2(
		-border_thickness / 2,
		(_terrain_bounds.size.y - _shop_layer_height) / 2
	)
	
	# Visual representation
	var visual = ColorRect.new()
	visual.color = border_color
	visual.size = shape.size
	visual.position = -shape.size / 2
	_left_border.add_child(visual)
	
	# Add grid pattern
	_add_border_pattern(visual)

func _create_right_border() -> void:
	_right_border = StaticBody2D.new()
	_right_border.name = "RightBorder"
	add_child(_right_border)
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(border_thickness, _terrain_bounds.size.y + _shop_layer_height)
	collision.shape = shape
	_right_border.add_child(collision)
	
	# Position: Directly touching right edge of terrain (no gap)
	_right_border.position = Vector2(
		_terrain_bounds.end.x + border_thickness / 2,
		(_terrain_bounds.size.y - _shop_layer_height) / 2
	)
	
	var visual = ColorRect.new()
	visual.color = border_color
	visual.size = shape.size
	visual.position = -shape.size / 2
	_right_border.add_child(visual)
	_add_border_pattern(visual)

func _create_bottom_border() -> void:
	_bottom_border = StaticBody2D.new()
	_bottom_border.name = "BottomBorder"
	add_child(_bottom_border)

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	# Extend width to match border thickness on sides
	shape.size = Vector2(_terrain_bounds.size.x + border_thickness * 2, border_thickness)
	collision.shape = shape
	_bottom_border.add_child(collision)

	# Position: Directly at bottom edge of terrain (end.y = position.y + size.y)
	_bottom_border.position = Vector2(
		_terrain_bounds.size.x / 2,
		_terrain_bounds.end.y + border_thickness / 2
	)
	
	var visual = ColorRect.new()
	visual.color = border_color
	visual.size = shape.size
	visual.position = -shape.size / 2
	_bottom_border.add_child(visual)
	_add_border_pattern(visual)

func _create_top_border() -> void:
	_top_border = StaticBody2D.new()
	_top_border.name = "TopBorder"
	add_child(_top_border)

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	# Extend width to match border thickness on sides
	shape.size = Vector2(_terrain_bounds.size.x + border_thickness * 2, border_thickness)
	collision.shape = shape
	_top_border.add_child(collision)

	# Position: At top of shop layer
	_top_border.position = Vector2(
		_terrain_bounds.size.x / 2,
		-_shop_layer_height - border_thickness / 2
	)
	
	var visual = ColorRect.new()
	visual.color = border_color
	visual.size = shape.size
	visual.position = -shape.size / 2
	_top_border.add_child(visual)
	_add_border_pattern(visual)

func _create_shop_top_border() -> void:
	_top_border = StaticBody2D.new()
	_top_border.name = "ShopTopBorder"
	add_child(_top_border)

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	# Match terrain width exactly (no need to extend for sides)
	shape.size = Vector2(_terrain_bounds.size.x, border_thickness)
	collision.shape = shape
	_top_border.add_child(collision)

	# Position: At top of shop layer
	_top_border.position = Vector2(
		_terrain_bounds.size.x / 2,
		-_shop_layer_height - border_thickness / 2
	)
	
	var visual = ColorRect.new()
	visual.color = border_color
	visual.size = shape.size
	visual.position = -shape.size / 2
	_top_border.add_child(visual)
	_add_border_pattern(visual)

func _create_shop_left_border() -> void:
	_left_border = StaticBody2D.new()
	_left_border.name = "ShopLeftBorder"
	add_child(_left_border)
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	# Only spans shop layer height
	shape.size = Vector2(border_thickness, _shop_layer_height)
	collision.shape = shape
	_left_border.add_child(collision)
	
	# Position: Left edge, centered in shop layer
	_left_border.position = Vector2(
		-border_thickness / 2,
		-_shop_layer_height / 2
	)
	
	var visual = ColorRect.new()
	visual.color = border_color
	visual.size = shape.size
	visual.position = -shape.size / 2
	_left_border.add_child(visual)
	_add_border_pattern(visual)

func _create_shop_right_border() -> void:
	_right_border = StaticBody2D.new()
	_right_border.name = "ShopRightBorder"
	add_child(_right_border)
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	# Only spans shop layer height
	shape.size = Vector2(border_thickness, _shop_layer_height)
	collision.shape = shape
	_right_border.add_child(collision)
	
	# Position: Right edge, centered in shop layer
	_right_border.position = Vector2(
		_terrain_bounds.size.x + border_thickness / 2,
		-_shop_layer_height / 2
	)
	
	var visual = ColorRect.new()
	visual.color = border_color
	visual.size = shape.size
	visual.position = -shape.size / 2
	_right_border.add_child(visual)
	_add_border_pattern(visual)

func _add_border_pattern(visual: ColorRect) -> void:
	# Add digital/circuit board pattern using Line2D
	var pattern = Node2D.new()
	visual.add_child(pattern)
	
	# Horizontal lines
	for i in range(0, int(visual.size.y), 50):
		var line = Line2D.new()
		line.add_point(Vector2(0, i))
		line.add_point(Vector2(visual.size.x, i))
		line.default_color = grid_line_color
		line.width = 1.0
		pattern.add_child(line)
	
	# Vertical lines
	for i in range(0, int(visual.size.x), 50):
		var line = Line2D.new()
		line.add_point(Vector2(i, 0))
		line.add_point(Vector2(i, visual.size.y))
		line.default_color = grid_line_color
		line.width = 1.0
		pattern.add_child(line)

func _create_grid_overlay() -> void:
	# Create depth layer indicators on left border
	var depth_markers = Node2D.new()
	depth_markers.name = "DepthMarkers"
	add_child(depth_markers)  # Add to WorldBorders instead of left_border
	
	var layers_count = 20
	var layer_height = _terrain_bounds.size.y / layers_count

	for i in range(layers_count + 1):
		var marker = Label.new()
		marker.text = "D:%d" % i
		marker.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0, 0.7))
		marker.position = Vector2(
			-60,  # Fixed position outside left border
			(i * layer_height) - 10
		)
		depth_markers.add_child(marker)
		
		# Horizontal depth line across terrain
		var line = Line2D.new()
		line.add_point(Vector2(0, i * layer_height))
		line.add_point(Vector2(_terrain_bounds.size.x, i * layer_height))
		line.default_color = Color(0.3, 0.5, 0.7, 0.2)
		line.width = 2.0
		line.z_index = -1  # Behind terrain
		depth_markers.add_child(line)
