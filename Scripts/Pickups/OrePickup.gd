class_name OrePickup extends Area2D
## Ore pickup that auto-collects when player is nearby, integrates with ItemDropsBus

signal ore_collected(ore_type: OreDetails.OreType, value: float)

var ore_type: OreDetails.OreType = OreDetails.OreType.DIRT
var ore_value: float = 0.0
var ore_texture: Texture2D
var ore_data: OreDetails

@onready var sprite: Sprite2D = $Sprite2D
@onready var collect_radius: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
        # Set visual
        if ore_texture:
                sprite.texture = ore_texture
        
        # Set color from ore data
        if ore_data:
                sprite.modulate = ore_data.ore_color
        
        # Set collision layers/masks (match ItemDropsBus pickup configuration)
        collision_layer = 8  # Layer 4 (pickups)
        collision_mask = 1   # Layer 1 (player)
        
        # Connect to ItemDropsBus for auto-collection
        if ItemDropsBus:
                ItemDropsBus.item_auto_collected.connect(_on_auto_collected)
        
        # Connect to player collision
        body_entered.connect(_on_body_entered)
        area_entered.connect(_on_area_entered)

func _on_body_entered(body: Node2D) -> void:
        if body.is_in_group("Player"):
                _collect()

func _on_area_entered(area: Area2D) -> void:
        if area.is_in_group("Player"):
                _collect()

func _on_auto_collected(item: Node) -> void:
        if item == self:
                _collect()

func _collect() -> void:
        if not is_inside_tree():
                return
        
        # Add to inventory
        if OreInventory:
                OreInventory.add_ore(ore_type, ore_value)
        
        # Play sound
        if ore_data and ore_data.pickup_sound:
                AudioManager.create_2d_audio_at_location(
                        global_position,
                        ore_data.pickup_sound.sound_type,
                        ore_data.pickup_sound.destination_audio_bus
                )
        
        # Emit signal and notify ItemDropsBus
        ore_collected.emit(ore_type, ore_value)
        
        if ItemDropsBus:
                ItemDropsBus.item_picked_up.emit(self)
        
        # Remove pickup
        queue_free()
