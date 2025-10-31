class_name OrePickup extends Pickup2D
## Specialized pickup for ore items
## Automatically creates an OrePickupResource from the OreDetails

## The OreDetails resource that defines this ore type
@export var ore_details: OreDetails
# The depth layer this ore was found at (affects value)
var _depth_layer: int = 0


func _ready() -> void:
	# Create the pickup resource from ore details
	if ore_details:
		if pickup_resource_file.is_empty():
			# No file specified, create resource from ore_details
			_create_ore_pickup_resource()
		else:
			# File is specified (OreDetails resource), load it and create pickup resource
			var loaded_ore_details = load(pickup_resource_file) as OreDetails
			if loaded_ore_details:
				ore_details = loaded_ore_details
				_create_ore_pickup_resource()
	
	super._ready()


## Creates an OrePickupResource from the OreDetails
func _create_ore_pickup_resource() -> void:
	var ore_pickup_resource = OrePickupResource.new()
	ore_pickup_resource.ore_type = ore_details.ore_type
	_depth_layer = ore_details.get_depth_layer()
	ore_pickup_resource.depth_found = _depth_layer
	ore_pickup_resource.ore_value = ore_details.get_value_at_depth(_depth_layer)
	ore_pickup_resource.auto_collect = true
	ore_pickup_resource.magnet_radius = 100.0
	
	# Save the resource to a temporary path (or just keep it in memory)
	# For now, we'll override the get_pickup_resource method to return it directly
	resource_loaded = ore_pickup_resource


func take(taker: PickupsCollector2D) -> PickupEvent:
	# Sound effects can be added later here if needed
	return super.take(taker)

## Override to return the pre-created resource
func get_pickup_resource() -> Resource:
	if resource_loaded:
		return resource_loaded
	return super.get_pickup_resource()


## Set the ore details and depth for this pickup
func setup(p_ore_details: OreDetails, p_depth_layer: int = 0) -> void:
	ore_details = p_ore_details
	_depth_layer = p_depth_layer
	
	# Set the texture if available
	if ore_details and ore_details.pickup_texture:
		set_texture(ore_details.pickup_texture)
	
	# Create the resource
	_create_ore_pickup_resource()
