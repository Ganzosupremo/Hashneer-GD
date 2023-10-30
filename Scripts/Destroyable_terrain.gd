extends Node2D
class_name DestroyableTerrain

@onready var collision_polygon : CollisionPolygon2D = %CollisionPolygon2D
@onready var terrain_polygon : Polygon2D = %Terrain

var coins : int = 0

func _ready():
	collision_polygon.polygon = terrain_polygon.polygon

func clip(polygon : CollisionPolygon2D) -> void:
#	var offset_polygon = Polygon2D.new()
	var offset_polygon = Transform2D(0, polygon.global_position) * polygon.polygon
#	offset_polygon.global_position = Vector2.ZERO
	
#	offset the polygon points to take into account the transformation
	var new_values = []
	for point in polygon.polygon:
		new_values.append(point + polygon.global_position)
	
	offset_polygon = PackedVector2Array(new_values)
	var result = Geometry2D.clip_polygons(collision_polygon.polygon, offset_polygon)
	
	terrain_polygon.polygon = result[0]
	collision_polygon.set_deferred("polygon", result[0])
	
	coins += 10
	print(coins)
	
#	add_islands(result)

func add_islands(result) -> void:
	if result.size() > 1:
		for i in range(len(result)):
			var island = Polygon2D.new()
			var island_collision = CollisionPolygon2D.new()
			island.global_position = Vector2.ZERO
			island_collision.global_position = Vector2.ZERO
			island.color = terrain_polygon.color
			
			island.polygon = result[i]
			island_collision.set_deferred("polygon", result[i])
			
			add_child(island)
			collision_polygon.add_child(island_collision)
