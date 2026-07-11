extends CanvasLayer

const DESIGN_SIZE: Vector2 = Vector2(1536.0, 1024.0)
const PAUSE_BACKGROUND_PATH: String = "res://Art/Menu/dutyra_pause_menu_background.png"
const MAIN_MENU_SCENE_PATH: String = "res://Scenes/MainMenu.tscn"

var screen_root: Control
var background_texture: TextureRect
var dark_overlay: ColorRect
var design_canvas: Control

var menu_buttons: Array[Button] = []
var resume_button: Button

var right_panel: Panel

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

var save_toast_panel: Panel
var save_toast_label: Label
var save_toast_timer: Timer

var pause_open: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	create_pause_screen()
	create_left_menu()
	create_pause_header()
	create_right_information_panel()
	create_bottom_hints()
	create_information_modal()
	create_save_toast()

	get_viewport().size_changed.connect(update_pause_layout)

	GameState.player_profile_changed.connect(refresh_pause_information)
	GameState.career_progress_changed.connect(refresh_pause_information)
	GameState.game_time_changed.connect(refresh_pause_information)
	GameState.report_logged.connect(refresh_pause_information)

	DispatchManager.active_call_changed.connect(
		_on_active_call_changed
	)

	update_pause_layout()
	refresh_pause_information()

	screen_root.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_F5 and pause_open:
				quick_save()
				get_viewport().set_input_as_handled()
				return

	if not event.is_action_pressed("ui_cancel"):
		return

	if modal_panel.visible:
		hide_information_modal()
		get_viewport().set_input_as_handled()
		return

	if pause_open:
		close_pause_menu()
		get_viewport().set_input_as_handled()
		return

	# Radio and MDT use a visible cursor. Let their own Esc handling run first.
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	open_pause_menu()
	get_viewport().set_input_as_handled()


# -------------------------------------------------------------------
# PAUSE SCREEN FOUNDATION
# -------------------------------------------------------------------

func create_pause_screen() -> void:
	screen_root = Control.new()
	screen_root.name = "PauseScreenRoot"
	screen_root.mouse_filter = Control.MOUSE_FILTER_STOP

	add_child(screen_root)

	screen_root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	background_texture = TextureRect.new()
	background_texture.name = "PauseBackground"
	background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE

	screen_root.add_child(background_texture)

	background_texture.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	if ResourceLoader.exists(PAUSE_BACKGROUND_PATH):
		background_texture.texture = load(PAUSE_BACKGROUND_PATH)
	else:
		print(
			"PAUSE BACKGROUND NOT FOUND: "
			+ PAUSE_BACKGROUND_PATH
		)

	dark_overlay = ColorRect.new()
	dark_overlay.name = "PauseDarkOverlay"
	dark_overlay.color = Color(0.0, 0.0, 0.0, 0.27)
	dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	screen_root.add_child(dark_overlay)

	dark_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

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

	var scaled_design_size: Vector2 = DESIGN_SIZE * scale_factor

	design_canvas.scale = Vector2(
		scale_factor,
		scale_factor
	)

	design_canvas.position = Vector2(
		(viewport_size.x - scaled_design_size.x) * 0.5,
		(viewport_size.y - scaled_design_size.y) * 0.5
	)


# -------------------------------------------------------------------
# LEFT MENU
# -------------------------------------------------------------------

