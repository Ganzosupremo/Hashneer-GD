class_name PolygonLib
## A library of static functions for polygon manipulation, cutting, triangulation, and utilities.
##
## This library provides a variety of functions to work with 2D polygons, including
## operations such as cutting, merging, and triangulating polygons, as well as
## utility functions for working with points and vectors in 2D space.

# MIT License
# -----------------------------------------------------------------------
#                       This file is part of:                           
#                     GODOT Polygon 2D Fracture                         
#           https://github.com/SoloByte/godot-polygon2d-fracture          
# -----------------------------------------------------------------------
# Copyright (c) 2021 David Grueneis
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.




## SUPERSHAPE - SUPERELLIPSE EXAMPLE PARAMETERS
const SUPER_ELLIPSE_EXAMPLES : Dictionary = {
	"star" : {"a" : 1.0, "b" : 1.0, "n" : 0.5},
	"box" : {"a" : 1.0, "b" : 1.0, "n" : 4.0},
	"diamond" : {"a" : 1.0, "b" : 1.0, "n" : 1.5}
}

## SUPERSHAPE 2D - SUPERFORMULA EXAMPLE PARAMETERS
const SUPERSHAPE_2D_EXAMPLES : Dictionary = {
	"simple" : {"a" : 1.0, "b" : 1.0, "n1" : 1.0, "n2" : 1.0, "n3" : 1.0, "m_range" : Vector2(1.0, 6.0)},
	"stars" : {"a" : 1.0, "b" : 1.0, "n1" : 0.3, "n2" : 0.3, "n3" : 03, "m_range" : Vector2(1.0, 6.0)},
	"bloated" :  {"a" : 1.0, "b" : 1.0, "n1" : 40.0, "n2" : 10.0, "n3" : 10.0, "m_range" : Vector2(1.0, 6.0)},
	"polygons" :  {"a" : 1.0, "b" : 1.0, "n1" : 800.0, "n2" : 800.0, "n3" : 800.0, "m_range" : Vector2(1.0, 6.0)},
	"asym" :  {"a" : 1.0, "b" : 1.0, "n1" : 60.0, "n2" : 55.0, "n3" : 30.0, "m_range" : Vector2(1.0, 6.0)}
	}


#region Cutting and Restoring
## Cut polygon = cut shape used to cut source polygon.[br]
## get_intersect determines if the the intersected area (area shared by both polygons, the area that is cut out of the source polygon) is returned as well.[br]
## Returns dictionary with final : Array and intersected : Array -> all holes are filtered out already
static func cutShape(source_polygon : PackedVector2Array, cut_polygon : PackedVector2Array, source_trans_global : Transform2D, cut_trans_global : Transform2D) -> Dictionary:
	var cut_pos : Vector2 = toLocal(source_trans_global, cut_trans_global.get_origin())
	
	cut_polygon = rotatePolygon(cut_polygon, cut_trans_global.get_rotation() - source_trans_global.get_rotation())
	cut_polygon = translatePolygon(cut_polygon, cut_pos)
	
	var intersected_polygons : Array = intersectPolygons(source_polygon, cut_polygon, true)
	if intersected_polygons.size() <= 0:
		return {"final" : [], "intersected" : []}
	
	var final_polygons : Array = clipPolygons(source_polygon, cut_polygon, true)
	
	return {"final" : final_polygons, "intersected" : intersected_polygons}

## Restores a polygon towards a target polygon by a certain amount.[br]
## [param cur_poly] The current polygon to restore.[br]
## [param target_poly] The target polygon to restore towards.[br]
## [param amount] The amount to restore by.[br]
static func restorePolygon(cur_poly : PackedVector2Array, target_poly : PackedVector2Array, amount : float) -> PackedVector2Array:
	var offset_polies : Array = offsetPolygon(cur_poly, amount, true)
	
	var offset_poly : PackedVector2Array
	if offset_polies.size() <= 0:
#		print("MorpPolygon - offset polies size < 0 - target poly returned")
		return target_poly
	elif offset_polies.size() == 1:
#		print("MorpPolygon - offset polies size == 1 - best behaviour")
		offset_poly = offset_polies[0]
	else:
#		print("MorpPolygon - offset polies size > 1 - worst behaviour")
		var biggest_area : float = INF
		var index : int = -1
		
		for i in range(offset_polies.size()):
			var area : float = getPolygonArea(offset_polies[i])
