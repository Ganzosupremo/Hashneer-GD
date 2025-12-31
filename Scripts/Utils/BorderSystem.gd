class_name BorderSystem extends Node2D
## Unified border system with consistent cyberpunk visuals.
##
## Creates physical and visual borders for game world boundaries.
## Supports both mining mode (with shop layer) and other game modes.

@export_category("Border Settings")
@export var border_thickness: float = 50.0
@export var border_color: Color = Color(0.1, 0.15, 0.25, 1.0)
@export var accent_color: Color = Color(0.3, 0.6, 0.9, 0.8)
@export var grid_line_color: Color = Color(0.3, 0.5, 0.7, 0.3)
@export var glow_color: Color = Color(0.4, 0.7, 1.0, 0.5)

var _left_border: StaticBody2D
var _right_border: StaticBody2D
var _bottom_border: StaticBody2D
var _top_border: StaticBody2D

var _terrain_bounds: Rect2
var _shop_layer_height: float = 500.0

## Generate borders for mining mode (shop layer + mining area).
## [param terrain_width]: Width of the mining terrain.
## [param terrain_height]: Height of the mining terrain.
## [param shop_height]: Height of the shop layer above terrain.
func generate_mining_borders(terrain_width: float, terrain_height: float, shop_height: float) -> void:
	_shop_layer_height = shop_height
	_terrain_bounds = Rect2(Vector2.ZERO, Vector2(terrain_width, terrain_height))
	
	_clear_borders()
	_create_shop_left_border()
	_create_shop_right_border()
	_create_shop_top_border()

## Generate borders for standard game modes.
## [param grid_size]: Grid dimensions.
## [param quadrant_size]: Size of each quadrant.
func generate_standard_borders(grid_size: Vector2i, quadrant_size: Vector2) -> void:
	var terrain_width: float = grid_size.x * quadrant_size.x
	var terrain_height: float = grid_size.y * quadrant_size.y
	
	_terrain_bounds = Rect2(Vector2.ZERO, Vector2(terrain_width, terrain_height))
	_shop_layer_height = 0.0
	
	_clear_borders()
	_create_left_border()
	_create_right_border()
	_create_bottom_border()
	_create_top_border()
	_create_depth_markers()

## Clear all existing borders.
func _clear_borders() -> void:
	if _left_border:
		_left_border.queue_free()
	if _right_border:
		_right_border.queue_free()
	if _bottom_border:
		_bottom_border.queue_free()
	if _top_border:
		_top_border.queue_free()
	_left_border = null
	_right_border = null
	_bottom_border = null
	_top_border = null

## Get the shop layer bounds.
func get_shop_layer_bounds() -> Rect2:
	return Rect2(
		Vector2(0, -_shop_layer_height),
		Vector2(_terrain_bounds.size.x, _shop_layer_height)
	)

## Get the mining/terrain bounds.
func get_mining_bounds() -> Rect2:
	return _terrain_bounds

## Check if a position is in the shop layer.
func is_in_shop_layer(pos: Vector2) -> bool:
	return get_shop_layer_bounds().has_point(pos)

## Check if a position is in the mining layer.
func is_in_mining_layer(pos: Vector2) -> bool:
	return _terrain_bounds.has_point(pos)

func _create_border(border_name: String, size: Vector2, pos: Vector2) -> StaticBody2D:
	var border: StaticBody2D = StaticBody2D.new()
	border.name = border_name
	add_child(border)
	
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	border.add_child(collision)
	border.position = pos
	
	var visual: ColorRect = ColorRect.new()
	visual.color = border_color
	visual.size = size
	visual.position = -size / 2
	border.add_child(visual)
	
	_add_cyberpunk_pattern(visual)
	_add_glow_effect(border, size)
	
	return border

func _create_left_border() -> void:
	var size: Vector2 = Vector2(border_thickness, _terrain_bounds.size.y + _shop_layer_height)
	var pos: Vector2 = Vector2(-border_thickness / 2, (_terrain_bounds.size.y - _shop_layer_height) / 2)
	_left_border = _create_border("LeftBorder", size, pos)

func _create_right_border() -> void:
	var size: Vector2 = Vector2(border_thickness, _terrain_bounds.size.y + _shop_layer_height)
	var pos: Vector2 = Vector2(_terrain_bounds.end.x + border_thickness / 2, (_terrain_bounds.size.y - _shop_layer_height) / 2)
	_right_border = _create_border("RightBorder", size, pos)

