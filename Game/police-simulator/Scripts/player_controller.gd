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

var camera_pitch: float = 0.0
var is_mdt_visible: bool = false
var radio_message_id: int = 0
var active_call_area: Node = null

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	interaction_prompt.visible = false
	dispatch_call_label.visible = false
	radio_message_label.visible = false

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
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event.is_action_pressed("interact"):
		handle_interact_input()

	if event.is_action_pressed("accept_call"):
		DispatchManager.accept_active_call()

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

func handle_interact_input() -> void:
	if try_interact_with_raycast():
		return

	if active_call_area != null:
		if active_call_area.has_method("get_prompt_text") and active_call_area.has_method("interact"):
			var area_prompt: String = active_call_area.get_prompt_text()

			if area_prompt != "":
				active_call_area.interact()
				return

func update_context_prompt() -> void:
	if show_raycast_prompt():
		return

	if active_call_area != null and active_call_area.has_method("get_prompt_text"):
		var area_prompt: String = active_call_area.get_prompt_text()

		if area_prompt != "":
			interaction_prompt.text = area_prompt
			interaction_prompt.visible = true
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

func update_duty_status_label(is_on_duty: bool) -> void:
	if is_on_duty:
		duty_status_label.text = "ON DUTY"
	else:
		duty_status_label.text = "OFF DUTY"

func _on_active_call_changed(call_text: String, has_call: bool) -> void:
	update_dispatch_call_label(call_text, has_call)

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