func create_left_menu() -> void:
	var button_x: float = 45.0
	var start_y: float = 238.0
	var button_width: float = 447.0
	var button_height: float = 72.0
	var button_gap: float = 3.0

	resume_button = create_pause_button(
		"RESUME GAME",
		"Return to your shift",
		"▶",
		Vector2(button_x, start_y),
		Vector2(button_width, button_height),
		_on_resume_pressed,
		true
	)

	create_pause_button(
		"SETTINGS",
		"Adjust game settings",
		"⚙",
		Vector2(
			button_x,
			start_y + (button_height + button_gap) * 1.0
		),
		Vector2(button_width, button_height),
		_on_settings_pressed
	)

	create_pause_button(
		"CONTROLS",
		"View and edit controls",
		"⌨",
		Vector2(
			button_x,
			start_y + (button_height + button_gap) * 2.0
		),
		Vector2(button_width, button_height),
		_on_controls_pressed
	)

	create_pause_button(
		"FIELD MANUAL",
		"Game tutorials and guidelines",
		"▤",
		Vector2(
			button_x,
			start_y + (button_height + button_gap) * 3.0
		),
		Vector2(button_width, button_height),
		_on_field_manual_pressed
	)

	create_pause_button(
		"PHOTO MODE",
		"Capture in-game moments",
		"●",
		Vector2(
			button_x,
			start_y + (button_height + button_gap) * 4.0
		),
		Vector2(button_width, button_height),
		_on_photo_mode_pressed
	)

	create_pause_button(
		"SAVE GAME",
		"Manually save your progress",
		"▣",
		Vector2(
			button_x,
			start_y + (button_height + button_gap) * 5.0
		),
		Vector2(button_width, button_height),
		_on_save_game_pressed
	)

	create_pause_button(
		"EXIT TO MAIN MENU",
		"Return to the main menu",
		"↩",
		Vector2(
			button_x,
			start_y + (button_height + button_gap) * 6.0
		),
		Vector2(button_width, button_height),
		_on_exit_to_main_menu_pressed
	)

	create_pause_button(
		"QUIT GAME",
		"Exit DUTYRA™",
		"⏻",
		Vector2(
			button_x,
			start_y + (button_height + button_gap) * 7.0
		),
		Vector2(button_width, button_height),
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
	var button := Button.new()

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
		create_pause_button_style(default_highlighted)
	)

	button.add_theme_stylebox_override(
		"hover",
		create_pause_button_style(true)
	)

	button.add_theme_stylebox_override(
		"pressed",
		create_pause_button_style(true)
	)

	button.add_theme_stylebox_override(
		"focus",
		create_pause_button_style(true)
	)

	design_canvas.add_child(button)
	menu_buttons.append(button)

	var accent_line := ColorRect.new()
	accent_line.name = "AccentLine"
	accent_line.position = Vector2.ZERO
	accent_line.size = Vector2(4.0, button_size.y)
	accent_line.color = Color(0.0, 0.61, 1.0, 1.0)
	accent_line.visible = default_highlighted
	accent_line.mouse_filter = Control.MOUSE_FILTER_IGNORE

	button.add_child(accent_line)

	var icon_label := Label.new()
	icon_label.name = "Icon"
	icon_label.text = icon_text
	icon_label.position = Vector2(18.0, 8.0)
	icon_label.size = Vector2(58.0, 56.0)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	icon_label.add_theme_font_size_override(
		"font_size",
		30
	)

	icon_label.add_theme_color_override(
		"font_color",
		Color(0.68, 0.70, 0.73, 1.0)
	)

	button.add_child(icon_label)

	var title_label := Label.new()
	title_label.name = "Title"
	title_label.text = title_text
	title_label.position = Vector2(84.0, 11.0)
	title_label.size = Vector2(300.0, 27.0)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	title_label.add_theme_font_size_override(
		"font_size",
		20
	)

	title_label.add_theme_color_override(
		"font_color",
		Color(0.95, 0.97, 1.0, 1.0)
	)

	button.add_child(title_label)

	var subtitle_label := Label.new()
	subtitle_label.name = "Subtitle"
	subtitle_label.text = subtitle_text
	subtitle_label.position = Vector2(84.0, 39.0)
	subtitle_label.size = Vector2(305.0, 22.0)
	subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subtitle_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	subtitle_label.add_theme_font_size_override(
		"font_size",
		13
	)

	subtitle_label.add_theme_color_override(
		"font_color",
		Color(0.59, 0.62, 0.68, 1.0)
	)

	button.add_child(subtitle_label)

	var arrow_label := Label.new()
	arrow_label.name = "Arrow"
	arrow_label.text = "›"
	arrow_label.position = Vector2(398.0, 11.0)
	arrow_label.size = Vector2(36.0, 50.0)
	arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow_label.visible = default_highlighted

	arrow_label.add_theme_font_size_override(
		"font_size",
		38
	)

	arrow_label.add_theme_color_override(
		"font_color",
		Color(0.0, 0.68, 1.0, 1.0)
	)

	button.add_child(arrow_label)

	button.mouse_entered.connect(
		_on_pause_button_highlighted.bind(
			button,
			accent_line,
			arrow_label
		)
	)

	button.focus_entered.connect(
		_on_pause_button_highlighted.bind(
			button,
			accent_line,
			arrow_label
		)
	)

	button.mouse_exited.connect(
		_on_pause_button_unhighlighted.bind(
			button,
			accent_line,
			arrow_label
		)
	)

	button.focus_exited.connect(
		_on_pause_button_unhighlighted.bind(
			button,
			accent_line,
			arrow_label
		)
	)

	return button


