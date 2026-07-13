extends CharacterBody3D

const MAX_UTILITY_SLOTS: int = 8

const EQUIPMENT_DATABASE := {
	"hands": {
		"name": "HANDS",
		"category": "DEFAULT"
	},
	"flashlight": {
		"name": "FLASHLIGHT",
		"category": "UTILITY"
	},
	"taser": {
		"name": "TASER",
		"category": "LESS LETHAL"
	},
	"handgun": {
		"name": "HANDGUN",
		"category": "FIREARM"
	},
	"handcuffs": {
		"name": "HANDCUFFS",
		"category": "RESTRAINT"
	},
	"baton": {
		"name": "BATON",
		"category": "LESS LETHAL"
	},
	"pepper_spray": {
		"name": "PEPPER SPRAY",
		"category": "LESS LETHAL"
	},
	"rifle": {
		"name": "PATROL RIFLE",
		"category": "FIREARM"
	},
	"road_spikes": {
		"name": "ROAD SPIKES",
		"category": "TRAFFIC"
	},
	"medkit": {
		"name": "MEDICAL KIT",
		"category": "MEDICAL"
	},
	"breaching_tool": {
		"name": "BREACHING TOOL",
		"category": "SPECIAL"
	}
}


@export var walk_speed: float = 4.6
@export var sprint_speed: float = 7.4
@export var crouch_speed: float = 2.3

@export var ground_acceleration: float = 18.0
@export var ground_deceleration: float = 24.0

@export var backward_speed_multiplier: float = 0.78
@export var strafe_speed_multiplier: float = 0.90

@export var gravity: float = 24.0
@export var mouse_sensitivity: float = 0.003

@export var standing_camera_height: float = 1.6
@export var crouching_camera_height: float = 1.25
@export var crouch_transition_speed: float = 5.0

@export var radio_message_seconds: float = 3.2
@export var standard_call_performance_xp: int = 25

@export var standing_body_height: float = 0.0
@export var crouching_body_height: float = 0.0
@export var body_crouch_transition_speed: float = 5.0

@export var crouching_collision_height: float = 1.2
@export var collision_crouch_transition_speed: float = 5.0

@export var max_stamina: float = 100.0
@export var sprint_stamina_drain_per_second: float = 7.0
@export var stamina_recovery_per_second: float = 9.0
@export var sprint_unlock_threshold: float = 25.0

@export var sprint_slowdown_start_ratio: float = 0.45
@export var tired_walk_speed: float = 2.2

@export var tired_camera_bob_amount: float = 0.045
@export var tired_camera_bob_speed: float = 7.5
@export var camera_bob_return_speed: float = 10.0

@export var utility_wheel_hold_seconds: float = 0.20


@onready var camera_pivot: Node3D = $CameraPivot
@onready var player_camera: Camera3D = $CameraPivot/PlayerCamera
@onready var flashlight: SpotLight3D = (
	$CameraPivot/PlayerCamera/Flashlight
)
@onready var held_flashlight: Node3D = (
	$CameraPivot/PlayerCamera/FirstPersonRig
)


@onready var interaction_ray: RayCast3D = (
	$CameraPivot/PlayerCamera/InteractionRay
)
@onready var interaction_prompt: Label = (
	$PlayerUI/InteractionPrompt
)
@onready var duty_status_label: Label = (
	$PlayerUI/DutyStatusLabel
)
@onready var dispatch_call_label: Label = (
	$PlayerUI/DispatchCallLabel
)
@onready var radio_message_label: Label = (
	$PlayerUI/RadioMessageLabel
)
@onready var player_ui: CanvasLayer = $PlayerUI
@onready var dutyra_character: Node3D = $DUTYRA_Character
@onready var animated_character: Node = $DUTYRA_Character
@onready var player_collision: CollisionShape3D = (
	$PlayerCollision
)


var camera_pitch: float = 0.0
var is_mdt_visible: bool = false
var mdt_tab_index: int = 0
var radio_message_id: int = 0
var subject_dialogue_id: int = 0
var call_clear_id: int = 0
var xp_popup_id: int = 0
var shift_summary_id: int = 0
var active_call_area: Node = null

var hud_status_dot: Panel

var mdt_panel: Panel
var mdt_screen_panel: Panel
var mdt_browser_bar: Panel
var mdt_title_label: Label

var mdt_home_tab_button: Button
var mdt_calls_tab_button: Button
var mdt_career_tab_button: Button
var mdt_reports_tab_button: Button
var mdt_settings_tab_button: Button

var mdt_close_hint_label: Label
var mdt_clock_label: Label
var mdt_date_label: Label
var mdt_status_label: Label
var career_mdt_label: Label
var mdt_background_texture: TextureRect
var mdt_page_title_label: Label
var mdt_home_label: Label
var mdt_settings_label: Label

var calls_dashboard_panel: Control
var calls_header_label: Label
var calls_incident_label: Label
var calls_unit_status_label: Label
var calls_location_label: Label
var calls_notes_label: Label

var reports_dashboard_panel: Control
var reports_header_label: Label
var reports_list_panel: Control
var reports_detail_label: Label
var reports_case_panel: Panel
var reports_back_button: Button
var reports_person_photo_box: Panel
var reports_person_photo_label: Label
var report_buttons: Array[Button] = []
var selected_report_index: int = -1

var career_dashboard_panel: Control
var career_header_label: Label
var career_officer_file_label: Label
var career_promotion_review_label: Label
var career_shift_label: Label

var career_xp_value_label: Label
var career_calls_value_label: Label
var career_shifts_value_label: Label
var career_xp_fill: ColorRect
var career_calls_fill: ColorRect
var career_shifts_fill: ColorRect

var subject_dialogue_panel: Panel
var subject_dialogue_label: Label
var call_clear_panel: Panel
var call_clear_label: Label
var shift_summary_panel: Panel
var shift_summary_label: Label
var xp_popup_panel: Panel
var xp_popup_label: Label
var xp_progress_background: ColorRect
var xp_progress_fill: ColorRect

var radio_wheel_container: Control
var is_radio_wheel_visible: bool = false
var radio_wheel_options: Array[Dictionary] = []
var highlighted_radio_option_index: int = -1

var standing_collision_height: float = 0.0
var standing_collision_y: float = 0.0

var current_stamina: float = 0.0
var sprint_locked: bool = false

var camera_base_position: Vector3 = Vector3.ZERO
var camera_bob_time: float = 0.0


var current_equipment_id: String = "hands"

var equipment_slots: Array[String] = [
	"hands",
	"flashlight",
	"taser",
	"handgun",
	"handcuffs",
	"",
	"",
	""
]

var utility_wheel_container: Control
var utility_wheel_background: ColorRect
var utility_wheel_backplate: Panel

var utility_wheel_center_panel: Panel
var utility_wheel_center_name_label: Label
var utility_wheel_center_category_label: Label
var utility_wheel_center_hint_label: Label

var utility_wheel_segment_polygons: Array[Polygon2D] = []
var utility_wheel_segment_outlines: Array[Line2D] = []
var utility_wheel_option_labels: Array[Label] = []

var utility_wheel_key_held: bool = false
var utility_wheel_hold_time: float = 0.0
var is_utility_wheel_visible: bool = false
var highlighted_utility_slot: int = -1


func _ready() -> void:
	Input.set_mouse_mode(
		Input.MOUSE_MODE_CAPTURED
	)

	current_stamina = max_stamina
	camera_base_position = player_camera.position
	flashlight.visible = false

	utility_wheel_key_held = false
	utility_wheel_hold_time = 0.0
	is_utility_wheel_visible = false
	highlighted_utility_slot = -1

	var capsule := (
		player_collision.shape as CapsuleShape3D
	)

	if capsule != null:
		standing_collision_height = capsule.height
		standing_collision_y = player_collision.position.y

	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(46.0)
	floor_stop_on_slope = true

	interaction_prompt.visible = false
	dispatch_call_label.visible = false
	radio_message_label.visible = false
	radio_message_label.size = Vector2(
		560.0,
		70.0
	)
	radio_message_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)
	radio_message_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT
	)
	radio_message_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_TOP
	)

	create_main_status_hud()
	create_mdt_ui()
	create_subject_dialogue_ui()
	create_call_clear_ui()
	create_shift_summary_ui()
	create_xp_popup_ui()
	create_radio_wheel_ui()
	create_utility_wheel()

	equip_equipment_item("hands")

	GameState.duty_status_changed.connect(
		_on_duty_status_changed
	)
	GameState.performance_xp_changed.connect(
		_on_performance_xp_changed
	)
	GameState.career_progress_changed.connect(
		_on_career_progress_changed
	)
	GameState.shift_ended.connect(
		_on_shift_ended
	)
	GameState.game_time_changed.connect(
		_on_game_time_changed
	)
	GameState.report_logged.connect(
		_on_report_logged
	)

	update_duty_status_label(
		GameState.is_on_duty
	)

	DispatchManager.active_call_changed.connect(
		_on_active_call_changed
	)

	update_dispatch_call_label(
		DispatchManager.get_display_text(),
		DispatchManager.has_active_call
	)

	RadioManager.radio_message_sent.connect(
		_on_radio_message_sent
	)


