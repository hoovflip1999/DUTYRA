extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var crouch_speed: float = 2.5
@export var jump_velocity: float = 6.0
@export var gravity: float = 20.0
@export var mouse_sensitivity: float = 0.003
@export var standing_camera_height: float = 1.6
@export var crouching_camera_height: float = 1.0
@export var radio_message_seconds: float = 4.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var interaction_ray: RayCast3D = $CameraPivot/PlayerCamera/InteractionRay
@onready var interaction_prompt: Label = $PlayerUI/InteractionPrompt
@onready var duty_status_label: Label = $PlayerUI/DutyStatusLabel
@onready var dispatch_call_label: Label = $PlayerUI/DispatchCallLabel
@onready var radio_message_label: Label = $PlayerUI/RadioMessageLabel
@onready var player_ui: CanvasLayer = $PlayerUI

var camera_pitch: float = 0.0
var is_mdt_visible: bool = false
var radio_message_id: int = 0
var active_call_area: Node = null

var radio_wheel_container: Control
var is_radio_wheel_visible: bool = false
var radio_wheel_options: Array[Dictionary] = []

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	interaction_prompt.visible = false
	dispatch_call_label.visible = false
	radio_message_label.visible = false

	create_radio_wheel_ui()

	GameState.duty_status_changed.connect(_on_duty_status_changed)
	update_duty_status_label(GameState.is_on_duty)

	DispatchManager.active_call_changed.connect(_on_active_call_changed)
	update_dispatch_call_label(DispatchManager.get_display_text(), DispatchManager.has_active_call)

	RadioManager.radio_message_sent.connect(_on_radio_message_sent)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)

		camera_pitch -= event.relative.y * mouse_sensitivity
		camera_pitch = clamp(camera_pitch, deg_to_rad(-80), deg_to_rad(80))
		camera_pivot.rotation.x = camera_pitch

	if event.is_action_pressed("ui_cancel"):
		if is_radio_wheel_visible:
			hide_radio_wheel()
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event.is_action_pressed("toggle_radio_menu"):
		toggle_radio_wheel()

	if is_radio_wheel_visible and event is InputEventKey:
		if event.pressed and not event.echo:
			handle_radio_wheel_number_input(event.keycode)
			return

	if event.is_action_pressed("interact"):
		handle_interact_input()

	if event.is_action_pressed("toggle_mdt"):
		toggle_mdt()