func create_pause_button_style(
	highlighted: bool
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

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
	_button: Button,
	accent_line: ColorRect,
	arrow_label: Label
) -> void:
	accent_line.visible = true
	arrow_label.visible = true


func _on_pause_button_unhighlighted(
	button: Button,
	accent_line: ColorRect,
	arrow_label: Label
) -> void:
	var keep_highlighted: bool = bool(
		button.get_meta(
			"default_highlighted",
			false
		)
	)

	accent_line.visible = keep_highlighted
	arrow_label.visible = keep_highlighted


# -------------------------------------------------------------------
# TOP-RIGHT HEADER
# -------------------------------------------------------------------

func create_pause_header() -> void:
	var slash_label := Label.new()
	slash_label.text = "/ /"
	slash_label.position = Vector2(1240.0, 25.0)
	slash_label.size = Vector2(65.0, 35.0)

	slash_label.add_theme_font_size_override(
		"font_size",
		28
	)

	slash_label.add_theme_color_override(
		"font_color",
		Color(0.15, 0.17, 0.19, 1.0)
	)

	design_canvas.add_child(slash_label)

	var paused_label := Label.new()
	paused_label.text = "GAME PAUSED"
	paused_label.position = Vector2(1318.0, 30.0)
	paused_label.size = Vector2(185.0, 30.0)

	paused_label.add_theme_font_size_override(
		"font_size",
		21
	)

	paused_label.add_theme_color_override(
		"font_color",
		Color(0.18, 0.60, 1.0, 1.0)
	)

	design_canvas.add_child(paused_label)

	var career_mode_label := Label.new()
	career_mode_label.text = "CAREER MODE"
	career_mode_label.position = Vector2(1357.0, 61.0)
	career_mode_label.size = Vector2(145.0, 25.0)

	career_mode_label.add_theme_font_size_override(
		"font_size",
		15
	)

	career_mode_label.add_theme_color_override(
		"font_color",
		Color(0.89, 0.89, 0.91, 1.0)
	)

	design_canvas.add_child(career_mode_label)


# -------------------------------------------------------------------
# RIGHT INFORMATION PANEL
# -------------------------------------------------------------------

func create_right_information_panel() -> void:
	right_panel = Panel.new()
	right_panel.name = "PauseInformationPanel"
	right_panel.position = Vector2(1096.0, 120.0)
	right_panel.size = Vector2(395.0, 788.0)
	right_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.005, 0.008, 0.012, 0.88)
	panel_style.border_color = Color(0.40, 0.43, 0.48, 0.64)

	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1

	panel_style.corner_radius_top_left = 5
	panel_style.corner_radius_top_right = 5
	panel_style.corner_radius_bottom_left = 5
	panel_style.corner_radius_bottom_right = 5

	right_panel.add_theme_stylebox_override(
		"panel",
		panel_style
	)

	design_canvas.add_child(right_panel)

	create_current_shift_section()
	create_objective_section()
	create_career_stats_section()
	create_city_status_section()