func _process(delta: float) -> void:
	if (
		utility_wheel_key_held
		and not Input.is_action_pressed(
			"utility_wheel"
		)
	):
		finish_utility_wheel_input()
		return

	if (
		utility_wheel_key_held
		and not is_utility_wheel_visible
		and not is_mdt_visible
		and not is_radio_wheel_visible
	):
		utility_wheel_hold_time += delta

		if (
			utility_wheel_hold_time
			>= utility_wheel_hold_seconds
		):
			show_utility_wheel()

	if is_utility_wheel_visible:
		update_utility_wheel_selection()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(
		"utility_wheel"
	):
		if (
			is_mdt_visible
			or is_radio_wheel_visible
		):
			return

		utility_wheel_key_held = true
		utility_wheel_hold_time = 0.0
		return

	if event.is_action_released(
		"utility_wheel"
	):
		finish_utility_wheel_input()
		return

	if is_utility_wheel_visible:
		if event.is_action_pressed("ui_cancel"):
			cancel_utility_wheel()
		return

	if (
		event is InputEventMouseMotion
		and not is_radio_wheel_visible
		and not is_mdt_visible
		and not is_utility_wheel_visible
	):
		rotate_y(
			-event.relative.x
			* mouse_sensitivity
		)

		camera_pitch -= (
			event.relative.y
			* mouse_sensitivity
		)

		camera_pitch = clampf(
			camera_pitch,
			deg_to_rad(-50.0),
			deg_to_rad(80.0)
		)

		camera_pivot.rotation.x = (
			camera_pitch
		)

	if event.is_action_pressed("ui_cancel"):
		if is_radio_wheel_visible:
			hide_radio_wheel()
		elif is_mdt_visible:
			close_mdt()
		else:
			Input.set_mouse_mode(
				Input.MOUSE_MODE_VISIBLE
			)

		return

	if event.is_action_pressed("toggle_mdt"):
		toggle_mdt()
		return

	if is_mdt_visible:
		return

	if event.is_action_pressed(
		"toggle_radio_menu"
	):
		toggle_radio_wheel()
		return

	if is_radio_wheel_visible:
		if event is InputEventMouseMotion:
			update_radio_wheel_mouse_selection()
			return

		if event is InputEventMouseButton:
			if (
				event.button_index
				== MOUSE_BUTTON_LEFT
				and event.pressed
			):
				update_radio_wheel_mouse_selection()
				select_highlighted_radio_option()

			return

		if event.is_action_pressed("interact"):
			update_radio_wheel_mouse_selection()
			select_highlighted_radio_option()
			return

		if event is InputEventKey:
			if event.pressed and not event.echo:
				handle_radio_wheel_number_input(
					event.keycode
				)

			return

		return

	if event is InputEventMouseButton:
		if (
			event.button_index
			== MOUSE_BUTTON_LEFT
			and event.pressed
		):
			Input.set_mouse_mode(
				Input.MOUSE_MODE_CAPTURED
			)

	if event.is_action_pressed("interact"):
		handle_interact_input()


func _physics_process(delta: float) -> void:
	update_context_prompt()

	if (
		is_radio_wheel_visible
		or is_mdt_visible
	):
		update_stamina(
			delta,
			false
		)
		lock_player_movement(delta)
		return

	var input_dir: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)

	var is_crouching: bool = (
		Input.is_action_pressed("crouch")
	)

	var wants_to_sprint: bool = (
		Input.is_action_pressed("sprint")
		and input_dir.y < -0.25
		and not is_crouching
	)

	var is_sprinting: bool = update_stamina(
		delta,
		wants_to_sprint
	)

	var stamina_ratio: float = clampf(
		current_stamina
		/ maxf(max_stamina, 0.01),
		0.0,
		1.0
	)

	var fatigue_amount: float = (
		1.0
		- clampf(
			stamina_ratio
			/ maxf(
				sprint_slowdown_start_ratio,
				0.01
			),
			0.0,
			1.0
		)
	)

	var target_camera_height: float = (
		crouching_camera_height
		if is_crouching
		else standing_camera_height
	)

	camera_pivot.position.y = move_toward(
		camera_pivot.position.y,
		target_camera_height,
		crouch_transition_speed * delta
	)

	var is_moving_input: bool = (
		input_dir.length_squared() > 0.01
	)

	var target_camera_local_position: Vector3 = (
		camera_base_position
	)

	if (
		is_moving_input
		and not is_crouching
		and fatigue_amount > 0.0
	):
		camera_bob_time += (
			delta
			* tired_camera_bob_speed
		)

		target_camera_local_position.y += (
			sin(camera_bob_time)
			* tired_camera_bob_amount
			* fatigue_amount
		)

		target_camera_local_position.x += (
			sin(camera_bob_time * 0.5)
			* tired_camera_bob_amount
			* 0.35
			* fatigue_amount
		)
	else:
		camera_bob_time = 0.0

	player_camera.position = (
		player_camera.position.lerp(
			target_camera_local_position,
			clampf(
				camera_bob_return_speed
				* delta,
				0.0,
				1.0
			)
		)
	)

	var capsule := (
		player_collision.shape
		as CapsuleShape3D
	)

	if capsule != null:
		var target_collision_height: float = (
			crouching_collision_height
			if is_crouching
			else standing_collision_height
		)

		capsule.height = move_toward(
			capsule.height,
			target_collision_height,
			collision_crouch_transition_speed
			* delta
		)

		var height_difference: float = (
			standing_collision_height
			- capsule.height
		)

		var target_collision_y: float = (
			standing_collision_y
			- height_difference * 0.5
		)

		player_collision.position.y = (
			move_toward(
				player_collision.position.y,
				target_collision_y,
				collision_crouch_transition_speed
				* delta
			)
		)

	var direction: Vector3 = (
		global_transform.basis
		* Vector3(
			input_dir.x,
			0.0,
			input_dir.y
		)
	)

	direction.y = 0.0
	direction = direction.normalized()

	var current_speed: float = walk_speed

	if is_crouching:
		current_speed = crouch_speed

	elif is_sprinting:
		var sprint_speed_factor: float = (
			clampf(
				stamina_ratio
				/ maxf(
					sprint_slowdown_start_ratio,
					0.01
				),
				0.0,
				1.0
			)
		)

		current_speed = lerpf(
			tired_walk_speed,
			sprint_speed,
			sprint_speed_factor
		)

	elif sprint_locked:
		var recovery_speed_factor: float = (
			clampf(
				current_stamina
				/ maxf(
					sprint_unlock_threshold,
					0.01
				),
				0.0,
				1.0
			)
		)

		current_speed = lerpf(
			tired_walk_speed,
			walk_speed,
			recovery_speed_factor
		)

	var is_moving_backward: bool = (
		input_dir.y > 0.1
	)

	if is_moving_backward:
		current_speed *= 0.50

	if (
		absf(input_dir.x) > 0.1
		and absf(input_dir.y) < 0.1
	):
		current_speed *= (
			strafe_speed_multiplier
		)

	var target_horizontal_velocity: Vector3 = (
		direction * current_speed
	)

	var horizontal_velocity := Vector3(
		velocity.x,
		0.0,
		velocity.z
	)

	var movement_rate: float = ground_deceleration

	if is_moving_input:
		movement_rate = ground_acceleration

		if (
			horizontal_velocity.length_squared()
			> 0.04
			and direction.length_squared()
			> 0.01
		):
			var current_move_direction: Vector3 = (
				horizontal_velocity.normalized()
			)

			var direction_alignment: float = (
				current_move_direction.dot(
					direction
				)
			)

			if direction_alignment < 0.98:
				movement_rate = (
					ground_acceleration
					* 3.5
				)

	horizontal_velocity = (
		horizontal_velocity.move_toward(
			target_horizontal_velocity,
			movement_rate * delta
		)
	)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	var target_body_yaw: float = (
		global_rotation.y
	)

	if (
		is_moving_input
		and not is_moving_backward
	):
		target_body_yaw = atan2(
			-direction.x,
			-direction.z
		)

	var body_rotation: Vector3 = (
		dutyra_character.global_rotation
	)

	body_rotation.y = lerp_angle(
		body_rotation.y,
		target_body_yaw,
		clampf(
			14.0 * delta,
			0.0,
			1.0
		)
	)

	dutyra_character.global_rotation = (
		body_rotation
	)

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	move_and_slide()

	var actual_horizontal_speed: float = Vector2(
		velocity.x,
		velocity.z
	).length()

	var is_moving: bool = (
		actual_horizontal_speed > 0.15
	)

	var movement_animation_speed: float = 1.0

	if is_crouching:
		movement_animation_speed = 0.50

	elif is_sprinting or sprint_locked:
		var animation_speed_ratio: float = (
			clampf(
				(
					current_speed
					- tired_walk_speed
				)
				/ maxf(
					sprint_speed
					- tired_walk_speed,
					0.01
				),
				0.0,
				1.0
			)
		)

		movement_animation_speed = lerpf(
			0.60,
			1.65,
			animation_speed_ratio
		)

	if dutyra_character.has_method(
		"set_moving"
	):
		dutyra_character.call(
			"set_moving",
			is_moving,
			movement_animation_speed
		)


func update_stamina(
	delta: float,
	wants_to_sprint: bool
) -> bool:
	var can_sprint: bool = (
		wants_to_sprint
		and not sprint_locked
		and current_stamina > 0.0
	)

	if can_sprint:
		current_stamina = maxf(
			current_stamina
			- sprint_stamina_drain_per_second
			* delta,
			0.0
		)

		if current_stamina <= 0.0:
			current_stamina = 0.0
			sprint_locked = true
			return false

		return true

	current_stamina = minf(
		current_stamina
		+ stamina_recovery_per_second
		* delta,
		max_stamina
	)

	if (
		sprint_locked
		and current_stamina
		>= sprint_unlock_threshold
	):
		sprint_locked = false

	return false


func lock_player_movement(delta: float) -> void:
	camera_bob_time = 0.0

	player_camera.position = (
		player_camera.position.lerp(
			camera_base_position,
			clampf(
				camera_bob_return_speed
				* delta,
				0.0,
				1.0
			)
		)
	)

	velocity.x = 0.0
	velocity.z = 0.0

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	if animated_character.has_method(
		"set_moving"
	):
		animated_character.call(
			"set_moving",
			false,
			1.0
		)


