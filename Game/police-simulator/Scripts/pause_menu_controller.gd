extends CanvasLayer

const DESIGN_SIZE: Vector2 = Vector2(1536.0, 1024.0)
const PAUSE_BACKGROUND_PATH: String = "res://Art/Menu/dutyra_pause_menu_background.png"
const MAIN_MENU_SCENE_PATH: String = "res://Scenes/MainMenu.tscn"
const AUTOSAVE_INTERVAL_SECONDS: float = 300.0
const CONTROL_ACTIONS := [
	"move_forward",
	"move_back",
	"move_left",
	"move_right",
	"sprint",
	"crouch",
	"interact",
	"utility_wheel",
	"toggle_radio_menu",
	"toggle_mdt"
]

const CONTROL_LABELS := {
	"move_forward": "MOVE FORWARD",
	"move_back": "MOVE BACKWARD",
	"move_left": "MOVE LEFT",
	"move_right": "MOVE RIGHT",
	"sprint": "SPRINT",
	"crouch": "CROUCH",
	"interact": "INTERACT / SELECT",
	"utility_wheel": "UTILITY WHEEL",
	"toggle_radio_menu": "RADIO WHEEL",
	"toggle_mdt": "MDT"
}
var screen_root: Control
var design_canvas: Control
var resume_button: Button
var pause_open: bool = false

var shift_officer_label: Label
var shift_time_label: Label
var objective_title_label: Label
var objective_body_label: Label
var career_xp_value: Label
var career_calls_value: Label
var career_shifts_value: Label
var career_reports_value: Label
var career_rank_value: Label
var city_time_value: Label

var modal_blocker: ColorRect
var modal_panel: Panel
var modal_title_label: Label
var modal_body_label: Label

var settings_blocker: ColorRect
var settings_panel: Panel
var window_mode_option: OptionButton
var resolution_option: OptionButton
var vsync_toggle: CheckButton
var frame_limit_option: OptionButton
var render_scale_slider: HSlider
var render_scale_value: Label
var master_volume_slider: HSlider
var master_volume_value: Label
var music_volume_slider: HSlider
var music_volume_value: Label
var sfx_volume_slider: HSlider
var sfx_volume_value: Label
var radio_volume_slider: HSlider
var radio_volume_value: Label
var mouse_sensitivity_slider: HSlider
var mouse_sensitivity_value: Label
var updating_settings: bool = false
var controls_blocker: ColorRect
var controls_panel: Panel
var controls_status_label: Label
var control_buttons: Dictionary = {}
var waiting_for_control_action: String = ""
var save_toast_panel: Panel
var save_toast_label: Label
var save_toast_timer: Timer
var autosave_timer: Timer
var autosave_notice_root: Control
var autosave_notice_panel: Panel
var autosave_notice_label: Label
var autosave_notice_timer: Timer
var window_modes: Array[String] = [
	"windowed",
	"borderless",
	"fullscreen"
]

var resolutions: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

var frame_limits: Array[int] = [
	30,
	60,
	120,
	144,
	165,
	240,
	0
]


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	create_pause_screen()
	create_left_menu()
	create_pause_header()
	create_right_information_panel()
	create_bottom_hints()
	create_information_modal()
	create_settings_panel()
	create_controls_panel()
	create_save_toast()
	create_autosave_system()

	get_viewport().size_changed.connect(update_pause_layout)

	GameState.player_profile_changed.connect(refresh_pause_information)
	GameState.career_progress_changed.connect(refresh_pause_information)
	GameState.game_time_changed.connect(refresh_pause_information)
	GameState.report_logged.connect(refresh_pause_information)
	DispatchManager.active_call_changed.connect(_on_active_call_changed)

	update_pause_layout()
	refresh_pause_information()

	screen_root.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	call_deferred("apply_saved_mouse_sensitivity")


func _input(event: InputEvent) -> void:
	if waiting_for_control_action != "":
		if event is InputEventKey:
			var rebind_key_event: InputEventKey = (
				event as InputEventKey
			)

			if (
				rebind_key_event.pressed
				and not rebind_key_event.echo
			):
				handle_control_rebind(
					rebind_key_event
				)

				get_viewport().set_input_as_handled()

		return

	if event is InputEventKey:
		var pause_key_event: InputEventKey = (
			event as InputEventKey
		)

		if (
			pause_key_event.pressed
			and not pause_key_event.echo
		):
			if (
				pause_key_event.keycode == KEY_F5
				and pause_open
			):
				quick_save()
				get_viewport().set_input_as_handled()
				return

	if not event.is_action_pressed("ui_cancel"):
		return

	if (
		controls_panel != null
		and controls_panel.visible
	):
		hide_controls_panel()
		get_viewport().set_input_as_handled()
		return

	if (
		settings_panel != null
		and settings_panel.visible
	):
		hide_settings_panel()
		get_viewport().set_input_as_handled()
		return

	if modal_panel != null and modal_panel.visible:
		hide_information_modal()
		get_viewport().set_input_as_handled()
		return

	if pause_open:
		close_pause_menu()
		get_viewport().set_input_as_handled()
		return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	open_pause_menu()
	get_viewport().set_input_as_handled()


func create_pause_screen() -> void:
	screen_root = Control.new()
	screen_root.name = "PauseScreenRoot"
	screen_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(screen_root)
	screen_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background: TextureRect = TextureRect.new()
	background.name = "PauseBackground"
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_root.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if ResourceLoader.exists(PAUSE_BACKGROUND_PATH):
		background.texture = load(PAUSE_BACKGROUND_PATH)
	else:
		print("PAUSE BACKGROUND NOT FOUND: " + PAUSE_BACKGROUND_PATH)

	var overlay: ColorRect = ColorRect.new()
	overlay.name = "PauseDarkOverlay"
	overlay.color = Color(0.0, 0.0, 0.0, 0.27)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_root.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	design_canvas = Control.new()
	design_canvas.name = "PauseDesignCanvas"
	design_canvas.size = DESIGN_SIZE
	design_canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	screen_root.add_child(design_canvas)


func update_pause_layout() -> void:
	if design_canvas == null:
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var scale_factor: float = minf(
		viewport_size.x / DESIGN_SIZE.x,
		viewport_size.y / DESIGN_SIZE.y
	)
	var scaled_size: Vector2 = DESIGN_SIZE * scale_factor

	design_canvas.scale = Vector2(scale_factor, scale_factor)
	design_canvas.position = Vector2(
		(viewport_size.x - scaled_size.x) * 0.5,
		(viewport_size.y - scaled_size.y) * 0.5
	)