func create_current_shift_section() -> void:
	create_section_title(
		right_panel,
		"CURRENT SHIFT",
		Vector2(28.0, 27.0)
	)

	var badge_box := Panel.new()
	badge_box.position = Vector2(29.0, 60.0)
	badge_box.size = Vector2(53.0, 64.0)

	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.035, 0.04, 0.05, 0.96)
	badge_style.border_color = Color(0.45, 0.49, 0.55, 0.75)

	badge_style.border_width_top = 1
	badge_style.border_width_bottom = 1
	badge_style.border_width_left = 1
	badge_style.border_width_right = 1

	badge_box.add_theme_stylebox_override(
		"panel",
		badge_style
	)

	right_panel.add_child(badge_box)

	var badge_label := Label.new()
	badge_label.text = "D"
	badge_label.size = Vector2(53.0, 64.0)
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	badge_label.add_theme_font_size_override(
		"font_size",
		29
	)

	badge_label.add_theme_color_override(
		"font_color",
		Color(0.90, 0.92, 0.95, 1.0)
	)

	badge_box.add_child(badge_label)

	shift_officer_label = Label.new()
	shift_officer_label.position = Vector2(96.0, 59.0)
	shift_officer_label.size = Vector2(270.0, 27.0)
	shift_officer_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	shift_officer_label.add_theme_font_size_override(
		"font_size",
		18
	)

	shift_officer_label.add_theme_color_override(
		"font_color",
		Color(0.96, 0.97, 1.0, 1.0)
	)

	right_panel.add_child(shift_officer_label)

	var shift_time_title := Label.new()
	shift_time_title.text = "SHIFT TIME"
	shift_time_title.position = Vector2(96.0, 93.0)
	shift_time_title.size = Vector2(140.0, 21.0)

	shift_time_title.add_theme_font_size_override(
		"font_size",
		13
	)

	shift_time_title.add_theme_color_override(
		"font_color",
		Color(0.57, 0.59, 0.63, 1.0)
	)

	right_panel.add_child(shift_time_title)

	shift_time_label = Label.new()
	shift_time_label.position = Vector2(96.0, 116.0)
	shift_time_label.size = Vector2(140.0, 28.0)

	shift_time_label.add_theme_font_size_override(
		"font_size",
		18
	)

	shift_time_label.add_theme_color_override(
		"font_color",
		Color(0.93, 0.94, 0.97, 1.0)
	)

	right_panel.add_child(shift_time_label)

	create_separator(
		right_panel,
		158.0
	)


func create_objective_section() -> void:
	create_section_title(
		right_panel,
		"OBJECTIVE",
		Vector2(28.0, 181.0)
	)

	var objective_icon := Label.new()
	objective_icon.text = "◎"
	objective_icon.position = Vector2(27.0, 218.0)
	objective_icon.size = Vector2(58.0, 62.0)
	objective_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	objective_icon.add_theme_font_size_override(
		"font_size",
		43
	)

	objective_icon.add_theme_color_override(
		"font_color",
		Color(0.57, 0.59, 0.62, 1.0)
	)

	right_panel.add_child(objective_icon)

	objective_title_label = Label.new()
	objective_title_label.position = Vector2(96.0, 211.0)
	objective_title_label.size = Vector2(270.0, 28.0)
	objective_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	objective_title_label.add_theme_font_size_override(
		"font_size",
		17
	)

	objective_title_label.add_theme_color_override(
		"font_color",
		Color(0.96, 0.97, 1.0, 1.0)
	)

	right_panel.add_child(objective_title_label)

	objective_body_label = Label.new()
	objective_body_label.position = Vector2(96.0, 246.0)
	objective_body_label.size = Vector2(270.0, 55.0)
	objective_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	objective_body_label.add_theme_font_size_override(
		"font_size",
		14
	)

	objective_body_label.add_theme_color_override(
		"font_color",
		Color(0.64, 0.66, 0.70, 1.0)
	)

	right_panel.add_child(objective_body_label)

	create_separator(
		right_panel,
		311.0
	)


