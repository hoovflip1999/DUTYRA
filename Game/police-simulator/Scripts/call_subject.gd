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

func get_dialogue_speaker() -> String:
	var call_title: String = get_active_call_title()

	if call_title == "noise complaint":
		return "RESIDENT"

	return "SUBJECT"

func get_dialogue_text() -> String:
	var call_title: String = get_active_call_title()

	if call_title == "suspicious person":
		return "I'm just waiting for my ride. I haven't bothered anyone."

	if call_title == "noise complaint":
		return "Sorry, I'll turn the music down."

	return "I understand, officer."

func get_contact_radio_message() -> String:
	var call_title: String = get_active_call_title()

	if call_title == "suspicious person":
		return "Dispatch, Unit 24 made contact with the suspicious person."

	if call_title == "noise complaint":
		return "Dispatch, Unit 24 made contact with the resident."

	return "Dispatch, Unit 24 made contact."

func get_resolution_note() -> String:
	var call_title: String = get_active_call_title()

	if call_title == "suspicious person":
		return "Subject identified. Waiting for a ride. No crime observed."

	if call_title == "noise complaint":
		return "Resident advised. Music turned down. Noise reduced."

	return "Contact made. No further action required."

func get_active_call_title() -> String:
	if not DispatchManager.has_active_call:
		return ""

	if not DispatchManager.active_call.has("title"):
		return ""

	return str(DispatchManager.active_call["title"]).to_lower()