func _physics_process(delta: float) -> void:
	update_context_prompt()

	var input_dir := Vector2.ZERO

	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1

	if Input.is_action_pressed("move_back"):
		input_dir.y += 1

	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1

	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	input_dir = input_dir.normalized()

	var direction := (global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var current_speed := walk_speed

	if Input.is_action_pressed("crouch"):
		current_speed = crouch_speed
		camera_pivot.position.y = crouching_camera_height
	elif Input.is_action_pressed("sprint"):
		current_speed = sprint_speed
		camera_pivot.position.y = standing_camera_height
	else:
		camera_pivot.position.y = standing_camera_height

	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
		else:
			velocity.y = 0

	move_and_slide()

func create_radio_wheel_ui() -> void:
	radio_wheel_container = Control.new()
	radio_wheel_container.name = "RadioWheel"
	radio_wheel_container.visible = false
	radio_wheel_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_ui.add_child(radio_wheel_container)
	radio_wheel_container.set_anchors_preset(Control.PRESET_FULL_RECT)

func toggle_radio_wheel() -> void:
	if is_radio_wheel_visible:
		hide_radio_wheel()
	else:
		show_radio_wheel()

func show_radio_wheel() -> void:
	is_radio_wheel_visible = true
	radio_wheel_container.visible = true
	refresh_radio_wheel()

func hide_radio_wheel() -> void:
	is_radio_wheel_visible = false
	radio_wheel_container.visible = false

func refresh_radio_wheel() -> void:
	for child in radio_wheel_container.get_children():
		child.queue_free()

	radio_wheel_options = build_radio_wheel_options()

	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var center: Vector2 = screen_size * 0.5

	var center_label := Label.new()
	center_label.text = "RADIO\n" + get_radio_status_text() + "\nQ to close"
	center_label.size = Vector2(280, 90)
	center_label.position = center - Vector2(140, 45)
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	radio_wheel_container.add_child(center_label)

	if radio_wheel_options.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No radio status available"
		empty_label.size = Vector2(300, 50)
		empty_label.position = center + Vector2(-150, 120)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		radio_wheel_container.add_child(empty_label)
		return

	var radius: float = 190.0
	var start_angle: float = -PI / 2.0
	var angle_step: float = TAU / float(radio_wheel_options.size())

	for i in range(radio_wheel_options.size()):
		var option: Dictionary = radio_wheel_options[i]
		var angle: float = start_angle + angle_step * float(i)
		var option_position: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius

		var option_label := Label.new()
		option_label.text = str(i + 1) + "  " + str(option["title"]) + "\n" + str(option["subtitle"])
		option_label.size = Vector2(260, 70)
		option_label.position = option_position - Vector2(130, 35)
		option_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		option_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		radio_wheel_container.add_child(option_label)

func build_radio_wheel_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []

	if not GameState.is_on_duty:
		options.append({
			"title": "10-41",
			"subtitle": "In Service",
			"action": "go_in_service"
		})
		return options

	if DispatchManager.has_active_call:
		if DispatchManager.call_status == "pending":
			options.append({
				"title": "10-76",
				"subtitle": "En Route",
				"action": "accept_call"
			})
		elif DispatchManager.call_status == "accepted":
			if can_report_on_scene():
				options.append({
					"title": "10-97",
					"subtitle": "On Scene",
					"action": "report_on_scene"
				})
		elif DispatchManager.call_status == "on_scene":
			if can_clear_call():
				options.append({
					"title": "10-8",
					"subtitle": "Clear / Available",
					"action": "clear_call"
				})

		return options

	options.append({
		"title": "10-42",
		"subtitle": "Out of Service",
		"action": "go_out_of_service"
	})

	return options

func get_radio_status_text() -> String:
	if not GameState.is_on_duty:
		return "Status: Off Duty"

	if DispatchManager.has_active_call:
		if DispatchManager.call_status == "pending":
			return "Status: Pending Call"

		if DispatchManager.call_status == "accepted":
			return "Status: En Route"

		if DispatchManager.call_status == "on_scene":
			return "Status: On Scene"

	return "Status: Available"

func handle_radio_wheel_number_input(keycode: int) -> void:
	var selected_index: int = -1

	if keycode >= KEY_1 and keycode <= KEY_9:
		selected_index = keycode - KEY_1

	if selected_index >= 0:
		select_radio_wheel_option(selected_index)

func select_radio_wheel_option(option_index: int) -> void:
	if option_index < 0:
		return

	if option_index >= radio_wheel_options.size():
		return

	var selected_option: Dictionary = radio_wheel_options[option_index]
	var action_name: String = str(selected_option["action"])

	hide_radio_wheel()

	if action_name == "go_in_service":
		GameState.set_duty_status(true)
	elif action_name == "go_out_of_service":
		GameState.set_duty_status(false)
	elif action_name == "accept_call":
		DispatchManager.accept_active_call()
	elif action_name == "report_on_scene":
		DispatchManager.mark_active_call_on_scene()
	elif action_name == "clear_call":
		RadioManager.send_player_message("Dispatch, show Unit 24 10 8. Contact made, no further action.")
		RadioManager.send_dispatch_ack("10 4, Unit 24 clear.")
		DispatchManager.clear_active_call(false)

func can_report_on_scene() -> bool:
	if active_call_area == null:
		return false

	var location_value: Variant = active_call_area.get("location_name")

	if location_value == null:
		return false

	if not DispatchManager.does_active_call_match_location(str(location_value)):
		return false

	return DispatchManager.call_status == "accepted"

func can_clear_call() -> bool:
	if active_call_area == null:
		return false

	var location_value: Variant = active_call_area.get("location_name")

	if location_value == null:
		return false

	if not DispatchManager.does_active_call_match_location(str(location_value)):
		return false

	if DispatchManager.call_status != "on_scene":
		return false

	return DispatchManager.call_objective_complete

func handle_interact_input() -> void:
	try_interact_with_raycast()

func update_context_prompt() -> void:
	if show_raycast_prompt():
		return

	interaction_prompt.visible = false

func show_raycast_prompt() -> bool:
	if not interaction_ray.is_colliding():
		return false

	var hit_object: Object = interaction_ray.get_collider()

	if hit_object == null:
		return false

	if not hit_object.has_method("interact"):
		return false

	var prompt_text: String = "Press E to interact"
	var object_prompt: Variant = hit_object.get("prompt_text")

	if object_prompt != null:
		prompt_text = str(object_prompt)

	if prompt_text == "":
		return false

	interaction_prompt.text = prompt_text
	interaction_prompt.visible = true
	return true

func try_interact_with_raycast() -> bool:
	if not interaction_ray.is_colliding():
		return false

	var hit_object: Object = interaction_ray.get_collider()

	if hit_object == null:
		return false

	if not hit_object.has_method("interact"):
		return false

	var object_prompt: Variant = hit_object.get("prompt_text")

	if object_prompt != null:
		if str(object_prompt) == "":
			return false

	hit_object.interact()
	return true

func set_active_call_area(call_area: Node) -> void:
	active_call_area = call_area

func clear_active_call_area(call_area: Node) -> void:
	if active_call_area == call_area:
		active_call_area = null
		interaction_prompt.visible = false

func toggle_mdt() -> void:
	is_mdt_visible = !is_mdt_visible
	dispatch_call_label.visible = is_mdt_visible

func _on_duty_status_changed(is_on_duty: bool) -> void:
	update_duty_status_label(is_on_duty)

	if is_radio_wheel_visible:
		refresh_radio_wheel()

func update_duty_status_label(is_on_duty: bool) -> void:
	if is_on_duty:
		duty_status_label.text = "ON DUTY"
	else:
		duty_status_label.text = "OFF DUTY"

func _on_active_call_changed(call_text: String, has_call: bool) -> void:
	update_dispatch_call_label(call_text, has_call)

	if is_radio_wheel_visible:
		refresh_radio_wheel()

func update_dispatch_call_label(call_text: String, _has_call: bool) -> void:
	dispatch_call_label.text = call_text

func _on_radio_message_sent(speaker_name: String, _message_text: String) -> void:
	show_radio_message("🔊 " + speaker_name)

func show_radio_message(message_text: String) -> void:
	radio_message_id += 1
	var current_message_id: int = radio_message_id

	radio_message_label.text = message_text
	radio_message_label.visible = true

	await get_tree().create_timer(radio_message_seconds).timeout

	if current_message_id == radio_message_id:
		radio_message_label.visible = false