func create_career_stats_section() -> void:
	create_section_title(
		right_panel,
		"CAREER STATS",
		Vector2(28.0, 337.0)
	)

	career_xp_value = create_stat_row(
		right_panel,
		"PERFORMANCE XP",
		"0",
		382.0
	)

	career_calls_value = create_stat_row(
		right_panel,
		"CALLS RESPONDED",
		"0",
		421.0
	)

	career_shifts_value = create_stat_row(
		right_panel,
		"SHIFTS COMPLETED",
		"0",
		460.0
	)

	career_reports_value = create_stat_row(
		right_panel,
		"REPORTS FILED",
		"0",
		499.0
	)

	career_rank_value = create_stat_row(
		right_panel,
		"CURRENT RANK",
		"ROOKIE",
		538.0
	)

	create_separator(
		right_panel,
		573.0
	)


func create_city_status_section() -> void:
	create_section_title(
		right_panel,
		"CITY STATUS",
		Vector2(28.0, 598.0)
	)

	var city_icon := Label.new()
	city_icon.text = "▥"
	city_icon.position = Vector2(27.0, 638.0)
	city_icon.size = Vector2(57.0, 58.0)
	city_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	city_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	city_icon.add_theme_font_size_override(
		"font_size",
		40
	)

	city_icon.add_theme_color_override(
		"font_color",
		Color(0.57, 0.59, 0.62, 1.0)
	)

	right_panel.add_child(city_icon)

	var city_name := Label.new()
	city_name.text = "DUTYRA CITY"
	city_name.position = Vector2(95.0, 643.0)
	city_name.size = Vector2(250.0, 27.0)

	city_name.add_theme_font_size_override(
		"font_size",
		17
	)

	city_name.add_theme_color_override(
		"font_color",
		Color(0.96, 0.97, 1.0, 1.0)
	)

	right_panel.add_child(city_name)

	var crime_label := Label.new()
	crime_label.text = "CRIME RATE"
	crime_label.position = Vector2(95.0, 684.0)
	crime_label.size = Vector2(140.0, 24.0)

	crime_label.add_theme_font_size_override(
		"font_size",
		13
	)

	crime_label.add_theme_color_override(
		"font_color",
		Color(0.62, 0.64, 0.68, 1.0)
	)

	right_panel.add_child(crime_label)

	var crime_value := Label.new()
	crime_value.text = "MODERATE"
	crime_value.position = Vector2(264.0, 684.0)
	crime_value.size = Vector2(102.0, 24.0)
	crime_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	crime_value.add_theme_font_size_override(
		"font_size",
		13
	)

	crime_value.add_theme_color_override(
		"font_color",
		Color(1.0, 0.66, 0.10, 1.0)
	)

	right_panel.add_child(crime_value)

	var time_title := Label.new()
	time_title.text = "TIME"
	time_title.position = Vector2(95.0, 721.0)
	time_title.size = Vector2(140.0, 24.0)

	time_title.add_theme_font_size_override(
		"font_size",
		13
	)

	time_title.add_theme_color_override(
		"font_color",
		Color(0.62, 0.64, 0.68, 1.0)
	)

	right_panel.add_child(time_title)

	city_time_value = Label.new()
	city_time_value.position = Vector2(264.0, 721.0)
	city_time_value.size = Vector2(102.0, 24.0)
	city_time_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	city_time_value.add_theme_font_size_override(
		"font_size",
		13
	)

	city_time_value.add_theme_color_override(
		"font_color",
		Color(0.88, 0.89, 0.92, 1.0)
	)

	right_panel.add_child(city_time_value)

	var weather_title := Label.new()
	weather_title.text = "WEATHER"
	weather_title.position = Vector2(95.0, 758.0)
	weather_title.size = Vector2(140.0, 24.0)

	weather_title.add_theme_font_size_override(
		"font_size",
		13
	)

	weather_title.add_theme_color_override(
		"font_color",
		Color(0.62, 0.64, 0.68, 1.0)
	)

	right_panel.add_child(weather_title)

	var weather_value := Label.new()
	weather_value.text = "RAIN   58°F"
	weather_value.position = Vector2(245.0, 758.0)
	weather_value.size = Vector2(121.0, 24.0)
	weather_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	weather_value.add_theme_font_size_override(
		"font_size",
		13
	)

	weather_value.add_theme_color_override(
		"font_color",
		Color(0.78, 0.82, 0.88, 1.0)
	)

	right_panel.add_child(weather_value)


