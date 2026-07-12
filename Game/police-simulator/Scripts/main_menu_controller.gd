extends Control

var background_texture: TextureRect
var dark_overlay: ColorRect
var modal_overlay: ColorRect

var continue_button: Button
var new_career_button: Button
var load_game_button: Button
var settings_button: Button
var credits_button: Button
var exit_button: Button
var menu_buttons: Array[Button] = []

var profile_panel: Panel
var profile_rank_label: Label
var profile_name_label: Label
var profile_level_label: Label
var profile_xp_label: Label
var profile_xp_fill: ColorRect

var new_career_panel: Panel
var last_name_input: LineEdit
var new_career_preview_label: Label
var new_career_error_label: Label

var slot_panel: Panel
var slot_title_label: Label
var slot_content: Control
var slot_status_label: Label
var slot_mode: String = ""
var pending_last_name: String = ""

var confirmation_panel: Panel
var confirmation_title_label: Label
var confirmation_body_label: Label
var confirmation_button: Button
var confirmation_action: String = ""
var confirmation_slot: int = 0

var info_panel: Panel
var info_title_label: Label
var info_body_label: Label
var main_menu_settings_overlay

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	create_background()
	create_left_menu()
	create_profile_box()

	create_modal_overlay()
	create_new_career_panel()
	create_slot_panel()
	create_confirmation_panel()
	create_info_panel()
	create_main_menu_settings_overlay()
	GameState.player_profile_changed.connect(_on_profile_changed)
	GameState.career_progress_changed.connect(_on_career_progress_changed)
	GameState.save_slots_changed.connect(_on_save_slots_changed)

	get_viewport().size_changed.connect(_on_viewport_size_changed)

	refresh_menu_state()
	update_menu_layout()

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if confirmation_panel.visible:
			hide_confirmation()
			return

		if slot_panel.visible:
			_on_slot_back_pressed()
			return

		if new_career_panel.visible:
			close_all_modal_panels()
			return

		if info_panel.visible:
			close_all_modal_panels()
			return

	if event.is_action_pressed("ui_accept"):
		if confirmation_panel.visible:
			_on_confirmation_pressed()
			return

		if new_career_panel.visible:
			_on_new_career_next_pressed()
			return


# -------------------------------------------------------------------
# BACKGROUND
# -------------------------------------------------------------------

func create_background() -> void:
	background_texture = TextureRect.new()
	background_texture.name = "MainMenuBackground"
	background_texture.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var background_path: String = (
		"res://Art/Menu/dutyra_main_menu_background.png"
	)

	if ResourceLoader.exists(background_path):
		background_texture.texture = load(background_path)
	else:
		print(
			"MAIN MENU BACKGROUND NOT FOUND: "
			+ background_path
		)

	add_child(background_texture)

	dark_overlay = ColorRect.new()
	dark_overlay.name = "MainMenuDarkOverlay"
	dark_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	dark_overlay.color = Color(0.0, 0.0, 0.0, 0.12)
	dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dark_overlay)


func create_modal_overlay() -> void:
	modal_overlay = ColorRect.new()
	modal_overlay.name = "ModalOverlay"
	modal_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	modal_overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	modal_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_overlay.visible = false
	modal_overlay.z_index = 40
	add_child(modal_overlay)


# -------------------------------------------------------------------
# LEFT MENU
# -------------------------------------------------------------------

func create_left_menu() -> void:
	continue_button = create_menu_button(
		"CONTINUE",
		"Continue your current career",
		_on_continue_pressed
	)

	new_career_button = create_menu_button(
		"NEW CAREER",
		"Start a new patrol career",
		_on_new_career_pressed
	)

	load_game_button = create_menu_button(
		"LOAD GAME",
		"Choose a saved career",
		_on_load_game_pressed
	)

	settings_button = create_menu_button(
		"SETTINGS",
		"Game options",
		_on_settings_pressed
	)

	credits_button = create_menu_button(
		"CREDITS",
		"Development credits",
		_on_credits_pressed
	)

	exit_button = create_menu_button(
		"EXIT GAME",
		"Quit to desktop",
		_on_exit_pressed
	)


