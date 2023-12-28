extends Area2D
class_name BlockCore

signal core_mined(ui_title: String, bg_color: Color)
@export var intial_health: float = 50.0

var current_health: float = 0.0
var level_index: int = 0
static var instance: BlockCore: get = get_instance

func _ready() -> void:
	instance = self
	current_health = intial_health

func pass_level_index(index: int):
	self.level_index = index

"""
Deals damage to the block core, returns true if the core's health is zero,
false otherwise
"""
func take_damage(damage: float, instakill: bool = false) -> bool:
	if instakill:
		current_health -= 1.79769e308
		return true
	else:
		current_health -= damage
	
	if current_health <= 0.0:
		return true
	
	return false

func mine_core(miner: String, block: BitcoinBlock) -> void:
	if current_health <= 0.0:
		print_rich("Level index in builder args is: ", GameManager.builder_args.level_index)
		BitcoinNetwork.emit_signal("block_core_destroyed", GameManager.builder_args.level_index, miner, block)
		
		if miner == "player":
			emit_signal("core_mined", "Block Core Mined Successfully!", Color.BISQUE)
		else:
			emit_signal("core_mined", "Block Core Mining Failed!", Color.CRIMSON)
		
		GameManager.emit_signal("level_completed", GameManager.builder_args.level_index+2)
		queue_free()

func build_block() -> BitcoinBlock:
	var instance_block: BitcoinBlock = BitcoinBlock.new(level_index, Time.get_datetime_string_from_system(false, true), "Block Height: %s" % level_index)
	return instance_block

static func get_instance() -> BlockCore:
	return instance
