extends Control

var background_texture: TextureRect
var dark_overlay: ColorRect

var continue_button: Button
var new_career_button: Button
var load_game_button: Button
var settings_button: Button
var credits_button: Button
var exit_button: Button

var profile_panel: Panel
var profile_rank_label: Label
var profile_name_label: Label
var profile_level_label: Label
var profile_xp_label: Label
var profile_xp_fill: ColorRect

var new_career_panel: Panel
var last_name_input: LineEdit
var new_career_error_label: Label
var new_career_preview_label: Label
var is_new_career_visible: bool = false

var info_panel: Panel
var info_title_label: Label
var info_body_label: Label
var is_info_panel_visible: bool = false

var menu_buttons: Array[Button] = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	create_background()
	create_left_menu()
	create_profile_box()
	create_new_career_panel()
	create_info_panel()
	refresh_menu_state()

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_new_career_visible:
			hide_new_career_panel()
			return

		if is_info_panel_visible:
			hide_info_panel()
			return

	if is_new_career_visible and event.is_action_pressed("ui_accept"):
		submit_new_career()

func create_background() -> void:
	background_texture = TextureRect.new()
	background_texture.name = "MainMenuBackground"
	background_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var background_path: String = "res://Art/Menu/dutyra_main_menu_background.png"

	if ResourceLoader.exists(background_path):
		background_texture.texture = load(background_path)
	else:
		print("MAIN MENU BACKGROUND NOT FOUND: " + background_path)

	add_child(background_texture)

	dark_overlay = ColorRect.new()
	dark_overlay.name = "MainMenuDarkOverlay"
	dark_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark_overlay.color = Color(0.0, 0.0, 0.0, 0.16)
	dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dark_overlay)

func create_left_menu() -> void:
	continue_button = create_menu_button(
		"CONTINUE",
		"Continue your current career",
		"",
		Vector2.ZERO,
		_on_continue_pressed
	)

	new_career_button = create_menu_button(
		"NEW CAREER",
		"Start a new patrol career",
		"",
		Vector2.ZERO,
		_on_new_career_pressed
	)

	load_game_button = create_menu_button(
		"LOAD GAME",
		"Load saved career",
		"",
		Vector2.ZERO,
		_on_load_game_pressed
	)

	settings_button = create_menu_button(
		"SETTINGS",
		"Game options",
		"",
		Vector2.ZERO,
		_on_settings_pressed
	)

	credits_button = create_menu_button(
		"CREDITS",
		"Development credits",
		"",
		Vector2.ZERO,
		_on_credits_pressed
	)

	exit_button = create_menu_button(
		"EXIT GAME",
		"Quit to desktop",
		"",
		Vector2.ZERO,
		_on_exit_pressed
	)

	update_menu_layout()

func create_menu_button(
	title_text: String,
	subtitle_text: String,
	_icon_text: String,
	button_position: Vector2,
	pressed_callable: Callable
) -> Button:
	var button := Button.new()
	button.name = title_text.replace(" ", "") + "Button"
	button.position = button_position
	button.size = Vector2(250, 54)
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(pressed_callable)

	button.add_theme_stylebox_override("normal", create_button_style(false, false))
	button.add_theme_stylebox_override("hover", create_button_style(true, false))
	button.add_theme_stylebox_override("pressed", create_button_style(true, false))
	button.add_theme_stylebox_override("disabled", create_button_style(false, true))

	add_child(button)
	menu_buttons.append(button)

	var blue_line := ColorRect.new()
	blue_line.name = "BlueLine"
	blue_line.position = Vector2(0, 0)
	blue_line.size = Vector2(4, 54)
	blue_line.color = Color(0.0, 0.60, 1.0, 0.95)
	blue_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(blue_line)

	var title_label := Label.new()
	title_label.name = "Title"
	title_label.text = title_text
	title_label.position = Vector2(20, 6)
	title_label.size = Vector2(215, 24)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override(
		"font_color",
		Color(0.96, 0.98, 1.0, 1.0)
	)
	button.add_child(title_label)

	var subtitle_label := Label.new()
	subtitle_label.name = "Subtitle"
	subtitle_label.text = subtitle_text
	subtitle_label.position = Vector2(20, 30)
	subtitle_label.size = Vector2(215, 18)
	subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subtitle_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	subtitle_label.add_theme_font_size_override("font_size", 11)
	subtitle_label.add_theme_color_override(
		"font_color",
		Color(0.62, 0.67, 0.74, 1.0)
	)
	button.add_child(subtitle_label)

	return button

