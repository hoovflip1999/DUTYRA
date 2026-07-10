extends Node

signal active_call_changed(call_text: String, has_call: bool)

var has_active_call: bool = false
var active_call_text: String = ""

func _ready() -> void:
	GameState.duty_status_changed.connect(_on_duty_status_changed)

func _on_duty_status_changed(is_on_duty: bool) -> void:
	if is_on_duty:
		assign_test_call()
	else:
		clear_active_call()

func assign_test_call() -> void:
	has_active_call = true
	active_call_text = "P3 - Suspicious Person near Gas Station"
	active_call_changed.emit(active_call_text, has_active_call)
	print("Dispatch assigned call: " + active_call_text)

func clear_active_call() -> void:
	has_active_call = false
	active_call_text = ""
	active_call_changed.emit(active_call_text, has_active_call)
	print("Dispatch cleared active call")