func create_menu_button(
	title_text: String,
	subtitle_text: String,
	pressed_callable: Callable
) -> Button:
	var button := Button.new()

	button.name = title_text.replace(" ", "") + "Button"
	button.size = Vector2(250, 54)
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(pressed_callable)

	button.add_theme_stylebox_override(
		"normal",
		create_menu_button_style(false, false)
	)

	button.add_theme_stylebox_override(
		"hover",
		create_menu_button_style(true, false)
	)

	button.add_theme_stylebox_override(
		"pressed",
		create_menu_button_style(true, false)
	)

	button.add_theme_stylebox_override(
		"disabled",
		create_menu_button_style(false, true)
	)

	add_child(button)
	menu_buttons.append(button)

	var blue_line := ColorRect.new()
	blue_line.name = "BlueLine"
	blue_line.position = Vector2.ZERO
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
	subtitle_label.text_overrun_behavior = (
		TextServer.OVERRUN_TRIM_ELLIPSIS
	)
	subtitle_label.add_theme_font_size_override("font_size", 11)
	subtitle_label.add_theme_color_override(
		"font_color",
		Color(0.62, 0.67, 0.74, 1.0)
	)
	button.add_child(subtitle_label)

	return button


func create_menu_button_style(
	is_hovered: bool,
	is_disabled: bool
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	if is_disabled:
		style.bg_color = Color(0.02, 0.025, 0.035, 0.32)
		style.border_color = Color(0.30, 0.34, 0.40, 0.22)
	else:
		style.bg_color = Color(0.015, 0.025, 0.04, 0.70)
		style.border_color = Color(0.62, 0.70, 0.80, 0.35)

	if is_hovered and not is_disabled:
		style.bg_color = Color(0.015, 0.09, 0.18, 0.88)
		style.border_color = Color(0.0, 0.58, 1.0, 1.0)

	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_width_left = 1
	style.border_width_right = 1

	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4

	return style


# -------------------------------------------------------------------
# TOP-RIGHT PROFILE
# -------------------------------------------------------------------

func create_profile_box() -> void:
	profile_panel = Panel.new()
	profile_panel.name = "CareerProfileBox"
	profile_panel.size = Vector2(365, 92)
	profile_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel_style := create_panel_style(
		Color(0.02, 0.025, 0.035, 0.76),
		Color(0.62, 0.70, 0.80, 0.38)
	)

	profile_panel.add_theme_stylebox_override(
		"panel",
		panel_style
	)

	add_child(profile_panel)

	var badge_box := Panel.new()
	badge_box.position = Vector2(16, 15)
	badge_box.size = Vector2(55, 62)
	badge_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var badge_style := create_panel_style(
		Color(0.04, 0.045, 0.055, 0.92),
		Color(0.45, 0.50, 0.58, 0.48)
	)

	badge_box.add_theme_stylebox_override(
		"panel",
		badge_style
	)

	profile_panel.add_child(badge_box)

	var badge_label := Label.new()
	badge_label.text = "D"
	badge_label.size = Vector2(55, 62)
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_label.add_theme_font_size_override("font_size", 28)
	badge_label.add_theme_color_override(
		"font_color",
		Color(0.86, 0.96, 1.0, 1.0)
	)
	badge_box.add_child(badge_label)

	profile_rank_label = Label.new()
	profile_rank_label.position = Vector2(90, 12)
	profile_rank_label.size = Vector2(190, 20)
	profile_rank_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_rank_label.add_theme_font_size_override("font_size", 12)
	profile_rank_label.add_theme_color_override(
		"font_color",
		Color(0.25, 0.68, 1.0, 1.0)
	)
	profile_panel.add_child(profile_rank_label)

	profile_name_label = Label.new()
	profile_name_label.position = Vector2(90, 31)
	profile_name_label.size = Vector2(205, 26)
	profile_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_name_label.text_overrun_behavior = (
		TextServer.OVERRUN_TRIM_ELLIPSIS
	)
	profile_name_label.add_theme_font_size_override("font_size", 16)
	profile_name_label.add_theme_color_override(
		"font_color",
		Color(0.95, 0.98, 1.0, 1.0)
	)
	profile_panel.add_child(profile_name_label)

	profile_xp_label = Label.new()
	profile_xp_label.position = Vector2(90, 58)
	profile_xp_label.size = Vector2(180, 20)
	profile_xp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_xp_label.add_theme_font_size_override("font_size", 12)
	profile_xp_label.add_theme_color_override(
		"font_color",
		Color(0.72, 0.76, 0.82, 1.0)
	)
	profile_panel.add_child(profile_xp_label)

	var level_title := Label.new()
	level_title.text = "LEVEL"
	level_title.position = Vector2(290, 19)
	level_title.size = Vector2(50, 18)
	level_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_title.add_theme_font_size_override("font_size", 11)
	level_title.add_theme_color_override(
		"font_color",
		Color(0.55, 0.58, 0.65, 1.0)
	)
	profile_panel.add_child(level_title)

	profile_level_label = Label.new()
	profile_level_label.position = Vector2(290, 37)
	profile_level_label.size = Vector2(50, 28)
	profile_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	profile_level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_level_label.add_theme_font_size_override("font_size", 23)
	profile_level_label.add_theme_color_override(
		"font_color",
		Color(0.25, 0.78, 1.0, 1.0)
	)
	profile_panel.add_child(profile_level_label)

	var xp_background := ColorRect.new()
	xp_background.position = Vector2(90, 79)
	xp_background.size = Vector2(250, 5)
	xp_background.color = Color(0.10, 0.11, 0.13, 0.92)
	xp_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_panel.add_child(xp_background)

	profile_xp_fill = ColorRect.new()
	profile_xp_fill.position = Vector2(90, 79)
	profile_xp_fill.size = Vector2(0, 5)
	profile_xp_fill.color = Color(0.0, 0.62, 1.0, 1.0)
	profile_xp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_panel.add_child(profile_xp_fill)


func update_profile_box() -> void:
	if not GameState.player_profile_created:
		profile_rank_label.text = "NO ACTIVE CAREER"
		profile_name_label.text = "SELECT OR CREATE CAREER"
		profile_xp_label.text = "0 / 500 XP"
		profile_level_label.text = "01"
		profile_xp_fill.size = Vector2(0, 5)
		return

	profile_rank_label.text = (
		"ACTIVE CAREER  •  SLOT "
		+ str(GameState.active_save_slot)
	)

	profile_name_label.text = (
		GameState.get_officer_display_name().to_upper()
	)

	profile_xp_label.text = (
		str(GameState.performance_xp)
		+ " / "
		+ str(GameState.promotion_eligibility_xp)
		+ " XP"
	)

	var level_number: int = maxi(
		GameState.current_rank_index,
		1
	)

	profile_level_label.text = str(level_number).pad_zeros(2)

	var xp_ratio: float = 0.0

	if GameState.promotion_eligibility_xp > 0:
		xp_ratio = clampf(
			float(GameState.performance_xp)
			/ float(GameState.promotion_eligibility_xp),
			0.0,
			1.0
		)

	profile_xp_fill.size = Vector2(
		250.0 * xp_ratio,
		5
	)


# -------------------------------------------------------------------
# NEW CAREER LAST-NAME SCREEN
# -------------------------------------------------------------------

func create_new_career_panel() -> void:
	new_career_panel = Panel.new()
	new_career_panel.name = "NewCareerPanel"
	new_career_panel.size = Vector2(520, 250)
	new_career_panel.visible = false
	new_career_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	new_career_panel.z_index = 50

	new_career_panel.add_theme_stylebox_override(
		"panel",
		create_panel_style(
			Color(0.015, 0.025, 0.04, 0.98),
			Color(0.0, 0.58, 1.0, 0.95)
		)
	)

	add_child(new_career_panel)

	var title_label := Label.new()
	title_label.text = "CREATE OFFICER PROFILE"
	title_label.position = Vector2(30, 20)
	title_label.size = Vector2(460, 32)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override(
		"font_color",
		Color(0.95, 0.98, 1.0, 1.0)
	)
	new_career_panel.add_child(title_label)

	var last_name_label := Label.new()
	last_name_label.text = "LAST NAME"
	last_name_label.position = Vector2(58, 69)
	last_name_label.size = Vector2(180, 22)
	last_name_label.add_theme_font_size_override("font_size", 13)
	last_name_label.add_theme_color_override(
		"font_color",
		Color(0.25, 0.68, 1.0, 1.0)
	)
	new_career_panel.add_child(last_name_label)

	last_name_input = LineEdit.new()
	last_name_input.position = Vector2(58, 96)
	last_name_input.size = Vector2(404, 40)
	last_name_input.placeholder_text = "Enter last name"
	last_name_input.max_length = 24
	last_name_input.text_changed.connect(
		_on_last_name_changed
	)
	new_career_panel.add_child(last_name_input)

	new_career_preview_label = Label.new()
	new_career_preview_label.text = "Rookie Officer"
	new_career_preview_label.position = Vector2(58, 145)
	new_career_preview_label.size = Vector2(404, 24)
	new_career_preview_label.add_theme_font_size_override(
		"font_size",
		14
	)
	new_career_preview_label.add_theme_color_override(
		"font_color",
		Color(0.86, 0.96, 1.0, 1.0)
	)
	new_career_panel.add_child(new_career_preview_label)

	new_career_error_label = Label.new()
	new_career_error_label.position = Vector2(58, 174)
	new_career_error_label.size = Vector2(240, 24)
	new_career_error_label.add_theme_font_size_override(
		"font_size",
		13
	)
	new_career_error_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.35, 0.35, 1.0)
	)
	new_career_panel.add_child(new_career_error_label)

	var back_button := Button.new()
	back_button.text = "BACK"
	back_button.position = Vector2(278, 200)
	back_button.size = Vector2(86, 36)
	back_button.pressed.connect(close_all_modal_panels)
	new_career_panel.add_child(back_button)

	var next_button := Button.new()
	next_button.text = "NEXT"
	next_button.position = Vector2(376, 200)
	next_button.size = Vector2(86, 36)
	next_button.pressed.connect(
		_on_new_career_next_pressed
	)
	new_career_panel.add_child(next_button)