func create_button_style(is_hovered: bool, is_disabled: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	if is_disabled:
		style.bg_color = Color(0.02, 0.025, 0.035, 0.36)
		style.border_color = Color(0.35, 0.38, 0.42, 0.28)
	else:
		style.bg_color = Color(0.015, 0.025, 0.04, 0.72)
		style.border_color = Color(0.62, 0.70, 0.80, 0.35)

	if is_hovered:
		style.bg_color = Color(0.015, 0.09, 0.18, 0.86)
		style.border_color = Color(0.0, 0.58, 1.0, 1.0)
		style.border_width_left = 4
	else:
		style.border_width_left = 1

	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_width_right = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4

	return style

func create_profile_box() -> void:
	profile_panel = Panel.new()
	profile_panel.name = "CareerProfileBox"
	profile_panel.position = Vector2(1185, 32)
	profile_panel.size = Vector2(365, 92)
	profile_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.02, 0.025, 0.035, 0.72)
	panel_style.border_color = Color(0.62, 0.70, 0.80, 0.35)
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.corner_radius_top_left = 5
	panel_style.corner_radius_top_right = 5
	panel_style.corner_radius_bottom_left = 5
	panel_style.corner_radius_bottom_right = 5
	profile_panel.add_theme_stylebox_override("panel", panel_style)

	add_child(profile_panel)

	var badge_box := Panel.new()
	badge_box.position = Vector2(16, 15)
	badge_box.size = Vector2(55, 62)
	badge_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.04, 0.045, 0.055, 0.9)
	badge_style.border_color = Color(0.45, 0.50, 0.58, 0.45)
	badge_style.border_width_top = 1
	badge_style.border_width_bottom = 1
	badge_style.border_width_left = 1
	badge_style.border_width_right = 1
	badge_box.add_theme_stylebox_override("panel", badge_style)

	profile_panel.add_child(badge_box)

	var badge_label := Label.new()
	badge_label.text = "D"
	badge_label.position = Vector2(0, 0)
	badge_label.size = Vector2(55, 62)
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_label.add_theme_font_size_override("font_size", 28)
	badge_label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	badge_box.add_child(badge_label)

	profile_rank_label = Label.new()
	profile_rank_label.text = "OFFICER"
	profile_rank_label.position = Vector2(90, 13)
	profile_rank_label.size = Vector2(190, 20)
	profile_rank_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_rank_label.add_theme_font_size_override("font_size", 13)
	profile_rank_label.add_theme_color_override("font_color", Color(0.25, 0.65, 1.0, 1.0))
	profile_panel.add_child(profile_rank_label)

	profile_name_label = Label.new()
	profile_name_label.text = "NO CAREER"
	profile_name_label.position = Vector2(90, 32)
	profile_name_label.size = Vector2(210, 26)
	profile_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_name_label.add_theme_font_size_override("font_size", 17)
	profile_name_label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
	profile_panel.add_child(profile_name_label)

	profile_xp_label = Label.new()
	profile_xp_label.text = "0 / 1,000 XP"
	profile_xp_label.position = Vector2(90, 59)
	profile_xp_label.size = Vector2(150, 20)
	profile_xp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_xp_label.add_theme_font_size_override("font_size", 13)
	profile_xp_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.82, 1.0))
	profile_panel.add_child(profile_xp_label)

	var level_text_label := Label.new()
	level_text_label.text = "LEVEL"
	level_text_label.position = Vector2(288, 22)
	level_text_label.size = Vector2(55, 20)
	level_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_text_label.add_theme_font_size_override("font_size", 12)
	level_text_label.add_theme_color_override("font_color", Color(0.55, 0.58, 0.65, 1.0))
	profile_panel.add_child(level_text_label)

	profile_level_label = Label.new()
	profile_level_label.text = "01"
	profile_level_label.position = Vector2(288, 40)
	profile_level_label.size = Vector2(55, 28)
	profile_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	profile_level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_level_label.add_theme_font_size_override("font_size", 24)
	profile_level_label.add_theme_color_override("font_color", Color(0.25, 0.78, 1.0, 1.0))
	profile_panel.add_child(profile_level_label)

	var xp_back := ColorRect.new()
	xp_back.position = Vector2(90, 78)
	xp_back.size = Vector2(250, 5)
	xp_back.color = Color(0.1, 0.11, 0.13, 0.9)
	xp_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_panel.add_child(xp_back)

	profile_xp_fill = ColorRect.new()
	profile_xp_fill.position = Vector2(90, 78)
	profile_xp_fill.size = Vector2(0, 5)
	profile_xp_fill.color = Color(0.0, 0.62, 1.0, 1.0)
	profile_xp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_panel.add_child(profile_xp_fill)