func create_left_menu() -> void:
	var x: float = 45.0
	var y: float = 238.0
	var width: float = 447.0
	var height: float = 72.0
	var gap: float = 15.5

	resume_button = create_pause_button(
		"RESUME GAME",
		"Return to your shift",
		"▶",
		Vector2(x, y),
		Vector2(width, height),
		_on_resume_pressed,
		true
	)

	create_pause_button(
		"SETTINGS",
		"Adjust game settings",
		"⚙",
		Vector2(x, y + (height + gap) * 1.0),
		Vector2(width, height),
		_on_settings_pressed
	)

	create_pause_button(
		"CONTROLS",
		"View and edit controls",
		"⌨",
		Vector2(x, y + (height + gap) * 2.0),
		Vector2(width, height),
		_on_controls_pressed
	)

	create_pause_button(
		"FIELD MANUAL",
		"Game tutorials and guidelines",
		"▤",
		Vector2(x, y + (height + gap) * 3.0),
		Vector2(width, height),
		_on_field_manual_pressed
	)

	create_pause_button(
		"SAVE GAME",
		"Manually save your progress",
		"▣",
		Vector2(x, y + (height + gap) * 4.0),
		Vector2(width, height),
		_on_save_game_pressed
	)

	create_pause_button(
		"EXIT TO MAIN MENU",
		"Return to the main menu",
		"↩",
		Vector2(x, y + (height + gap) * 5.0),
		Vector2(width, height),
		_on_exit_to_main_menu_pressed
	)

	create_pause_button(
		"QUIT GAME",
		"Exit DUTYRA™",
		"⏻",
		Vector2(x, y + (height + gap) * 6.0),
		Vector2(width, height),
		_on_quit_game_pressed
	)


func create_pause_button(
	title_text: String,
	subtitle_text: String,
	icon_text: String,
	button_position: Vector2,
	button_size: Vector2,
	pressed_callable: Callable,
	default_highlighted: bool = false
) -> Button:
	var button: Button = Button.new()
	button.name = title_text.replace(" ", "") + "PauseButton"
	button.position = button_position
	button.size = button_size
	button.text = ""
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_meta("default_highlighted", default_highlighted)
	button.pressed.connect(pressed_callable)

	button.add_theme_stylebox_override(
		"normal",
		create_button_style(default_highlighted)
	)
	button.add_theme_stylebox_override(
		"hover",
		create_button_style(true)
	)
	button.add_theme_stylebox_override(
		"pressed",
		create_button_style(true)
	)
	button.add_theme_stylebox_override(
		"focus",
		create_button_style(true)
	)

	design_canvas.add_child(button)

	var accent: ColorRect = ColorRect.new()
	accent.name = "AccentLine"
	accent.size = Vector2(4.0, button_size.y)
	accent.color = Color(0.0, 0.61, 1.0, 1.0)
	accent.visible = default_highlighted
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(accent)

	var icon: Label = make_label(
		icon_text,
		Vector2(18.0, 8.0),
		Vector2(58.0, 56.0),
		30,
		Color(0.68, 0.70, 0.73, 1.0),
		button
	)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	make_label(
		title_text,
		Vector2(84.0, 11.0),
		Vector2(300.0, 27.0),
		20,
		Color(0.95, 0.97, 1.0, 1.0),
		button
	)

	var subtitle: Label = make_label(
		subtitle_text,
		Vector2(84.0, 39.0),
		Vector2(305.0, 22.0),
		13,
		Color(0.59, 0.62, 0.68, 1.0),
		button
	)
	subtitle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	var arrow: Label = make_label(
		"›",
		Vector2(398.0, 11.0),
		Vector2(36.0, 50.0),
		38,
		Color(0.0, 0.68, 1.0, 1.0),
		button
	)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow.visible = default_highlighted

	button.mouse_entered.connect(
		_on_pause_button_highlighted.bind(accent, arrow)
	)
	button.focus_entered.connect(
		_on_pause_button_highlighted.bind(accent, arrow)
	)
	button.mouse_exited.connect(
		_on_pause_button_unhighlighted.bind(button, accent, arrow)
	)
	button.focus_exited.connect(
		_on_pause_button_unhighlighted.bind(button, accent, arrow)
	)

	return button


