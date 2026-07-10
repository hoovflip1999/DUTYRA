extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var crouch_speed: float = 2.5
@export var jump_velocity: float = 6.0
@export var gravity: float = 20.0
@export var mouse_sensitivity: float = 0.003
@export var standing_camera_height: float = 1.6
@export var crouching_camera_height: float = 1.0
@export var radio_message_seconds: float = 3.2

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
var subject_dialogue_id: int = 0
var call_clear_id: int = 0
var active_call_area: Node = null

var hud_status_dot: Panel
var mdt_panel: Panel
var subject_dialogue_panel: Panel
var subject_dialogue_label: Label
var call_clear_panel: Panel
var call_clear_label: Label
var radio_wheel_container: Control
var is_radio_wheel_visible: bool = false
var radio_wheel_options: Array[Dictionary] = []
var highlighted_radio_option_index: int = -1

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	interaction_prompt.visible = false
	dispatch_call_label.visible = false
	radio_message_label.visible = false
	radio_message_label.size = Vector2(560, 70)
	radio_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	radio_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	radio_message_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

	create_main_status_hud()
	create_mdt_ui()
	create_subject_dialogue_ui()
	create_call_clear_ui()
	create_radio_wheel_ui()

	GameState.duty_status_changed.connect(_on_duty_status_changed)
	update_duty_status_label(GameState.is_on_duty)

	DispatchManager.active_call_changed.connect(_on_active_call_changed)
	update_dispatch_call_label(DispatchManager.get_display_text(), DispatchManager.has_active_call)

	RadioManager.radio_message_sent.connect(_on_radio_message_sent)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not is_radio_wheel_visible:
		rotate_y(-event.relative.x * mouse_sensitivity)

		camera_pitch -= event.relative.y * mouse_sensitivity
		camera_pitch = clamp(camera_pitch, deg_to_rad(-80), deg_to_rad(80))
		camera_pivot.rotation.x = camera_pitch

	if event.is_action_pressed("ui_cancel"):
		if is_radio_wheel_visible:
			hide_radio_wheel()
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		return

	if event.is_action_pressed("toggle_radio_menu"):
		toggle_radio_wheel()
		return

	if is_radio_wheel_visible:
		if event is InputEventMouseMotion:
			update_radio_wheel_mouse_selection()
			return

		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				update_radio_wheel_mouse_selection()
				select_highlighted_radio_option()

			return

		if event.is_action_pressed("interact"):
			update_radio_wheel_mouse_selection()
			select_highlighted_radio_option()
			return

		if event is InputEventKey:
			if event.pressed and not event.echo:
				handle_radio_wheel_number_input(event.keycode)

			return

		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event.is_action_pressed("interact"):
		handle_interact_input()

	if event.is_action_pressed("toggle_mdt"):
		toggle_mdt()

func _physics_process(delta: float) -> void:
	update_context_prompt()

	if is_radio_wheel_visible:
		lock_player_movement(delta)
		return

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

func lock_player_movement(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	move_and_slide()

func create_main_status_hud() -> void:
	hud_status_dot = Panel.new()
	hud_status_dot.name = "HUDStatusDot"
	hud_status_dot.size = Vector2(16, 16)
	hud_status_dot.position = Vector2(20, 24)
	hud_status_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_ui.add_child(hud_status_dot)

	duty_status_label.position = Vector2(45, 20)
	duty_status_label.size = Vector2(300, 50)

	update_main_status_hud()

func create_mdt_ui() -> void:
	mdt_panel = Panel.new()
	mdt_panel.name = "MDTPanel"
	mdt_panel.position = Vector2(20, 70)
	mdt_panel.size = Vector2(520, 390)
	mdt_panel.visible = false
	mdt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mdt_panel.z_index = 5

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.01, 0.015, 0.02, 0.86)
	panel_style.border_color = Color(0.1, 0.75, 1.0, 0.75)
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	mdt_panel.add_theme_stylebox_override("panel", panel_style)

	player_ui.add_child(mdt_panel)

	dispatch_call_label.position = Vector2(40, 90)
	dispatch_call_label.size = Vector2(480, 350)
	dispatch_call_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dispatch_call_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dispatch_call_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	dispatch_call_label.z_index = 6