func create_new_career_panel() -> void:
	new_career_panel = Panel.new()
	new_career_panel.name = "NewCareerPanel"
	new_career_panel.size = Vector2(520, 270)
	new_career_panel.visible = false
	new_career_panel.z_index = 50
	new_career_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.015, 0.025, 0.04, 0.97)
	panel_style.border_color = Color(0.0, 0.58, 1.0, 0.95)
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	new_career_panel.add_theme_stylebox_override("panel", panel_style)

	add_child(new_career_panel)

	var title := Label.new()
	title.text = "CREATE OFFICER PROFILE"
	title.position = Vector2(30, 20)
	title.size = Vector2(460, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override(
		"font_color",
		Color(0.95, 0.98, 1.0, 1.0)
	)
	new_career_panel.add_child(title)

	var last_name_label := Label.new()
	last_name_label.text = "LAST NAME"
	last_name_label.position = Vector2(58, 70)
	last_name_label.size = Vector2(180, 22)
	last_name_label.add_theme_font_size_override("font_size", 13)
	last_name_label.add_theme_color_override(
		"font_color",
		Color(0.25, 0.65, 1.0, 1.0)
	)
	new_career_panel.add_child(last_name_label)

	last_name_input = LineEdit.new()
	last_name_input.position = Vector2(58, 96)
	last_name_input.size = Vector2(404, 40)
	last_name_input.placeholder_text = "Enter last name"
	last_name_input.max_length = 24
	last_name_input.text_changed.connect(_on_last_name_text_changed)
	new_career_panel.add_child(last_name_input)

	new_career_preview_label = Label.new()
	new_career_preview_label.text = "Rookie Officer"
	new_career_preview_label.position = Vector2(58, 148)
	new_career_preview_label.size = Vector2(404, 24)
	new_career_preview_label.add_theme_font_size_override("font_size", 14)
	new_career_preview_label.add_theme_color_override(
		"font_color",
		Color(0.86, 0.96, 1.0, 1.0)
	)
	new_career_panel.add_child(new_career_preview_label)

	new_career_error_label = Label.new()
	new_career_error_label.text = ""
	new_career_error_label.position = Vector2(58, 180)
	new_career_error_label.size = Vector2(400, 26)
	new_career_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	new_career_error_label.add_theme_font_size_override("font_size", 13)
	new_career_error_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.35, 0.35, 1.0)
	)
	new_career_panel.add_child(new_career_error_label)

	var back_button := Button.new()
	back_button.text = "BACK"
	back_button.position = Vector2(278, 216)
	back_button.size = Vector2(86, 38)
	back_button.pressed.connect(hide_new_career_panel)
	new_career_panel.add_child(back_button)

	var create_button := Button.new()
	create_button.text = "CREATE"
	create_button.position = Vector2(376, 216)
	create_button.size = Vector2(86, 38)
	create_button.pressed.connect(submit_new_career)
	new_career_panel.add_child(create_button)

