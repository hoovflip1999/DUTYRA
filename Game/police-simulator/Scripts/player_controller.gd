extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var crouch_speed: float = 2.5
@export var jump_velocity: float = 6.0
@export var gravity: float = 20.0
@export var mouse_sensitivity: float = 0.003
@export var standing_camera_height: float = 1.6
@export var crouching_camera_height: float = 1.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var interaction_ray: RayCast3D = $CameraPivot/PlayerCamera/InteractionRay
@onready var interaction_prompt: Label = $PlayerUI/InteractionPrompt
@onready var duty_status_label: Label = $PlayerUI/DutyStatusLabel

var camera_pitch: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	interaction_prompt.visible = false

	GameState.duty_status_changed.connect(_on_duty_status_changed)
	update_duty_status_label(GameState.is_on_duty)

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
		try_interact()

	if event.is_action_pressed("toggle_duty"):
		GameState.toggle_duty()

func _physics_process(delta: float) -> void:
	update_interaction_prompt()

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

func update_interaction_prompt() -> void:
	interaction_prompt.visible = false

	if interaction_ray.is_colliding():
		var hit_object := interaction_ray.get_collider()

		if hit_object and hit_object.has_method("interact"):
			if "prompt_text" in hit_object:
				interaction_prompt.text = hit_object.prompt_text
			else:
				interaction_prompt.text = "Press E to interact"

			interaction_prompt.visible = true

func try_interact() -> void:
	if interaction_ray.is_colliding():
		var hit_object := interaction_ray.get_collider()

		if hit_object and hit_object.has_method("interact"):
			hit_object.interact()

func _on_duty_status_changed(is_on_duty: bool) -> void:
	update_duty_status_label(is_on_duty)

func update_duty_status_label(is_on_duty: bool) -> void:
	if is_on_duty:
		duty_status_label.text = "ON DUTY"
	else:
		duty_status_label.text = "OFF DUTY"
