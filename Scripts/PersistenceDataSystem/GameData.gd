class_name GameData  extends Resource

var last_updated

var player_data: PlayerData
var bitcoin_network_data: BitcoinNetworkData
var bitcoin_wallet_data: BitcoinWalletData
var skill_node_data: SkillStatsData
var data: Dictionary = {}

func _init() -> void:
	player_data = PlayerData.new()
	bitcoin_network_data = BitcoinNetworkData.new()
	bitcoin_wallet_data = BitcoinWalletData.new()
	skill_node_data = SkillStatsData.new()
	
	data = {
		"player_data": player_data,
		"bitcoin_network_data": bitcoin_network_data,
		"bitcoin_wallet_data": bitcoin_wallet_data,
		"skill_node_data": skill_node_data.upgrades_data,
	}


class PlayerData:
	var speed: float = 0.0
	var health: float = 0.0

class BitcoinNetworkData:
	var chain: Array = []
	var height: int = -1
	var block_subsidy: float = 0.0
	var coins_lost: float = 0.0

class BitcoinWalletData:
	var btc_holdings: float = 0.0
	var fiat_holdings: float = 0.0
	var bitcoin_price: float = 35_000.0

class SkillStatsData:
	var data: Dictionary = {}
	var upgrades_data: Dictionary = {}