func _create_bottom_border() -> void:
	var size: Vector2 = Vector2(_terrain_bounds.size.x + border_thickness * 2, border_thickness)
	var pos: Vector2 = Vector2(_terrain_bounds.size.x / 2, _terrain_bounds.end.y + border_thickness / 2)
	_bottom_border = _create_border("BottomBorder", size, pos)

func _create_top_border() -> void:
	var size: Vector2 = Vector2(_terrain_bounds.size.x + border_thickness * 2, border_thickness)
	var pos: Vector2 = Vector2(_terrain_bounds.size.x / 2, -_shop_layer_height - border_thickness / 2)
	_top_border = _create_border("TopBorder", size, pos)

func _create_shop_left_border() -> void:
	var size: Vector2 = Vector2(border_thickness, _shop_layer_height)
	var pos: Vector2 = Vector2(-border_thickness / 2, -_shop_layer_height / 2)
	_left_border = _create_border("ShopLeftBorder", size, pos)

func _create_shop_right_border() -> void:
	var size: Vector2 = Vector2(border_thickness, _shop_layer_height)
	var pos: Vector2 = Vector2(_terrain_bounds.size.x + border_thickness / 2, -_shop_layer_height / 2)
	_right_border = _create_border("ShopRightBorder", size, pos)

func _create_shop_top_border() -> void:
	var size: Vector2 = Vector2(_terrain_bounds.size.x, border_thickness)
	var pos: Vector2 = Vector2(_terrain_bounds.size.x / 2, -_shop_layer_height - border_thickness / 2)
	_top_border = _create_border("ShopTopBorder", size, pos)

func _add_cyberpunk_pattern(visual: ColorRect) -> void:
	var pattern: Node2D = Node2D.new()
	pattern.name = "CyberpunkPattern"
	visual.add_child(pattern)
	
	var line_spacing: int = 25
	
	for i in range(0, int(visual.size.y), line_spacing):
		var line: Line2D = Line2D.new()
		line.add_point(Vector2(0, i))
		line.add_point(Vector2(visual.size.x, i))
		line.default_color = grid_line_color
		line.width = 1.0
		pattern.add_child(line)
	
	for i in range(0, int(visual.size.x), line_spacing):
		var line: Line2D = Line2D.new()
		line.add_point(Vector2(i, 0))
		line.add_point(Vector2(i, visual.size.y))
		line.default_color = grid_line_color
		line.width = 1.0
		pattern.add_child(line)
	
	_add_accent_lines(pattern, visual.size)

func _add_accent_lines(pattern: Node2D, size: Vector2) -> void:
	var accent_line_top: Line2D = Line2D.new()
	accent_line_top.add_point(Vector2(0, 2))
	accent_line_top.add_point(Vector2(size.x, 2))
	accent_line_top.default_color = accent_color
	accent_line_top.width = 2.0
	pattern.add_child(accent_line_top)
	
	var accent_line_bottom: Line2D = Line2D.new()
	accent_line_bottom.add_point(Vector2(0, size.y - 2))
	accent_line_bottom.add_point(Vector2(size.x, size.y - 2))
	accent_line_bottom.default_color = accent_color
	accent_line_bottom.width = 2.0
	pattern.add_child(accent_line_bottom)

func _add_glow_effect(border: StaticBody2D, size: Vector2) -> void:
	var glow: ColorRect = ColorRect.new()
	glow.name = "GlowEffect"
	glow.color = glow_color
	glow.size = Vector2(4, size.y)
	glow.position = Vector2(-size.x / 2 - 2, -size.y / 2)
	glow.z_index = -1
	border.add_child(glow)

func _create_depth_markers() -> void:
	var depth_markers: Node2D = Node2D.new()
	depth_markers.name = "DepthMarkers"
	add_child(depth_markers)
	
	var layers_count: int = 20
	var layer_height: float = _terrain_bounds.size.y / layers_count
	
	for i in range(layers_count + 1):
		var marker: Label = Label.new()
		marker.text = "D:%d" % i
		marker.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0, 0.7))
		marker.position = Vector2(-60, (i * layer_height) - 10)
		depth_markers.add_child(marker)
		
		var line: Line2D = Line2D.new()
		line.add_point(Vector2(0, i * layer_height))
		line.add_point(Vector2(_terrain_bounds.size.x, i * layer_height))
		line.default_color = Color(0.3, 0.5, 0.7, 0.2)
		line.width = 2.0
		line.z_index = -1
		depth_markers.add_child(line)