func create_section_title(
	parent: Control,
	title_text: String,
	title_position: Vector2
) -> void:
	var section_title := Label.new()
	section_title.text = title_text
	section_title.position = title_position
	section_title.size = Vector2(260.0, 24.0)

	section_title.add_theme_font_size_override(
		"font_size",
		14
	)

	section_title.add_theme_color_override(
		"font_color",
		Color(0.16, 0.61, 1.0, 1.0)
	)

	parent.add_child(section_title)


func create_separator(
	parent: Control,
	separator_y: float
) -> void:
	var separator := ColorRect.new()
	separator.position = Vector2(0.0, separator_y)
	separator.size = Vector2(395.0, 1.0)
	separator.color = Color(0.35, 0.38, 0.43, 0.63)
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE

	parent.add_child(separator)


func create_stat_row(
	parent: Control,
	title_text: String,
	initial_value: String,
	row_y: float
) -> Label:
	var icon_label := Label.new()
	icon_label.text = "◇"
	icon_label.position = Vector2(28.0, row_y)
	icon_label.size = Vector2(25.0, 23.0)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	icon_label.add_theme_font_size_override(
		"font_size",
		17
	)

	icon_label.add_theme_color_override(
		"font_color",
		Color(0.53, 0.55, 0.59, 1.0)
	)

	parent.add_child(icon_label)

	var title_label := Label.new()
	title_label.text = title_text
	title_label.position = Vector2(63.0, row_y)
	title_label.size = Vector2(200.0, 23.0)

	title_label.add_theme_font_size_override(
		"font_size",
		13
	)

	title_label.add_theme_color_override(
		"font_color",
		Color(0.63, 0.65, 0.69, 1.0)
	)

	parent.add_child(title_label)

	var value_label := Label.new()
	value_label.text = initial_value
	value_label.position = Vector2(260.0, row_y)
	value_label.size = Vector2(106.0, 23.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	value_label.add_theme_font_size_override(
		"font_size",
		13
	)

	value_label.add_theme_color_override(
		"font_color",
		Color(0.86, 0.87, 0.90, 1.0)
	)

	parent.add_child(value_label)

	return value_label


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

	city_time_value.text = GameState.get_game_time_text()


func _on_active_call_changed(
	_call_text: String,
	_has_call: bool
) -> void:
	refresh_pause_information()


# -------------------------------------------------------------------
# BOTTOM HINTS
# -------------------------------------------------------------------

func create_bottom_hints() -> void:
	var esc_box := Panel.new()
	esc_box.position = Vector2(55.0, 957.0)
	esc_box.size = Vector2(40.0, 32.0)

	var key_style := StyleBoxFlat.new()
	key_style.bg_color = Color(0.02, 0.025, 0.03, 0.96)
	key_style.border_color = Color(0.55, 0.58, 0.64, 0.95)

	key_style.border_width_top = 1
	key_style.border_width_bottom = 1
	key_style.border_width_left = 1
	key_style.border_width_right = 1

	key_style.corner_radius_top_left = 4
	key_style.corner_radius_top_right = 4
	key_style.corner_radius_bottom_left = 4
	key_style.corner_radius_bottom_right = 4

	esc_box.add_theme_stylebox_override(
		"panel",
		key_style
	)

	design_canvas.add_child(esc_box)

	var esc_key_label := Label.new()
	esc_key_label.text = "ESC"
	esc_key_label.size = Vector2(40.0, 32.0)
	esc_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	esc_key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	esc_key_label.add_theme_font_size_override(
		"font_size",
		13
	)

	esc_key_label.add_theme_color_override(
		"font_color",
		Color(0.94, 0.95, 0.97, 1.0)
	)

	esc_box.add_child(esc_key_label)

	var back_label := Label.new()
	back_label.text = "BACK"
	back_label.position = Vector2(106.0, 959.0)
	back_label.size = Vector2(90.0, 30.0)

	back_label.add_theme_font_size_override(
		"font_size",
		16
	)

	back_label.add_theme_color_override(
		"font_color",
		Color(0.77, 0.78, 0.82, 1.0)
	)

	design_canvas.add_child(back_label)

	var f5_box := Panel.new()
	f5_box.position = Vector2(1331.0, 957.0)
	f5_box.size = Vector2(34.0, 32.0)
	f5_box.add_theme_stylebox_override(
		"panel",
		key_style
	)

	design_canvas.add_child(f5_box)

	var f5_key_label := Label.new()
	f5_key_label.text = "F5"
	f5_key_label.size = Vector2(34.0, 32.0)
	f5_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	f5_key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	f5_key_label.add_theme_font_size_override(
		"font_size",
		13
	)

	f5_key_label.add_theme_color_override(
		"font_color",
		Color(0.94, 0.95, 0.97, 1.0)
	)

	f5_box.add_child(f5_key_label)

	var quick_save_label := Label.new()
	quick_save_label.text = "QUICK SAVE"
	quick_save_label.position = Vector2(1377.0, 959.0)
	quick_save_label.size = Vector2(130.0, 30.0)

	quick_save_label.add_theme_font_size_override(
		"font_size",
		16
	)

	quick_save_label.add_theme_color_override(
		"font_color",
		Color(0.77, 0.78, 0.82, 1.0)
	)

	design_canvas.add_child(quick_save_label)


# -------------------------------------------------------------------
# INFORMATION MODAL
# -------------------------------------------------------------------

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

	var modal_style := StyleBoxFlat.new()
	modal_style.bg_color = Color(0.01, 0.018, 0.03, 0.99)
	modal_style.border_color = Color(0.0, 0.59, 1.0, 0.95)

	modal_style.border_width_top = 2
	modal_style.border_width_bottom = 2
	modal_style.border_width_left = 2
	modal_style.border_width_right = 2

	modal_style.corner_radius_top_left = 6
	modal_style.corner_radius_top_right = 6
	modal_style.corner_radius_bottom_left = 6
	modal_style.corner_radius_bottom_right = 6

	modal_panel.add_theme_stylebox_override(
		"panel",
		modal_style
	)

	design_canvas.add_child(modal_panel)

	modal_title_label = Label.new()
	modal_title_label.position = Vector2(35.0, 28.0)
	modal_title_label.size = Vector2(530.0, 34.0)
	modal_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	modal_title_label.add_theme_font_size_override(
		"font_size",
		23
	)

	modal_title_label.add_theme_color_override(
		"font_color",
		Color(0.95, 0.97, 1.0, 1.0)
	)

	modal_panel.add_child(modal_title_label)

	modal_body_label = Label.new()
	modal_body_label.position = Vector2(52.0, 88.0)
	modal_body_label.size = Vector2(496.0, 150.0)
	modal_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	modal_body_label.add_theme_font_size_override(
		"font_size",
		16
	)

	modal_body_label.add_theme_color_override(
		"font_color",
		Color(0.72, 0.77, 0.84, 1.0)
	)

	modal_panel.add_child(modal_body_label)

	var back_button := Button.new()
	back_button.text = "BACK"
	back_button.position = Vector2(240.0, 266.0)
	back_button.size = Vector2(120.0, 42.0)
	back_button.pressed.connect(hide_information_modal)

	modal_panel.add_child(back_button)


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


# -------------------------------------------------------------------
# SAVE TOAST
# -------------------------------------------------------------------

func create_save_toast() -> void:
	save_toast_panel = Panel.new()
	save_toast_panel.position = Vector2(1190.0, 900.0)
	save_toast_panel.size = Vector2(290.0, 48.0)
	save_toast_panel.visible = false
	save_toast_panel.z_index = 45

	var toast_style := StyleBoxFlat.new()
	toast_style.bg_color = Color(0.01, 0.06, 0.12, 0.97)
	toast_style.border_color = Color(0.0, 0.65, 1.0, 1.0)

	toast_style.border_width_top = 1
	toast_style.border_width_bottom = 1
	toast_style.border_width_left = 4
	toast_style.border_width_right = 1

	toast_style.corner_radius_top_left = 4
	toast_style.corner_radius_top_right = 4
	toast_style.corner_radius_bottom_left = 4
	toast_style.corner_radius_bottom_right = 4

	save_toast_panel.add_theme_stylebox_override(
		"panel",
		toast_style
	)

	design_canvas.add_child(save_toast_panel)

	save_toast_label = Label.new()
	save_toast_label.size = Vector2(290.0, 48.0)
	save_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	save_toast_label.add_theme_font_size_override(
		"font_size",
		15
	)

	save_toast_label.add_theme_color_override(
		"font_color",
		Color(0.90, 0.96, 1.0, 1.0)
	)

	save_toast_panel.add_child(save_toast_label)

	save_toast_timer = Timer.new()
	save_toast_timer.one_shot = true
	save_toast_timer.wait_time = 2.2
	save_toast_timer.timeout.connect(
		_on_save_toast_timeout
	)

	add_child(save_toast_timer)


func show_save_toast(message_text: String) -> void:
	save_toast_label.text = message_text
	save_toast_panel.visible = true
	save_toast_timer.start()


func _on_save_toast_timeout() -> void:
	save_toast_panel.visible = false


# -------------------------------------------------------------------
# OPEN / CLOSE
# -------------------------------------------------------------------

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
	save_toast_panel.visible = false

	screen_root.visible = false
	pause_open = false

	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# -------------------------------------------------------------------
# BUTTON ACTIONS
# -------------------------------------------------------------------

func _on_resume_pressed() -> void:
	close_pause_menu()


func _on_settings_pressed() -> void:
	show_information_modal(
		"SETTINGS",
		"Graphics, audio, HUD, accessibility, and mouse sensitivity settings will be added to this screen."
	)


func _on_controls_pressed() -> void:
	show_information_modal(
		"CONTROLS",
		"WASD — Move\nMouse — Look\nE — Interact\nQ — Radio\nM — MDT\nEsc — Pause Menu"
	)


func _on_field_manual_pressed() -> void:
	show_information_modal(
		"FIELD MANUAL",
		"Police procedures, radio codes, call-response guidance, and academy tutorials will be available here."
	)


func _on_photo_mode_pressed() -> void:
	show_information_modal(
		"PHOTO MODE",
		"Photo Mode is not active in this development build."
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

	get_tree().paused = false
	pause_open = false
	screen_root.visible = false

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var change_result: Error = get_tree().change_scene_to_file(
		MAIN_MENU_SCENE_PATH
	)

	if change_result != OK:
		print(
			"Could not return to main menu. Error: "
			+ str(change_result)
		)


func _on_quit_game_pressed() -> void:
	if GameState.player_profile_created:
		GameState.save_active_career()

	get_tree().paused = false
	get_tree().quit()
