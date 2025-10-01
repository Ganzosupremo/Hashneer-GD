class_name PolygonRestorer

var shape_stack : Array = []
var cur_entry : Dictionary

func _init() -> void:
	cur_entry = createShapeEntry(PackedVector2Array([]), -1.0, true)

func getOriginShape() -> PackedVector2Array:
	if shape_stack.size() <= 0:
		if cur_entry:
			return cur_entry.shape
		else:
			return PackedVector2Array([])
	else:
		return shape_stack.front().shape

func getOriginArea() -> float:
	if shape_stack.size() <= 0:
		if cur_entry:
			return cur_entry.area
		else:
			return -1.0
	else:
		return shape_stack.front().area

func getCurShape() -> PackedVector2Array:
	if shape_stack.size() <= 0:
		return getOriginShape()
	else:
		return cur_entry.shape

func getCurArea() -> float:
	if shape_stack.size() <= 0:
		return getOriginArea()
	else:
		return cur_entry.area

func clear() -> void:
	shape_stack.clear()
	cur_entry = createShapeEntry(PackedVector2Array([]), -1.0, true)

func addShape(shape : PackedVector2Array, shape_area : float = -1.0) -> void:
	if not cur_entry.empty:
		shape_stack.push_back(cur_entry)
	
	cur_entry =  createShapeEntry(shape, shape_area)

func popLast() -> Dictionary:
	if shape_stack.size() <= 0:
		return createShapeEntry(PackedVector2Array([]), -1.0, true)
	
	cur_entry = shape_stack.pop_back()
	return cur_entry

func getLast() -> Dictionary:
	if shape_stack.size() <= 0:
		return createShapeEntry(PackedVector2Array([]), -1.0, true)
	else:
		return shape_stack.back()

func createShapeEntry(shape : PackedVector2Array, area : float = -1.0, empty : bool = false) -> Dictionary:
	if area <= 0.0:
		area = PolygonLib.getPolygonArea(shape)
	
	var origin_area : float = getOriginArea()
	var total_p : float = 1.0
	if origin_area > 0.0:
		total_p = area / origin_area
	
	var delta_p : float = 0.0
	if shape_stack.size() > 0:
		delta_p = getLast().total_p - total_p
	
	return {"shape" : shape, "area" : area, "total_p" : total_p, "delta_p" : delta_p, "empty" : empty}