#			print("Check offset polies areas - Index: %d - Area: %f" % [i, area])
			if biggest_area == INF or area > biggest_area:
				biggest_area = area
				index = i
		
		offset_poly = offset_polies[index]
	
	var intersect_polies : Array = intersectPolygons(offset_poly, target_poly, true)
	if intersect_polies.size() <= 0:
#		print("MorpPolygon - intersect polies size < 0 - target poly returned")
		return target_poly
	elif intersect_polies.size() == 1:
#		print("MorpPolygon - intersect polies size == 1 - best behaviour")
		return intersect_polies[0]
	else:
#		print("MorpPolygon - intersect polies size > 1 - worst behaviour")
		var biggest_area : float = INF
		var index : int = -1
		
		for i in range(intersect_polies.size()):
			var area : float = getPolygonArea(intersect_polies[i])
#			print("Check intersect polies areas - Index: %d - Area: %f" % [i, area])
			if biggest_area == INF or area > biggest_area:
				biggest_area = area
				index = i
		
		return intersect_polies[index]


#endregion


#region Triangulation
## Returns a triangulation dictionary (is used in other funcs parameters).[br]
## [param poly] The polygon to create triangles for.[br]
## [param triangle_points] The indices of the points forming the triangles.[br]
## [param with_area] Whether to calculate and include the area of each triangle.[br]
## [param with_centroid] Whether to calculate and include the centroid of each triangle.[br]
static func makeTriangles(poly : PackedVector2Array, triangle_points : PackedInt32Array, with_area : bool = true, with_centroid : bool = true) -> Dictionary:
	var triangles : Array = []
	var total_area : float = 0.0
	for i in range(triangle_points.size() / 3):
		var index : int = i * 3
		var points : PackedVector2Array = [poly[triangle_points[index]], poly[triangle_points[index + 1]], poly[triangle_points[index + 2]]]
		
		var area : float = 0.0
		if with_area:
			area = getTriangleArea(points)
		
		var centroid := Vector2.ZERO
		if with_centroid:
			centroid = getTriangleCentroid(points)
		
		total_area += area
		
		triangles.append(makeTriangle(points, area, centroid))
	return {"triangles" : triangles, "area" : total_area}

## Returns a dictionary for triangles.[br]
## [param points] The 3 points of the triangle.[br]
## [param area] The area of the triangle.[br]
## [param centroid] The centroid of the triangle.[br]
static func makeTriangle(points : PackedVector2Array, area : float, centroid : Vector2) -> Dictionary:
	return {"points" : points, "area" : area, "centroid" : centroid}

## Triangulates a polygon and additionally calculates the centroid 
## and area of each triangle alongside the total area of the polygon.[br]
## [param poly] The polygon to triangulate.[br]
## [param with_area] Whether to calculate and include the area of each triangle.[br]
## [param with_centroid] Whether to calculate and include the centroid of each triangle.[br]
static func triangulatePolygon(poly : PackedVector2Array, with_area : bool = true, with_centroid : bool = true) -> Dictionary:
	var total_area : float = 0.0
	var triangle_points : PackedInt32Array = Geometry2D.triangulate_polygon(poly)
	return makeTriangles(poly, triangle_points, with_area, with_centroid)

## Triangulates a polygon with the delaunay method and 
## additionally calculates the centroid and area of each 
## triangle alongside the total area of the polygon.[br]
## [param poly] The polygon to triangulate.[br]
## [param with_area] Whether to calculate and include the area of each triangle.[br]
## [param with_centroid] Whether to calculate and include the centroid of each triangle.[br]
static func triangulatePolygonDelaunay(poly : PackedVector2Array, with_area : bool = true, with_centroid : bool = true) -> Dictionary:
	var total_area : float = 0.0
	var triangle_points = Geometry2D.triangulate_delaunay(poly)
	return makeTriangles(poly, triangle_points, with_area, with_centroid)

#endregion



#region Utilities

## Triangulates a polygon and sums the areas of the triangles.[br]
## [param poly] The polygon to calculate the area for.[br]
static func getPolygonArea(poly : PackedVector2Array) -> float:
	var total_area : float = 0.0
	var triangle_points = Geometry2D.triangulate_polygon(poly)
	for i in range(triangle_points.size() / 3):
		var index : int = i * 3
		var points : Array = [poly[triangle_points[index]], poly[triangle_points[index + 1]], poly[triangle_points[index + 2]]]
		total_area += getTriangleArea(points)
	return total_area