func show_new_career_panel(
	clear_name: bool = true
) -> void:
	close_all_modal_panels()

	modal_overlay.visible = true
	new_career_panel.visible = true

	if clear_name:
		last_name_input.text = ""
		pending_last_name = ""

	new_career_error_label.text = ""
	update_new_career_preview()

	update_menu_layout()
	last_name_input.grab_focus()


func _on_last_name_changed(_new_text: String) -> void:
	new_career_error_label.text = ""
	update_new_career_preview()


func update_new_career_preview() -> void:
	var clean_name: String = (
		last_name_input.text.strip_edges()
	)

	if clean_name == "":
		new_career_preview_label.text = "Rookie Officer"
	else:
		new_career_preview_label.text = (
			"Rookie Officer " + clean_name
		)


func _on_new_career_next_pressed() -> void:
	var clean_name: String = (
		last_name_input.text.strip_edges()
	)

	if clean_name == "":
		new_career_error_label.text = "Enter a last name."
		last_name_input.grab_focus()
		return

	pending_last_name = clean_name
	show_slot_panel("new")


# -------------------------------------------------------------------
# LOAD / SAVE SLOT SCREEN
# -------------------------------------------------------------------

func create_slot_panel() -> void:
	slot_panel = Panel.new()
	slot_panel.name = "CareerSlotPanel"
	slot_panel.size = Vector2(760, 500)
	slot_panel.visible = false
	slot_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	slot_panel.z_index = 50

	slot_panel.add_theme_stylebox_override(
		"panel",
		create_panel_style(
			Color(0.012, 0.022, 0.038, 0.985),
			Color(0.0, 0.58, 1.0, 0.95)
		)
	)

	add_child(slot_panel)

	slot_title_label = Label.new()
	slot_title_label.position = Vector2(30, 20)
	slot_title_label.size = Vector2(700, 36)
	slot_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slot_title_label.add_theme_font_size_override(
		"font_size",
		23
	)
	slot_title_label.add_theme_color_override(
		"font_color",
		Color(0.95, 0.98, 1.0, 1.0)
	)
	slot_panel.add_child(slot_title_label)

	slot_content = Control.new()
	slot_content.position = Vector2(30, 70)
	slot_content.size = Vector2(700, 325)
	slot_panel.add_child(slot_content)

	slot_status_label = Label.new()
	slot_status_label.position = Vector2(30, 405)
	slot_status_label.size = Vector2(700, 28)
	slot_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slot_status_label.add_theme_font_size_override(
		"font_size",
		13
	)
	slot_status_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.42, 0.42, 1.0)
	)
	slot_panel.add_child(slot_status_label)

	var back_button := Button.new()
	back_button.text = "BACK"
	back_button.position = Vector2(30, 447)
	back_button.size = Vector2(120, 38)
	back_button.pressed.connect(_on_slot_back_pressed)
	slot_panel.add_child(back_button)