func create_utility_wheel() -> void:
	utility_wheel_container = Control.new()
	utility_wheel_container.name = "UtilityWheel"
	utility_wheel_container.visible = false
	utility_wheel_container.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)
	utility_wheel_container.z_index = 90

	player_ui.add_child(
		utility_wheel_container
	)

	utility_wheel_container.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	utility_wheel_background = ColorRect.new()
	utility_wheel_background.color = Color(
		0.0,
		0.0,
		0.0,
		0.16
	)
	utility_wheel_background.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	utility_wheel_container.add_child(
		utility_wheel_background
	)

	utility_wheel_background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	utility_wheel_backplate = Panel.new()
	utility_wheel_backplate.size = Vector2(
		500.0,
		500.0
	)
	utility_wheel_backplate.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)
	utility_wheel_backplate.add_theme_stylebox_override(
		"panel",
		make_utility_circle_style(
			Color(
				0.010,
				0.014,
				0.018,
				0.66
			),
			Color(
				0.18,
				0.21,
				0.24,
				0.72
			),
			250,
			2
		)
	)

	utility_wheel_container.add_child(
		utility_wheel_backplate
	)

	for index in range(MAX_UTILITY_SLOTS):
		var segment := Polygon2D.new()
		segment.color = Color(
			0.030,
			0.036,
			0.043,
			0.66
		)

		utility_wheel_container.add_child(
			segment
		)

		utility_wheel_segment_polygons.append(
			segment
		)

		var outline := Line2D.new()
		outline.width = 1.5
		outline.default_color = Color(
			0.17,
			0.20,
			0.23,
			0.76
		)
		outline.closed = true
		outline.antialiased = true

		utility_wheel_container.add_child(
			outline
		)

		utility_wheel_segment_outlines.append(
			outline
		)

		var option_label := Label.new()
		option_label.size = Vector2(
			116.0,
			58.0
		)
		option_label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
		)
		option_label.vertical_alignment = (
			VERTICAL_ALIGNMENT_CENTER
		)
		option_label.autowrap_mode = (
			TextServer.AUTOWRAP_WORD_SMART
		)
		option_label.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)
		option_label.add_theme_font_size_override(
			"font_size",
			12
		)
		option_label.add_theme_color_override(
			"font_color",
			Color(
				0.78,
				0.82,
				0.86,
				0.92
			)
		)
		option_label.add_theme_color_override(
			"font_outline_color",
			Color(
				0.0,
				0.0,
				0.0,
				0.86
			)
		)
		option_label.add_theme_constant_override(
			"outline_size",
			3
		)

		utility_wheel_container.add_child(
			option_label
		)

		utility_wheel_option_labels.append(
			option_label
		)

	utility_wheel_center_panel = Panel.new()
	utility_wheel_center_panel.size = Vector2(
		166.0,
		166.0
	)
	utility_wheel_center_panel.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)
	utility_wheel_center_panel.add_theme_stylebox_override(
		"panel",
		make_utility_circle_style(
			Color(
				0.008,
				0.012,
				0.017,
				0.80
			),
			Color(
				0.25,
				0.29,
				0.33,
				0.82
			),
			83,
			2
		)
	)

	utility_wheel_container.add_child(
		utility_wheel_center_panel
	)

	utility_wheel_center_name_label = Label.new()
	utility_wheel_center_name_label.position = Vector2(
		14.0,
		35.0
	)
	utility_wheel_center_name_label.size = Vector2(
		138.0,
		55.0
	)
	utility_wheel_center_name_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	utility_wheel_center_name_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)
	utility_wheel_center_name_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)
	utility_wheel_center_name_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)
	utility_wheel_center_name_label.add_theme_font_size_override(
		"font_size",
		17
	)
	utility_wheel_center_name_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	utility_wheel_center_panel.add_child(
		utility_wheel_center_name_label
	)

	utility_wheel_center_category_label = Label.new()
	utility_wheel_center_category_label.position = Vector2(
		14.0,
		91.0
	)
	utility_wheel_center_category_label.size = Vector2(
		138.0,
		20.0
	)
	utility_wheel_center_category_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	utility_wheel_center_category_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)
	utility_wheel_center_category_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)
	utility_wheel_center_category_label.add_theme_font_size_override(
		"font_size",
		10
	)
	utility_wheel_center_category_label.add_theme_color_override(
		"font_color",
		Color(
			0.56,
			0.68,
			0.76,
			0.96
		)
	)

	utility_wheel_center_panel.add_child(
		utility_wheel_center_category_label
	)

	utility_wheel_center_hint_label = Label.new()
	utility_wheel_center_hint_label.position = Vector2(
		14.0,
		119.0
	)
	utility_wheel_center_hint_label.size = Vector2(
		138.0,
		22.0
	)
	utility_wheel_center_hint_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	utility_wheel_center_hint_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)
	utility_wheel_center_hint_label.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)
	utility_wheel_center_hint_label.add_theme_font_size_override(
		"font_size",
		9
	)
	utility_wheel_center_hint_label.add_theme_color_override(
		"font_color",
		Color(
			0.48,
			0.56,
			0.62,
			0.96
		)
	)

	utility_wheel_center_panel.add_child(
		utility_wheel_center_hint_label
	)

	position_utility_wheel()
	refresh_utility_wheel()

	get_viewport().size_changed.connect(
		position_utility_wheel
	)


