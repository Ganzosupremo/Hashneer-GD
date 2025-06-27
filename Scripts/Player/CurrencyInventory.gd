class_name CurrencyInventory extends Node2D

func add_to_inventory(resource: Resource, amount: float) -> bool:
	if resource is CurrencyPickupResource:
		match resource.currency_type:
			CurrencyPickupResource.CURRENCY_TYPE.FIAT:
				return true
                        # Mine a new block only if this level hasn't been mined before
                        CurrencyPickupResource.CURRENCY_TYPE.BTC:
                                var lvl: int = GameManager.get_current_level()
                                if !BitcoinNetwork.is_level_mined(lvl):
                                        BitcoinNetwork.mine_block("Player")
                                return true
			CurrencyPickupResource.CURRENCY_TYPE.NONE:
				return false
			_:
				return false
	return false