## Triangulates a polygon and sums the weighted centroids of all triangles.[br]
## [param triangles] The array of triangles (dictionaries) generated from [method PolygonLib.triangulatePolygon] or [method PolygonLib.triangulatePolygonDelaunay].[br]
## [param total_area] The total area of the polygon (can be obtained from [method PolygonLib.triangulatePolygon] or [method PolygonLib.triangulatePolygonDelaunay].[br]
static func getPolygonCentroid(triangles : Array, total_area : float) -> Vector2:
	var weighted_centroid := Vector2.ZERO
	for triangle in triangles:
		weighted_centroid += (triangle.centroid * triangle.area)
	return weighted_centroid / total_area

## The same as getPolygonCentroid but only takes the source polygon (if you have no triangulation use this)
## If you need triangulation it is better to triangulate the polygon, store the triangulation info and use getPolygonCentroid
## with the generated triangles.[br]
## [param poly] The polygon to calculate the centroid for.[br]
static func calculatePolygonCentroid(poly : PackedVector2Array) -> Vector2:
	var triangulation : Dictionary = triangulatePolygon(poly, true, true)
	return getPolygonCentroid(triangulation.triangles, triangulation.area)

## @deprecated: Not in use anymore (but maybe it is helpful to someone).[br]
## Calculates the visual center point of a polygon by averaging the midpoints of each edge.[br]
## [param poly] The polygon to calculate the center point for.[br]
static func getPolygonVisualCenterPoint(poly : PackedVector2Array) -> Vector2:
	var center_points : Array = []
	
	for i in range(poly.size() - 1):
		var p : Vector2 = lerp(poly[i], poly[i+1], 0.5)
		center_points.append(p)
	
	var total := Vector2.ZERO
	for p in center_points:
		total += p
	
	total /= center_points.size()
	
	return total

## Moves all points of the polygon by offset.[br]
## [param poly] The polygon to translate.[br]
## [param offset] The offset vector.[br]
static func translatePolygon(poly : PackedVector2Array, offset : Vector2) -> PackedVector2Array:
	var new_poly : PackedVector2Array = []
	for p in poly:
		new_poly.append(p + offset)
	return new_poly

## Rotates all points of the polygon by rot (in radians).[br]
## [param poly] The polygon to rotate.[br]
## [param rot] The rotation angle (in radians).[br]
static func rotatePolygon(poly : PackedVector2Array, rot : float) -> PackedVector2Array:
	var rotated_polygon : PackedVector2Array = []
	
	for p in poly:
		rotated_polygon.append(p.rotated(rot))
	
	return rotated_polygon

## Scales all points of a polygon.[br]
## [param poly] The polygon to scale.[br]
## [param scale] The scale factor.[br]
static func scalePolygon(poly : PackedVector2Array, scale : Vector2) -> PackedVector2Array:
	var scaled_polygon : PackedVector2Array = []
	
	for p in poly:
		scaled_polygon.append(p * scale)
	
	return scaled_polygon 

## Calculates the centroid of the polygon and uses it to translate the polygon to [annotation Vector2.ZERO].[br]
## [param poly] The polygon to center.[br]
static func centerPolygon(poly : PackedVector2Array) -> PackedVector2Array:
	var centered_polygon : PackedVector2Array = []
	
	var triangulation : Dictionary = triangulatePolygon(poly, true, true)
	var centroid : Vector2 = getPolygonCentroid(triangulation.triangles, triangulation.area)
	
	centered_polygon = translatePolygon(poly, -centroid)
	
	return centered_polygon


## Calculates the area of a triangle.[br]
## [param points] The 3 points of the triangle.[br]
static func getTriangleArea(points : PackedVector2Array) -> float:
	var a : float = (points[1] - points[2]).length()
	var b : float = (points[2] - points[0]).length()
	var c : float = (points[0] - points[1]).length()
	var s : float = (a + b + c) * 0.5
	
	var value : float = s * (s - a) * (s - b) * (s - c)
	if value < 0.0:
		return 1.0
	var area : float = sqrt(value)
	return area

