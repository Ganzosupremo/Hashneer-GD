extends Node2D
class_name  QuadrantBuilder

@export var quadrant_size : int = 100
@export var quadrant_grid_size :Vector2 = Vector2(10,5)
@export var colpol_texture: Texture2D
@export var resource_droprate_multiplier: float = 1.5

var quadrants_grid: Array = []
var quadrant : PackedScene = preload("res://Scenes/QuadrantTerrain/Quadrant.tscn")
var block_core: PackedScene = preload("res://Scenes/QuadrantTerrain/block_center.tscn")
var core_ins: CenterBlock = null
static var instance: QuadrantBuilder: get = get_instance
var currency: float = 0.0

@onready var carve_area : Polygon2D = %CarveArea
@onready var quadrants : Node2D = %Quadrants
@onready var player := %Player

func _ready():
	instance = self
	spawn_quadrants()

func spawn_quadrants():
	for i in range(quadrant_grid_size.x):
		quadrants_grid.push_back([])
		for j in range(quadrant_grid_size.y):
			var quadrant_ins: Quadrant = quadrant.instantiate()
			quadrant_ins.default_quadrant_polygon = [
				Vector2(quadrant_size*i,quadrant_size*j),
				Vector2(quadrant_size*(i+1),quadrant_size*j),
				Vector2(quadrant_size*(i+1),quadrant_size*(j+1)),
				Vector2(quadrant_size*i,quadrant_size*(j+1))]
			quadrant_ins.add_to_group("QuadrantTerrain")
			quadrants_grid[-1].push_back(quadrant)
			quadrants.add_child(quadrant_ins)
	spawn_block_core()

func spawn_block_core():
	var center_x = quadrant_size * quadrant_grid_size.x * 0.5
	var center_y = quadrant_size * quadrant_grid_size.y * 0.5
	core_ins = block_core.instantiate()
	add_child(core_ins)
#	var random_x = randf_range(quadrant_size, quadrant_grid_size.x * 0.5)
#	var random_y = randf_range(quadrant_size, quadrant_grid_size.y * 0.5)
	var spawn_pos: Vector2 = Vector2(center_x, center_y)
	core_ins.block_center_mined.connect(Callable(self, "_on_block_center_block_center_mined"))
	core_ins.global_position = spawn_pos

func carve(quadrant_position : Vector2, other_polygon : CollisionPolygon2D, damage: float = 0.0) -> void:
	var new_polygon: PackedVector2Array = Transform2D(0, quadrant_position) * other_polygon.polygon
	var four_quadrants = get_affected_quadrants(quadrant_position, other_polygon)
	for quadrant_new in four_quadrants:
		if quadrant_new.take_damage(damage) == 0.0:
			quadrant_new.carve(new_polygon, colpol_texture)

func get_affected_quadrants(pos: Vector2, other_polygon: CollisionPolygon2D) -> Array:
	"""
	Returns array of Quadrants that are affected by
	the carving.
	"""
	var affected_quadrants_array = []
#	var should: bool = false
	for quadrant_new in quadrants.get_children():
		var quadrant_top_left = quadrant_new.default_quadrant_polygon[0]
		var quadrant_bottom_right = quadrant_new.default_quadrant_polygon[2]
		
		# Check if the carving circle intersects with the bounding box of the quadrant
		if is_polygon_intersects_aabb(pos, other_polygon.polygon, quadrant_top_left, quadrant_bottom_right):
			affected_quadrants_array.push_back(quadrant_new)
		
	return affected_quadrants_array

func is_polygon_intersects_aabb(polygon_pos: Vector2, polygon_points: PackedVector2Array, aabb_min: Vector2, aabb_max: Vector2) -> bool:
	"""Checks if a circle intersects with an axis-aligned bounding box (AABB). 
	It does this by finding the closest point on the AABB to the circle's center and 
	then checking if this point is inside the circle. If it is, the circle and AABB intersect."""
	# Check if any point of the polygon is inside the AABB
	var buffer: float = 3.0
	aabb_min -= Vector2(buffer, buffer)
	aabb_max += Vector2(buffer, buffer)

#	for point in polygon_points:
#		if point + polygon_pos > aabb_min and point + polygon_pos < aabb_max:
#			print("inside AABB")
#			return true
		
	# Check if any point of the AABB is inside the polygon
	var aabb_points = [aabb_min, Vector2(aabb_max.x, aabb_min.y), aabb_max, Vector2(aabb_min.x, aabb_max.y)]
	for point in aabb_points:
		if Geometry2D.is_point_in_polygon(point, polygon_points):
			return true
	
	# Check for edge-edge intersection between the polygon and the AABB
	for i in range(polygon_points.size()):
		var p1 = polygon_points[i] + polygon_pos
		var p2 = polygon_points[(i+1) % polygon_points.size()] + polygon_pos
		for j in range(4):
			var q1 = aabb_points[j]
			var q2 = aabb_points[(j+1) % 4]
			if Geometry2D.segment_intersects_segment(p1, p2, q1, q2):
				return true
	return false

func _on_center_body_entered(body: Node2D) -> void:
	print(body)

func _on_center_area_entered(area: Area2D) -> void:
	if area is BulletC:
		core_ins.take_damage(area.bullet_damage)

func _on_block_center_block_center_mined() -> void:
	print(BitcoinNetwork.issue_coins(SceneManager.current_level_index))

static func get_instance() -> QuadrantBuilder:
	return instance
