class_name NetworkVisualizer extends Control

@onready var coins_lost: Label = %CoinsLost
@onready var coins_on_player: Label = %CoinsOnPlayer
@onready var coins_left: Label = %CoinsLeft
@onready var blocks_left: Label = %"Blocks Left"
@onready var displayer_scene: PackedScene = preload("res://Scenes/Miscelaneous/block_displayer.tscn")
@onready var block_container: HBoxContainer = %BlockContainer

func _ready() -> void:
	set_textes()
	set_block_visualizers()

func set_textes() -> void:
	coins_lost.text = "Coins Lost: %.2f"%BitcoinNetwork.coins_lost
	coins_on_player.text = "Coins in Wallet: %.2f"%BitcoinWallet.bitcoin_balance
	var left_to_mine: float = BitcoinNetwork.TOTAL_COINS - (BitcoinNetwork.coins_lost + BitcoinWallet.bitcoin_balance)
	coins_left.text = "Coins Left to Mine: %.2f"%left_to_mine

func set_block_visualizers() -> void:
	var chain_copy: Array = BitcoinNetwork.chain
	chain_copy.reverse()
	
	for i in chain_copy.size():
		if i == 0 || i == 1: continue
		var ins : BlockDisplayer = displayer_scene.instantiate()
		block_container.add_child(ins)
		ins.set_label_text("%s"%chain_copy[i])
