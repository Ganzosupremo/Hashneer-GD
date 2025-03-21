class_name CurrencyInventory extends Node2D

func add_to_inventory(resource: Resource, amount: float) -> bool:
	print("Adding resource {0} to inventory: {1}".format([resource.display_name, amount]))
	if resource is CurrencyPickupResource:
		match resource.currency_type:
			CurrencyPickupResource.CURRENCY_TYPE.FIAT:
				BitcoinWallet.add_fiat(amount)
				return true
			# The BTC is not added here since it's added directly to the wallet by the BitcoinNetwork class
			CurrencyPickupResource.CURRENCY_TYPE.NONE:
				return false
			_:
				return false
	return false
