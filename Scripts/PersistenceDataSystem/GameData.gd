class_name GameData  extends Resource

var last_updated

@export var player_data: PlayerData
@export var bitcoin_network_data: BitcoinNetworkData
@export var bitcoin_wallet_data: BitcoinWalletData
@export var skill_node_data: SkillTreeData

func _init() -> void:
	player_data = PlayerData.new()
	bitcoin_network_data = BitcoinNetworkData.new()
	bitcoin_wallet_data = BitcoinWalletData.new()
	skill_node_data = SkillTreeData.new()