func create_subject_dialogue_ui() -> void:
	subject_dialogue_panel = Panel.new()
	subject_dialogue_panel.name = "SubjectDialoguePanel"
	subject_dialogue_panel.size = Vector2(620, 110)
	subject_dialogue_panel.visible = false
	subject_dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subject_dialogue_panel.z_index = 20

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.02, 0.02, 0.02, 0.88)
	panel_style.border_color = Color(1.0, 1.0, 1.0, 0.45)
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	subject_dialogue_panel.add_theme_stylebox_override("panel", panel_style)

	player_ui.add_child(subject_dialogue_panel)

	subject_dialogue_label = Label.new()
	subject_dialogue_label.position = Vector2(18, 12)
	subject_dialogue_label.size = Vector2(584, 86)
	subject_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subject_dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subject_dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subject_dialogue_panel.add_child(subject_dialogue_label)

func create_call_clear_ui() -> void:
	call_clear_panel = Panel.new()
	call_clear_panel.name = "CallClearPanel"
	call_clear_panel.size = Vector2(520, 150)
	call_clear_panel.visible = false
	call_clear_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	call_clear_panel.z_index = 25

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.01, 0.04, 0.02, 0.92)
	panel_style.border_color = Color(0.1, 1.0, 0.25, 0.85)
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.corner_radius_top_left = 14
	panel_style.corner_radius_top_right = 14
	panel_style.corner_radius_bottom_left = 14
	panel_style.corner_radius_bottom_right = 14
	call_clear_panel.add_theme_stylebox_override("panel", panel_style)

	player_ui.add_child(call_clear_panel)

	call_clear_label = Label.new()
	call_clear_label.position = Vector2(18, 14)
	call_clear_label.size = Vector2(484, 122)
	call_clear_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	call_clear_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	call_clear_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	call_clear_panel.add_child(call_clear_label)

func update_main_status_hud() -> void:
	duty_status_label.text = get_hud_status_text()

	if hud_status_dot == null:
		return

	var dot_style := StyleBoxFlat.new()
	dot_style.bg_color = get_radio_status_color()
	dot_style.corner_radius_top_left = 8
	dot_style.corner_radius_top_right = 8
	dot_style.corner_radius_bottom_left = 8
	dot_style.corner_radius_bottom_right = 8

	hud_status_dot.add_theme_stylebox_override("panel", dot_style)

func get_hud_status_text() -> String:
	if not GameState.is_on_duty:
		return "OFF DUTY"

	if DispatchManager.has_active_call:
		if DispatchManager.call_status == "pending":
			return "PENDING CALL"

		if DispatchManager.call_status == "accepted":
			return "EN ROUTE"

		if DispatchManager.call_status == "on_scene":
			return "ON SCENE"

	return "AVAILABLE"

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
	highlighted_radio_option_index = -1
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	radio_wheel_container.visible = true
	center_mouse_on_radio_wheel()
	refresh_radio_wheel()

func hide_radio_wheel() -> void:
	is_radio_wheel_visible = false
	highlighted_radio_option_index = -1
	radio_wheel_container.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func center_mouse_on_radio_wheel() -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	get_viewport().warp_mouse(screen_size * 0.5)

