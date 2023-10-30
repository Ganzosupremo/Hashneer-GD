extends CollisionPolygon2D
class_name ColPol

@onready var texture_polygon : Polygon2D = %Polygon2D

func _ready():
	texture_polygon.polygon = polygon

func update_pol(polygon_points: PackedVector2Array, polygon_texture: Texture2D) -> void:
	polygon = polygon_points
	texture_polygon.polygon = polygon
	
	if polygon_texture != null:
		update_texture_polygon(polygon_texture)

func update_texture_polygon(new_texture: Texture2D) -> void:
	texture_polygon.texture = new_texture