## Centroid is the center point of a triangle.[br]
## [param points] The 3 points of the triangle.[br]
static func getTriangleCentroid(points : PackedVector2Array) -> Vector2:
	var ab : Vector2 = points[1] - points[0]
	var ac : Vector2 = points[2] - points[0]
	var centroid : Vector2 = points[0] + (ab + ac) / 3.0
	return centroid

## Checks all polygons in the array and only returns clockwise polygons (holes)[br]
## [param polygons] The array of polygons to check.[br]
static func getClockwisePolygons(polygons : Array) -> Array:
	var cw_polygons : Array = []
	for poly in polygons:
		if Geometry2D.is_polygon_clockwise(poly):
			cw_polygons.append(poly)
	return cw_polygons

## Checks all polygons in the array and only returns not clockwise (counter clockwise) polygons (filled polygons).[br]
## [param polygons] The array of polygons to check.[br]
static func getCounterClockwisePolygons(polygons : Array) -> Array:
	var ccw_polygons : Array = []
	for poly in polygons:
		if not Geometry2D.is_polygon_clockwise(poly):
			ccw_polygons.append(poly)
	return ccw_polygons

## Does the same as [method Node.toGlobal()][br]
## [param global_transform] The global transform of the node.[br]
## [param local_pos] The local position to convert.[br]
static func toGlobal(global_transform : Transform2D, local_pos : Vector2) -> Vector2:
	return global_transform * (local_pos)

## Does the same as [method Node.toLocal()][br]
## [param global_transform] The global transform of the node.[br]
## [param global_pos] The global position to convert.[br]
static func toLocal(global_transform : Transform2D, global_pos : Vector2) -> Vector2:
	return global_transform.affine_inverse() * (global_pos)

## Used to set the texture offset in an texture_info dictionary.[br]
## [param texture_info] The texture info dictionary.[br]
## [param centroid] The centroid point to offset the texture.[br]
static func setTextureOffset(texture_info : Dictionary, centroid : Vector2) -> Dictionary:
	texture_info.offset += centroid.rotated(texture_info.rot)
	return texture_info

#endregion


#region Bounding Rect
## Calculates the bounding rect of a polygon and returns it in form of a Rect2.[br]
## [param poly] The polygon to calculate the bounding rect for.
static func getBoundingRect(poly : PackedVector2Array) -> Rect2:
	var start := Vector2.ZERO
	var end := Vector2.ZERO
	
	for point in poly:
		if point.x < start.x:
			start.x = point.x
		elif point.x > end.x:
			end.x = point.x
		
		if point.y < start.y:
			start.y = point.y
		elif point.y > end.y:
			end.y = point.y
	
	return Rect2(start, end - start)

## Calculates the furthest distance between to corners (AC) or (BD)
## of the bounding rect and returns it as float.[br]
## [param bounding_rect] The bounding rect to calculate the max size for.[br]
static func getBoundingRectMaxSize(bounding_rect : Rect2) -> float:
	var corners : Dictionary = getBoundingRectCorners(bounding_rect)
	
	var AC : Vector2 = corners.C - corners.C
	var BD : Vector2 = corners.D - corners.B
	
	if AC.length_squared() > BD.length_squared():
		return AC.length()
	else:
		return BD.length() 

## Returns a dictionary with the 4 corners of the bounding Rect 
## (TopLeft = A, TopRight = B, BottomRight = C, BottomLeft = D).[br]
## [param bounding_rect] The bounding rect to get the corners for.
static func getBoundingRectCorners(bounding_rect : Rect2) -> Dictionary:
	var A : Vector2 = bounding_rect.position
	var C : Vector2 = bounding_rect.end
	
	var B : Vector2 = Vector2(C.x, A.y)
	var D : Vector2 = Vector2(A.x, C.y)
	return {"A" : A, "B" : B, "C" : C, "D" : D}

#endregion


#region Shape Creation