func refresh_radio_wheel() -> void:
	for child in radio_wheel_container.get_children():
		child.queue_free()

	radio_wheel_options = build_radio_wheel_options()

	if highlighted_radio_option_index >= radio_wheel_options.size():
		highlighted_radio_option_index = -1

	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var center: Vector2 = screen_size * 0.5

	var blur_overlay := ColorRect.new()
	blur_overlay.name = "RadioBlurOverlay"
	blur_overlay.position = Vector2.ZERO
	blur_overlay.size = screen_size
	blur_overlay.color = Color.WHITE
	blur_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blur_overlay.material = create_radio_blur_material()
	radio_wheel_container.add_child(blur_overlay)

	var center_panel := Panel.new()
	center_panel.name = "RadioCenterCircle"
	center_panel.size = Vector2(280, 280)
	center_panel.position = center - Vector2(140, 140)
	center_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var center_style := StyleBoxFlat.new()
	center_style.bg_color = Color(0.02, 0.02, 0.02, 0.72)
	center_style.border_color = get_radio_status_color()
	center_style.border_width_top = 4
	center_style.border_width_bottom = 4
	center_style.border_width_left = 4
	center_style.border_width_right = 4
	center_style.corner_radius_top_left = 140
	center_style.corner_radius_top_right = 140
	center_style.corner_radius_bottom_left = 140
	center_style.corner_radius_bottom_right = 140
	center_panel.add_theme_stylebox_override("panel", center_style)

	radio_wheel_container.add_child(center_panel)

	var center_label := Label.new()
	center_label.text = "RADIO\n" + get_radio_status_text() + "\nMove mouse\nE / Click to select\nQ / Esc to close"
	center_label.size = Vector2(260, 140)
	center_label.position = center - Vector2(130, 70)
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	radio_wheel_container.add_child(center_label)

	var status_dot := Panel.new()
	status_dot.name = "RadioStatusDot"
	status_dot.size = Vector2(20, 20)
	status_dot.position = center + Vector2(-105, -38)
	status_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var dot_style := StyleBoxFlat.new()
	dot_style.bg_color = get_radio_status_color()
	dot_style.corner_radius_top_left = 10
	dot_style.corner_radius_top_right = 10
	dot_style.corner_radius_bottom_left = 10
	dot_style.corner_radius_bottom_right = 10
	status_dot.add_theme_stylebox_override("panel", dot_style)

	radio_wheel_container.add_child(status_dot)

	if radio_wheel_options.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No radio status available"
		empty_label.size = Vector2(300, 50)
		empty_label.position = center + Vector2(-150, 150)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		radio_wheel_container.add_child(empty_label)
		return

	var radius: float = 230.0
	var start_angle: float = -PI / 2.0
	var angle_step: float = TAU / float(radio_wheel_options.size())

	for i in range(radio_wheel_options.size()):
		var option: Dictionary = radio_wheel_options[i]
		var angle: float = start_angle + angle_step * float(i)
		var option_position: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius
		var is_highlighted: bool = i == highlighted_radio_option_index

		var option_panel := Panel.new()
		option_panel.size = Vector2(300, 90)
		option_panel.position = option_position - Vector2(150, 45)
		option_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var option_style := StyleBoxFlat.new()

		if is_highlighted:
			option_style.bg_color = Color(0.08, 0.08, 0.08, 0.92)
			option_style.border_color = get_radio_status_color()
			option_style.border_width_top = 4
			option_style.border_width_bottom = 4
			option_style.border_width_left = 4
			option_style.border_width_right = 4
		else:
			option_style.bg_color = Color(0.02, 0.02, 0.02, 0.62)
			option_style.border_color = Color(0.4, 0.4, 0.4, 0.45)
			option_style.border_width_top = 2
			option_style.border_width_bottom = 2
			option_style.border_width_left = 2
			option_style.border_width_right = 2

		option_style.corner_radius_top_left = 18
		option_style.corner_radius_top_right = 18
		option_style.corner_radius_bottom_left = 18
		option_style.corner_radius_bottom_right = 18

		option_panel.add_theme_stylebox_override("panel", option_style)
		radio_wheel_container.add_child(option_panel)

		var option_label := Label.new()

		if is_highlighted:
			option_label.text = "> " + str(option["title"]) + " <\n" + str(option["subtitle"])
			option_label.add_theme_color_override("font_color", get_radio_status_color())
		else:
			option_label.text = str(i + 1) + "  " + str(option["title"]) + "\n" + str(option["subtitle"])

		option_label.size = Vector2(300, 90)
		option_label.position = option_position - Vector2(150, 45)
		option_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		option_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		radio_wheel_container.add_child(option_label)