func create_button_style(highlighted: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()

	if highlighted:
		style.bg_color = Color(0.015, 0.105, 0.245, 0.91)
		style.border_color = Color(0.0, 0.59, 1.0, 1.0)
	else:
		style.bg_color = Color(0.008, 0.012, 0.017, 0.86)
		style.border_color = Color(0.38, 0.41, 0.46, 0.56)

	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4

	return style


func _on_pause_button_highlighted(
	accent: ColorRect,
	arrow: Label
) -> void:
	accent.visible = true
	arrow.visible = true


func _on_pause_button_unhighlighted(
	button: Button,
	accent: ColorRect,
	arrow: Label
) -> void:
	var keep: bool = bool(
		button.get_meta(
			"default_highlighted",
			false
		)
	)

	accent.visible = keep
	arrow.visible = keep


func create_pause_header() -> void:
	make_label(
		"/ /",
		Vector2(1240.0, 25.0),
		Vector2(65.0, 35.0),
		28,
		Color(0.15, 0.17, 0.19, 1.0),
		design_canvas
	)

	make_label(
		"GAME PAUSED",
		Vector2(1318.0, 30.0),
		Vector2(185.0, 30.0),
		21,
		Color(0.18, 0.60, 1.0, 1.0),
		design_canvas
	)

	make_label(
		"CAREER MODE",
		Vector2(1357.0, 61.0),
		Vector2(145.0, 25.0),
		15,
		Color(0.89, 0.89, 0.91, 1.0),
		design_canvas
	)


func create_right_information_panel() -> void:
	var panel: Panel = Panel.new()
	panel.position = Vector2(1096.0, 120.0)
	panel.size = Vector2(395.0, 788.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	panel.add_theme_stylebox_override(
		"panel",
		create_panel_style(
			Color(0.005, 0.008, 0.012, 0.88),
			Color(0.40, 0.43, 0.48, 0.64),
			1
		)
	)

	design_canvas.add_child(panel)

	make_label(
		"CURRENT SHIFT",
		Vector2(28.0, 27.0),
		Vector2(250.0, 24.0),
		14,
		Color(0.16, 0.61, 1.0, 1.0),
		panel
	)

	shift_officer_label = make_label(
		"NO ACTIVE OFFICER",
		Vector2(28.0, 64.0),
		Vector2(338.0, 28.0),
		18,
		Color(0.96, 0.97, 1.0, 1.0),
		panel
	)
	shift_officer_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	make_label(
		"SHIFT TIME",
		Vector2(28.0, 101.0),
		Vector2(140.0, 21.0),
		13,
		Color(0.57, 0.59, 0.63, 1.0),
		panel
	)

	shift_time_label = make_label(
		"00:00",
		Vector2(28.0, 124.0),
		Vector2(140.0, 28.0),
		18,
		Color(0.93, 0.94, 0.97, 1.0),
		panel
	)

	add_horizontal_line(
		panel,
		158.0,
		395.0
	)

	make_label(
		"OBJECTIVE",
		Vector2(28.0, 181.0),
		Vector2(250.0, 24.0),
		14,
		Color(0.16, 0.61, 1.0, 1.0),
		panel
	)

	objective_title_label = make_label(
		"PATROL ASSIGNMENT",
		Vector2(28.0, 218.0),
		Vector2(338.0, 28.0),
		17,
		Color(0.96, 0.97, 1.0, 1.0),
		panel
	)

	objective_body_label = make_label(
		"Patrol your assigned area and respond to dispatch calls.",
		Vector2(28.0, 252.0),
		Vector2(338.0, 55.0),
		14,
		Color(0.64, 0.66, 0.70, 1.0),
		panel
	)
	objective_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	add_horizontal_line(
		panel,
		311.0,
		395.0
	)

	make_label(
		"CAREER STATS",
		Vector2(28.0, 337.0),
		Vector2(250.0, 24.0),
		14,
		Color(0.16, 0.61, 1.0, 1.0),
		panel
	)

	career_xp_value = create_stat_row(
		panel,
		"PERFORMANCE XP",
		382.0
	)

	career_calls_value = create_stat_row(
		panel,
		"CALLS RESPONDED",
		421.0
	)

	career_shifts_value = create_stat_row(
		panel,
		"SHIFTS COMPLETED",
		460.0
	)

	career_reports_value = create_stat_row(
		panel,
		"REPORTS FILED",
		499.0
	)

	career_rank_value = create_stat_row(
		panel,
		"CURRENT RANK",
		538.0
	)

	add_horizontal_line(
		panel,
		573.0,
		395.0
	)

	make_label(
		"CITY STATUS",
		Vector2(28.0, 598.0),
		Vector2(250.0, 24.0),
		14,
		Color(0.16, 0.61, 1.0, 1.0),
		panel
	)

	make_label(
		"DUTYRA CITY",
		Vector2(28.0, 643.0),
		Vector2(250.0, 27.0),
		17,
		Color(0.96, 0.97, 1.0, 1.0),
		panel
	)

	make_label(
		"CRIME RATE",
		Vector2(28.0, 684.0),
		Vector2(140.0, 24.0),
		13,
		Color(0.62, 0.64, 0.68, 1.0),
		panel
	)

	var crime: Label = make_label(
		"MODERATE",
		Vector2(264.0, 684.0),
		Vector2(102.0, 24.0),
		13,
		Color(1.0, 0.66, 0.10, 1.0),
		panel
	)
	crime.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	make_label(
		"TIME",
		Vector2(28.0, 721.0),
		Vector2(140.0, 24.0),
		13,
		Color(0.62, 0.64, 0.68, 1.0),
		panel
	)

	city_time_value = make_label(
		"00:00",
		Vector2(264.0, 721.0),
		Vector2(102.0, 24.0),
		13,
		Color(0.88, 0.89, 0.92, 1.0),
		panel
	)
	city_time_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func create_stat_row(
	parent: Control,
	title_text: String,
	y: float
) -> Label:
	make_label(
		title_text,
		Vector2(28.0, y),
		Vector2(220.0, 23.0),
		13,
		Color(0.63, 0.65, 0.69, 1.0),
		parent
	)

	var value: Label = make_label(
		"0",
		Vector2(260.0, y),
		Vector2(106.0, 23.0),
		13,
		Color(0.86, 0.87, 0.90, 1.0),
		parent
	)

	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return value


func refresh_pause_information() -> void:
	if shift_officer_label == null:
		return

	if GameState.player_profile_created:
		shift_officer_label.text = (
			GameState.get_officer_display_name().to_upper()
		)
	else:
		shift_officer_label.text = "NO ACTIVE OFFICER"

	shift_time_label.text = GameState.get_game_time_text()
	city_time_value.text = GameState.get_game_time_text()

	if DispatchManager.has_active_call:
		objective_title_label.text = str(
			DispatchManager.active_call.get(
				"title",
				"ACTIVE INCIDENT"
			)
		).to_upper()

		objective_body_label.text = (
			DispatchManager.get_current_objective_text()
		)
	else:
		objective_title_label.text = "PATROL ASSIGNMENT"
		objective_body_label.text = (
			"Patrol your assigned area and respond to dispatch calls."
		)

	career_xp_value.text = (
		str(GameState.performance_xp)
		+ " / "
		+ str(GameState.promotion_eligibility_xp)
	)

	career_calls_value.text = str(
		GameState.calls_cleared
	)

	career_shifts_value.text = str(
		GameState.shifts_completed
	)

	career_reports_value.text = str(
		GameState.get_report_count()
	)

	career_rank_value.text = (
		GameState.get_current_rank_name().to_upper()
	)


func _on_active_call_changed(
	_call_text: String,
	_has_call: bool
) -> void:
	refresh_pause_information()


func create_bottom_hints() -> void:
	var esc_box: Panel = Panel.new()
	esc_box.position = Vector2(55.0, 957.0)
	esc_box.size = Vector2(40.0, 32.0)

	esc_box.add_theme_stylebox_override(
		"panel",
		create_panel_style(
			Color(0.02, 0.025, 0.03, 0.96),
			Color(0.55, 0.58, 0.64, 0.95),
			1
		)
	)

	design_canvas.add_child(esc_box)

	var esc: Label = make_label(
		"ESC",
		Vector2.ZERO,
		Vector2(40.0, 32.0),
		13,
		Color(0.94, 0.95, 0.97, 1.0),
		esc_box
	)

	esc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	esc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	make_label(
		"BACK",
		Vector2(106.0, 959.0),
		Vector2(90.0, 30.0),
		16,
		Color(0.77, 0.78, 0.82, 1.0),
		design_canvas
	)

	make_label(
		"F5   QUICK SAVE",
		Vector2(1325.0, 959.0),
		Vector2(180.0, 30.0),
		16,
		Color(0.77, 0.78, 0.82, 1.0),
		design_canvas
	)


func create_information_modal() -> void:
	modal_blocker = ColorRect.new()
	modal_blocker.position = Vector2.ZERO
	modal_blocker.size = DESIGN_SIZE
	modal_blocker.color = Color(0.0, 0.0, 0.0, 0.74)
	modal_blocker.visible = false
	modal_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_blocker.z_index = 50
	design_canvas.add_child(modal_blocker)

	modal_panel = Panel.new()
	modal_panel.position = Vector2(468.0, 340.0)
	modal_panel.size = Vector2(600.0, 330.0)
	modal_panel.visible = false
	modal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_panel.z_index = 51

	modal_panel.add_theme_stylebox_override(
		"panel",
		create_panel_style(
			Color(0.01, 0.018, 0.03, 0.99),
			Color(0.0, 0.59, 1.0, 0.95),
			2
		)
	)

	design_canvas.add_child(modal_panel)

	modal_title_label = make_label(
		"",
		Vector2(35.0, 28.0),
		Vector2(530.0, 34.0),
		23,
		Color(0.95, 0.97, 1.0, 1.0),
		modal_panel
	)
	modal_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	modal_body_label = make_label(
		"",
		Vector2(52.0, 88.0),
		Vector2(496.0, 150.0),
		16,
		Color(0.72, 0.77, 0.84, 1.0),
		modal_panel
	)

	modal_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var back: Button = Button.new()
	back.text = "BACK"
	back.position = Vector2(240.0, 266.0)
	back.size = Vector2(120.0, 42.0)
	back.pressed.connect(hide_information_modal)
	modal_panel.add_child(back)


func show_information_modal(
	title_text: String,
	body_text: String
) -> void:
	modal_title_label.text = title_text
	modal_body_label.text = body_text
	modal_blocker.visible = true
	modal_panel.visible = true


func hide_information_modal() -> void:
	modal_blocker.visible = false
	modal_panel.visible = false


func create_settings_panel() -> void:
	settings_blocker = ColorRect.new()
	settings_blocker.position = Vector2.ZERO
	settings_blocker.size = DESIGN_SIZE
	settings_blocker.color = Color(0.0, 0.0, 0.0, 0.80)
	settings_blocker.visible = false
	settings_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_blocker.z_index = 59
	design_canvas.add_child(settings_blocker)

	settings_panel = Panel.new()
	settings_panel.position = Vector2(218.0, 92.0)
	settings_panel.size = Vector2(1100.0, 840.0)
	settings_panel.visible = false
	settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_panel.z_index = 60

	settings_panel.add_theme_stylebox_override(
		"panel",
		create_panel_style(
			Color(0.008, 0.014, 0.024, 0.99),
			Color(0.0, 0.58, 1.0, 0.95),
			2
		)
	)

	design_canvas.add_child(settings_panel)

	make_label(
		"SETTINGS",
		Vector2(38.0, 24.0),
		Vector2(500.0, 38.0),
		27,
		Color(0.95, 0.97, 1.0, 1.0),
		settings_panel
	)

	make_label(
		"Changes are saved and applied automatically.",
		Vector2(40.0, 62.0),
		Vector2(520.0, 25.0),
		14,
		Color(0.58, 0.63, 0.70, 1.0),
		settings_panel
	)

	add_horizontal_line(
		settings_panel,
		94.0,
		1030.0,
		35.0
	)

	var close: Button = Button.new()
	close.text = "X"
	close.position = Vector2(1030.0, 24.0)
	close.size = Vector2(42.0, 38.0)
	close.pressed.connect(hide_settings_panel)
	settings_panel.add_child(close)

	create_settings_sections()

	var reset: Button = Button.new()
	reset.text = "RESET DEFAULTS"
	reset.position = Vector2(40.0, 774.0)
	reset.size = Vector2(180.0, 42.0)
	reset.pressed.connect(_on_reset_settings_pressed)
	settings_panel.add_child(reset)

	var back: Button = Button.new()
	back.text = "BACK"
	back.position = Vector2(920.0, 774.0)
	back.size = Vector2(140.0, 42.0)
	back.pressed.connect(hide_settings_panel)
	settings_panel.add_child(back)


func create_settings_sections() -> void:
	create_settings_title(
		"DISPLAY",
		Vector2(40.0, 112.0)
	)

	window_mode_option = OptionButton.new()

	create_option_row(
		"WINDOW MODE",
		"Windowed, borderless, or fullscreen.",
		Vector2(40.0, 148.0),
		window_mode_option
	)

	window_mode_option.add_item("WINDOWED")
	window_mode_option.add_item("BORDERLESS")
	window_mode_option.add_item("FULLSCREEN")
	window_mode_option.item_selected.connect(_on_window_mode_selected)

	resolution_option = OptionButton.new()

	create_option_row(
		"RESOLUTION",
		"Used while the game is in windowed mode.",
		Vector2(40.0, 208.0),
		resolution_option
	)

	for resolution: Vector2i in resolutions:
		resolution_option.add_item(
			str(resolution.x)
			+ " × "
			+ str(resolution.y)
		)

	resolution_option.item_selected.connect(_on_resolution_selected)

	vsync_toggle = CheckButton.new()

	create_toggle_row(
		"VERTICAL SYNC",
		"Helps prevent visible screen tearing.",
		Vector2(40.0, 268.0),
		vsync_toggle
	)

	vsync_toggle.toggled.connect(_on_vsync_toggled)

	frame_limit_option = OptionButton.new()

	create_option_row(
		"FRAME-RATE LIMIT",
		"Maximum frames rendered each second.",
		Vector2(40.0, 328.0),
		frame_limit_option
	)

	for limit: int in frame_limits:
		if limit == 0:
			frame_limit_option.add_item("UNLIMITED")
		else:
			frame_limit_option.add_item(
				str(limit)
				+ " FPS"
			)

	frame_limit_option.item_selected.connect(_on_frame_limit_selected)

	create_settings_title(
		"GRAPHICS",
		Vector2(40.0, 405.0)
	)

	render_scale_slider = HSlider.new()
	render_scale_value = Label.new()

	create_slider_row(
		"RENDER SCALE",
		"Lower values improve performance but reduce clarity.",
		Vector2(40.0, 442.0),
		render_scale_slider,
		render_scale_value,
		50.0,
		100.0,
		5.0
	)

	render_scale_slider.value_changed.connect(_on_render_scale_changed)

	create_settings_title(
		"AUDIO",
		Vector2(575.0, 112.0)
	)

	master_volume_slider = HSlider.new()
	master_volume_value = Label.new()

	create_slider_row(
		"MASTER VOLUME",
		"Controls all game audio.",
		Vector2(575.0, 148.0),
		master_volume_slider,
		master_volume_value,
		0.0,
		100.0,
		1.0
	)

	master_volume_slider.value_changed.connect(_on_master_volume_changed)

	music_volume_slider = HSlider.new()
	music_volume_value = Label.new()

	create_slider_row(
		"MUSIC VOLUME",
		"Controls music and menu ambience.",
		Vector2(575.0, 208.0),
		music_volume_slider,
		music_volume_value,
		0.0,
		100.0,
		1.0
	)

	music_volume_slider.value_changed.connect(_on_music_volume_changed)

	sfx_volume_slider = HSlider.new()
	sfx_volume_value = Label.new()

	create_slider_row(
		"SOUND-EFFECT VOLUME",
		"Controls vehicles, equipment, and world sounds.",
		Vector2(575.0, 268.0),
		sfx_volume_slider,
		sfx_volume_value,
		0.0,
		100.0,
		1.0
	)

	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)

	radio_volume_slider = HSlider.new()
	radio_volume_value = Label.new()

	create_slider_row(
		"RADIO / DIALOGUE",
		"Controls dispatch, radio, and spoken dialogue.",
		Vector2(575.0, 328.0),
		radio_volume_slider,
		radio_volume_value,
		0.0,
		100.0,
		1.0
	)

	radio_volume_slider.value_changed.connect(_on_radio_volume_changed)

	create_settings_title(
		"GAMEPLAY",
		Vector2(575.0, 405.0)
	)

	mouse_sensitivity_slider = HSlider.new()
	mouse_sensitivity_value = Label.new()

	create_slider_row(
		"MOUSE SENSITIVITY",
		"Controls first-person camera movement speed.",
		Vector2(575.0, 442.0),
		mouse_sensitivity_slider,
		mouse_sensitivity_value,
		1.0,
		10.0,
		1.0
	)

	mouse_sensitivity_slider.value_changed.connect(
		_on_mouse_sensitivity_changed
	)

	add_horizontal_line(
		settings_panel,
		752.0,
		1030.0,
		35.0
	)


func create_settings_title(
	text_value: String,
	position_value: Vector2
) -> void:
	make_label(
		text_value,
		position_value,
		Vector2(350.0, 28.0),
		16,
		Color(0.10, 0.62, 1.0, 1.0),
		settings_panel
	)


func create_setting_text(
	title_text: String,
	subtitle_text: String,
	row_position: Vector2
) -> void:
	make_label(
		title_text,
		row_position,
		Vector2(245.0, 24.0),
		14,
		Color(0.91, 0.93, 0.97, 1.0),
		settings_panel
	)

	make_label(
		subtitle_text,
		Vector2(
			row_position.x,
			row_position.y + 25.0
		),
		Vector2(265.0, 24.0),
		11,
		Color(0.52, 0.57, 0.64, 1.0),
		settings_panel
	)


func create_option_row(
	title_text: String,
	subtitle_text: String,
	row_position: Vector2,
	option: OptionButton
) -> void:
	create_setting_text(
		title_text,
		subtitle_text,
		row_position
	)

	option.position = Vector2(
		row_position.x + 280.0,
		row_position.y + 4.0
	)

	option.size = Vector2(200.0, 42.0)
	settings_panel.add_child(option)


func create_toggle_row(
	title_text: String,
	subtitle_text: String,
	row_position: Vector2,
	toggle: CheckButton
) -> void:
	create_setting_text(
		title_text,
		subtitle_text,
		row_position
	)

	toggle.text = "ENABLED"

	toggle.position = Vector2(
		row_position.x + 335.0,
		row_position.y + 4.0
	)

	toggle.size = Vector2(145.0, 42.0)
	settings_panel.add_child(toggle)


func create_slider_row(
	title_text: String,
	subtitle_text: String,
	row_position: Vector2,
	slider: HSlider,
	value_label: Label,
	minimum_value: float,
	maximum_value: float,
	step_value: float
) -> void:
	create_setting_text(
		title_text,
		subtitle_text,
		row_position
	)

	slider.position = Vector2(
		row_position.x + 250.0,
		row_position.y + 6.0
	)

	slider.size = Vector2(165.0, 38.0)
	slider.min_value = minimum_value
	slider.max_value = maximum_value
	slider.step = step_value
	settings_panel.add_child(slider)

	value_label.position = Vector2(
		row_position.x + 420.0,
		row_position.y + 8.0
	)

	value_label.size = Vector2(60.0, 30.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	value_label.add_theme_font_size_override(
		"font_size",
		14
	)

	value_label.add_theme_color_override(
		"font_color",
		Color(0.90, 0.94, 1.0, 1.0)
	)

	settings_panel.add_child(value_label)


func show_settings_panel() -> void:
	load_settings_values()
	settings_blocker.visible = true
	settings_panel.visible = true
	window_mode_option.grab_focus()


func hide_settings_panel() -> void:
	if settings_blocker != null:
		settings_blocker.visible = false

	if settings_panel != null:
		settings_panel.visible = false


func load_settings_values() -> void:
	updating_settings = true

	var mode: String = str(
		SettingsManager.get_setting(
			"display",
			"window_mode",
			"windowed"
		)
	)

	var mode_index: int = window_modes.find(mode)

	window_mode_option.select(
		maxi(
			mode_index,
			0
		)
	)

	resolution_option.disabled = mode != "windowed"

	var current_resolution: Vector2i = Vector2i(
		int(
			SettingsManager.get_setting(
				"display",
				"resolution_width",
				1920
			)
		),
		int(
			SettingsManager.get_setting(
				"display",
				"resolution_height",
				1080
			)
		)
	)

	var resolution_index: int = resolutions.find(
		current_resolution
	)

	if resolution_index < 0:
		resolutions.append(current_resolution)

		resolution_option.add_item(
			str(current_resolution.x)
			+ " × "
			+ str(current_resolution.y)
		)

		resolution_index = resolutions.size() - 1

	resolution_option.select(resolution_index)

	vsync_toggle.button_pressed = bool(
		SettingsManager.get_setting(
			"display",
			"vsync",
			true
		)
	)

	var frame_limit: int = int(
		SettingsManager.get_setting(
			"display",
			"frame_rate_limit",
			0
		)
	)

	var frame_index: int = frame_limits.find(
		frame_limit
	)

	if frame_index < 0:
		frame_limits.append(frame_limit)

		frame_limit_option.add_item(
			str(frame_limit)
			+ " FPS"
		)

		frame_index = frame_limits.size() - 1

	frame_limit_option.select(frame_index)

	var render_scale: float = float(
		SettingsManager.get_setting(
			"graphics",
			"render_scale",
			1.0
		)
	)

	render_scale_slider.value = render_scale * 100.0

	render_scale_value.text = (
		str(
			int(
				round(
					render_scale * 100.0
				)
			)
		)
		+ "%"
	)

	set_volume_control(
		master_volume_slider,
		master_volume_value,
		float(
			SettingsManager.get_setting(
				"audio",
				"master_volume",
				1.0
			)
		)
	)

	set_volume_control(
		music_volume_slider,
		music_volume_value,
		float(
			SettingsManager.get_setting(
				"audio",
				"music_volume",
				0.8
			)
		)
	)

	set_volume_control(
		sfx_volume_slider,
		sfx_volume_value,
		float(
			SettingsManager.get_setting(
				"audio",
				"sfx_volume",
				0.9
			)
		)
	)

	set_volume_control(
		radio_volume_slider,
		radio_volume_value,
		float(
			SettingsManager.get_setting(
				"audio",
				"radio_volume",
				0.9
			)
		)
	)

	var sensitivity: float = get_safe_mouse_sensitivity()

	mouse_sensitivity_slider.value = sensitivity * 1000.0

	mouse_sensitivity_value.text = str(
		int(
			round(
				sensitivity * 1000.0
			)
		)
	)

	updating_settings = false


func set_volume_control(
	slider: HSlider,
	value_label: Label,
	linear_value: float
) -> void:
	var percent: int = int(
		round(
			clampf(
				linear_value,
				0.0,
				1.0
			) * 100.0
		)
	)

	slider.value = float(percent)
	value_label.text = str(percent) + "%"


func _on_window_mode_selected(index: int) -> void:
	if (
		updating_settings
		or index < 0
		or index >= window_modes.size()
	):
		return

	var mode: String = window_modes[index]

	SettingsManager.set_setting(
		"display",
		"window_mode",
		mode
	)

	resolution_option.disabled = mode != "windowed"


func _on_resolution_selected(index: int) -> void:
	if (
		updating_settings
		or index < 0
		or index >= resolutions.size()
	):
		return

	var resolution: Vector2i = resolutions[index]

	SettingsManager.set_setting(
		"display",
		"resolution_width",
		resolution.x,
		false
	)

	SettingsManager.set_setting(
		"display",
		"resolution_height",
		resolution.y
	)


func _on_vsync_toggled(enabled: bool) -> void:
	if updating_settings:
		return

	SettingsManager.set_setting(
		"display",
		"vsync",
		enabled
	)


func _on_frame_limit_selected(index: int) -> void:
	if (
		updating_settings
		or index < 0
		or index >= frame_limits.size()
	):
		return

	SettingsManager.set_setting(
		"display",
		"frame_rate_limit",
		frame_limits[index]
	)


func _on_render_scale_changed(value: float) -> void:
	render_scale_value.text = (
		str(
			int(
				round(value)
			)
		)
		+ "%"
	)

	if updating_settings:
		return

	SettingsManager.set_setting(
		"graphics",
		"render_scale",
		value / 100.0
	)


func _on_master_volume_changed(value: float) -> void:
	update_volume_setting(
		"master_volume",
		value,
		master_volume_value
	)


func _on_music_volume_changed(value: float) -> void:
	update_volume_setting(
		"music_volume",
		value,
		music_volume_value
	)


func _on_sfx_volume_changed(value: float) -> void:
	update_volume_setting(
		"sfx_volume",
		value,
		sfx_volume_value
	)


func _on_radio_volume_changed(value: float) -> void:
	update_volume_setting(
		"radio_volume",
		value,
		radio_volume_value
	)


func update_volume_setting(
	setting_key: String,
	value: float,
	value_label: Label
) -> void:
	value_label.text = (
		str(
			int(
				round(value)
			)
		)
		+ "%"
	)

	if updating_settings:
		return

	SettingsManager.set_setting(
		"audio",
		setting_key,
		value / 100.0
	)


func _on_mouse_sensitivity_changed(value: float) -> void:
	mouse_sensitivity_value.text = str(
		int(
			round(value)
		)
	)

	if updating_settings:
		return

	var sensitivity: float = value * 0.001

	SettingsManager.set_setting(
		"gameplay",
		"mouse_sensitivity",
		sensitivity
	)

	apply_mouse_sensitivity_to_tree(sensitivity)


func get_safe_mouse_sensitivity() -> float:
	var sensitivity: float = float(
		SettingsManager.get_setting(
			"gameplay",
			"mouse_sensitivity",
			0.003
		)
	)

	if (
		sensitivity < 0.001
		or sensitivity > 0.01
	):
		sensitivity = 0.003

		SettingsManager.set_setting(
			"gameplay",
			"mouse_sensitivity",
			sensitivity
		)

	return sensitivity


func apply_saved_mouse_sensitivity() -> void:
	apply_mouse_sensitivity_to_tree(
		get_safe_mouse_sensitivity()
	)


func apply_mouse_sensitivity_to_tree(
	sensitivity: float
) -> void:
	if (
		get_tree() == null
		or get_tree().root == null
	):
		return

	apply_mouse_sensitivity_to_node(
		get_tree().root,
		sensitivity
	)


func apply_mouse_sensitivity_to_node(
	node: Node,
	sensitivity: float
) -> void:
	var property_list: Array[Dictionary] = node.get_property_list()

	for property_info: Dictionary in property_list:
		var property_name: String = str(
			property_info.get(
				"name",
				""
			)
		)

		if property_name == "mouse_sensitivity":
			node.set(
				"mouse_sensitivity",
				sensitivity
			)

			break

	for child: Node in node.get_children():
		apply_mouse_sensitivity_to_node(
			child,
			sensitivity
		)


func _on_reset_settings_pressed() -> void:
	SettingsManager.reset_all_settings()
	load_settings_values()
	apply_saved_mouse_sensitivity()

# -------------------------------------------------------------------
# CONTROLS PANEL
# -------------------------------------------------------------------

func create_controls_panel() -> void:
	controls_blocker = ColorRect.new()
	controls_blocker.position = Vector2.ZERO
	controls_blocker.size = DESIGN_SIZE
	controls_blocker.color = Color(
		0.0,
		0.0,
		0.0,
		0.80
	)
	controls_blocker.visible = false
	controls_blocker.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)
	controls_blocker.z_index = 69

	design_canvas.add_child(
		controls_blocker
	)

	controls_panel = Panel.new()
	controls_panel.position = Vector2(
		288.0,
		122.0
	)
	controls_panel.size = Vector2(
		960.0,
		780.0
	)
	controls_panel.visible = false
	controls_panel.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)
	controls_panel.z_index = 70

	controls_panel.add_theme_stylebox_override(
		"panel",
		create_panel_style(
			Color(
				0.008,
				0.014,
				0.024,
				0.99
			),
			Color(
				0.0,
				0.58,
				1.0,
				0.95
			),
			2
		)
	)

	design_canvas.add_child(
		controls_panel
	)

	make_label(
		"CONTROLS",
		Vector2(38.0, 24.0),
		Vector2(450.0, 38.0),
		27,
		Color(
			0.95,
			0.97,
			1.0,
			1.0
		),
		controls_panel
	)

	make_label(
		"Click a key binding, then press the replacement key.",
		Vector2(40.0, 62.0),
		Vector2(620.0, 25.0),
		14,
		Color(
			0.58,
			0.63,
			0.70,
			1.0
		),
		controls_panel
	)

	var close_button: Button = Button.new()
	close_button.text = "X"
	close_button.position = Vector2(
		890.0,
		24.0
	)
	close_button.size = Vector2(
		42.0,
		38.0
	)

	close_button.pressed.connect(
		hide_controls_panel
	)

	controls_panel.add_child(
		close_button
	)

	add_horizontal_line(
		controls_panel,
		94.0,
		890.0,
		35.0
	)

	for index: int in range(
		CONTROL_ACTIONS.size()
	):
		var action_name: String = str(
			CONTROL_ACTIONS[index]
		)

		var column: int = int(
			index / 5
		)

		var row: int = index % 5

		var row_position := Vector2(
			40.0 + float(column) * 460.0,
			125.0 + float(row) * 100.0
		)

		create_control_binding_row(
			action_name,
			row_position
		)

	controls_status_label = make_label(
		"Select a binding to change it.",
		Vector2(40.0, 635.0),
		Vector2(880.0, 34.0),
		15,
		Color(
			0.70,
			0.78,
			0.88,
			1.0
		),
		controls_panel
	)

	controls_status_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	controls_status_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	add_horizontal_line(
		controls_panel,
		687.0,
		890.0,
		35.0
	)

	var reset_button: Button = Button.new()
	reset_button.text = "RESET DEFAULTS"
	reset_button.position = Vector2(
		40.0,
		710.0
	)
	reset_button.size = Vector2(
		180.0,
		42.0
	)

	reset_button.pressed.connect(
		_on_reset_controls_pressed
	)

	controls_panel.add_child(
		reset_button
	)

	var back_button: Button = Button.new()
	back_button.text = "BACK"
	back_button.position = Vector2(
		780.0,
		710.0
	)
	back_button.size = Vector2(
		140.0,
		42.0
	)

	back_button.pressed.connect(
		hide_controls_panel
	)

	controls_panel.add_child(
		back_button
	)


