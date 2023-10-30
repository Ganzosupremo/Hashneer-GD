extends Node2D
class_name BNetwork

signal reward_issued(reward_issued: float)

var total_coins: float = 21000000
var total_blocks: int = 21
var genesis_reward: float = 0
var current_block:int= 0
var completed_levels: Dictionary = {}  # Dictionary to keep track of completed levels

func _ready() -> void:
	create_genesis_reward()


func issue_coins(block_heigth: int) -> float:
	if completed_levels.has(block_heigth):  # Check if the level has already been completed
		print("Level already completed!")
		return 0.0  # Return 0 as no coins are issued
	
	var current_reward: float = genesis_reward
	current_block = block_heigth
	var total_distributed: float = 0.0
	total_distributed += current_reward
	current_reward *= 0.5 # Halve the block reward
	emit_signal("reward_issued", total_distributed)
	
	completed_levels[block_heigth] = true  # Mark the level as completed
	return total_distributed

func create_genesis_reward():
	genesis_reward = total_coins / (2 * (1 - pow(0.5, total_blocks)))