func make_utility_circle_style(
	background_color: Color,
	border_color: Color,
	corner_radius: int,
	border_width: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	style.bg_color = background_color
	style.border_color = border_color

	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width

	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius

	style.shadow_color = Color(
		0.0,
		0.0,
		0.0,
		0.40
	)
	style.shadow_size = 10

	return style


func create_utility_segment_points(
	center: Vector2,
	inner_radius: float,
	outer_radius: float,
	start_angle: float,
	end_angle: float
) -> PackedVector2Array:
	var points := PackedVector2Array()
	var curve_points: int = 18

	for point_index in range(
		curve_points + 1
	):
		var progress: float = (
			float(point_index)
			/ float(curve_points)
		)

		var angle: float = lerpf(
			start_angle,
			end_angle,
			progress
		)

		points.append(
			center
			+ Vector2(
				cos(angle),
				sin(angle)
			)
			* outer_radius
		)

	for point_index in range(
		curve_points,
		-1,
		-1
	):
		var progress: float = (
			float(point_index)
			/ float(curve_points)
		)

		var angle: float = lerpf(
			start_angle,
			end_angle,
			progress
		)

		points.append(
			center
			+ Vector2(
				cos(angle),
				sin(angle)
			)
			* inner_radius
		)

	return points


func position_utility_wheel() -> void:
	if utility_wheel_container == null:
		return

	var viewport_size: Vector2 = (
		get_viewport().get_visible_rect().size
	)

	var screen_center: Vector2 = (
		viewport_size * 0.5
	)

	utility_wheel_backplate.position = (
		screen_center
		- utility_wheel_backplate.size
		* 0.5
	)

	utility_wheel_center_panel.position = (
		screen_center
		- utility_wheel_center_panel.size
		* 0.5
	)

	var option_count: int = MAX_UTILITY_SLOTS
	var inner_radius: float = 90.0
	var outer_radius: float = 235.0
	var label_radius: float = 165.0
	var angle_size: float = (
		TAU / float(option_count)
	)
	var angle_gap: float = 0.022

	for index in range(option_count):
		var center_angle: float = (
			-PI * 0.5
			+ angle_size * float(index)
		)

		var start_angle: float = (
			center_angle
			- angle_size * 0.5
			+ angle_gap
		)

		var end_angle: float = (
			center_angle
			+ angle_size * 0.5
			- angle_gap
		)

		var segment_points: PackedVector2Array = (
			create_utility_segment_points(
				screen_center,
				inner_radius,
				outer_radius,
				start_angle,
				end_angle
			)
		)

		var segment: Polygon2D = (
			utility_wheel_segment_polygons[index]
		)
		segment.visible = true
		segment.polygon = segment_points

		var outline: Line2D = (
			utility_wheel_segment_outlines[index]
		)
		outline.visible = true
		outline.points = segment_points

		var option_direction := Vector2(
			cos(center_angle),
			sin(center_angle)
		)

		var option_label: Label = (
			utility_wheel_option_labels[index]
		)
		option_label.visible = true
		option_label.position = (
			screen_center
			+ option_direction * label_radius
			- option_label.size * 0.5
		)


func show_utility_wheel() -> void:
	if (
		is_mdt_visible
		or is_radio_wheel_visible
	):
		utility_wheel_key_held = false
		utility_wheel_hold_time = 0.0
		return

	if utility_wheel_container == null:
		utility_wheel_key_held = false
		utility_wheel_hold_time = 0.0
		is_utility_wheel_visible = false

		Input.set_mouse_mode(
			Input.MOUSE_MODE_CAPTURED
		)
		return

	highlighted_utility_slot = -1

	position_utility_wheel()
	refresh_utility_wheel()

	utility_wheel_container.visible = true
	is_utility_wheel_visible = true

	Input.set_mouse_mode(
		Input.MOUSE_MODE_VISIBLE
	)

	var viewport_center: Vector2 = (
		get_viewport().get_visible_rect().size
		* 0.5
	)

	Input.warp_mouse(
		viewport_center
	)


func hide_utility_wheel() -> void:
	is_utility_wheel_visible = false
	highlighted_utility_slot = -1

	if utility_wheel_container != null:
		utility_wheel_container.visible = false

	if (
		not is_mdt_visible
		and not is_radio_wheel_visible
	):
		Input.set_mouse_mode(
			Input.MOUSE_MODE_CAPTURED
		)


func cancel_utility_wheel() -> void:
	utility_wheel_key_held = false
	utility_wheel_hold_time = 0.0

	hide_utility_wheel()


func finish_utility_wheel_input() -> void:
	if (
		not utility_wheel_key_held
		and not is_utility_wheel_visible
	):
		return

	utility_wheel_key_held = false
	utility_wheel_hold_time = 0.0

	if is_utility_wheel_visible:
		var selected_equipment_id: String = (
			get_equipment_id_for_slot(
				highlighted_utility_slot
			)
		)

		hide_utility_wheel()

		if selected_equipment_id != "":
			equip_equipment_item(
				selected_equipment_id
			)

		return

	equip_equipment_item("hands")

	Input.set_mouse_mode(
		Input.MOUSE_MODE_CAPTURED
	)


func update_utility_wheel_selection() -> void:
	if not is_utility_wheel_visible:
		return

	var viewport_center: Vector2 = (
		get_viewport().get_visible_rect().size
		* 0.5
	)

	var mouse_offset: Vector2 = (
		get_viewport().get_mouse_position()
		- viewport_center
	)

	var new_highlighted_slot: int = -1

	if mouse_offset.length() >= 82.0:
		var option_angle_size: float = (
			TAU / float(MAX_UTILITY_SLOTS)
		)

		var mouse_angle: float = atan2(
			mouse_offset.y,
			mouse_offset.x
		)

		var adjusted_angle: float = fposmod(
			mouse_angle
			+ PI * 0.5
			+ option_angle_size * 0.5,
			TAU
		)

		var option_index: int = int(
			floor(
				adjusted_angle
				/ option_angle_size
			)
		)

		var possible_slot: int = (
			option_index + 1
		)

		if get_equipment_id_for_slot(
			possible_slot
		) != "":
			new_highlighted_slot = (
				possible_slot
			)

	if (
		new_highlighted_slot
		== highlighted_utility_slot
	):
		return

	highlighted_utility_slot = (
		new_highlighted_slot
	)

	refresh_utility_wheel()


func refresh_utility_wheel() -> void:
	if utility_wheel_container == null:
		return

	for index in range(MAX_UTILITY_SLOTS):
		var segment: Polygon2D = (
			utility_wheel_segment_polygons[index]
		)

		var outline: Line2D = (
			utility_wheel_segment_outlines[index]
		)

		var label: Label = (
			utility_wheel_option_labels[index]
		)

		var slot: int = index + 1
		var equipment_id: String = (
			get_equipment_id_for_slot(slot)
		)

		var is_empty: bool = (
			equipment_id == ""
		)

		var is_equipped: bool = (
			not is_empty
			and equipment_id
			== current_equipment_id
		)

		var is_highlighted: bool = (
			not is_empty
			and slot
			== highlighted_utility_slot
		)

		var segment_color := Color(
			0.030,
			0.036,
			0.043,
			0.66
		)

		var outline_color := Color(
			0.17,
			0.20,
			0.23,
			0.76
		)

		var text_color := Color(
			0.78,
			0.82,
			0.86,
			0.92
		)

		var font_size: int = 12

		if is_empty:
			segment_color = Color(
				0.018,
				0.021,
				0.025,
				0.42
			)

			outline_color = Color(
				0.10,
				0.11,
				0.13,
				0.50
			)

			text_color = Color(
				0.33,
				0.36,
				0.39,
				0.70
			)

		elif is_equipped:
			segment_color = Color(
				0.026,
				0.105,
				0.145,
				0.72
			)

			outline_color = Color(
				0.16,
				0.65,
				0.88,
				0.90
			)

			text_color = Color(
				0.65,
				0.90,
				1.0,
				1.0
			)

		if is_highlighted:
			segment_color = Color(
				0.70,
				0.80,
				0.84,
				0.84
			)

			outline_color = Color(
				0.92,
				0.98,
				1.0,
				1.0
			)

			text_color = Color(
				0.025,
				0.035,
				0.045,
				1.0
			)

			font_size = 14

		segment.color = segment_color
		outline.default_color = outline_color

		if is_empty:
			label.text = (
				"0"
				+ str(slot)
				+ "\nEMPTY"
			)
		else:
			label.text = (
				"0"
				+ str(slot)
				+ "\n"
				+ get_equipment_name(
					equipment_id
				)
			)

		label.add_theme_color_override(
			"font_color",
			text_color
		)

		label.add_theme_font_size_override(
			"font_size",
			font_size
		)

		if is_highlighted:
			label.add_theme_color_override(
				"font_outline_color",
				Color(
					1.0,
					1.0,
					1.0,
					0.0
				)
			)
		else:
			label.add_theme_color_override(
				"font_outline_color",
				Color(
					0.0,
					0.0,
					0.0,
					0.82
				)
			)

	var center_equipment_id: String = (
		current_equipment_id
	)

	if highlighted_utility_slot > 0:
		var highlighted_id: String = (
			get_equipment_id_for_slot(
				highlighted_utility_slot
			)
		)

		if highlighted_id != "":
			center_equipment_id = (
				highlighted_id
			)

	utility_wheel_center_name_label.text = (
		get_equipment_name(
			center_equipment_id
		)
	)

	utility_wheel_center_category_label.text = (
		get_equipment_category(
			center_equipment_id
		)
	)

	if highlighted_utility_slot > 0:
		utility_wheel_center_hint_label.text = (
			"RELEASE F TO EQUIP"
		)
	else:
		utility_wheel_center_hint_label.text = (
			"KEEP MOVING — SELECT ITEM"
		)


func update_equipment_visuals() -> void:
	var flashlight_equipped: bool = (
		current_equipment_id == "flashlight"
	)

	flashlight.visible = flashlight_equipped

	if held_flashlight != null:
		held_flashlight.visible = (
			flashlight_equipped
		)
func equip_equipment_item(
	equipment_id: String
) -> void:
	if not EQUIPMENT_DATABASE.has(
		equipment_id
	):
		return

	if not has_equipment(
		equipment_id
	):
		return

	current_equipment_id = equipment_id

	update_equipment_visuals()
	refresh_utility_wheel()


func get_available_equipment_ids() -> Array[String]:
	var available_equipment: Array[String] = []

	for equipment_id: String in equipment_slots:
		if equipment_id == "":
			continue

		available_equipment.append(
			equipment_id
		)

	return available_equipment


func get_equipment_id_for_slot(
	slot: int
) -> String:
	var index: int = slot - 1

	if (
		index < 0
		or index >= equipment_slots.size()
	):
		return ""

	return equipment_slots[index]


func get_equipment_name(
	equipment_id: String
) -> String:
	if equipment_id == "":
		return "EMPTY"

	if not EQUIPMENT_DATABASE.has(
		equipment_id
	):
		return "UNKNOWN"

	var equipment_data: Dictionary = (
		EQUIPMENT_DATABASE[equipment_id]
	)

	return str(
		equipment_data.get(
			"name",
			"UNKNOWN"
		)
	)


func get_equipment_category(
	equipment_id: String
) -> String:
	if equipment_id == "":
		return ""

	if not EQUIPMENT_DATABASE.has(
		equipment_id
	):
		return "UNKNOWN"

	var equipment_data: Dictionary = (
		EQUIPMENT_DATABASE[equipment_id]
	)

	return str(
		equipment_data.get(
			"category",
			"UTILITY"
		)
	)


func has_equipment(
	equipment_id: String
) -> bool:
	if equipment_id == "":
		return false

	return equipment_slots.has(
		equipment_id
	)


func add_equipment(
	equipment_id: String
) -> bool:
	if equipment_id == "hands":
		return false

	if not EQUIPMENT_DATABASE.has(
		equipment_id
	):
		push_warning(
			"Unknown equipment: "
			+ equipment_id
		)
		return false

	if has_equipment(
		equipment_id
	):
		return false

	for slot_index in range(
		1,
		MAX_UTILITY_SLOTS
	):
		if equipment_slots[slot_index] == "":
			equipment_slots[slot_index] = (
				equipment_id
			)

			update_utility_wheel_inventory()
			return true

	push_warning(
		"Utility wheel is full."
	)
	return false


func remove_equipment(
	equipment_id: String
) -> bool:
	if equipment_id == "hands":
		return false

	for slot_index in range(
		1,
		MAX_UTILITY_SLOTS
	):
		if (
			equipment_slots[slot_index]
			== equipment_id
		):
			equipment_slots[slot_index] = ""

			if (
				current_equipment_id
				== equipment_id
			):
				current_equipment_id = "hands"
				update_equipment_visuals()

			update_utility_wheel_inventory()
			return true

	return false


func set_shift_loadout(
	equipment_ids: Array[String]
) -> void:
	equipment_slots = [
		"hands",
		"",
		"",
		"",
		"",
		"",
		"",
		""
	]

	var next_slot: int = 1

	for equipment_id: String in equipment_ids:
		if next_slot >= MAX_UTILITY_SLOTS:
			break

		if equipment_id == "hands":
			continue

		if not EQUIPMENT_DATABASE.has(
			equipment_id
		):
			continue

		if equipment_slots.has(
			equipment_id
		):
			continue

		equipment_slots[next_slot] = (
			equipment_id
		)

		next_slot += 1

	if not has_equipment(
		current_equipment_id
	):
		current_equipment_id = "hands"
		update_equipment_visuals()

	update_utility_wheel_inventory()


func set_equipment_in_slot(
	slot: int,
	equipment_id: String
) -> bool:
	if (
		slot < 2
		or slot > MAX_UTILITY_SLOTS
	):
		return false

	if equipment_id == "":
		equipment_slots[slot - 1] = ""
		update_utility_wheel_inventory()
		return true

	if equipment_id == "hands":
		return false

	if not EQUIPMENT_DATABASE.has(
		equipment_id
	):
		return false

	var existing_index: int = (
		equipment_slots.find(
			equipment_id
		)
	)

	if existing_index >= 1:
		equipment_slots[existing_index] = ""

	equipment_slots[slot - 1] = equipment_id

	update_utility_wheel_inventory()
	return true


func update_utility_wheel_inventory() -> void:
	highlighted_utility_slot = -1

	if utility_wheel_container == null:
		return

	position_utility_wheel()
	refresh_utility_wheel()

# KEEP YOUR EXISTING:
# func create_main_status_hud() -> void:
# AND EVERYTHING BELOW IT DIRECTLY AFTER THIS LINE.

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
	mdt_panel.name = "LaptopMDT"
	mdt_panel.size = Vector2(1120, 680)
	mdt_panel.visible = false
	mdt_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	mdt_panel.z_index = 40

	var laptop_style := StyleBoxFlat.new()
	laptop_style.bg_color = Color(0.025, 0.025, 0.03, 0.97)
	laptop_style.border_color = Color(0.08, 0.08, 0.09, 1.0)
	laptop_style.border_width_top = 16
	laptop_style.border_width_bottom = 28
	laptop_style.border_width_left = 16
	laptop_style.border_width_right = 16
	laptop_style.corner_radius_top_left = 22
	laptop_style.corner_radius_top_right = 22
	laptop_style.corner_radius_bottom_left = 22
	laptop_style.corner_radius_bottom_right = 22
	mdt_panel.add_theme_stylebox_override("panel", laptop_style)

	player_ui.add_child(mdt_panel)

	mdt_screen_panel = Panel.new()
	mdt_screen_panel.name = "MDTScreen"
	mdt_screen_panel.position = Vector2(32, 32)
	mdt_screen_panel.size = Vector2(1056, 590)
	mdt_screen_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var screen_style := StyleBoxFlat.new()
	screen_style.bg_color = Color(0.015, 0.07, 0.13, 0.98)
	screen_style.border_color = Color(0.1, 0.75, 1.0, 0.7)
	screen_style.border_width_top = 3
	screen_style.border_width_bottom = 3
	screen_style.border_width_left = 3
	screen_style.border_width_right = 3
	screen_style.corner_radius_top_left = 10
	screen_style.corner_radius_top_right = 10
	screen_style.corner_radius_bottom_left = 10
	screen_style.corner_radius_bottom_right = 10
	mdt_screen_panel.add_theme_stylebox_override("panel", screen_style)

	mdt_panel.add_child(mdt_screen_panel)

	create_mdt_background_image()

	mdt_browser_bar = Panel.new()
	mdt_browser_bar.name = "MDTBrowserBar"
	mdt_browser_bar.position = Vector2(44, 44)
	mdt_browser_bar.size = Vector2(1032, 54)
	mdt_browser_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var browser_style := StyleBoxFlat.new()
	browser_style.bg_color = Color(0.02, 0.035, 0.05, 0.86)
	browser_style.border_color = Color(0.2, 0.45, 0.65, 0.6)
	browser_style.border_width_bottom = 2
	browser_style.corner_radius_top_left = 8
	browser_style.corner_radius_top_right = 8
	mdt_browser_bar.add_theme_stylebox_override("panel", browser_style)

	mdt_panel.add_child(mdt_browser_bar)

	mdt_title_label = Label.new()
	mdt_title_label.name = "MDTTitle"
	mdt_title_label.text = "DUTYRA™ PD  |  SECURE MDT"
	mdt_title_label.position = Vector2(60, 52)
	mdt_title_label.size = Vector2(360, 38)
	mdt_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	mdt_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mdt_title_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	mdt_panel.add_child(mdt_title_label)

	mdt_home_tab_button = create_mdt_side_tab("HOME", Vector2(50, 130), _on_mdt_home_tab_pressed)
	mdt_calls_tab_button = create_mdt_side_tab("CALLS", Vector2(50, 215), _on_mdt_calls_tab_pressed)
	mdt_career_tab_button = create_mdt_side_tab("PERSONNEL", Vector2(50, 300), _on_mdt_career_tab_pressed)
	mdt_reports_tab_button = create_mdt_side_tab("REPORTS", Vector2(50, 385), _on_mdt_reports_tab_pressed)
	mdt_settings_tab_button = create_mdt_side_tab("SETTINGS", Vector2(50, 470), _on_mdt_settings_tab_pressed)

	mdt_close_hint_label = Label.new()
	mdt_close_hint_label.text = "M / Esc Close"
	mdt_close_hint_label.position = Vector2(940, 55)
	mdt_close_hint_label.size = Vector2(120, 34)
	mdt_close_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mdt_close_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mdt_close_hint_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	mdt_panel.add_child(mdt_close_hint_label)

	dispatch_call_label.position = Vector2(205, 138)
	dispatch_call_label.size = Vector2(820, 395)
	dispatch_call_label.visible = false

	career_mdt_label = Label.new()
	career_mdt_label.name = "CareerMDTLabel"
	career_mdt_label.position = Vector2(205, 138)
	career_mdt_label.size = Vector2(820, 395)
	career_mdt_label.visible = false
	player_ui.add_child(career_mdt_label)

	create_calls_dashboard_ui()
	create_reports_dashboard_ui()
	create_career_dashboard_ui()
	create_mdt_extra_pages()
	create_mdt_top_time_bar()

	update_mdt_layout_position()
	update_mdt_tab_display()

func create_mdt_side_tab(tab_text: String, tab_position: Vector2, pressed_callable: Callable) -> Button:
	var tab_button := Button.new()
	tab_button.text = tab_text
	tab_button.position = tab_position
	tab_button.size = Vector2(120, 64)
	tab_button.pressed.connect(pressed_callable)
	mdt_panel.add_child(tab_button)

	return tab_button

func create_mdt_background_image() -> void:
	mdt_background_texture = TextureRect.new()
	mdt_background_texture.name = "MDTBackgroundImage"
	mdt_background_texture.position = Vector2(32, 32)
	mdt_background_texture.size = Vector2(1056, 590)
	mdt_background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mdt_background_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	mdt_background_texture.modulate = Color(1.0, 1.0, 1.0, 0.70)
	mdt_background_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var background_path: String = "res://Art/UI/dutyra_mdt_background.png"

	if ResourceLoader.exists(background_path):
		mdt_background_texture.texture = load(background_path)
	else:
		print("MDT BACKGROUND NOT FOUND: " + background_path)

	mdt_panel.add_child(mdt_background_texture)

	var dark_overlay := ColorRect.new()
	dark_overlay.name = "MDTReadableDarkOverlay"
	dark_overlay.position = Vector2(32, 32)
	dark_overlay.size = Vector2(1056, 590)
	dark_overlay.color = Color(0.0, 0.015, 0.035, 0.35)
	dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mdt_panel.add_child(dark_overlay)

func create_calls_dashboard_ui() -> void:
	calls_dashboard_panel = Control.new()
	calls_dashboard_panel.name = "CallsDashboardPanel"
	calls_dashboard_panel.position = Vector2(205, 125)
	calls_dashboard_panel.size = Vector2(820, 430)
	calls_dashboard_panel.visible = false
	calls_dashboard_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mdt_panel.add_child(calls_dashboard_panel)

	calls_header_label = Label.new()
	calls_header_label.text = "DUTYRA™ MDT CALL MANAGEMENT"
	calls_header_label.position = Vector2(0, 0)
	calls_header_label.size = Vector2(820, 30)
	calls_header_label.add_theme_font_size_override("font_size", 20)
	calls_header_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	calls_dashboard_panel.add_child(calls_header_label)

	var incident_card: Panel = create_calls_dashboard_card(Vector2(0, 42), Vector2(820, 100), "ACTIVE INCIDENT")
	calls_incident_label = create_calls_card_body_label(incident_card, 12)

	var unit_card: Panel = create_calls_dashboard_card(Vector2(0, 155), Vector2(400, 115), "UNIT STATUS")
	calls_unit_status_label = create_calls_card_body_label(unit_card, 12)

	var location_card: Panel = create_calls_dashboard_card(Vector2(420, 155), Vector2(400, 115), "LOCATION / RESPONSE")
	calls_location_label = create_calls_card_body_label(location_card, 12)

	var notes_card: Panel = create_calls_dashboard_card(Vector2(0, 285), Vector2(820, 120), "NOTES / NEXT ACTION")
	calls_notes_label = create_calls_card_body_label(notes_card, 12)

	update_calls_dashboard()

func create_calls_dashboard_card(card_position: Vector2, card_size: Vector2, card_title: String) -> Panel:
	var card := Panel.new()
	card.position = card_position
	card.size = card_size
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.015, 0.04, 0.07, 0.82)
	card_style.border_color = Color(0.35, 0.75, 1.0, 0.55)
	card_style.border_width_top = 2
	card_style.border_width_bottom = 2
	card_style.border_width_left = 2
	card_style.border_width_right = 2
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", card_style)

	calls_dashboard_panel.add_child(card)

	var title_label := Label.new()
	title_label.text = card_title
	title_label.position = Vector2(14, 8)
	title_label.size = Vector2(card_size.x - 28, 22)
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0, 1.0))
	card.add_child(title_label)

	var divider := ColorRect.new()
	divider.position = Vector2(14, 34)
	divider.size = Vector2(card_size.x - 28, 1)
	divider.color = Color(0.45, 0.85, 1.0, 0.45)
	card.add_child(divider)

	return card

