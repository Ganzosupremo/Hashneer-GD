class_name CurrencyInventory extends Node2D

func add_to_inventory(resource: Resource, _amount: float) -> bool:
	if resource is CurrencyPickupResource:
		match resource.currency_type:
			Constants.CurrencyType.FIAT:
				return true
			# Mine a new block only if this level hasn't been mined before
			Constants.CurrencyType.BITCOIN:
					var lvl: int = GameManager.get_current_level()
					if !BitcoinNetwork.is_level_mined(lvl):
							BitcoinNetwork.mine_block("Player")
					return true
			_:
				return false
	return false
