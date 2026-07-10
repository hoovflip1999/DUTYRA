extends Area3D

@export var call_name: String = "Suspicious Person"
@export var location_name: String = "gas station"

var player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		player_inside = true

		if body.has_method("set_active_call_area"):
			body.set_active_call_area(self)

func _on_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		player_inside = false

		if body.has_method("clear_active_call_area"):
			body.clear_active_call_area(self)

func get_prompt_text() -> String:
	if not player_inside:
		return ""

	if not GameState.is_on_duty:
		return ""

	if not DispatchManager.has_active_call:
		return ""

	if DispatchManager.call_status == "pending":
		return "Accept call first"

	if DispatchManager.call_status == "accepted":
		return "Press E to report on scene"

	if DispatchManager.call_status == "on_scene":
		return "Press E to handle " + call_name

	return ""

func interact() -> void:
	if not GameState.is_on_duty:
		print("You are off duty")
		return

	if not DispatchManager.has_active_call:
		print("No active dispatch call")
		return

	if DispatchManager.call_status == "pending":
		print("Accept the call first")
		return

	if DispatchManager.call_status == "accepted":
		DispatchManager.mark_active_call_on_scene()
		return

	if DispatchManager.call_status == "on_scene":
		print("Handled call: " + call_name)
		RadioManager.send_radio_message("Dispatch, M24 clear from " + location_name + ".")
		DispatchManager.clear_active_call(false)
		return
