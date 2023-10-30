extends Control

@onready var currency_label: Label = %CurrencyLabel


func _ready() -> void:
	BitcoinNetwork.reward_issued.connect(Callable(self, "on_resource_added"))

func on_resource_added(resource_amount: float) -> void:
	currency_label.text = "Currency: " + str(resource_amount)