func create_info_panel() -> void:
	info_panel = Panel.new()
	info_panel.name = "InfoPanel"
	info_panel.size = Vector2(600, 330)
	info_panel.visible = false
	info_panel.z_index = 50
	info_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.015, 0.025, 0.04, 0.96)
	panel_style.border_color = Color(0.62, 0.70, 0.80, 0.45)
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	info_panel.add_theme_stylebox_override("panel", panel_style)

	add_child(info_panel)

	info_title_label = Label.new()
	info_title_label.position = Vector2(35, 25)
	info_title_label.size = Vector2(530, 34)
	info_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_title_label.add_theme_font_size_override("font_size", 22)
	info_title_label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
	info_panel.add_child(info_title_label)

	info_body_label = Label.new()
	info_body_label.position = Vector2(45, 80)
	info_body_label.size = Vector2(510, 170)
	info_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_body_label.add_theme_font_size_override("font_size", 15)
	info_body_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.90, 1.0))
	info_panel.add_child(info_body_label)

	var back_button := Button.new()
	back_button.text = "BACK"
	back_button.position = Vector2(250, 265)
	back_button.size = Vector2(100, 38)
	back_button.pressed.connect(hide_info_panel)
	info_panel.add_child(back_button)

func refresh_menu_state() -> void:
	var has_profile: bool = GameState.player_profile_created

	continue_button.disabled = not has_profile
	load_game_button.disabled = not has_profile

	var continue_subtitle: Label = continue_button.get_node("Subtitle")
	var load_subtitle: Label = load_game_button.get_node("Subtitle")

	if has_profile:
		continue_subtitle.text = "Continue as " + GameState.get_officer_display_name()
		load_subtitle.text = "Load saved career"
	else:
		continue_subtitle.text = "No current career found"
		load_subtitle.text = "No saved career found"

	update_profile_box()

func update_profile_box() -> void:
	if not GameState.player_profile_created:
		profile_rank_label.text = "OFFICER"
		profile_name_label.text = "NO CAREER"
		profile_xp_label.text = "0 / " + str(GameState.promotion_eligibility_xp) + " XP"
		profile_level_label.text = "01"
		profile_xp_fill.size = Vector2(0, 5)
		return

	profile_rank_label.text = "OFFICER"
	profile_name_label.text = GameState.get_officer_display_name().to_upper()
	profile_xp_label.text = str(GameState.performance_xp) + " / " + str(GameState.promotion_eligibility_xp) + " XP"

	var level_number: int = max(1, GameState.current_rank_index)
	var level_text: String = str(level_number)

	if level_number < 10:
		level_text = "0" + level_text

	profile_level_label.text = level_text

	var xp_ratio: float = 0.0

	if GameState.promotion_eligibility_xp > 0:
		xp_ratio = clampf(float(GameState.performance_xp) / float(GameState.promotion_eligibility_xp), 0.0, 1.0)

	profile_xp_fill.size = Vector2(250.0 * xp_ratio, 5)

func show_new_career_panel() -> void:
	is_new_career_visible = true
	is_info_panel_visible = false
	info_panel.visible = false

	last_name_input.text = ""
	new_career_error_label.text = ""
	new_career_preview_label.text = "Preview: Rookie Officer"
	update_menu_layout()

	new_career_panel.visible = true
	last_name_input.grab_focus()

func hide_new_career_panel() -> void:
	is_new_career_visible = false
	new_career_panel.visible = false

func submit_new_career() -> void:
	var last_name: String = last_name_input.text.strip_edges()

	if last_name == "":
		new_career_error_label.text = "Enter a last name."
		last_name_input.grab_focus()
		return

	new_career_error_label.text = "Creating career..."

	GameState.create_player_profile("", last_name)

	if not GameState.player_profile_created:
		new_career_error_label.text = "The officer profile could not be created."
		return

	start_patrol()
func show_info_panel(title_text: String, body_text: String) -> void:
	is_info_panel_visible = true
	is_new_career_visible = false
	new_career_panel.visible = false

	info_title_label.text = title_text
	info_body_label.text = body_text
	update_menu_layout()
	info_panel.visible = true

func hide_info_panel() -> void:
	is_info_panel_visible = false
	info_panel.visible = false

