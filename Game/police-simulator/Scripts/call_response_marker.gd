extends StaticBody3D

@export var call_name: String = "Suspicious Person"
@export var prompt_text: String = "No active call here"

func _physics_process(_delta: float) -> void:
	update_prompt()

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
		RadioManager.send_radio_message("Scene handled. Unit clear from gas station.")
		DispatchManager.clear_active_call()
		return

	print("Call is not ready to handle")

func update_prompt() -> void:
	if not GameState.is_on_duty:
		prompt_text = "Off duty"
	elif not DispatchManager.has_active_call:
		prompt_text = "No active call here"
	elif DispatchManager.call_status == "pending":
		prompt_text = "Accept call first"
	elif DispatchManager.call_status == "accepted":
		prompt_text = "Press E to mark on scene"
	elif DispatchManager.call_status == "on_scene":
		prompt_text = "Press E to handle " + call_name
	else:
		prompt_text = "No active call here"