func create_control_binding_row(
	action_name: String,
	row_position: Vector2
) -> void:
	var display_name: String = str(
		CONTROL_LABELS.get(
			action_name,
			action_name.to_upper()
		)
	)

	make_label(
		display_name,
		row_position,
		Vector2(235.0, 28.0),
		15,
		Color(
			0.91,
			0.93,
			0.97,
			1.0
		),
		controls_panel
	)

	make_label(
		"Click the key to rebind",
		Vector2(
			row_position.x,
			row_position.y + 30.0
		),
		Vector2(235.0, 24.0),
		11,
		Color(
			0.52,
			0.57,
			0.64,
			1.0
		),
		controls_panel
	)

	var bind_button: Button = Button.new()

	bind_button.position = Vector2(
		row_position.x + 245.0,
		row_position.y + 3.0
	)

	bind_button.size = Vector2(
		165.0,
		48.0
	)

	bind_button.text = "UNBOUND"

	bind_button.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND
	)

	bind_button.pressed.connect(
		_on_control_binding_pressed.bind(
			action_name
		)
	)

	controls_panel.add_child(
		bind_button
	)

	control_buttons[action_name] = bind_button


func show_controls_panel() -> void:
	waiting_for_control_action = ""

	refresh_control_bindings()

	controls_status_label.text = (
		"Select a binding to change it."
	)

	controls_blocker.visible = true
	controls_panel.visible = true

	var first_button: Button = (
		control_buttons.get(
			"move_forward"
		) as Button
	)

	if first_button != null:
		first_button.grab_focus()


