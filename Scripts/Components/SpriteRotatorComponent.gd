class_name SpriteRotatorComponent extends Sprite2D

## This component rotates a sprite around its center.
## It can be used for rotating weapons, items, or any other sprite in the game.
@export var rotation_speed: float = 1.0
## 1 for clockwise, -1 for counterclockwise
@export var rotation_direction: int = 1 

func _process(delta: float) -> void:
	# Rotate the sprite based on the speed and direction
	rotation += rotation_speed * rotation_direction * delta
	# Ensure the rotation stays within 0 to 2*PI range
	rotation = fposmod(rotation, 2 * PI)