func show_slot_panel(requested_mode: String) -> void:
	close_all_modal_panels()

	slot_mode = requested_mode

	modal_overlay.visible = true
	slot_panel.visible = true
	slot_status_label.text = ""

	if slot_mode == "load":
		slot_title_label.text = "LOAD CAREER"
	else:
		slot_title_label.text = "SELECT CAREER SLOT"

	refresh_slot_panel()
	update_menu_layout()


func refresh_slot_panel() -> void:
	for child in slot_content.get_children():
		slot_content.remove_child(child)
		child.queue_free()

	create_slot_card(1, 0)
	create_slot_card(2, 165)


func create_slot_card(
	slot_number: int,
	card_y: float
) -> void:
	var slot_data: Dictionary = (
		GameState.get_save_slot_summary(slot_number)
	)

	var occupied: bool = bool(
		slot_data.get("occupied", false)
	)

	var card := Panel.new()
	card.position = Vector2(0, card_y)
	card.size = Vector2(700, 145)
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	var border_color := Color(
		0.46,
		0.56,
		0.68,
		0.55
	)

	if slot_number == GameState.active_save_slot:
		border_color = Color(
			0.0,
			0.68,
			1.0,
			0.95
		)

	var card_style := create_panel_style(
		Color(0.018, 0.035, 0.058, 0.94),
		border_color
	)

	card_style.border_width_left = 4

	card.add_theme_stylebox_override(
		"panel",
		card_style
	)

	slot_content.add_child(card)

	var slot_label := Label.new()
	slot_label.text = "CAREER SLOT " + str(slot_number)
	slot_label.position = Vector2(20, 13)
	slot_label.size = Vector2(300, 20)
	slot_label.add_theme_font_size_override("font_size", 12)
	slot_label.add_theme_color_override(
		"font_color",
		Color(0.25, 0.70, 1.0, 1.0)
	)
	card.add_child(slot_label)

	if slot_number == GameState.active_save_slot:
		var active_label := Label.new()
		active_label.text = "ACTIVE"
		active_label.position = Vector2(420, 13)
		active_label.size = Vector2(90, 20)
		active_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		active_label.add_theme_font_size_override(
			"font_size",
			11
		)
		active_label.add_theme_color_override(
			"font_color",
			Color(0.20, 0.90, 1.0, 1.0)
		)
		card.add_child(active_label)

	var name_label := Label.new()
	name_label.position = Vector2(20, 39)
	name_label.size = Vector2(480, 30)
	name_label.text_overrun_behavior = (
		TextServer.OVERRUN_TRIM_ELLIPSIS
	)
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override(
		"font_color",
		Color(0.96, 0.98, 1.0, 1.0)
	)
	card.add_child(name_label)

	var details_label := Label.new()
	details_label.position = Vector2(20, 75)
	details_label.size = Vector2(480, 58)
	details_label.add_theme_font_size_override("font_size", 13)
	details_label.add_theme_color_override(
		"font_color",
		Color(0.72, 0.79, 0.88, 1.0)
	)
	card.add_child(details_label)

	if occupied:
		name_label.text = str(
			slot_data.get(
				"display_name",
				"UNKNOWN OFFICER"
			)
		).to_upper()

		details_label.text = (
			"XP: "
			+ str(slot_data.get("performance_xp", 0))
			+ "     CALLS: "
			+ str(slot_data.get("calls_cleared", 0))
			+ "     SHIFTS: "
			+ str(slot_data.get("shifts_completed", 0))
			+ "\nLAST SAVE: "
			+ str(slot_data.get("date", ""))
			+ "  "
			+ str(slot_data.get("time", ""))
		)
	else:
		name_label.text = "EMPTY CAREER SLOT"
		details_label.text = (
			"No career is saved in this slot."
		)

	if slot_mode == "load":
		create_load_slot_controls(
			card,
			slot_number,
			occupied
		)
	else:
		create_new_slot_controls(
			card,
			slot_number,
			occupied
		)