func create_calls_card_body_label(parent_card: Panel, font_size: int) -> Label:
	var body_label := Label.new()
	body_label.position = Vector2(14, 42)
	body_label.size = Vector2(parent_card.size.x - 28, parent_card.size.y - 48)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	body_label.add_theme_font_size_override("font_size", font_size)
	body_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	parent_card.add_child(body_label)

	return body_label

func update_calls_dashboard() -> void:
	if calls_dashboard_panel == null:
		return

	if calls_incident_label == null:
		return

	if not DispatchManager.has_active_call:
		calls_incident_label.text = "NO ACTIVE INCIDENT\nUnit 24 available for dispatch."
		calls_unit_status_label.text = "UNIT: Unit 24\nSTATUS: " + get_hud_status_text() + "\nDUTY: " + GameState.get_duty_status_text()
		calls_location_label.text = "LOCATION: None assigned\nRESPONSE: Stand by"
		calls_notes_label.text = "NOTES: No active call notes.\n\nNEXT: " + DispatchManager.get_mdt_radio_hint_text()
		return

	var incident_title: String = get_active_call_value("title", "Unknown Incident")
	var priority_text: String = get_active_call_value("priority", "Unknown")
	var response_text: String = get_active_call_value("response", "Unknown")
	var response_description: String = get_active_call_value("response_description", "")
	var location_text: String = get_active_call_value("location", "Unknown Location")

	var notes_text: String = "No notes yet."

	if DispatchManager.call_resolution_note != "":
		notes_text = DispatchManager.call_resolution_note

	calls_incident_label.text = "INCIDENT: " + incident_title + "\n" \
		+ "PRIORITY: " + priority_text + "\n" \
		+ "CAD STATUS: " + DispatchManager.get_status_text()

	calls_unit_status_label.text = "UNIT: Unit 24\n" \
		+ "STATUS: " + get_hud_status_text() + "\n" \
		+ "DUTY: " + GameState.get_duty_status_text()

	calls_location_label.text = "LOCATION: " + location_text + "\n" \
		+ "RESPONSE: " + response_text + "\n" \
		+ response_description

	calls_notes_label.text = "NOTES: " + notes_text + "\n\n" \
		+ "NEXT: " + DispatchManager.get_current_objective_text() + "\n" \
		+ DispatchManager.get_mdt_radio_hint_text()

