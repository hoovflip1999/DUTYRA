extends Node

signal active_call_changed(call_text: String, has_call: bool)

var has_active_call: bool = false
var active_call_text: String = ""
var call_status: String = "none"

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
	call_status = "pending"
	active_call_changed.emit(get_display_text(), has_active_call)
	print("Dispatch assigned call: " + active_call_text)

func accept_active_call() -> void:
	if not has_active_call:
		print("No active call to accept")
		return

	if call_status != "pending":
		print("Call is not pending")
		return

	call_status = "accepted"
	active_call_changed.emit(get_display_text(), has_active_call)
	print("Call accepted: " + active_call_text)

func clear_active_call() -> void:
	has_active_call = false
	active_call_text = ""
	call_status = "none"
	active_call_changed.emit(get_display_text(), has_active_call)
	print("Dispatch cleared active call")

func get_display_text() -> String:
	if not has_active_call:
		return "No active call"

	if call_status == "pending":
		return "PENDING: " + active_call_text + " | Press R to accept"

	if call_status == "accepted":
		return "EN ROUTE: " + active_call_text

	return active_call_text