func create_load_slot_controls(
	card: Panel,
	slot_number: int,
	occupied: bool
) -> void:
	var load_button := Button.new()
	load_button.text = "LOAD"
	load_button.position = Vector2(520, 25)
	load_button.size = Vector2(120, 42)
	load_button.disabled = not occupied
	load_button.pressed.connect(
		_on_load_slot_pressed.bind(slot_number)
	)
	card.add_child(load_button)

	var trash_button := Button.new()
	trash_button.text = "🗑"
	trash_button.tooltip_text = "Delete Career"
	trash_button.position = Vector2(650, 25)
	trash_button.size = Vector2(40, 42)
	trash_button.disabled = not occupied
	trash_button.focus_mode = Control.FOCUS_NONE
	trash_button.pressed.connect(
		_on_delete_slot_pressed.bind(slot_number)
	)

	trash_button.add_theme_font_size_override(
		"font_size",
		20
	)

	trash_button.add_theme_stylebox_override(
		"normal",
		create_red_button_style(false)
	)

	trash_button.add_theme_stylebox_override(
		"hover",
		create_red_button_style(true)
	)

	trash_button.add_theme_stylebox_override(
		"pressed",
		create_red_button_style(true)
	)

	trash_button.add_theme_color_override(
		"font_color",
		Color(1.0, 0.85, 0.85, 1.0)
	)

	card.add_child(trash_button)


func create_new_slot_controls(
	card: Panel,
	slot_number: int,
	occupied: bool
) -> void:
	var select_button := Button.new()

	if occupied:
		select_button.text = "OVERWRITE"
	else:
		select_button.text = "USE SLOT"

	select_button.position = Vector2(520, 48)
	select_button.size = Vector2(160, 44)
	select_button.pressed.connect(
		_on_new_slot_pressed.bind(
			slot_number,
			occupied
		)
	)

	card.add_child(select_button)