func hide_controls_panel() -> void:
	if waiting_for_control_action != "":
		refresh_control_bindings()

	waiting_for_control_action = ""

	if controls_status_label != null:
		controls_status_label.text = (
			"Select a binding to change it."
		)

	if controls_blocker != null:
		controls_blocker.visible = false

	if controls_panel != null:
		controls_panel.visible = false


func refresh_control_bindings() -> void:
	for action_value: Variant in CONTROL_ACTIONS:
		var action_name: String = str(
			action_value
		)

		var button: Button = (
			control_buttons.get(
				action_name
			) as Button
		)

		if button == null:
			continue

		button.text = get_control_key_text(
			action_name
		)


func get_control_key_text(
	action_name: String
) -> String:
	var keycode: int = int(
		SettingsManager.get_setting(
			"controls",
			action_name,
			0
		)
	)

	if keycode <= 0:
		return "UNBOUND"

	return get_key_name(keycode)


func _on_control_binding_pressed(
	action_name: String
) -> void:
	waiting_for_control_action = action_name

	refresh_control_bindings()

	var button: Button = (
		control_buttons.get(
			action_name
		) as Button
	)

	if button != null:
		button.text = "PRESS A KEY..."

	var display_name: String = str(
		CONTROL_LABELS.get(
			action_name,
			action_name.to_upper()
		)
	)

	controls_status_label.text = (
		"Press a key for "
		+ display_name
		+ ". Press Esc to cancel."
	)


