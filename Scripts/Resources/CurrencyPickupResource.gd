class_name CurrencyPickupResource
extends Resource

enum CURRENCY_TYPE{
	NONE = 0,
	FIAT = 1,
	BTC = 2
}

@export var display_name: String
@export var amount: float
@export var currency_type: CURRENCY_TYPE = CURRENCY_TYPE.NONE