func _on_load_slot_pressed(slot_number: int) -> void:
	slot_status_label.text = ""

	if not GameState.load_career_slot(slot_number):
		slot_status_label.text = (
			"Career slot could not be loaded."
		)
		return

	start_patrol()


func _on_delete_slot_pressed(slot_number: int) -> void:
	var slot_data: Dictionary = (
		GameState.get_save_slot_summary(slot_number)
	)

	if not bool(slot_data.get("occupied", false)):
		return

	show_confirmation(
		"DELETE CAREER?",
		"This permanently deletes "
		+ str(slot_data.get("display_name", "this career"))
		+ " from Career Slot "
		+ str(slot_number)
		+ ".",
		"DELETE",
		"delete",
		slot_number
	)


func _on_new_slot_pressed(
	slot_number: int,
	occupied: bool
) -> void:
	if pending_last_name == "":
		slot_status_label.text = (
			"Officer last name is missing."
		)
		return

	if occupied:
		var slot_data: Dictionary = (
			GameState.get_save_slot_summary(slot_number)
		)

		show_confirmation(
			"OVERWRITE CAREER?",
			"Career Slot "
			+ str(slot_number)
			+ " currently contains "
			+ str(slot_data.get("display_name", "a career"))
			+ ". This save will be permanently replaced.",
			"OVERWRITE",
			"overwrite",
			slot_number
		)
		return

	create_career_in_slot(slot_number)


func create_career_in_slot(slot_number: int) -> void:
	if not GameState.create_new_career_in_slot(
		slot_number,
		pending_last_name
	):
		slot_status_label.text = (
			"Career could not be created."
		)
		return

	start_patrol()


func _on_slot_back_pressed() -> void:
	if slot_mode == "new":
		show_new_career_panel(false)
		return

	close_all_modal_panels()


# -------------------------------------------------------------------
# DELETE / OVERWRITE CONFIRMATION
# -------------------------------------------------------------------

func create_confirmation_panel() -> void:
	confirmation_panel = Panel.new()
	confirmation_panel.name = "ConfirmationPanel"
	confirmation_panel.size = Vector2(470, 230)
	confirmation_panel.visible = false
	confirmation_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	confirmation_panel.z_index = 60

	confirmation_panel.add_theme_stylebox_override(
		"panel",
		create_panel_style(
			Color(0.025, 0.018, 0.022, 0.99),
			Color(0.88, 0.16, 0.16, 0.95)
		)
	)

	add_child(confirmation_panel)

	confirmation_title_label = Label.new()
	confirmation_title_label.position = Vector2(25, 20)
	confirmation_title_label.size = Vector2(420, 32)
	confirmation_title_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	confirmation_title_label.add_theme_font_size_override(
		"font_size",
		21
	)
	confirmation_title_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.86, 0.86, 1.0)
	)
	confirmation_panel.add_child(
		confirmation_title_label
	)

	confirmation_body_label = Label.new()
	confirmation_body_label.position = Vector2(38, 68)
	confirmation_body_label.size = Vector2(394, 78)
	confirmation_body_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)
	confirmation_body_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	confirmation_body_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)
	confirmation_body_label.add_theme_font_size_override(
		"font_size",
		14
	)
	confirmation_body_label.add_theme_color_override(
		"font_color",
		Color(0.90, 0.91, 0.94, 1.0)
	)
	confirmation_panel.add_child(
		confirmation_body_label
	)

	var cancel_button := Button.new()
	cancel_button.text = "CANCEL"
	cancel_button.position = Vector2(130, 174)
	cancel_button.size = Vector2(100, 38)
	cancel_button.pressed.connect(hide_confirmation)
	confirmation_panel.add_child(cancel_button)

	confirmation_button = Button.new()
	confirmation_button.position = Vector2(242, 174)
	confirmation_button.size = Vector2(120, 38)
	confirmation_button.pressed.connect(
		_on_confirmation_pressed
	)

	confirmation_button.add_theme_stylebox_override(
		"normal",
		create_red_button_style(false)
	)

	confirmation_button.add_theme_stylebox_override(
		"hover",
		create_red_button_style(true)
	)

	confirmation_button.add_theme_stylebox_override(
		"pressed",
		create_red_button_style(true)
	)

	confirmation_panel.add_child(
		confirmation_button
	)