func get_active_call_value(key_name: String, fallback_text: String) -> String:
	if not DispatchManager.active_call.has(key_name):
		return fallback_text

	return str(DispatchManager.active_call[key_name])

func create_reports_dashboard_ui() -> void:
	reports_dashboard_panel = Control.new()
	reports_dashboard_panel.name = "ReportsDashboardPanel"
	reports_dashboard_panel.position = Vector2(205, 125)
	reports_dashboard_panel.size = Vector2(820, 430)
	reports_dashboard_panel.visible = false
	reports_dashboard_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mdt_panel.add_child(reports_dashboard_panel)

	reports_header_label = Label.new()
	reports_header_label.text = "DUTYRA™ MDT REPORT MANAGEMENT"
	reports_header_label.position = Vector2(0, 0)
	reports_header_label.size = Vector2(820, 30)
	reports_header_label.add_theme_font_size_override("font_size", 20)
	reports_header_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	reports_dashboard_panel.add_child(reports_header_label)

	reports_list_panel = Control.new()
	reports_list_panel.position = Vector2(0, 50)
	reports_list_panel.size = Vector2(820, 345)
	reports_dashboard_panel.add_child(reports_list_panel)

	create_report_case_view()
	update_reports_dashboard()

func create_report_case_view() -> void:
	reports_case_panel = Panel.new()
	reports_case_panel.name = "ReportCasePanel"
	reports_case_panel.position = Vector2(0, 42)
	reports_case_panel.size = Vector2(820, 365)
	reports_case_panel.visible = false
	reports_case_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var paper_style := StyleBoxFlat.new()
	paper_style.bg_color = Color(0.88, 0.90, 0.86, 0.96)
	paper_style.border_color = Color(0.2, 0.24, 0.28, 0.95)
	paper_style.border_width_top = 3
	paper_style.border_width_bottom = 3
	paper_style.border_width_left = 3
	paper_style.border_width_right = 3
	paper_style.corner_radius_top_left = 4
	paper_style.corner_radius_top_right = 4
	paper_style.corner_radius_bottom_left = 4
	paper_style.corner_radius_bottom_right = 4
	reports_case_panel.add_theme_stylebox_override("panel", paper_style)

	reports_dashboard_panel.add_child(reports_case_panel)

	reports_back_button = Button.new()
	reports_back_button.text = "< BACK TO REPORTS"
	reports_back_button.position = Vector2(12, 12)
	reports_back_button.size = Vector2(170, 32)
	reports_back_button.pressed.connect(_on_reports_back_pressed)
	reports_case_panel.add_child(reports_back_button)

	reports_person_photo_box = Panel.new()
	reports_person_photo_box.position = Vector2(620, 55)
	reports_person_photo_box.size = Vector2(170, 190)

	var photo_style := StyleBoxFlat.new()
	photo_style.bg_color = Color(0.12, 0.13, 0.13, 1.0)
	photo_style.border_color = Color(0.05, 0.05, 0.05, 1.0)
	photo_style.border_width_top = 2
	photo_style.border_width_bottom = 2
	photo_style.border_width_left = 2
	photo_style.border_width_right = 2
	reports_person_photo_box.add_theme_stylebox_override("panel", photo_style)

	reports_case_panel.add_child(reports_person_photo_box)

	reports_person_photo_label = Label.new()
	reports_person_photo_label.text = "INVOLVED\nPERSON\nPHOTO\nPENDING"
	reports_person_photo_label.position = Vector2(10, 20)
	reports_person_photo_label.size = Vector2(150, 150)
	reports_person_photo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reports_person_photo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reports_person_photo_label.add_theme_font_size_override("font_size", 14)
	reports_person_photo_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.78, 1.0))
	reports_person_photo_box.add_child(reports_person_photo_label)

	reports_detail_label = Label.new()
	reports_detail_label.position = Vector2(28, 55)
	reports_detail_label.size = Vector2(570, 285)
	reports_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reports_detail_label.add_theme_font_size_override("font_size", 14)
	reports_detail_label.add_theme_color_override("font_color", Color(0.03, 0.04, 0.05, 1.0))
	reports_case_panel.add_child(reports_detail_label)

func update_reports_dashboard() -> void:
	if reports_dashboard_panel == null:
		return

	if reports_list_panel == null:
		return

	for child in reports_list_panel.get_children():
		child.queue_free()

	report_buttons.clear()

	var report_count: int = GameState.get_report_count()

	if report_count == 0:
		reports_header_label.text = "DUTYRA™ MDT REPORT MANAGEMENT"
		reports_list_panel.visible = true
		reports_case_panel.visible = false

		var empty_label := Label.new()
		empty_label.text = "NO REPORTS FILED\n\nCleared calls will automatically appear here.\n\nAfter clearing a call, click the report to open the full case file."
		empty_label.position = Vector2(0, 0)
		empty_label.size = Vector2(820, 250)
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_font_size_override("font_size", 17)
		empty_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
		reports_list_panel.add_child(empty_label)
		return

	reports_header_label.text = "DUTYRA™ MDT REPORT MANAGEMENT"
	reports_list_panel.visible = selected_report_index < 0

	if selected_report_index < 0:
		reports_case_panel.visible = false

	var max_reports_to_show: int = mini(report_count, 7)

	for i in range(max_reports_to_show):
		var report_data: Dictionary = GameState.get_report_at(i)

		var button := Button.new()
		button.position = Vector2(0, i * 48)
		button.size = Vector2(820, 42)
		button.text = str(report_data.get("report_number", "RPT")) \
			+ "     " + str(report_data.get("date", "")) \
			+ " " + str(report_data.get("time", "")) \
			+ "     " + str(report_data.get("title", "Call")) \
			+ "     " + str(report_data.get("location", ""))
		button.pressed.connect(_on_report_button_pressed.bind(i))
		reports_list_panel.add_child(button)
		report_buttons.append(button)

func _on_report_button_pressed(report_index: int) -> void:
	selected_report_index = report_index
	reports_list_panel.visible = false
	reports_case_panel.visible = true
	reports_header_label.text = "DUTYRA™ CASE REPORT"
	update_report_detail_display()

func _on_reports_back_pressed() -> void:
	selected_report_index = -1
	reports_case_panel.visible = false
	reports_list_panel.visible = true
	reports_header_label.text = "DUTYRA™ MDT REPORT MANAGEMENT"
	update_reports_dashboard()

func update_report_detail_display() -> void:
	if reports_detail_label == null:
		return

	var report_data: Dictionary = GameState.get_report_at(selected_report_index)

	if report_data.is_empty():
		reports_detail_label.text = "No report selected."
		return

	reports_detail_label.text = "OFFICIAL INCIDENT REPORT\n" \
		+ "DUTYRA™ POLICE DEPARTMENT\n\n" \
		+ "REPORT NUMBER: " + str(report_data.get("report_number", "")) + "\n" \
		+ "DATE / TIME: " + str(report_data.get("date", "")) + "  " + str(report_data.get("time", "")) + "\n" \
		+ "UNIT: " + str(report_data.get("unit", "")) + "\n" \
		+ "OFFICER RANK: " + str(report_data.get("officer_rank", "")) + "\n\n" \
		+ "INCIDENT: " + str(report_data.get("title", "")) + "\n" \
		+ "LOCATION: " + str(report_data.get("location", "")) + "\n" \
		+ "PRIORITY: " + str(report_data.get("priority", "")) + "\n" \
		+ "RESPONSE: " + str(report_data.get("response", "")) + "\n" \
		+ "STATUS: " + str(report_data.get("status", "")) + "\n\n" \
		+ "NARRATIVE / OFFICER NOTES:\n" \
		+ str(report_data.get("notes", "")) + "\n\n" \
		+ "ATTACHMENTS:\n" \
		+ "Person photo pending. Bodycam / evidence modules not active."

func create_career_dashboard_ui() -> void:
	career_dashboard_panel = Control.new()
	career_dashboard_panel.name = "CareerDashboardPanel"
	career_dashboard_panel.position = Vector2(205, 125)
	career_dashboard_panel.size = Vector2(820, 430)
	career_dashboard_panel.visible = false
	career_dashboard_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mdt_panel.add_child(career_dashboard_panel)

	career_header_label = Label.new()
	career_header_label.text = "DUTYRA™ MDT PERSONNEL PORTAL"
	career_header_label.position = Vector2(0, 0)
	career_header_label.size = Vector2(820, 30)
	career_header_label.add_theme_font_size_override("font_size", 20)
	career_header_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	career_dashboard_panel.add_child(career_header_label)

	var officer_card: Panel = create_dashboard_card(Vector2(0, 42), Vector2(260, 135), "OFFICER FILE")
	career_officer_file_label = create_card_body_label(officer_card)

	var review_card: Panel = create_dashboard_card(Vector2(280, 42), Vector2(540, 135), "PROMOTION REVIEW")
	career_promotion_review_label = create_card_body_label(review_card)

	var shift_card: Panel = create_dashboard_card(Vector2(0, 192), Vector2(820, 85), "CURRENT SHIFT")
	career_shift_label = create_card_body_label(shift_card)

	var requirements_card: Panel = create_dashboard_card(Vector2(0, 292), Vector2(820, 118), "PROMOTION REQUIREMENTS")

	var xp_label := Label.new()
	xp_label.text = "Performance XP"
	xp_label.position = Vector2(20, 42)
	xp_label.size = Vector2(165, 20)
	xp_label.add_theme_font_size_override("font_size", 12)
	xp_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	requirements_card.add_child(xp_label)

	career_xp_value_label = Label.new()
	career_xp_value_label.position = Vector2(650, 42)
	career_xp_value_label.size = Vector2(140, 20)
	career_xp_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	career_xp_value_label.add_theme_font_size_override("font_size", 12)
	career_xp_value_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	requirements_card.add_child(career_xp_value_label)

	career_xp_fill = create_requirement_progress_bar(requirements_card, Vector2(195, 47), 440.0)

	var calls_label := Label.new()
	calls_label.text = "Calls Cleared"
	calls_label.position = Vector2(20, 68)
	calls_label.size = Vector2(165, 20)
	calls_label.add_theme_font_size_override("font_size", 12)
	calls_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	requirements_card.add_child(calls_label)

	career_calls_value_label = Label.new()
	career_calls_value_label.position = Vector2(650, 68)
	career_calls_value_label.size = Vector2(140, 20)
	career_calls_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	career_calls_value_label.add_theme_font_size_override("font_size", 12)
	career_calls_value_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	requirements_card.add_child(career_calls_value_label)

	career_calls_fill = create_requirement_progress_bar(requirements_card, Vector2(195, 73), 440.0)

	var shifts_label := Label.new()
	shifts_label.text = "Shifts Completed"
	shifts_label.position = Vector2(20, 94)
	shifts_label.size = Vector2(165, 20)
	shifts_label.add_theme_font_size_override("font_size", 12)
	shifts_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	requirements_card.add_child(shifts_label)

	career_shifts_value_label = Label.new()
	career_shifts_value_label.position = Vector2(650, 94)
	career_shifts_value_label.size = Vector2(140, 20)
	career_shifts_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	career_shifts_value_label.add_theme_font_size_override("font_size", 12)
	career_shifts_value_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	requirements_card.add_child(career_shifts_value_label)

	career_shifts_fill = create_requirement_progress_bar(requirements_card, Vector2(195, 99), 440.0)

	update_career_dashboard()