func handle_control_rebind(
	key_event: InputEventKey
) -> void:
	var physical_keycode: int = int(
		key_event.physical_keycode
	)

	if physical_keycode == 0:
		physical_keycode = int(
			key_event.keycode
		)

	if physical_keycode == KEY_ESCAPE:
		var cancelled_action: String = (
			waiting_for_control_action
		)

		waiting_for_control_action = ""

		refresh_control_bindings()

		var cancelled_name: String = str(
			CONTROL_LABELS.get(
				cancelled_action,
				cancelled_action.to_upper()
			)
		)

		controls_status_label.text = (
			"Rebinding cancelled for "
			+ cancelled_name
			+ "."
		)

		return

	if physical_keycode <= 0:
		return

	var duplicate_action: String = (
		get_action_using_key(
			physical_keycode,
			waiting_for_control_action
		)
	)

	if duplicate_action != "":
		var duplicate_name: String = str(
			CONTROL_LABELS.get(
				duplicate_action,
				duplicate_action.to_upper()
			)
		)

		controls_status_label.text = (
			get_key_name(
				physical_keycode
			)
			+ " is already assigned to "
			+ duplicate_name
			+ ". Choose another key."
		)

		return

	var changed_action: String = (
		waiting_for_control_action
	)

	SettingsManager.set_setting(
		"controls",
		changed_action,
		physical_keycode
	)

	waiting_for_control_action = ""

	refresh_control_bindings()

	var changed_name: String = str(
		CONTROL_LABELS.get(
			changed_action,
			changed_action.to_upper()
		)
	)

	controls_status_label.text = (
		changed_name
		+ " changed to "
		+ get_key_name(
			physical_keycode
		)
		+ "."
	)


