extends FracturableStaticBody2D

func create_polygon_shape() -> PackedVector2Array:
	var poly_fracture: PolygonFracture = PolygonFracture.new()
	return poly_fracture.generateRandomPolygon(Vector2(20, 20), Vector2(1.0, 5.0))
