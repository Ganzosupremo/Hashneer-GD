extends Control

@onready var request: HTTPRequest = $HTTPRequest

func _ready() -> void:
	request.request_completed.connect(on_request_completed)
	request.request("https://bitcoinexplorer.org/api/price")

func on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS: return
		
	var json = JSON.parse_string(body.get_string_from_utf8())
	var price: float = json["usd"].to_float()
