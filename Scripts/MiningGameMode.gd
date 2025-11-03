extends Node2D

@onready var player_bullets_pool: PoolFracture = $PlayerBulletsPool


func _ready() -> void:
	# Get components
	var shop_layer = %ShopLayer
	var quadrant_builder = %QuadrantBuilder
	var player = %Player
	
	# Set camera limits based on world borders
	if quadrant_builder.world_borders:
		var mining_bounds = quadrant_builder.world_borders.get_mining_bounds()
		var shop_bounds = quadrant_builder.world_borders.get_shop_layer_bounds()
		
		var camera = $AdvancedCamera
		camera.limit_left = int(mining_bounds.position.x)
		camera.limit_right = int(mining_bounds.end.x)
		camera.limit_top = int(shop_bounds.position.y)
		camera.limit_bottom = int(mining_bounds.end.y)
	
	# Position player at spawn
	if shop_layer:
		player.global_position = shop_layer.get_player_spawn_position()


func _on_terminate_button_pressed() -> void:
	GameManager.emit_level_completed(Constants.ERROR_210)