func get_action_using_key(
	physical_keycode: int,
	excluded_action: String
) -> String:
	for action_value: Variant in CONTROL_ACTIONS:
		var action_name: String = str(
			action_value
		)

		if action_name == excluded_action:
			continue

		var assigned_keycode: int = int(
			SettingsManager.get_setting(
				"controls",
				action_name,
				0
			)
		)

		if assigned_keycode == physical_keycode:
			return action_name

	return ""


func get_key_name(
	physical_keycode: int
) -> String:
	var key_text: String = (
		OS.get_keycode_string(
			physical_keycode
		)
	)

	if key_text.is_empty():
		return str(physical_keycode)

	return key_text.to_upper()


func _on_reset_controls_pressed() -> void:
	waiting_for_control_action = ""

	SettingsManager.reset_section(
		"controls"
	)

	refresh_control_bindings()

	controls_status_label.text = (
		"Controls restored to defaults."
	)
# -------------------------------------------------------------------
# AUTOSAVE
# -------------------------------------------------------------------

func create_autosave_system() -> void:
	autosave_notice_root = Control.new()
	autosave_notice_root.name = "AutosaveNoticeRoot"
	autosave_notice_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(autosave_notice_root)

	autosave_notice_root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	autosave_notice_panel = Panel.new()
	autosave_notice_panel.name = "AutosaveNoticePanel"

	autosave_notice_panel.anchor_left = 1.0
	autosave_notice_panel.anchor_top = 0.0
	autosave_notice_panel.anchor_right = 1.0
	autosave_notice_panel.anchor_bottom = 0.0

	autosave_notice_panel.offset_left = -365.0
	autosave_notice_panel.offset_top = 28.0
	autosave_notice_panel.offset_right = -28.0
	autosave_notice_panel.offset_bottom = 104.0

	autosave_notice_panel.visible = false
	autosave_notice_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	autosave_notice_panel.pivot_offset = Vector2(337.0, 38.0)

	var autosave_style: StyleBoxFlat = StyleBoxFlat.new()

	autosave_style.bg_color = Color(
		0.006,
		0.011,
		0.019,
		0.97
	)

	autosave_style.border_color = Color(
		0.12,
		0.36,
		0.58,
		0.95
	)

	autosave_style.border_width_left = 1
	autosave_style.border_width_top = 1
	autosave_style.border_width_right = 1
	autosave_style.border_width_bottom = 1

	autosave_style.corner_radius_top_left = 8
	autosave_style.corner_radius_top_right = 8
	autosave_style.corner_radius_bottom_left = 8
	autosave_style.corner_radius_bottom_right = 8

	autosave_style.shadow_color = Color(
		0.0,
		0.0,
		0.0,
		0.72
	)

	autosave_style.shadow_size = 12

	autosave_notice_panel.add_theme_stylebox_override(
		"panel",
		autosave_style
	)

	autosave_notice_root.add_child(
		autosave_notice_panel
	)

	var accent_bar: ColorRect = ColorRect.new()
	accent_bar.position = Vector2(0.0, 8.0)
	accent_bar.size = Vector2(4.0, 60.0)

	accent_bar.color = Color(
		0.0,
		0.61,
		1.0,
		1.0
	)

	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	autosave_notice_panel.add_child(
		accent_bar
	)

	var icon_panel: Panel = Panel.new()
	icon_panel.position = Vector2(16.0, 13.0)
	icon_panel.size = Vector2(50.0, 50.0)
	icon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon_style: StyleBoxFlat = StyleBoxFlat.new()

	icon_style.bg_color = Color(
		0.0,
		0.25,
		0.48,
		0.42
	)

	icon_style.border_color = Color(
		0.0,
		0.61,
		1.0,
		0.72
	)

	icon_style.border_width_left = 1
	icon_style.border_width_top = 1
	icon_style.border_width_right = 1
	icon_style.border_width_bottom = 1

	icon_style.corner_radius_top_left = 6
	icon_style.corner_radius_top_right = 6
	icon_style.corner_radius_bottom_left = 6
	icon_style.corner_radius_bottom_right = 6

	icon_panel.add_theme_stylebox_override(
		"panel",
		icon_style
	)

	autosave_notice_panel.add_child(
		icon_panel
	)

	var handcuff_icon: Label = Label.new()
	handcuff_icon.text = "◉═◉"
	handcuff_icon.size = Vector2(50.0, 50.0)

	handcuff_icon.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	handcuff_icon.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	handcuff_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	handcuff_icon.add_theme_font_size_override(
		"font_size",
		17
	)

	handcuff_icon.add_theme_color_override(
		"font_color",
		Color(
			0.35,
			0.78,
			1.0,
			1.0
		)
	)

	icon_panel.add_child(
		handcuff_icon
	)

	var autosave_header: Label = Label.new()
	autosave_header.text = "AUTOSAVE COMPLETE"
	autosave_header.position = Vector2(82.0, 12.0)
	autosave_header.size = Vector2(235.0, 23.0)
	autosave_header.mouse_filter = Control.MOUSE_FILTER_IGNORE

	autosave_header.add_theme_font_size_override(
		"font_size",
		12
	)

	autosave_header.add_theme_color_override(
		"font_color",
		Color(
			0.12,
			0.68,
			1.0,
			1.0
		)
	)

	autosave_notice_panel.add_child(
		autosave_header
	)

	autosave_notice_label = Label.new()
	autosave_notice_label.text = "CAREER PROGRESS SECURED"
	autosave_notice_label.position = Vector2(82.0, 33.0)
	autosave_notice_label.size = Vector2(235.0, 24.0)
	autosave_notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	autosave_notice_label.add_theme_font_size_override(
		"font_size",
		15
	)

	autosave_notice_label.add_theme_color_override(
		"font_color",
		Color(
			0.92,
			0.95,
			0.99,
			1.0
		)
	)

	autosave_notice_panel.add_child(
		autosave_notice_label
	)

	var autosave_subtitle: Label = Label.new()
	autosave_subtitle.text = "Officer data and career progress saved"
	autosave_subtitle.position = Vector2(82.0, 55.0)
	autosave_subtitle.size = Vector2(235.0, 18.0)
	autosave_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE

	autosave_subtitle.add_theme_font_size_override(
		"font_size",
		10
	)

	autosave_subtitle.add_theme_color_override(
		"font_color",
		Color(
			0.48,
			0.55,
			0.63,
			1.0
		)
	)

	autosave_notice_panel.add_child(
		autosave_subtitle
	)

	autosave_notice_timer = Timer.new()
	autosave_notice_timer.one_shot = true
	autosave_notice_timer.wait_time = 2.2

	autosave_notice_timer.timeout.connect(
		_on_autosave_notice_timeout
	)

	add_child(autosave_notice_timer)

	autosave_timer = Timer.new()
	autosave_timer.name = "CareerAutosaveTimer"
	autosave_timer.wait_time = AUTOSAVE_INTERVAL_SECONDS
	autosave_timer.one_shot = false
	autosave_timer.autostart = true
	autosave_timer.process_callback = Timer.TIMER_PROCESS_IDLE

	autosave_timer.timeout.connect(
		_on_autosave_timeout
	)

	add_child(autosave_timer)


