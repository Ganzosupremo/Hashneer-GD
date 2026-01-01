class_name ShopLayer extends Node2D
## Visual and functional layer for the mining shop area (underground chamber)

## Platform scene for instancing
@onready var platform_scene: PackedScene = preload("res://Scenes/Utils/Platform.tscn")

@export var platform_color: Color = Color(0.35, 0.30, 0.25, 1.0)  ## Bronze/copper to match chamber walls
@export var platform_margin: float = 20.0  ## Margin from chamber walls
const PLATFORM_THICKNESS: float = 40.0

var _shop_spawn_point: Marker2D
var _player_spawn_point: Marker2D
var _chamber_bounds: Rect2 = Rect2()  ## World coordinates of chamber interior

## Initialize with chamber bounds (world coordinates)
func initialize_in_chamber(chamber_bounds: Rect2) -> void:
        _clear_layer()
        _chamber_bounds = chamber_bounds
        
        if _chamber_bounds.size == Vector2.ZERO:
                push_warning("ShopLayer: No chamber bounds provided, shop will not be created")
                return
        
        position = _chamber_bounds.position
        
        _create_chamber_platform()
        _create_spawn_points()
        _add_ambient_effects()
        
        print("ShopLayer: Initialized in chamber at %s size %s" % [_chamber_bounds.position, _chamber_bounds.size])

## Legacy initialize for backwards compatibility (floating shop)
func initialize(terrain_width: float) -> void:
        push_warning("ShopLayer: Using legacy floating initialization - consider using initialize_in_chamber()")
        _clear_layer()
        _chamber_bounds = Rect2(0, -500, terrain_width, 500)
        position = Vector2(0, -500)
        _create_chamber_platform()
        _create_spawn_points()
        _add_ambient_effects()


func _clear_layer() -> void:
        for child in get_children():
                remove_child(child)
                child.queue_free()

        _shop_spawn_point = null
        _player_spawn_point = null

func _create_chamber_platform() -> void:
        var chamber_width: float = _chamber_bounds.size.x
        var chamber_height: float = _chamber_bounds.size.y
        
        var platform_width: float = chamber_width - (platform_margin * 2)
        var platform_y: float = chamber_height - PLATFORM_THICKNESS / 2 - platform_margin
        
        var platform: StaticBody2D = platform_scene.instantiate()
        platform.name = "ShopPlatform"
        add_child(platform)

        var collision: CollisionShape2D = platform.get_node_or_null("Collision")
        var shape: RectangleShape2D = RectangleShape2D.new()
        shape.size = Vector2(platform_width, PLATFORM_THICKNESS)
        collision.shape = shape
        collision.position = Vector2.ZERO

        platform.position = Vector2(chamber_width / 2, platform_y)

        var visual: ColorRect = platform.get_node_or_null("Visual")
        visual.color = platform_color
        visual.size = shape.size
        visual.position = -shape.size / 2

        _add_platform_details(visual)

func _add_platform_details(visual: ColorRect) -> void:
        for i in range(0, int(visual.size.x), 80):
                var line = Line2D.new()
                line.add_point(Vector2(i, 0))
                line.add_point(Vector2(i, visual.size.y))
                line.default_color = Color(0.5, 0.45, 0.35, 0.4)  ## Bronze accent
                line.width = 2.0
                visual.add_child(line)
        
        for i in range(0, int(visual.size.x), 80):
                var rivet = ColorRect.new()
                rivet.color = Color(0.6, 0.55, 0.4, 0.6)
                rivet.size = Vector2(6, 6)
                rivet.position = Vector2(i - 3, 8)
                visual.add_child(rivet)

                var rivet2 = ColorRect.new()
                rivet2.color = Color(0.6, 0.55, 0.4, 0.6)
                rivet2.size = Vector2(6, 6)
                rivet2.position = Vector2(i - 3, visual.size.y - 14)
                visual.add_child(rivet2)

func _create_spawn_points() -> void:
        var chamber_width: float = _chamber_bounds.size.x
        var chamber_height: float = _chamber_bounds.size.y
        var platform_top: float = chamber_height - PLATFORM_THICKNESS - platform_margin - 20.0
        
        _player_spawn_point = Marker2D.new()
        _player_spawn_point.name = "PlayerSpawnPoint"
        _player_spawn_point.position = Vector2(chamber_width * 0.35, platform_top)
        add_child(_player_spawn_point)

        _shop_spawn_point = Marker2D.new()
        _shop_spawn_point.name = "ShopSpawnPoint"
        _shop_spawn_point.position = Vector2(chamber_width * 0.65, platform_top)
        add_child(_shop_spawn_point)

func _add_ambient_effects() -> void:
        var chamber_width: float = _chamber_bounds.size.x
        var chamber_height: float = _chamber_bounds.size.y
        
        var particles: GPUParticles2D = GPUParticles2D.new()
        particles.name = "AmbientParticles"
        particles.amount = 20  ## Fewer particles for smaller chamber
        particles.lifetime = 4.0
        particles.position = Vector2(chamber_width / 2, chamber_height / 2)

        var p_material: ParticleProcessMaterial = ParticleProcessMaterial.new()
        p_material.direction = Vector3(0, -1, 0)  ## Fall down like dust
        p_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
        p_material.emission_box_extents = Vector3(chamber_width / 2 - 20, chamber_height / 4, 0)
        p_material.initial_velocity_min = 5.0
        p_material.initial_velocity_max = 15.0
        p_material.gravity = Vector3(0, 10, 0)
        p_material.scale_min = 0.5
        p_material.scale_max = 2.0
        p_material.color = Color(0.6, 0.5, 0.3, 0.15)  ## Dusty bronze color

        particles.process_material = p_material
        add_child(particles)
        particles.emitting = true

func get_player_spawn_position() -> Vector2:
        if _player_spawn_point:
                return _player_spawn_point.global_position
        return global_position

func get_shop_spawn_position() -> Vector2:
        if _shop_spawn_point:
                return _shop_spawn_point.global_position
        return global_position

func get_chamber_bounds() -> Rect2:
        return _chamber_bounds
