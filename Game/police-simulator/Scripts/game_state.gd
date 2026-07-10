extends Node

signal duty_status_changed(is_on_duty: bool)

var is_on_duty: bool = false

func toggle_duty() -> void:
	set_duty_status(!is_on_duty)

func set_duty_status(new_status: bool) -> void:
	if is_on_duty == new_status:
		return

	is_on_duty = new_status
	duty_status_changed.emit(is_on_duty)

	if is_on_duty:
		print("Player is now ON DUTY")
	else:
		print("Player is now OFF DUTY")

func get_duty_status_text() -> String:
	if is_on_duty:
		return "ON DUTY"

	return "OFF DUTY"
