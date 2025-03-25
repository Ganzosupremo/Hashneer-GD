class_name CurrencyInventory extends Node2D

func add_to_inventory(resource: Resource, amount: float) -> bool:
	if resource is CurrencyPickupResource:
		match resource.currency_type:
			CurrencyPickupResource.CURRENCY_TYPE.FIAT:
				# FED.authorize_transaction(amount)
				return true
			# The BTC is not added here since it's added directly to the wallet by the BitcoinNetwork class
			CurrencyPickupResource.CURRENCY_TYPE.NONE:
				return false
			CurrencyPickupResource.CURRENCY_TYPE.BTC:
				return true
			_:
				return false
	return false