func start_patrol() -> void:
	var patrol_scene_path: String = "res://Scenes/Main.tscn"

	if not ResourceLoader.exists(patrol_scene_path):
		new_career_error_label.text = "Patrol scene not found: Scenes/Main.tscn"
		return

	var patrol_scene: PackedScene = load(patrol_scene_path) as PackedScene

	if patrol_scene == null:
		new_career_error_label.text = "Patrol scene failed to load. Check the Debugger."
		return

	get_tree().paused = false

	await get_tree().process_frame

	var scene_change_result: Error = get_tree().change_scene_to_packed(
		patrol_scene
	)

	if scene_change_result != OK:
		new_career_error_label.text = (
			"Could not enter patrol. Error code: "
			+ str(scene_change_result)
		)

func _on_continue_pressed() -> void:
	if not GameState.player_profile_created:
		return

	start_patrol()

func _on_new_career_pressed() -> void:
	show_new_career_panel()

func _on_load_game_pressed() -> void:
	if not GameState.player_profile_created:
		return

	start_patrol()

func _on_settings_pressed() -> void:
	show_info_panel(
		"SETTINGS",
		"Settings are not active yet.\n\nFuture settings will include mouse sensitivity, graphics, audio, controls, HUD options, and accessibility."
	)

func _on_credits_pressed() -> void:
	show_info_panel(
		"CREDITS",
		"DUTYRA™\nThe open-world police career simulator.\n\nDevelopment build.\nMore credits will be added later."
	)

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_last_name_text_changed(new_text: String) -> void:
	var clean_name: String = new_text.strip_edges()

	new_career_error_label.text = ""

	if clean_name == "":
		new_career_preview_label.text = "Rookie Officer"
	else:
		new_career_preview_label.text = "Rookie Officer " + clean_name

func _on_viewport_size_changed() -> void:
	update_menu_layout()

func update_menu_layout() -> void:
	var screen_size: Vector2 = get_viewport_rect().size

	var button_x: float = 12.0
	var button_width: float = 250.0
	var button_height: float = 54.0

	# Normal spacing from Continue through Credits.
	var regular_gap: float = 12.0

	# Larger spacing only between Credits and Exit Game.
	var credits_exit_gap: float = 32.0
	var bottom_margin: float = 18.0

	var exit_button_y: float = screen_size.y - button_height - bottom_margin

	var main_button_count: int = mini(menu_buttons.size(), 5)
	var main_group_height: float = (
		float(main_button_count) * button_height
		+ float(maxi(main_button_count - 1, 0)) * regular_gap
	)

	# Preferred lower position, but prevents Credits from overlapping Exit.
	var preferred_start_y: float = screen_size.y * 0.37
	var latest_safe_start_y: float = (
		exit_button_y
		- credits_exit_gap
		- main_group_height
	)

	var start_y: float = minf(
		preferred_start_y,
		latest_safe_start_y
	)

	start_y = maxf(start_y, 140.0)

	# Continue, New Career, Load Game, Settings, Credits.
	for i in range(main_button_count):
		var button: Button = menu_buttons[i]

		button.position = Vector2(
			button_x,
			start_y + float(i) * (button_height + regular_gap)
		)

		button.size = Vector2(button_width, button_height)

		var blue_line: ColorRect = button.get_node_or_null("BlueLine")

		if blue_line != null:
			blue_line.position = Vector2.ZERO
			blue_line.size = Vector2(4, button_height)

	# Exit Game stays near the bottom with a separate gap.
	if menu_buttons.size() > 5:
		var exit_menu_button: Button = menu_buttons[5]

		exit_menu_button.position = Vector2(
			button_x,
			exit_button_y
		)

		exit_menu_button.size = Vector2(
			button_width,
			button_height
		)

		var exit_blue_line: ColorRect = exit_menu_button.get_node_or_null("BlueLine")

		if exit_blue_line != null:
			exit_blue_line.position = Vector2.ZERO
			exit_blue_line.size = Vector2(4, button_height)

	if profile_panel != null:
		profile_panel.position = Vector2(
			screen_size.x - profile_panel.size.x - 28.0,
			28.0
		)

	if new_career_panel != null:
		new_career_panel.position = Vector2(
			(screen_size.x - new_career_panel.size.x) * 0.5,
			(screen_size.y - new_career_panel.size.y) * 0.5
		)

	if info_panel != null:
		info_panel.position = Vector2(
			(screen_size.x - info_panel.size.x) * 0.5,
			(screen_size.y - info_panel.size.y) * 0.5
		)