func create_radio_blur_material() -> ShaderMaterial:
	var shader := Shader.new()

	shader.code = """
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

void fragment() {
	vec2 clear_center = vec2(0.5, 0.5);
	float clear_radius = 0.17;
	float edge_softness = 0.08;
	float blur_size = 4.0;
	float darken_amount = 0.42;

	vec2 pixel = SCREEN_PIXEL_SIZE * blur_size;

	vec4 original_color = texture(screen_texture, SCREEN_UV);

	vec4 blurred_color = vec4(0.0);
	blurred_color += texture(screen_texture, SCREEN_UV + vec2(-pixel.x, -pixel.y));
	blurred_color += texture(screen_texture, SCREEN_UV + vec2(0.0, -pixel.y));
	blurred_color += texture(screen_texture, SCREEN_UV + vec2(pixel.x, -pixel.y));
	blurred_color += texture(screen_texture, SCREEN_UV + vec2(-pixel.x, 0.0));
	blurred_color += texture(screen_texture, SCREEN_UV);
	blurred_color += texture(screen_texture, SCREEN_UV + vec2(pixel.x, 0.0));
	blurred_color += texture(screen_texture, SCREEN_UV + vec2(-pixel.x, pixel.y));
	blurred_color += texture(screen_texture, SCREEN_UV + vec2(0.0, pixel.y));
	blurred_color += texture(screen_texture, SCREEN_UV + vec2(pixel.x, pixel.y));
	blurred_color /= 9.0;

	float distance_from_center = distance(SCREEN_UV, clear_center);
	float effect_strength = smoothstep(clear_radius, clear_radius + edge_softness, distance_from_center);

	vec4 final_color = mix(original_color, blurred_color, effect_strength);
	final_color.rgb = mix(final_color.rgb, vec3(0.0), darken_amount * effect_strength);

	COLOR = final_color;
}
"""

	var material := ShaderMaterial.new()
	material.shader = shader

	return material

func update_radio_wheel_mouse_selection() -> void:
	var new_highlighted_index: int = get_radio_option_index_from_mouse()

	if new_highlighted_index == highlighted_radio_option_index:
		return

	highlighted_radio_option_index = new_highlighted_index
	refresh_radio_wheel()

func get_radio_option_index_from_mouse() -> int:
	if radio_wheel_options.is_empty():
		return -1

	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var center: Vector2 = screen_size * 0.5
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var mouse_offset: Vector2 = mouse_position - center

	if mouse_offset.length() < 80.0:
		return -1

	var radius: float = 230.0
	var start_angle: float = -PI / 2.0
	var angle_step: float = TAU / float(radio_wheel_options.size())

	var best_index: int = -1
	var best_distance: float = 999999.0

	for i in range(radio_wheel_options.size()):
		var angle: float = start_angle + angle_step * float(i)
		var option_position: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius
		var distance_to_option: float = mouse_position.distance_to(option_position)

		if distance_to_option < best_distance:
			best_distance = distance_to_option
			best_index = i

	return best_index

func select_highlighted_radio_option() -> void:
	if highlighted_radio_option_index < 0:
		return

	select_radio_wheel_option(highlighted_radio_option_index)

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

func get_radio_status_color() -> Color:
	if not GameState.is_on_duty:
		return Color(1.0, 0.1, 0.1, 1.0)

	if DispatchManager.has_active_call:
		return Color(1.0, 0.55, 0.05, 1.0)

	return Color(0.1, 1.0, 0.25, 1.0)

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
		var cleared_call_title: String = get_current_call_title_for_result()
		var cleared_call_note: String = get_current_call_note_for_result()

		RadioManager.send_player_message("Dispatch, show Unit 24 10 8. Contact made, no further action.")
		RadioManager.send_dispatch_ack("10 4, Unit 24 clear.")
		DispatchManager.clear_active_call(false)
		show_call_cleared_result(cleared_call_title, cleared_call_note)

func get_current_call_title_for_result() -> String:
	if not DispatchManager.has_active_call:
		return "Call"

	if not DispatchManager.active_call.has("title"):
		return "Call"

	return str(DispatchManager.active_call["title"])

func get_current_call_note_for_result() -> String:
	if DispatchManager.call_resolution_note != "":
		return DispatchManager.call_resolution_note

	return "No further action required."

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
	if is_radio_wheel_visible:
		interaction_prompt.visible = false
		return

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

	var dialogue_speaker: String = ""
	var dialogue_text: String = ""

	if hit_object.has_method("get_dialogue_speaker"):
		dialogue_speaker = str(hit_object.get_dialogue_speaker())

	if hit_object.has_method("get_dialogue_text"):
		dialogue_text = str(hit_object.get_dialogue_text())

	hit_object.interact()

	if dialogue_text != "":
		show_subject_dialogue(dialogue_speaker, dialogue_text)

	return true

