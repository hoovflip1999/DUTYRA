extends Node

signal active_call_changed(call_text: String, has_call: bool)

var has_active_call: bool = false
var call_status: String = "none"
var call_objective_complete: bool = false
var call_resolution_note: String = ""

var active_call: Dictionary = {}
var call_templates: Array[Dictionary] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	setup_call_templates()
	GameState.duty_status_changed.connect(_on_duty_status_changed)

func setup_call_templates() -> void:
	call_templates = [
		{
			"title": "Suspicious Person",
			"priority": "P3",
			"location": "Gas Station",
			"response": "Code 2",
			"response_description": "Routine response",
			"dispatch_radio": "Unit 24, this is dispatch. Respond Code 2, suspicious person, gas station.",
			"objective_pending": "Accept the call",
			"objective_accepted": "Go to the gas station",
			"objective_on_scene": "Contact the subject",
			"objective_complete": "Clear call when ready"
		},
		{
			"title": "Noise Complaint",
			"priority": "P3",
			"location": "Apartment",
			"response": "Code 2",
			"response_description": "Routine response",
			"dispatch_radio": "Unit 24, this is dispatch. Respond Code 2, noise complaint, apartment building.",
			"objective_pending": "Accept the call",
			"objective_accepted": "Go to the apartment building",
			"objective_on_scene": "Contact the involved person",
			"objective_complete": "Clear call when ready"
		}
	]

func _on_duty_status_changed(is_on_duty: bool) -> void:
	if is_on_duty:
		assign_random_call()
	else:
		clear_active_call()

func assign_random_call() -> void:
	if call_templates.is_empty():
		print("No call templates available")
		return

	var call_index: int = rng.randi_range(0, call_templates.size() - 1)
	active_call = call_templates[call_index].duplicate(true)

	has_active_call = true
	call_status = "pending"
	call_objective_complete = false
	call_resolution_note = ""

	active_call_changed.emit(get_display_text(), has_active_call)

	RadioManager.send_dispatch_message(str(active_call["dispatch_radio"]))

	print("Dispatch assigned call: " + get_active_call_summary())

func accept_active_call() -> void:
	if not has_active_call:
		print("No active call to accept")
		return

	if call_status != "pending":
		print("Call is not pending")
		return

	call_status = "accepted"

	active_call_changed.emit(get_display_text(), has_active_call)

	RadioManager.send_player_message("Dispatch, show Unit 24 10 76.")
	RadioManager.send_dispatch_ack("10 4, Unit 24.")

	print("Call accepted: " + get_active_call_summary())

func mark_active_call_on_scene() -> void:
	if not has_active_call:
		print("No active call")
		return

	if call_status != "accepted":
		print("Call must be accepted before marking on scene")
		return

	call_status = "on_scene"

	active_call_changed.emit(get_display_text(), has_active_call)

	RadioManager.send_player_message("Dispatch, Unit 24 10 97.")
	RadioManager.send_dispatch_ack("10 4, Unit 24.")

	print("Unit marked on scene: " + get_active_call_summary())

func complete_active_call_objective(resolution_note: String) -> void:
	if not has_active_call:
		return

	if call_status != "on_scene":
		return

	call_objective_complete = true
	call_resolution_note = resolution_note

	active_call_changed.emit(get_display_text(), has_active_call)

	print("Call objective complete")

func clear_active_call(send_radio_message: bool = true) -> void:
	var had_call: bool = has_active_call

	has_active_call = false
	call_status = "none"
	call_objective_complete = false
	call_resolution_note = ""
	active_call = {}

	active_call_changed.emit(get_display_text(), has_active_call)

	if had_call and send_radio_message:
		RadioManager.send_player_message("Dispatch, show Unit 24 10 8.")
		RadioManager.send_dispatch_ack("10 4, Unit 24 clear.")

	print("Dispatch cleared active call")

func does_active_call_match_location(location_name: String) -> bool:
	if not has_active_call:
		return false

	if not active_call.has("location"):
		return false

	return str(active_call["location"]).to_lower() == location_name.to_lower()

func get_active_call_summary() -> String:
	if not has_active_call:
		return "No active call"

	return str(active_call["priority"]) + " - " + str(active_call["title"]) + " near " + str(active_call["location"])

func get_current_objective_text() -> String:
	if not has_active_call:
		return ""

	if call_status == "pending":
		return str(active_call["objective_pending"])

	if call_status == "accepted":
		return str(active_call["objective_accepted"])

	if call_status == "on_scene":
		if call_objective_complete:
			return str(active_call["objective_complete"])

		return str(active_call["objective_on_scene"])

	return ""

func get_status_text() -> String:
	if call_status == "pending":
		return "Pending"

	if call_status == "accepted":
		return "En Route"

	if call_status == "on_scene":
		return "On Scene"

	return "Unknown"

func get_display_text() -> String:
	if not has_active_call:
		return "MDT CALL DETAILS\n\nNo active call."

	var mdt_text: String = "MDT CALL DETAILS\n\n" \
		+ "Status: " + get_status_text() + "\n" \
		+ "Call: " + str(active_call["title"]) + "\n" \
		+ "Priority: " + str(active_call["priority"]) + "\n" \
		+ "Location: " + str(active_call["location"]) + "\n" \
		+ "Response: " + str(active_call["response"]) + " - " + str(active_call["response_description"]) + "\n" \
		+ "Objective: " + get_current_objective_text() + "\n"

	if call_resolution_note != "":
		mdt_text += "Notes: " + call_resolution_note + "\n"

	mdt_text += "\nRadio Codes:\n" \
		+ "10-76 = En Route\n" \
		+ "10-97 = On Scene\n" \
		+ "10-8 = Clear / Available"

	return mdt_text
