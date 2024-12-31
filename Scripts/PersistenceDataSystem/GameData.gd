## Container used to save all the game resources to the disk. Used by the GameManager.
class_name GameData  extends Resource

var last_updated

@export var player_data: PlayerSaveData
@export var bitcoin_network_data: BitcoinNetworkData
@export var bitcoin_wallet_data: BitcoinWalletData
@export var skill_nodes_data_dic: Dictionary
@export var game_manager_data: GameManagerData


func _init() -> void:
	player_data = PlayerSaveData.new()
	bitcoin_network_data = BitcoinNetworkData.new()
	bitcoin_wallet_data = BitcoinWalletData.new()
	skill_nodes_data_dic = {}
	game_manager_data = GameManagerData.new(1)
