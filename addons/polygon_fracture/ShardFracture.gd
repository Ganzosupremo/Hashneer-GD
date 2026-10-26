extends Polygon2D




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




const LINE_FADE_SPEED : float  = 1.5




signal Despawn(ref)




## Velocity damping per second (exponential). 3 = loses ~95% of its speed in one second.
@export_range(0.0, 32.0, 0.05) var lin_drag: float = 0.0
@export_range(0.0, 32.0, 0.05) var ang_drag: float = 0.0
@export var gravity_direction: Vector2 = Vector2(0, 1)
@export var gravity_scale: float = 10.0

@export var lifetime_scale_curve: Curve

@onready var _line := $Line2D
@onready var _timer := $Timer
@onready var _line_lerp_start_color : Color = _line.modulate

var _t : float = 1.0
var _lifetime : float = 0.0

var _lin_accel := Vector2.ZERO
var _ang_accel : float = 0.0
var _lin_vel := Vector2.ZERO
var _ang_vel : float = 0.0

var _mass : float = 1.0
var _scale_lerp_start := Vector2.ZERO

func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	visible = false

func _process(delta: float) -> void:
	if _t < 1.0:
		_t += delta * LINE_FADE_SPEED
		_line.modulate = lerp(_line_lerp_start_color, self_modulate, min(_t, 1.0))
	
	if not _timer.is_stopped() and _lifetime > 0.0:
		var p : float = clamp(1.0 - (_timer.time_left / _lifetime), 0.0, 1.0)
		if lifetime_scale_curve:
			p = lifetime_scale_curve.sample_baked(p)
		global_scale = lerp(_scale_lerp_start, Vector2.ZERO, p)

func _physics_process(delta: float) -> void:
	# Gravity is an acceleration (px/s²): going through addForce divided it by the mass, so tiny
	# shards fell hundreds of times faster than big ones.
	_lin_vel += gravity_direction.normalized() * gravity_scale * delta
	_lin_vel += _lin_accel
	_ang_vel += _ang_accel
	
	# Exponential damping: the old "v -= v * drag * delta" overshoots once drag * delta > 1
	# (125 * 1/60 = 2.08), flipping and growing the velocity every frame.
	_lin_vel *= exp(-lin_drag * delta)
	_ang_vel *= exp(-ang_drag * delta)
	
	global_position += _lin_vel * delta
	global_rotation += _ang_vel * delta
	
	_lin_accel = Vector2.ZERO
	_ang_accel = 0.0

func spawn(pos : Vector2, rot : float, s : Vector2, lifetime : float = 3.0) -> void:
	visible = true
	
	global_position = pos
	global_rotation = rot
	global_scale = s
	_scale_lerp_start = s
	
	_lifetime = lifetime
	_timer.start(lifetime)
	_t = 0.0
	
	_lin_vel = Vector2.ZERO
	_ang_vel = 0.0
	_lin_accel = Vector2.ZERO
	_ang_accel = 0.0
	
	set_process(true)
	set_physics_process(true)

func despawn(_ref: Node2D = null) -> void:
	visible = false
	set_process(false)
	set_physics_process(false)
	_t = 1.0

func addForce(force : Vector2) -> void:
	# A NaN/inf force (e.g. from a division by zero upstream) would poison _lin_vel for the
	# shard's whole lifetime and spam normalize() warnings in _physics_process.
	if not force.is_finite():
		return
	if _mass > 0.0:
		force /= _mass
	_lin_accel += force

func addTorque(torque : float) -> void:
	_ang_accel += torque

func setPolygon(poly : PackedVector2Array, c : Color, texture_info : Dictionary) -> void:
	set_polygon(poly)
	var outline : PackedVector2Array = poly.duplicate()
	outline.append(outline[0])
	_line.points = outline
	setColor(c)
	setTexture(texture_info)

func setTexture(texture_info : Dictionary) -> void:
	if not texture_info: return
	texture = texture_info.texture
	texture_scale = texture_info.scale
	texture_offset = texture_info.offset
	texture_rotation = texture_info.rot

func setColor(_color : Color) -> void:
	self_modulate = _color

func setMass(new_mass : float) -> void:
	_mass = new_mass if is_finite(new_mass) else 1.0

func _on_Timer_timeout() -> void:
	emit_signal("Despawn", self)
