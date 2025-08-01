class_name HealthUIWavesGameMode extends Control

@onready var _health_progress_bar: ProgressBar = %HealthProgressBar
@onready var _health_text: Label = %HealthText

func _ready() -> void:
	GameManager.player.get_health_node().update_health.connect(_on_health_changed)
	var current_health: float = GameManager.player.get_current_health()
	var max_health: float = GameManager.player.get_max_health()
	_on_health_changed(current_health, max_health)

func _on_health_changed(current_health: float, max_health: float) -> void:
	_health_progress_bar.max_value = max_health
	_health_text.text = "%.0f/%.0f" % [current_health, max_health]
	var tween: Tween = GameManager.init_tween().set_parallel(true).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_health_progress_bar, "value", current_health, 0.15).from(_health_progress_bar.value).set_trans(Tween.TRANS_BACK)