func show_subject_dialogue(speaker_name: String, dialogue_text: String) -> void:
	subject_dialogue_id += 1
	var current_dialogue_id: int = subject_dialogue_id

	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	subject_dialogue_panel.position = Vector2((screen_size.x - subject_dialogue_panel.size.x) * 0.5, screen_size.y - 170)

	if speaker_name == "":
		speaker_name = "SUBJECT"

	subject_dialogue_label.text = speaker_name + "\n" + dialogue_text
	subject_dialogue_panel.visible = true

	await get_tree().create_timer(4.0).timeout

	if current_dialogue_id == subject_dialogue_id:
		subject_dialogue_panel.visible = false

func show_call_cleared_result(call_title: String, call_note: String) -> void:
	call_clear_id += 1
	var current_clear_id: int = call_clear_id

	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	call_clear_panel.position = Vector2((screen_size.x - call_clear_panel.size.x) * 0.5, 120)

	call_clear_label.text = "CALL CLEARED\n\n" + call_title + "\n" + call_note + "\n\nStatus: Available"
	call_clear_panel.visible = true

	await get_tree().create_timer(4.0).timeout

	if current_clear_id == call_clear_id:
		call_clear_panel.visible = false

func set_active_call_area(call_area: Node) -> void:
	active_call_area = call_area

func clear_active_call_area(call_area: Node) -> void:
	if active_call_area == call_area:
		active_call_area = null
		interaction_prompt.visible = false

func toggle_mdt() -> void:
	is_mdt_visible = !is_mdt_visible
	dispatch_call_label.visible = is_mdt_visible

	if mdt_panel != null:
		mdt_panel.visible = is_mdt_visible

func _on_duty_status_changed(is_on_duty: bool) -> void:
	update_duty_status_label(is_on_duty)

	if is_radio_wheel_visible:
		refresh_radio_wheel()

func update_duty_status_label(_is_on_duty: bool) -> void:
	update_main_status_hud()

func _on_active_call_changed(call_text: String, has_call: bool) -> void:
	update_dispatch_call_label(call_text, has_call)
	update_main_status_hud()

	if is_radio_wheel_visible:
		refresh_radio_wheel()

func update_dispatch_call_label(call_text: String, _has_call: bool) -> void:
	dispatch_call_label.text = call_text

func _on_radio_message_sent(speaker_name: String, message_text: String) -> void:
	show_radio_message(speaker_name, message_text)

func show_radio_message(speaker_name: String, message_text: String) -> void:
	radio_message_id += 1
	var current_message_id: int = radio_message_id

	var compact_message: String = get_compact_radio_message(speaker_name, message_text)

	radio_message_label.text = speaker_name + "\n" + compact_message
	radio_message_label.visible = true

	await get_tree().create_timer(get_radio_message_display_seconds(compact_message)).timeout

	if current_message_id == radio_message_id:
		radio_message_label.visible = false

func get_compact_radio_message(speaker_name: String, message_text: String) -> String:
	var lower_message: String = message_text.to_lower()

	if speaker_name == "DISPATCH":
		if DispatchManager.has_active_call and DispatchManager.call_status == "pending":
			if DispatchManager.active_call.has("title") and DispatchManager.active_call.has("location"):
				return "New call: " + str(DispatchManager.active_call["title"]) + " - " + str(DispatchManager.active_call["location"])

	if lower_message.find("10 41") != -1:
		return "10-41 In service"

	if lower_message.find("10 42") != -1:
		return "10-42 Out of service"

	if lower_message.find("10 76") != -1:
		return "10-76 En route"

	if lower_message.find("10 97") != -1:
		return "10-97 On scene"

	if lower_message.find("10 8") != -1:
		return "10-8 Clear / available"

	if lower_message.find("10 4") != -1:
		return "10-4 Acknowledged"

	return limit_radio_message_length(message_text, 58)

func limit_radio_message_length(message_text: String, max_characters: int) -> String:
	if message_text.length() <= max_characters:
		return message_text

	return message_text.substr(0, max_characters - 3) + "..."

func get_radio_message_display_seconds(compact_message: String) -> float:
	var words: PackedStringArray = compact_message.split(" ", false)
	var calculated_time: float = float(words.size()) * 0.18 + 1.8

	return maxf(radio_message_seconds, calculated_time)
