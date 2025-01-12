## Container used to save all the game resources to the disk. Used by the GameManager.
class_name GameData  extends Resource

var last_updated

var player_data: PlayerSaveData
var bitcoin_network_data: BitcoinNetworkData
var bitcoin_wallet_data: BitcoinWalletData
var skill_nodes_data_dic: Dictionary
var game_manager_data: GameManagerData


func _init() -> void:
	player_data = PlayerSaveData.new()
	bitcoin_network_data = BitcoinNetworkData.new()
	bitcoin_wallet_data = BitcoinWalletData.new()
	skill_nodes_data_dic = {}
	game_manager_data = GameManagerData.new(1)


func _to_string() -> String:
	return "Player Data: %s\n" % player_data + "Bitcoin Network Data: %s\n" % bitcoin_network_data + "Bitcoin Wallet Data: %s\n" % bitcoin_wallet_data + "Game Manager Data: %s\n" % game_manager_data + "Skill Nodes Saved: %s" % skill_nodes_data_dic
