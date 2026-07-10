extends StaticBody3D

@export var prompt_text: String = ""
@export var subject_name: String = "Suspicious Person"
@export var location_name: String = "Gas Station"

func _physics_process(_delta: float) -> void:
	update_prompt()

func update_prompt() -> void:
	if not GameState.is_on_duty:
		prompt_text = ""
		return

	if not DispatchManager.has_active_call:
		prompt_text = ""
		return

	if not DispatchManager.does_active_call_match_location(location_name):
		prompt_text = ""
		return

	if DispatchManager.call_status != "on_scene":
		prompt_text = ""
		return

	if DispatchManager.call_objective_complete:
		prompt_text = ""
		return

	prompt_text = "Press E to contact"

func interact() -> void:
	if not GameState.is_on_duty:
		return

	if not DispatchManager.has_active_call:
		return

	if not DispatchManager.does_active_call_match_location(location_name):
		return

	if DispatchManager.call_status != "on_scene":
		return

	if DispatchManager.call_objective_complete:
		return

	print("Contacted " + subject_name)

	RadioManager.send_player_message(get_contact_radio_message())

	DispatchManager.complete_active_call_objective(get_resolution_note())

func get_contact_radio_message() -> String:
	if not DispatchManager.has_active_call:
		return "Dispatch, Unit 24 making contact."

	var call_title: String = ""

	if DispatchManager.active_call.has("title"):
		call_title = str(DispatchManager.active_call["title"]).to_lower()

	if call_title == "suspicious person":
		return "Dispatch, Unit 24 made contact with the suspicious person."

	if call_title == "noise complaint":
		return "Dispatch, Unit 24 made contact with the resident."

	return "Dispatch, Unit 24 made contact."

func get_resolution_note() -> String:
	if not DispatchManager.has_active_call:
		return "Contact made."

	var call_title: String = ""

	if DispatchManager.active_call.has("title"):
		call_title = str(DispatchManager.active_call["title"]).to_lower()

	if call_title == "suspicious person":
		return "Subject identified. Waiting for a ride. No crime observed."

	if call_title == "noise complaint":
		return "Resident advised. Music turned down. Noise reduced."

	return "Contact made. No further action required."