func show_confirmation(
	title_text: String,
	body_text: String,
	button_text: String,
	action_name: String,
	slot_number: int
) -> void:
	confirmation_title_label.text = title_text
	confirmation_body_label.text = body_text
	confirmation_button.text = button_text

	confirmation_action = action_name
	confirmation_slot = slot_number

	confirmation_panel.visible = true
	update_menu_layout()


func hide_confirmation() -> void:
	confirmation_panel.visible = false
	confirmation_action = ""
	confirmation_slot = 0


func _on_confirmation_pressed() -> void:
	if confirmation_action == "delete":
		var deleted: bool = GameState.delete_career_slot(
			confirmation_slot
		)

		hide_confirmation()

		if not deleted:
			slot_status_label.text = (
				"Career could not be deleted."
			)
			return

		GameState.load_last_active_slot()
		refresh_menu_state()
		refresh_slot_panel()
		return

	if confirmation_action == "overwrite":
		var overwrite_slot: int = confirmation_slot
		hide_confirmation()
		create_career_in_slot(overwrite_slot)


# -------------------------------------------------------------------
# SETTINGS / CREDITS
# -------------------------------------------------------------------
func create_main_menu_settings_overlay() -> void:
	main_menu_settings_overlay = preload(
		"res://Scripts/main_menu_settings_overlay.gd"
	).new()

	main_menu_settings_overlay.name = (
		"MainMenuSettingsOverlay"
	)

	add_child(
		main_menu_settings_overlay
	)
func create_info_panel() -> void:
	info_panel = Panel.new()
	info_panel.name = "InfoPanel"
	info_panel.size = Vector2(600, 330)
	info_panel.visible = false
	info_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	info_panel.z_index = 50

	info_panel.add_theme_stylebox_override(
		"panel",
		create_panel_style(
			Color(0.015, 0.025, 0.04, 0.98),
			Color(0.62, 0.70, 0.80, 0.48)
		)
	)

	add_child(info_panel)

	info_title_label = Label.new()
	info_title_label.position = Vector2(35, 25)
	info_title_label.size = Vector2(530, 34)
	info_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_title_label.add_theme_font_size_override("font_size", 22)
	info_title_label.add_theme_color_override(
		"font_color",
		Color(0.95, 0.98, 1.0, 1.0)
	)
	info_panel.add_child(info_title_label)

	info_body_label = Label.new()
	info_body_label.position = Vector2(45, 80)
	info_body_label.size = Vector2(510, 170)
	info_body_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)
	info_body_label.add_theme_font_size_override("font_size", 15)
	info_body_label.add_theme_color_override(
		"font_color",
		Color(0.75, 0.82, 0.90, 1.0)
	)
	info_panel.add_child(info_body_label)

	var back_button := Button.new()
	back_button.text = "BACK"
	back_button.position = Vector2(250, 265)
	back_button.size = Vector2(100, 38)
	back_button.pressed.connect(close_all_modal_panels)
	info_panel.add_child(back_button)


func show_info_panel(
	title_text: String,
	body_text: String
) -> void:
	close_all_modal_panels()

	modal_overlay.visible = true
	info_panel.visible = true
	info_title_label.text = title_text
	info_body_label.text = body_text

	update_menu_layout()


# -------------------------------------------------------------------
# MAIN MENU ACTIONS
# -------------------------------------------------------------------

func refresh_menu_state() -> void:
	var has_any_save: bool = (
		GameState.has_save_in_slot(1)
		or GameState.has_save_in_slot(2)
	)

	continue_button.disabled = (
		not GameState.player_profile_created
	)

	load_game_button.disabled = not has_any_save

	var continue_subtitle: Label = (
		continue_button.get_node("Subtitle")
	)

	var load_subtitle: Label = (
		load_game_button.get_node("Subtitle")
	)

	if GameState.player_profile_created:
		continue_subtitle.text = (
			"Continue as "
			+ GameState.get_officer_display_name()
		)
	else:
		continue_subtitle.text = "No active career"

	if has_any_save:
		load_subtitle.text = "Choose a saved career"
	else:
		load_subtitle.text = "No saved careers"

	update_profile_box()


func _on_continue_pressed() -> void:
	if not GameState.player_profile_created:
		return

	start_patrol()


func _on_new_career_pressed() -> void:
	show_new_career_panel(true)


func _on_load_game_pressed() -> void:
	show_slot_panel("load")


func _on_settings_pressed() -> void:
	close_all_modal_panels()
	main_menu_settings_overlay.show_overlay()


func _on_credits_pressed() -> void:
	show_info_panel(
		"CREDITS",
		"DUTYRA™\n\nOpen-world police career simulator.\n\nDevelopment build. Full development credits will be added later."
	)


func _on_exit_pressed() -> void:
	get_tree().quit()