func _on_autosave_timeout() -> void:
	if not GameState.player_profile_created:
		return

	if get_tree().paused:
		return

	if GameState.save_active_career():
		show_autosave_notice(
			"CAREER AUTOSAVED"
		)
	else:
		show_autosave_notice(
			"AUTOSAVE FAILED"
		)


func show_autosave_notice(
	message_text: String
) -> void:
	autosave_notice_label.text = message_text

	autosave_notice_panel.visible = true
	autosave_notice_panel.modulate = Color(
		1.0,
		1.0,
		1.0,
		0.0
	)

	autosave_notice_panel.scale = Vector2(
		0.96,
		0.96
	)

	var tween: Tween = create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		autosave_notice_panel,
		"modulate:a",
		1.0,
		0.20
	)

	tween.tween_property(
		autosave_notice_panel,
		"scale",
		Vector2.ONE,
		0.20
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	autosave_notice_timer.start()


func _on_autosave_notice_timeout() -> void:
	var tween: Tween = create_tween()

	tween.tween_property(
		autosave_notice_panel,
		"modulate:a",
		0.0,
		0.18
	)

	tween.tween_callback(
		autosave_notice_panel.hide
	)
func create_save_toast() -> void:
	save_toast_panel = Panel.new()
	save_toast_panel.position = Vector2(1190.0, 900.0)
	save_toast_panel.size = Vector2(290.0, 48.0)
	save_toast_panel.visible = false
	save_toast_panel.z_index = 45

	save_toast_panel.add_theme_stylebox_override(
		"panel",
		create_panel_style(
			Color(0.01, 0.06, 0.12, 0.97),
			Color(0.0, 0.65, 1.0, 1.0),
			1
		)
	)

	design_canvas.add_child(save_toast_panel)

	save_toast_label = make_label(
		"",
		Vector2.ZERO,
		Vector2(290.0, 48.0),
		15,
		Color(0.90, 0.96, 1.0, 1.0),
		save_toast_panel
	)

	save_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	save_toast_timer = Timer.new()
	save_toast_timer.one_shot = true
	save_toast_timer.wait_time = 2.2
	save_toast_timer.timeout.connect(_on_save_toast_timeout)
	add_child(save_toast_timer)


func show_save_toast(message_text: String) -> void:
	save_toast_label.text = message_text
	save_toast_panel.visible = true
	save_toast_timer.start()


func _on_save_toast_timeout() -> void:
	save_toast_panel.visible = false


func open_pause_menu() -> void:
	if pause_open:
		return

	pause_open = true
	refresh_pause_information()
	screen_root.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true

	if resume_button != null:
		resume_button.grab_focus()


func close_pause_menu() -> void:
	if not pause_open:
		return

	hide_information_modal()
	hide_settings_panel()
	hide_controls_panel()
	save_toast_panel.visible = false
	screen_root.visible = false
	pause_open = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_resume_pressed() -> void:
	close_pause_menu()


func _on_settings_pressed() -> void:
	show_settings_panel()


func _on_controls_pressed() -> void:
	show_controls_panel()


func _on_field_manual_pressed() -> void:
	show_information_modal(
		"FIELD MANUAL",
		"Police procedures, radio codes, call-response guidance, "
		+ "and academy tutorials will be available here."
	)


func _on_save_game_pressed() -> void:
	quick_save()


func quick_save() -> void:
	if not GameState.player_profile_created:
		show_save_toast("NO ACTIVE CAREER")
		return

	if GameState.save_active_career():
		show_save_toast("CAREER SAVED")
	else:
		show_save_toast("SAVE FAILED")


func _on_exit_to_main_menu_pressed() -> void:
	if GameState.player_profile_created:
		GameState.save_active_career()

	hide_information_modal()
	hide_settings_panel()
	hide_controls_panel()

	get_tree().paused = false
	pause_open = false
	screen_root.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var result: Error = get_tree().change_scene_to_file(
		MAIN_MENU_SCENE_PATH
	)

	if result != OK:
		print(
			"Could not return to main menu. Error: "
			+ str(result)
		)


func _on_quit_game_pressed() -> void:
	if GameState.player_profile_created:
		GameState.save_active_career()

	get_tree().paused = false
	get_tree().quit()


func make_label(
	text_value: String,
	position_value: Vector2,
	size_value: Vector2,
	font_size: int,
	font_color: Color,
	parent: Control
) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.position = position_value
	label.size = size_value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	label.add_theme_font_size_override(
		"font_size",
		font_size
	)

	label.add_theme_color_override(
		"font_color",
		font_color
	)

	parent.add_child(label)
	return label


func create_panel_style(
	background_color: Color,
	border_color: Color,
	border_width: int
) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5

	return style


func add_horizontal_line(
	parent: Control,
	y: float,
	width: float,
	x: float = 0.0
) -> void:
	var line: ColorRect = ColorRect.new()
	line.position = Vector2(x, y)
	line.size = Vector2(width, 1.0)
	line.color = Color(0.35, 0.38, 0.43, 0.63)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)
