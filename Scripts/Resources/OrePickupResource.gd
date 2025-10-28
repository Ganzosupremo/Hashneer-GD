class_name OrePickupResource extends Resource
## Pickup resource for ore items

@export var ore_type: OreDetails.OreType = OreDetails.OreType.DIRT
@export var ore_value: float = 0.0
@export var depth_found: int = 0
@export var auto_collect: bool = true
@export var magnet_radius: float = 100.0