func create_dashboard_card(card_position: Vector2, card_size: Vector2, card_title: String) -> Panel:
	var card := Panel.new()
	card.position = card_position
	card.size = card_size
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.015, 0.04, 0.07, 0.82)
	card_style.border_color = Color(0.35, 0.75, 1.0, 0.55)
	card_style.border_width_top = 2
	card_style.border_width_bottom = 2
	card_style.border_width_left = 2
	card_style.border_width_right = 2
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", card_style)

	career_dashboard_panel.add_child(card)

	var title_label := Label.new()
	title_label.text = card_title
	title_label.position = Vector2(14, 10)
	title_label.size = Vector2(card_size.x - 28, 24)
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0, 1.0))
	card.add_child(title_label)

	var divider := ColorRect.new()
	divider.position = Vector2(14, 39)
	divider.size = Vector2(card_size.x - 28, 1)
	divider.color = Color(0.45, 0.85, 1.0, 0.45)
	card.add_child(divider)

	return card

func create_card_body_label(parent_card: Panel) -> Label:
	var body_label := Label.new()
	body_label.position = Vector2(14, 42)
	body_label.size = Vector2(parent_card.size.x - 28, parent_card.size.y - 48)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	body_label.add_theme_font_size_override("font_size", 11)
	body_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	parent_card.add_child(body_label)

	return body_label
	return body_label

func create_requirement_progress_bar(parent_card: Panel, bar_position: Vector2, bar_width: float) -> ColorRect:
	var bar_background := ColorRect.new()
	bar_background.position = bar_position
	bar_background.size = Vector2(bar_width, 14)
	bar_background.color = Color(0.03, 0.08, 0.12, 0.95)
	parent_card.add_child(bar_background)

	var bar_fill := ColorRect.new()
	bar_fill.position = bar_position
	bar_fill.size = Vector2(0, 14)
	bar_fill.color = Color(0.25, 0.85, 1.0, 0.95)
	parent_card.add_child(bar_fill)

	return bar_fill

func update_career_dashboard() -> void:
	if career_dashboard_panel == null:
		return

	var review_status: String = "Not eligible yet"

	if GameState.is_promotion_eligible():
		review_status = "Eligible for review"

	career_officer_file_label.text = "UNIT: Unit 24\n" \
		+ "AGENCY: DUTYRA™ PD\n" \
		+ "TRACK: " + GameState.career_track + "\n" \
		+ "RANK: " + GameState.get_current_rank_name()

	career_promotion_review_label.text = "NEXT RANK: " + GameState.get_next_rank_name() + "\n\n" \
		+ "STATUS: " + review_status + "\n\n" \
		+ "Promotion requires supervisor review after all requirements are met."

	career_shift_label.text = "SHIFT STATUS: " + GameState.get_shift_status_text() + "\n" \
		+ "TOTAL SHIFTS COMPLETED: " \
		+ str(GameState.shifts_completed) + " / " + str(GameState.required_shifts_for_promotion)

	career_xp_value_label.text = str(GameState.performance_xp) + " / " + str(GameState.promotion_eligibility_xp)
	career_calls_value_label.text = str(GameState.calls_cleared) + " / " + str(GameState.required_calls_for_promotion)
	career_shifts_value_label.text = str(GameState.shifts_completed) + " / " + str(GameState.required_shifts_for_promotion)

	set_requirement_bar(career_xp_fill, GameState.performance_xp, GameState.promotion_eligibility_xp, 440.0)
	set_requirement_bar(career_calls_fill, GameState.calls_cleared, GameState.required_calls_for_promotion, 440.0)
	set_requirement_bar(career_shifts_fill, GameState.shifts_completed, GameState.required_shifts_for_promotion, 440.0)

func set_requirement_bar(bar_fill: ColorRect, current_value: int, required_value: int, bar_width: float) -> void:
	if bar_fill == null:
		return

	var ratio: float = 0.0

	if required_value > 0:
		ratio = clampf(float(current_value) / float(required_value), 0.0, 1.0)

	bar_fill.size = Vector2(bar_width * ratio, 14)

func create_mdt_extra_pages() -> void:
	mdt_page_title_label = Label.new()
	mdt_page_title_label.position = Vector2(205, 112)
	mdt_page_title_label.size = Vector2(820, 34)
	mdt_page_title_label.add_theme_font_size_override("font_size", 20)
	mdt_page_title_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	mdt_page_title_label.visible = false
	mdt_panel.add_child(mdt_page_title_label)

	mdt_home_label = create_mdt_page_label()
	mdt_settings_label = create_mdt_page_label()

func create_mdt_page_label() -> Label:
	var page_label := Label.new()
	page_label.position = Vector2(205, 155)
	page_label.size = Vector2(820, 360)
	page_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page_label.add_theme_font_size_override("font_size", 16)
	page_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	page_label.visible = false
	mdt_panel.add_child(page_label)

	return page_label

func create_mdt_top_time_bar() -> void:
	mdt_date_label = Label.new()
	mdt_date_label.position = Vector2(440, 55)
	mdt_date_label.size = Vector2(165, 28)
	mdt_date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mdt_date_label.add_theme_color_override("font_color", Color(0.70, 0.90, 1.0, 1.0))
	mdt_panel.add_child(mdt_date_label)

	mdt_clock_label = Label.new()
	mdt_clock_label.position = Vector2(615, 55)
	mdt_clock_label.size = Vector2(120, 28)
	mdt_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	mdt_clock_label.add_theme_color_override("font_color", Color(0.70, 0.90, 1.0, 1.0))
	mdt_panel.add_child(mdt_clock_label)

	mdt_status_label = Label.new()
	mdt_status_label.position = Vector2(720, 575)
	mdt_status_label.size = Vector2(320, 28)
	mdt_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mdt_status_label.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0, 1.0))
	mdt_panel.add_child(mdt_status_label)

	update_mdt_clock_display()

func update_mdt_clock_display() -> void:
	if mdt_clock_label == null:
		return

	mdt_date_label.text = GameState.get_game_date_text()
	mdt_clock_label.text = GameState.get_game_time_text()
	mdt_status_label.text = "SECURE CONNECTION  |  UNIT 24"

func update_mdt_layout_position() -> void:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	mdt_panel.position = Vector2((screen_size.x - mdt_panel.size.x) * 0.5, (screen_size.y - mdt_panel.size.y) * 0.5)

func open_mdt() -> void:
	is_mdt_visible = true
	update_mdt_layout_position()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mdt_panel.visible = true
	update_mdt_tab_display()

func close_mdt() -> void:
	is_mdt_visible = false
	mdt_panel.visible = false
	dispatch_call_label.visible = false

	if calls_dashboard_panel != null:
		calls_dashboard_panel.visible = false

	if reports_dashboard_panel != null:
		reports_dashboard_panel.visible = false

	if career_mdt_label != null:
		career_mdt_label.visible = false

	if career_dashboard_panel != null:
		career_dashboard_panel.visible = false

	if mdt_page_title_label != null:
		mdt_page_title_label.visible = false

	if mdt_home_label != null:
		mdt_home_label.visible = false

	if mdt_settings_label != null:
		mdt_settings_label.visible = false

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func toggle_mdt() -> void:
	if is_mdt_visible:
		close_mdt()
	else:
		open_mdt()

func _on_mdt_home_tab_pressed() -> void:
	mdt_tab_index = 0
	update_mdt_tab_display()

func _on_mdt_calls_tab_pressed() -> void:
	mdt_tab_index = 1
	update_mdt_tab_display()

func _on_mdt_career_tab_pressed() -> void:
	mdt_tab_index = 2
	update_mdt_tab_display()

func _on_mdt_reports_tab_pressed() -> void:
	mdt_tab_index = 3
	update_mdt_tab_display()

func _on_mdt_settings_tab_pressed() -> void:
	mdt_tab_index = 4
	update_mdt_tab_display()

