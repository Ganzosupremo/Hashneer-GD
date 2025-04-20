class_name CurrencyInventory extends Node2D

func add_to_inventory(resource: Resource, amount: float) -> bool:
	if resource is CurrencyPickupResource:
		match resource.currency_type:
			CurrencyPickupResource.CURRENCY_TYPE.FIAT:
				return true
			# The BTC is not added here since it's added directly to the wallet by the BitcoinNetwork class.
			# TEST - Mine the block when the pickup is picked up
			CurrencyPickupResource.CURRENCY_TYPE.BTC:
				BitcoinNetwork.mine_block("Player")
				return true
			CurrencyPickupResource.CURRENCY_TYPE.NONE:
				return false
			_:
				return false
	return false