## Creates a rectangle polygon given size and optional local center.[br]
## [param size] The size of the rectangle.[br]
## [param local_center] The local center of the rectangle.
static func createRectanglePolygon(size : Vector2, local_center: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	var rectangle : PackedVector2Array = []
	var extend : Vector2 = size * 0.5
	rectangle.append(local_center - extend)#A
	rectangle.append(local_center + Vector2(extend.x, -extend.y))#B
	rectangle.append(local_center + extend)#C
	rectangle.append(local_center + Vector2(-extend.x, extend.y))#D
	return rectangle

## Creates a circle polygon given radius and optional smoothing and local center.[br]
## Smooting affects point count -> 0 = 8 Points, 1 = 16, 2 = 32, 3 = 64, 4 = 128, 5 = 256.[br]
## [param radius] The radius of the circle.[br]
## [param smoothing] The smoothing level of the circle.[br]
## [param local_center] The local center of the circle.
static func createCirclePolygon(radius: float, smoothing: int = 0, local_center: Vector2 = Vector2.ZERO) -> PackedVector2Array:
	var circle : PackedVector2Array = []
	
	smoothing = clamp(smoothing, 0, 5)
	var point_number : int = pow(2, 3 + smoothing)
	
	var radius_line : Vector2 = Vector2.RIGHT * radius
	var angle_step : float = (PI * 2.0) / point_number as float
	
	for i in range(point_number):
		circle.append(local_center + radius_line.rotated(angle_step * i))
	
	return circle

## Creates a beam with a seperate start and end width.[br]
## [param dir] The direction of the beam.[br]
## [param distance] The distance (length) of the beam.[br]
## [param start_width] The width at the start of the beam.[br]
## [param end_width] The width at the end of the beam.[br]
## [start_point_local] The local start point of the beam.
static func createBeamPolygon(dir : Vector2, distance : float, start_width : float, end_width : float, start_point_local := Vector2.ZERO) -> PackedVector2Array:
	var beam : PackedVector2Array = []
	if distance == 0: 
		return beam
	
	if start_width <= 0.0 and end_width <= 0.0:
		return beam
	
	if distance < 0:
		dir = -dir
		distance *= -1.0
	
	var end_point : Vector2 = start_point_local + (dir * distance)
	var perpendicular : Vector2 = dir.rotated(PI * 0.5)
	
	if start_width <= 0.0:
		beam.append(start_point_local)
		beam.append(end_point + perpendicular * end_width * 0.5)
		beam.append(end_point - perpendicular * end_width * 0.5)
	elif end_width <= 0.0:
		beam.append(start_point_local + perpendicular * start_width * 0.5)
		beam.append(end_point)
		beam.append(start_point_local - perpendicular * start_width * 0.5)
	else:
		beam.append(start_point_local + perpendicular * start_width * 0.5)
		beam.append(end_point + perpendicular * end_width * 0.5)
		beam.append(end_point - perpendicular * end_width * 0.5)
		beam.append(start_point_local - perpendicular * start_width * 0.5)
	
	return beam


#implemented thanks to Daniel Shiffman´s (@shiffman) coding challenges
#https://thecodingtrain.com/CodingChallenges/019-superellipse.html
#https://en.wikipedia.org/wiki/Superellipse
## Creates a superellipse polygon with given parameters.[br]
## [param p_number] The number of points to create.[br]
## [param a] The a parameter of the superellipse.[br]
## [param b] The b parameter of the superellipse.[br]
## [param n] The n parameter of the superellipse.[br]
## [param start_angle_deg] The starting angle in degrees.[br]
## [param max_angle_deg] The maximum angle in degrees.[br]
## [param offset] The local offset of the superellipse. 
static func createSuperEllipsePolygon(p_number : int, a : float, b : float, n : float, start_angle_deg : float = 0.0, max_angle_deg : float = 360.0, offset := Vector2.ZERO) -> PackedVector2Array:
	var poly : PackedVector2Array = []
	
	var angle_step_rad : float = (2 * PI) / p_number as float
	var start_angle_rad : float = deg_to_rad(start_angle_deg)
	var max_angle_rad : float = deg_to_rad(max_angle_deg)
	var current_angle_rad : float = start_angle_rad
	var na : float = 2.0 / n
	
	while current_angle_rad < start_angle_rad + max_angle_rad:
		var x : float = pow(abs(cos(current_angle_rad)), na) * a * sign(cos(current_angle_rad))
		var y : float = pow(abs(sin(current_angle_rad)), na) * b * sign(sin(current_angle_rad))
		
		poly.append(Vector2(x, y) + offset)
		
		current_angle_rad += angle_step_rad
	return poly

#implemented thanks to Daniel Shiffman´s (@shiffman) coding challenges
#https://thecodingtrain.com/CodingChallenges/023-supershape2d.html
#http://paulbourke.net/geometry/supershape/
static func createSupershape2DPolygon(p_number : int, a : float, b : float, m : float, n1 : float, n2 : float, n3 : float, start_angle_deg : float = 0.0, max_angle_deg : float = 360.0, offset := Vector2.ZERO) -> PackedVector2Array:
	var poly : PackedVector2Array = []
	
	var angle_step_rad : float = (2 * PI) / p_number as float
	var start_angle_rad : float = deg_to_rad(start_angle_deg)
	var max_angle_rad : float = deg_to_rad(max_angle_deg)
	var current_angle_rad : float = start_angle_rad
	
	while current_angle_rad < start_angle_rad + max_angle_rad:
		var r : float = calculateSupershape2DRadius(current_angle_rad, a, b, m, n1, n2, n3)
		var x = r * cos(current_angle_rad)
		var y = r * sin(current_angle_rad)
		
		poly.append(Vector2(x, y) + offset)
		
		current_angle_rad += angle_step_rad
	
	return poly


static func calculateSupershape2DRadius(angle_rad : float, a : float, b : float, m : float, n1 : float, n2 : float, n3 : float) -> float:
	var part1 : float = (1.0 / a) * cos((angle_rad * m) / 4.0)
	part1 = abs(part1)
	part1 = pow(part1, n2)
	
	var part2 = (1.0 / b) * sin((angle_rad * m) / 4.0)
	part2 = abs(part2)
	part2 = pow(part2, n3)
	
	var part3 = pow(part1 + part2, 1.0 / n1)
	
	if part3 == 0.0:
		return 1.0
	
	return 1.0 / part3

#endregion



#SHAPE INFO
#-------------------------------------------------------------------------------
#just makes a dictionary that can be used in different funcs
static func makeShapeInfo(shape : PackedVector2Array, centered_shape : PackedVector2Array, centroid : Vector2, spawn_pos : Vector2, area : float, source_global_trans : Transform2D) -> Dictionary:
	return {"shape" : shape, "centered_shape" : centered_shape, "centroid" : centroid, "spawn_pos" : spawn_pos, "spawn_rot" : source_global_trans.get_rotation(), "area" : area, "source_global_trans" : source_global_trans}

#makes a shape info with the given parameters
static func getShapeInfo(source_global_trans : Transform2D, source_polygon : PackedVector2Array) -> Dictionary:
	var triangulation : Dictionary = triangulatePolygon(source_polygon, true, true)
	var centroid : Vector2 = getPolygonCentroid(triangulation.triangles, triangulation.area)
	var centered_shape : PackedVector2Array = translatePolygon(source_polygon, -centroid)
	return makeShapeInfo(source_polygon, centered_shape, centroid, getShapeSpawnPos(source_global_trans, centroid), triangulation.area, source_global_trans)

#makes a shape info with the given parameters and has different parameters than getShapeInfo
static func getShapeInfoSimple(source_global_trans : Transform2D, source_polygon : PackedVector2Array, triangulation : Dictionary) -> Dictionary:
	var centroid : Vector2 = getPolygonCentroid(triangulation.triangles, triangulation.area)
	var centered_shape : PackedVector2Array = translatePolygon(source_polygon, -centroid)
	return makeShapeInfo(source_polygon, centered_shape, centroid, getShapeSpawnPos(source_global_trans, centroid), triangulation.area, source_global_trans)

#calculates the global world position for a given centroid
static func getShapeSpawnPos(source_global_trans : Transform2D, centroid : Vector2) -> Vector2:
	var spawn_pos : Vector2 = toGlobal(source_global_trans, centroid)
	return spawn_pos
#-------------------------------------------------------------------------------





#POLYGON OPERATIONS
#-------------------------------------------------------------------------------
static func clipPolygons(poly_a : PackedVector2Array, poly_b : PackedVector2Array, exclude_holes : bool = true) -> Array:
	var new_polygons : Array = Geometry2D.clip_polygons(poly_a, poly_b)
	if exclude_holes:
		return getCounterClockwisePolygons(new_polygons)
	else:
		return new_polygons


static func excludePolygons(poly_a : PackedVector2Array, poly_b : PackedVector2Array, exclude_holes : bool = true) -> Array:
	var new_polygons : Array = Geometry2D.exclude_polygons(poly_a, poly_b)
	if exclude_holes:
		return getCounterClockwisePolygons(new_polygons)
	else:
		return new_polygons


static func intersectPolygons(poly_a : PackedVector2Array, poly_b : PackedVector2Array, exclude_holes : bool = true) -> Array:
	var new_polygons : Array = Geometry2D.intersect_polygons(poly_a, poly_b)
	if exclude_holes:
		return getCounterClockwisePolygons(new_polygons)
	else:
		return new_polygons


static func mergePolygons(poly_a : PackedVector2Array, poly_b : PackedVector2Array, exclude_holes : bool = true) -> Array:
	var new_polygons : Array = Geometry2D.merge_polygons(poly_a, poly_b)
	if exclude_holes:
		return getCounterClockwisePolygons(new_polygons)
	else:
		return new_polygons


static func offsetPolyline(line : PackedVector2Array, delta : float, exclude_holes : bool = true) -> Array:
	var new_polygons : Array = Geometry2D.offset_polyline(line, delta)
	if exclude_holes:
		return getCounterClockwisePolygons(new_polygons)
	else:
		return new_polygons


static func offsetPolygon(poly : PackedVector2Array, delta : float, exclude_holes : bool = true) -> Array:
	var new_polygons : Array = Geometry2D.offset_polygon(poly, delta)
	if exclude_holes:
		return getCounterClockwisePolygons(new_polygons)
	else:
		return new_polygons
#-------------------------------------------------------------------------------




#SIMPLIFY LINE
#-------------------------------------------------------------------------------
#my own simplify line code ^^
static func simplifyLine(line : PackedVector2Array, segment_min_length : float = 100.0) -> PackedVector2Array:
	var final_line : PackedVector2Array = [line[0]]

	var i : int = 0
	while i < line.size() - 1:
		var start : Vector2 = line[i]
		var total_dis : float = 0.0
		for j in range(i + 1, line.size()):
			var end : Vector2 = line[j]
			var vec : Vector2 = end - start 
			var dis : float = vec.length()
			var dir : Vector2 = vec.normalized()
			total_dis += dis
			if total_dis > segment_min_length or j >= line.size() - 1:
				final_line.append(end)
				i = j
				break
	
	return final_line

static func simplifyLineRDP(line : PackedVector2Array, epsilon : float = 10.0) -> PackedVector2Array:
	var total : int = line.size()
	var start : Vector2 = line[0]
	var end : Vector2 = line[total - 1]
	
	var rdp_points : Array = [start]
	RDP.calculate(0, total - 1, Array(line), rdp_points, epsilon)
	rdp_points.append(end)
	
	return PackedVector2Array(rdp_points)

#used to simplify a line (less points)
#Ramer-Douglas-Peucker Algorithm (iterative end-point fit algorithm)
class RDP:
	static func calculate(startIndex : int, endIndex : int, line : Array, final_line : Array, epsilon : float) -> void:
		var nextIndex : int = findFurthest(line, startIndex, endIndex, epsilon)
		if nextIndex > 0:
			if startIndex != nextIndex:
				calculate(startIndex, nextIndex, line, final_line, epsilon)
			
			final_line.append(line[nextIndex])
			
			if (endIndex != nextIndex):
				calculate(nextIndex, endIndex, line, final_line, epsilon)

	static func findFurthest(points : Array, a : int, b : int, epsilon : float) -> int:
		var recordDistance : float = -1.0
		var start : Vector2 = points[a]
		var end : Vector2 = points[b]
		var furthestIndex : int = -1
		for i in range(a+1,b):
			var currentPoint : Vector2 = points[i]
			var d : float = lineDist(currentPoint, start, end);
			if d > recordDistance:
				recordDistance = d; 
				furthestIndex = i;
	  
		if recordDistance > epsilon:
			return furthestIndex
		else:
			return -1


	static func lineDist(point : Vector2, line_start : Vector2, line_end : Vector2) -> float:
		var norm = scalarProjection(point, line_start, line_end)
		return (point - norm).length()


	static func scalarProjection(p : Vector2, a : Vector2, b : Vector2) -> Vector2:
		var ap : Vector2 = p - a
		var ab : Vector2 = b - a
		ab = ab.normalized()
		ab *= ap.dot(ab)
		return a + ab

#-------------------------------------------------------------------------------
