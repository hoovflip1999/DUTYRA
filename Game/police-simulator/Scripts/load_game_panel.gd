extends Panel

signal load_requested()
signal delete_requested()
signal back_requested()

var officer_name_label: Label
var career_details_label: Label
var load_button: Button
var delete_button: Button
var back_button: Button
var status_label: Label

var delete_confirmation_active: bool = false


func _ready() -> void:
	name = "LoadGamePanel"
	size = Vector2(620, 360)
	visible = false
	z_index = 60
	mouse_filter = Control.MOUSE_FILTER_STOP

	create_panel_style()
	create_content()


func create_panel_style() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.012, 0.022, 0.038, 0.98)
	panel_style.border_color = Color(0.0, 0.58, 1.0, 0.95)
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8

	add_theme_stylebox_override("panel", panel_style)


func create_content() -> void:
	var title_label := Label.new()
	title_label.text = "LOAD CAREER"
	title_label.position = Vector2(30, 22)
	title_label.size = Vector2(560, 34)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 23)
	title_label.add_theme_color_override(
		"font_color",
		Color(0.95, 0.98, 1.0, 1.0)
	)
	add_child(title_label)

	var save_slot_panel := Panel.new()
	save_slot_panel.position = Vector2(40, 72)
	save_slot_panel.size = Vector2(540, 190)

	var slot_style := StyleBoxFlat.new()
	slot_style.bg_color = Color(0.02, 0.035, 0.055, 0.92)
	slot_style.border_color = Color(0.48, 0.60, 0.74, 0.48)
	slot_style.border_width_top = 1
	slot_style.border_width_bottom = 1
	slot_style.border_width_left = 4
	slot_style.border_width_right = 1
	slot_style.corner_radius_top_left = 5
	slot_style.corner_radius_top_right = 5
	slot_style.corner_radius_bottom_left = 5
	slot_style.corner_radius_bottom_right = 5
	save_slot_panel.add_theme_stylebox_override("panel", slot_style)

	add_child(save_slot_panel)

	var slot_title := Label.new()
	slot_title.text = "CAREER SAVE 01"
	slot_title.position = Vector2(22, 14)
	slot_title.size = Vector2(250, 22)
	slot_title.add_theme_font_size_override("font_size", 13)
	slot_title.add_theme_color_override(
		"font_color",
		Color(0.25, 0.70, 1.0, 1.0)
	)
	save_slot_panel.add_child(slot_title)

	officer_name_label = Label.new()
	officer_name_label.text = "NO CAREER"
	officer_name_label.position = Vector2(22, 42)
	officer_name_label.size = Vector2(480, 32)
	officer_name_label.add_theme_font_size_override("font_size", 21)
	officer_name_label.add_theme_color_override(
		"font_color",
		Color(0.96, 0.98, 1.0, 1.0)
	)
	save_slot_panel.add_child(officer_name_label)

	career_details_label = Label.new()
	career_details_label.position = Vector2(22, 82)
	career_details_label.size = Vector2(490, 92)
	career_details_label.add_theme_font_size_override("font_size", 14)
	career_details_label.add_theme_color_override(
		"font_color",
		Color(0.72, 0.79, 0.88, 1.0)
	)
	save_slot_panel.add_child(career_details_label)

	status_label = Label.new()
	status_label.text = ""
	status_label.position = Vector2(40, 273)
	status_label.size = Vector2(540, 24)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.42, 0.42, 1.0)
	)
	add_child(status_label)

	back_button = Button.new()
	back_button.text = "BACK"
	back_button.position = Vector2(40, 307)
	back_button.size = Vector2(120, 38)
	back_button.visible = true
	back_button.pressed.connect(_on_back_pressed)
	add_child(back_button)

	delete_button = Button.new()
	delete_button.text = "DELETE CAREER"
	delete_button.position = Vector2(175, 307)
	delete_button.size = Vector2(180, 38)
	delete_button.visible = true
	delete_button.pressed.connect(_on_delete_pressed)

	var delete_normal_style := StyleBoxFlat.new()
	delete_normal_style.bg_color = Color(0.28, 0.035, 0.035, 0.96)
	delete_normal_style.border_color = Color(0.85, 0.15, 0.15, 1.0)
	delete_normal_style.border_width_top = 2
	delete_normal_style.border_width_bottom = 2
	delete_normal_style.border_width_left = 2
	delete_normal_style.border_width_right = 2
	delete_normal_style.corner_radius_top_left = 5
	delete_normal_style.corner_radius_top_right = 5
	delete_normal_style.corner_radius_bottom_left = 5
	delete_normal_style.corner_radius_bottom_right = 5

	var delete_hover_style := delete_normal_style.duplicate()
	delete_hover_style.bg_color = Color(0.5, 0.045, 0.045, 1.0)
	delete_hover_style.border_color = Color(1.0, 0.25, 0.25, 1.0)

	delete_button.add_theme_stylebox_override(
		"normal",
		delete_normal_style
	)
	delete_button.add_theme_stylebox_override(
		"hover",
		delete_hover_style
	)
	delete_button.add_theme_stylebox_override(
		"pressed",
		delete_hover_style
	)
	delete_button.add_theme_color_override(
		"font_color",
		Color(1.0, 0.85, 0.85, 1.0)
	)

	add_child(delete_button)

	load_button = Button.new()
	load_button.text = "LOAD CAREER"
	load_button.position = Vector2(370, 307)
	load_button.size = Vector2(210, 38)
	load_button.visible = true
	load_button.pressed.connect(_on_load_pressed)
	add_child(load_button)


func refresh() -> void:
	delete_confirmation_active = false
	delete_button.text = "DELETE CAREER"
	status_label.text = ""

	var has_career: bool = GameState.player_profile_created
	load_button.visible = true
	delete_button.visible = true
	back_button.visible = true
	load_button.disabled = not has_career
	delete_button.disabled = not has_career

	if not has_career:
		officer_name_label.text = "EMPTY SAVE SLOT"
		career_details_label.text = "No officer career has been created."
		return

	officer_name_label.text = GameState.get_officer_display_name().to_upper()

	career_details_label.text = \
		"BADGE: " + GameState.officer_badge_number + \
		"     CALLSIGN: " + GameState.officer_callsign + "\n" + \
		"PERFORMANCE XP: " + str(GameState.performance_xp) + \
		" / " + str(GameState.promotion_eligibility_xp) + "\n" + \
		"CALLS CLEARED: " + str(GameState.calls_cleared) + \
		"     SHIFTS COMPLETED: " + str(GameState.shifts_completed) + "\n" + \
		"CAREER DATE: " + GameState.get_game_date_text() + \
		"     TIME: " + GameState.get_game_time_text()


func show_panel() -> void:
	refresh()
	visible = true


func hide_panel() -> void:
	delete_confirmation_active = false
	delete_button.text = "DELETE CAREER"
	status_label.text = ""
	visible = false


func update_position(screen_size: Vector2) -> void:
	position = Vector2(
		(screen_size.x - size.x) * 0.5,
		(screen_size.y - size.y) * 0.5
	)


func _on_load_pressed() -> void:
	if not GameState.player_profile_created:
		status_label.text = "No career save found."
		return

	load_requested.emit()


func _on_delete_pressed() -> void:
	if not GameState.player_profile_created:
		return

	if not delete_confirmation_active:
		delete_confirmation_active = true
		delete_button.text = "CONFIRM DELETE"
		status_label.text = "Press Confirm Delete again to permanently remove this career."
		return

	delete_requested.emit()


func _on_back_pressed() -> void:
	back_requested.emit()