func start_patrol() -> void:
	var patrol_scene_path: String = (
		"res://Scenes/Main.tscn"
	)

	if not ResourceLoader.exists(patrol_scene_path):
		show_info_panel(
			"LOAD ERROR",
			"Patrol scene was not found at:\n"
			+ patrol_scene_path
		)
		return

	get_tree().paused = false

	var change_result: Error = (
		get_tree().change_scene_to_file(
			patrol_scene_path
		)
	)

	if change_result != OK:
		show_info_panel(
			"LOAD ERROR",
			"Patrol could not be opened.\nError code: "
			+ str(change_result)
		)


func close_all_modal_panels() -> void:
	new_career_panel.visible = false
	slot_panel.visible = false
	confirmation_panel.visible = false
	info_panel.visible = false
	modal_overlay.visible = false

	slot_mode = ""
	confirmation_action = ""
	confirmation_slot = 0


# -------------------------------------------------------------------
# SIGNALS
# -------------------------------------------------------------------

func _on_profile_changed() -> void:
	refresh_menu_state()


func _on_career_progress_changed() -> void:
	refresh_menu_state()


func _on_save_slots_changed() -> void:
	refresh_menu_state()

	if slot_panel.visible:
		refresh_slot_panel()


func _on_viewport_size_changed() -> void:
	update_menu_layout()


# -------------------------------------------------------------------
# LAYOUT
# -------------------------------------------------------------------

func update_menu_layout() -> void:
	var screen_size: Vector2 = get_viewport_rect().size

	var button_x: float = 12.0
	var button_width: float = 250.0
	var button_height: float = 54.0
	var regular_gap: float = 12.0
	var credits_exit_gap: float = 32.0
	var bottom_margin: float = 18.0

	var exit_button_y: float = (
		screen_size.y
		- button_height
		- bottom_margin
	)

	var main_button_count: int = mini(
		menu_buttons.size(),
		5
	)

	var main_group_height: float = (
		float(main_button_count) * button_height
		+ float(maxi(main_button_count - 1, 0))
		* regular_gap
	)

	var preferred_start_y: float = screen_size.y * 0.40

	var latest_safe_start_y: float = (
		exit_button_y
		- credits_exit_gap
		- main_group_height
	)

	var start_y: float = minf(
		preferred_start_y,
		latest_safe_start_y
	)

	start_y = maxf(start_y, 120.0)

	for i in range(main_button_count):
		var button: Button = menu_buttons[i]

		button.position = Vector2(
			button_x,
			start_y
			+ float(i)
			* (button_height + regular_gap)
		)

		button.size = Vector2(
			button_width,
			button_height
		)

		var blue_line: ColorRect = (
			button.get_node_or_null("BlueLine")
		)

		if blue_line != null:
			blue_line.position = Vector2.ZERO
			blue_line.size = Vector2(
				4,
				button_height
			)

	if menu_buttons.size() > 5:
		exit_button.position = Vector2(
			button_x,
			exit_button_y
		)

		exit_button.size = Vector2(
			button_width,
			button_height
		)

		var exit_blue_line: ColorRect = (
			exit_button.get_node_or_null(
				"BlueLine"
			)
		)

		if exit_blue_line != null:
			exit_blue_line.position = Vector2.ZERO
			exit_blue_line.size = Vector2(
				4,
				button_height
			)

	if profile_panel != null:
		profile_panel.position = Vector2(
			screen_size.x
			- profile_panel.size.x
			- 28.0,
			28.0
		)

	center_panel(new_career_panel, screen_size)
	center_panel(slot_panel, screen_size)
	center_panel(confirmation_panel, screen_size)
	center_panel(info_panel, screen_size)


func center_panel(
	panel: Control,
	screen_size: Vector2
) -> void:
	if panel == null:
		return

	panel.position = Vector2(
		(screen_size.x - panel.size.x) * 0.5,
		(screen_size.y - panel.size.y) * 0.5
	)


# -------------------------------------------------------------------
# STYLE HELPERS
# -------------------------------------------------------------------

func create_panel_style(
	background_color: Color,
	border_color: Color
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	style.bg_color = background_color
	style.border_color = border_color

	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2

	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7

	return style


func create_red_button_style(
	is_hovered: bool
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	if is_hovered:
		style.bg_color = Color(0.55, 0.035, 0.035, 1.0)
		style.border_color = Color(1.0, 0.25, 0.25, 1.0)
	else:
		style.bg_color = Color(0.30, 0.025, 0.025, 0.98)
		style.border_color = Color(0.88, 0.14, 0.14, 1.0)

	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2

	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5

	return style
