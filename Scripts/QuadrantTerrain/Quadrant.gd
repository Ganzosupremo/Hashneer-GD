extends Node2D
class_name Quadrant

var is_carved: bool = false
var can_carve: bool = false
var initial_health: float = 100.0
var current_health: float= 0.0
var default_quadrant_polygon: PackedVector2Array = []
var resource_droprate: float = 0.5
@onready var static_body = %StaticBody
@onready var ColPol_scene : PackedScene = preload("res://Scenes/QuadrantTerrain/Col_pol.tscn")

func _ready():
	init_quadrant()

func init_quadrant():
	"""
	Initiates the default (square) ColPol
	"""
	current_health = initial_health
	static_body.add_child(create_new_colpol(default_quadrant_polygon))
	can_carve = false
	is_carved = false

func reset_quadrant():
	"""
	Removes all collision polygons
	and initiates the default ColPol
	"""
	for colpol in static_body.get_children():
		colpol.free()
	init_quadrant()

func take_damage(damage: float) -> float:
	current_health = max(0, current_health - damage)  # Clamp the value to a minimum of 0
#	print("Quadrant health: ", current_health)
	
	if current_health <= 0.0 and not is_carved:
		can_carve = true
#		print("Quadrant can be carved!")
	return current_health

func update_colpol_texture(four_quadrants: Array, new_texture: Texture2D) -> void:
	for quadrant in four_quadrants:
		for new_colpol in quadrant.static_body.get_children():
			new_colpol.update_texture_polygon(new_texture)

func carve(clipping_polygon: PackedVector2Array, polygon_texture: Texture2D = null) -> void:
	"""
	Carves the clipping_polygon away from the quadrant
	"""
#	take_damage(damage)
#	if not can_carve and is_carved: return
	
	for colpol in static_body.get_children():
		var clipped_polygons = Geometry2D.clip_polygons(colpol.polygon, clipping_polygon)
		var n_clipped_polygons = len(clipped_polygons)
		match n_clipped_polygons:
			0:
				# clipping_polygon completely overlaps colpol
				colpol.free()
			1:
				# Clipping produces only one polygon
				colpol.call_deferred("update_pol", clipped_polygons[0], polygon_texture)
			2:
				# Check if you carved a hole (one of the two polygons
				# is clockwise). If so, split the polygon in two that
				# together make a "hollow" collision shape
				if is_hole(clipped_polygons):
					# split and add
					for p in split_polygon(clipping_polygon):
						var new_colpol = create_new_colpol(
							Geometry2D.intersect_polygons(p, colpol.polygon)[0])
						static_body.call_deferred("add_child", new_colpol)
					colpol.free()
				# if its not a hole, behave as in match _
				else:
					colpol.call_deferred("update_pol", clipped_polygons[0], polygon_texture)
					for i in range(n_clipped_polygons-1):
						static_body.call_deferred("add_child", create_new_colpol(clipped_polygons[i+1]))
			
			# if more than two polygons, simply add all of
			# them to the quadrant
			_:
				colpol.call_deferred("update_pol", clipped_polygons[0], polygon_texture)
				for i in range(n_clipped_polygons - 1):
					static_body.call_deferred("add_child", create_new_colpol(clipped_polygons[i + 1]))
	is_carved = true
	can_carve = false
	current_health = initial_health

func is_hole(clipped_polygons) -> bool:
	"""
	If either of the two polygons after clipping
	are clockwise, then you have carved a hole
	"""
	return Geometry2D.is_polygon_clockwise(clipped_polygons[0]) or Geometry2D.is_polygon_clockwise(clipped_polygons[1])

func split_polygon(clip_polygon: Array) -> Array:
	"""
	Returns two polygons produced by vertically
	splitting split_polygon in half
	"""
	var avg_x = average_position(clip_polygon).x
	
	var left_subquadrant = default_quadrant_polygon.duplicate()
	left_subquadrant[1] = Vector2(avg_x, left_subquadrant[1].y)
	left_subquadrant[2] = Vector2(avg_x, left_subquadrant[2].y)
	
	var right_subquadrant = default_quadrant_polygon.duplicate()
	right_subquadrant[0] = Vector2(avg_x, right_subquadrant[0].y)
	right_subquadrant[3] = Vector2(avg_x, right_subquadrant[3].y)
	
	var pol1 = Geometry2D.clip_polygons(left_subquadrant, clip_polygon)[0]
	var pol2 = Geometry2D.clip_polygons(right_subquadrant, clip_polygon)[0]
	return [pol1, pol2]

func average_position(array: Array) -> Vector2:
	"""
	Average 2D position in an
	array of positions
	"""
	var sum : Vector2 = Vector2()
	for p in array:
		sum += p
	return sum/len(array)

func create_new_colpol(polygon : Array) -> CollisionPolygon2D:
	"""
	Returns ColPol instance
	with assigned polygon
	"""
	var colpol = ColPol_scene.instantiate()
	colpol.polygon = polygon
	return colpol