func update_mdt_tab_display() -> void:
	if mdt_home_tab_button == null:
		return

	dispatch_call_label.visible = false

	if calls_dashboard_panel != null:
		update_calls_dashboard()
		calls_dashboard_panel.visible = is_mdt_visible and mdt_tab_index == 1

	if reports_dashboard_panel != null:
		update_reports_dashboard()
		reports_dashboard_panel.visible = is_mdt_visible and mdt_tab_index == 3

	if career_mdt_label != null:
		career_mdt_label.visible = false

	if career_dashboard_panel != null:
		update_career_dashboard()
		career_dashboard_panel.visible = is_mdt_visible and mdt_tab_index == 2

	if mdt_page_title_label != null:
		mdt_page_title_label.visible = is_mdt_visible and (mdt_tab_index == 0 or mdt_tab_index == 4)

	if mdt_home_label != null:
		mdt_home_label.visible = is_mdt_visible and mdt_tab_index == 0

	if mdt_settings_label != null:
		mdt_settings_label.visible = is_mdt_visible and mdt_tab_index == 4

	if mdt_home_label != null:
		mdt_home_label.text = "SYSTEM HOME\n\n" \
			+ "Welcome, Unit 24.\n\n" \
			+ "Status: " + get_hud_status_text() + "\n" \
			+ "Connection: Secure\n" \
			+ "Active Module: Patrol Operations\n\n" \
			+ "Use the left-side MDT tabs to access calls, personnel records, reports, and system settings."

	if mdt_settings_label != null:
		mdt_settings_label.text = "SYSTEM SETTINGS\n\n" \
			+ "Device: DUTYRA™ Patrol MDT\n" \
			+ "Assigned Unit: Unit 24\n" \
			+ "Network: Secure Department Connection\n" \
			+ "Camera / CAD / Report modules pending."

	if mdt_page_title_label != null:
		if mdt_tab_index == 0:
			mdt_page_title_label.text = "DUTYRA™ MDT HOME"
		elif mdt_tab_index == 4:
			mdt_page_title_label.text = "SYSTEM SETTINGS"

	update_mdt_tab_button_visuals()
	update_mdt_clock_display()

func update_mdt_tab_button_visuals() -> void:
	set_mdt_tab_button_text(mdt_home_tab_button, "HOME", mdt_tab_index == 0)
	set_mdt_tab_button_text(mdt_calls_tab_button, "CALLS", mdt_tab_index == 1)
	set_mdt_tab_button_text(mdt_career_tab_button, "PERSONNEL", mdt_tab_index == 2)
	set_mdt_tab_button_text(mdt_reports_tab_button, "REPORTS", mdt_tab_index == 3)
	set_mdt_tab_button_text(mdt_settings_tab_button, "SETTINGS", mdt_tab_index == 4)

func set_mdt_tab_button_text(button: Button, base_text: String, is_selected: bool) -> void:
	if button == null:
		return

	if is_selected:
		button.text = "> " + base_text
	else:
		button.text = base_text

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
	call_clear_panel.size = Vector2(540, 170)
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
	call_clear_label.size = Vector2(504, 142)
	call_clear_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	call_clear_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	call_clear_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	call_clear_panel.add_child(call_clear_label)

func create_shift_summary_ui() -> void:
	shift_summary_panel = Panel.new()
	shift_summary_panel.name = "ShiftSummaryPanel"
	shift_summary_panel.size = Vector2(560, 170)
	shift_summary_panel.visible = false
	shift_summary_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shift_summary_panel.z_index = 28

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.015, 0.025, 0.04, 0.93)
	panel_style.border_color = Color(0.1, 0.65, 1.0, 0.85)
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.corner_radius_top_left = 14
	panel_style.corner_radius_top_right = 14
	panel_style.corner_radius_bottom_left = 14
	panel_style.corner_radius_bottom_right = 14
	shift_summary_panel.add_theme_stylebox_override("panel", panel_style)

	player_ui.add_child(shift_summary_panel)

	shift_summary_label = Label.new()
	shift_summary_label.position = Vector2(18, 14)
	shift_summary_label.size = Vector2(524, 142)
	shift_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shift_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shift_summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shift_summary_panel.add_child(shift_summary_label)

func create_xp_popup_ui() -> void:
	xp_popup_panel = Panel.new()
	xp_popup_panel.name = "PerformanceXPPopup"
	xp_popup_panel.size = Vector2(430, 88)
	xp_popup_panel.visible = false
	xp_popup_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_popup_panel.z_index = 30

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.02, 0.03, 0.02, 0.92)
	panel_style.border_color = Color(0.1, 1.0, 0.25, 0.8)
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	xp_popup_panel.add_theme_stylebox_override("panel", panel_style)

	player_ui.add_child(xp_popup_panel)

	xp_popup_label = Label.new()
	xp_popup_label.position = Vector2(16, 10)
	xp_popup_label.size = Vector2(398, 44)
	xp_popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	xp_popup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	xp_popup_panel.add_child(xp_popup_label)

	xp_progress_background = ColorRect.new()
	xp_progress_background.position = Vector2(16, 64)
	xp_progress_background.size = Vector2(398, 10)
	xp_progress_background.color = Color(0.15, 0.15, 0.15, 0.95)
	xp_popup_panel.add_child(xp_progress_background)

	xp_progress_fill = ColorRect.new()
	xp_progress_fill.position = Vector2(16, 64)
	xp_progress_fill.size = Vector2(0, 10)
	xp_progress_fill.color = Color(0.1, 1.0, 0.25, 1.0)
	xp_popup_panel.add_child(xp_progress_fill)

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
		var performance_reward: int = get_current_call_performance_reward()

		log_current_call_report(cleared_call_note)

		RadioManager.send_player_message("Dispatch, show Unit 24 10 8. Contact made, no further action.")
		RadioManager.send_dispatch_ack("10 4, Unit 24 clear.")
		DispatchManager.clear_active_call(false)

		GameState.award_call_performance(performance_reward)
		show_call_cleared_result(cleared_call_title, cleared_call_note, performance_reward)

func log_current_call_report(report_note: String) -> void:
	var call_title: String = get_active_call_value("title", "Call")
	var call_location: String = get_active_call_value("location", "Unknown Location")
	var call_priority: String = get_active_call_value("priority", "Unknown")
	var call_response: String = get_active_call_value("response", "Unknown")

	GameState.log_call_report(call_title, call_location, call_priority, call_response, "Cleared", report_note)

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

func get_current_call_performance_reward() -> int:
	return standard_call_performance_xp

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
	if is_radio_wheel_visible or is_mdt_visible:
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

func show_call_cleared_result(call_title: String, call_note: String, performance_reward: int) -> void:
	call_clear_id += 1
	var current_clear_id: int = call_clear_id

	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	call_clear_panel.position = Vector2((screen_size.x - call_clear_panel.size.x) * 0.5, 120)

	call_clear_label.text = "CALL CLEARED\n\n" \
		+ call_title + "\n" \
		+ call_note + "\n\n" \
		+ "+" + str(performance_reward) + " Performance XP\n" \
		+ "Status: Available"

	call_clear_panel.visible = true

	await get_tree().create_timer(4.0).timeout

	if current_clear_id == call_clear_id:
		call_clear_panel.visible = false

func show_shift_summary_popup(shift_counted: bool, calls_cleared_this_shift: int, shifts_completed_total: int) -> void:
	shift_summary_id += 1
	var current_shift_summary_id: int = shift_summary_id

	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	shift_summary_panel.position = Vector2((screen_size.x - shift_summary_panel.size.x) * 0.5, 120)

	if shift_counted:
		shift_summary_label.text = "SHIFT COMPLETE\n\n" \
			+ "Calls Cleared This Shift: " + str(calls_cleared_this_shift) + "\n" \
			+ "Shift Progress: " + str(shifts_completed_total) + " / " + str(GameState.required_shifts_for_promotion) + "\n\n" \
			+ "Status: Off Duty"
	else:
		shift_summary_label.text = "SHIFT ENDED\n\n" \
			+ "No calls cleared.\n" \
			+ "Shift did not count toward promotion eligibility.\n\n" \
			+ "Status: Off Duty"

	shift_summary_panel.visible = true

	await get_tree().create_timer(4.0).timeout

	if current_shift_summary_id == shift_summary_id:
		shift_summary_panel.visible = false

func show_xp_progress_popup(amount_added: int) -> void:
	xp_popup_id += 1
	var current_popup_id: int = xp_popup_id

	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	xp_popup_panel.position = Vector2(screen_size.x - xp_popup_panel.size.x - 30, 90)

	var progress_ratio: float = 0.0

	if GameState.promotion_eligibility_xp > 0:
		progress_ratio = clampf(float(GameState.performance_xp) / float(GameState.promotion_eligibility_xp), 0.0, 1.0)

	xp_popup_label.text = "+" + str(amount_added) + " Performance XP\n" + GameState.get_promotion_progress_text()
	xp_progress_fill.size = Vector2(398.0 * progress_ratio, 10)

	xp_popup_panel.visible = true

	await get_tree().create_timer(3.0).timeout

	if current_popup_id == xp_popup_id:
		xp_popup_panel.visible = false

func set_active_call_area(call_area: Node) -> void:
	active_call_area = call_area

func clear_active_call_area(call_area: Node) -> void:
	if active_call_area == call_area:
		active_call_area = null
		interaction_prompt.visible = false

func _on_duty_status_changed(is_on_duty: bool) -> void:
	update_duty_status_label(is_on_duty)

	if career_mdt_label != null:
		career_mdt_label.text = GameState.get_career_mdt_text()

	update_calls_dashboard()
	update_career_dashboard()
	update_mdt_clock_display()

	if is_radio_wheel_visible:
		refresh_radio_wheel()

	if is_mdt_visible:
		update_mdt_tab_display()

func update_duty_status_label(_is_on_duty: bool) -> void:
	update_main_status_hud()

func _on_performance_xp_changed(_current_xp: int, amount_added: int) -> void:
	if career_mdt_label != null:
		career_mdt_label.text = GameState.get_career_mdt_text()

	update_career_dashboard()
	show_xp_progress_popup(amount_added)

func _on_career_progress_changed() -> void:
	if career_mdt_label != null:
		career_mdt_label.text = GameState.get_career_mdt_text()

	update_career_dashboard()

	if is_mdt_visible:
		update_mdt_tab_display()

func _on_shift_ended(shift_counted: bool, calls_cleared_this_shift: int, shifts_completed_total: int) -> void:
	show_shift_summary_popup(shift_counted, calls_cleared_this_shift, shifts_completed_total)

func _on_game_time_changed() -> void:
	update_mdt_clock_display()

func _on_report_logged() -> void:
	update_reports_dashboard()

func _on_active_call_changed(call_text: String, has_call: bool) -> void:
	update_dispatch_call_label(call_text, has_call)
	update_main_status_hud()
	update_calls_dashboard()

	if is_radio_wheel_visible:
		refresh_radio_wheel()

	if is_mdt_visible:
		update_mdt_tab_display()

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
