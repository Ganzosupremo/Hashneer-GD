class_name CurrencyPickupResource
extends Resource
# This resource represents a currency pickup in the game, which can be either fiat or bitcoin.
@export var display_name: String
@export var amount: float
@export var currency_type: Constants.CurrencyType = Constants.CurrencyType.FIAT
