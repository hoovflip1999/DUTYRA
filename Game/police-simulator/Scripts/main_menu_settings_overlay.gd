extends Control

var blocker: ColorRect
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

var window_modes: Array[String] = [
	"windowed",
	"borderless",
	"fullscreen"
]

var resolution_values: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

var frame_limit_values: Array[int] = [
	30,
	60,
	120,
	144,
	165,
	240,
	0
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	create_overlay()
	create_settings_panel()

	get_viewport().size_changed.connect(
		update_panel_position
	)

	update_panel_position()
	visible = false


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		hide_overlay()
		get_viewport().set_input_as_handled()


func create_overlay() -> void:
	blocker = ColorRect.new()
	blocker.name = "SettingsBlocker"
	blocker.color = Color(
		0.0,
		0.0,
		0.0,
		0.82
	)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP

	add_child(blocker)

	blocker.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


func create_settings_panel() -> void:
	settings_panel = Panel.new()
	settings_panel.name = "MainMenuSettingsPanel"
	settings_panel.size = Vector2(
		1080.0,
		720.0
	)
	settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	settings_panel.add_theme_stylebox_override(
		"panel",
		create_panel_style(
			Color(
				0.006,
				0.012,
				0.022,
				0.99
			),
			Color(
				0.0,
				0.58,
				1.0,
				0.95
			),
			2,
			8
		)
	)

	add_child(settings_panel)

	create_label(
		"SETTINGS",
		Vector2(38.0, 24.0),
		Vector2(500.0, 38.0),
		27,
		Color(
			0.95,
			0.97,
			1.0,
			1.0
		)
	)

	create_label(
		"Changes are saved and applied automatically.",
		Vector2(40.0, 62.0),
		Vector2(600.0, 25.0),
		14,
		Color(
			0.58,
			0.63,
			0.70,
			1.0
		)
	)

	var close_button: Button = Button.new()
	close_button.text = "X"
	close_button.position = Vector2(
		1010.0,
		24.0
	)
	close_button.size = Vector2(
		42.0,
		38.0
	)
	close_button.pressed.connect(
		hide_overlay
	)

	settings_panel.add_child(
		close_button
	)

	create_horizontal_line(
		94.0
	)

	create_display_settings()
	create_graphics_settings()
	create_audio_settings()
	create_gameplay_settings()

	create_horizontal_line(
		632.0
	)

	var reset_button: Button = Button.new()
	reset_button.text = "RESET DEFAULTS"
	reset_button.position = Vector2(
		40.0,
		654.0
	)
	reset_button.size = Vector2(
		180.0,
		42.0
	)
	reset_button.pressed.connect(
		_on_reset_settings_pressed
	)

	settings_panel.add_child(
		reset_button
	)

	var back_button: Button = Button.new()
	back_button.text = "BACK"
	back_button.position = Vector2(
		900.0,
		654.0
	)
	back_button.size = Vector2(
		140.0,
		42.0
	)
	back_button.pressed.connect(
		hide_overlay
	)

	settings_panel.add_child(
		back_button
	)


func create_display_settings() -> void:
	create_section_title(
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

	window_mode_option.add_item(
		"WINDOWED"
	)

	window_mode_option.add_item(
		"BORDERLESS"
	)

	window_mode_option.add_item(
		"FULLSCREEN"
	)

	window_mode_option.item_selected.connect(
		_on_window_mode_selected
	)

	resolution_option = OptionButton.new()

	create_option_row(
		"RESOLUTION",
		"Used while playing in windowed mode.",
		Vector2(40.0, 208.0),
		resolution_option
	)

	for resolution: Vector2i in resolution_values:
		resolution_option.add_item(
			str(resolution.x)
			+ " × "
			+ str(resolution.y)
		)

	resolution_option.item_selected.connect(
		_on_resolution_selected
	)

	vsync_toggle = CheckButton.new()

	create_toggle_row(
		"VERTICAL SYNC",
		"Helps prevent visible screen tearing.",
		Vector2(40.0, 268.0),
		vsync_toggle
	)

	vsync_toggle.toggled.connect(
		_on_vsync_toggled
	)

	frame_limit_option = OptionButton.new()

	create_option_row(
		"FRAME-RATE LIMIT",
		"Maximum frames rendered each second.",
		Vector2(40.0, 328.0),
		frame_limit_option
	)

	for frame_limit: int in frame_limit_values:
		if frame_limit == 0:
			frame_limit_option.add_item(
				"UNLIMITED"
			)
		else:
			frame_limit_option.add_item(
				str(frame_limit)
				+ " FPS"
			)

	frame_limit_option.item_selected.connect(
		_on_frame_limit_selected
	)


func create_graphics_settings() -> void:
	create_section_title(
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

	render_scale_slider.value_changed.connect(
		_on_render_scale_changed
	)


func create_audio_settings() -> void:
	create_section_title(
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

	master_volume_slider.value_changed.connect(
		_on_master_volume_changed
	)

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

	music_volume_slider.value_changed.connect(
		_on_music_volume_changed
	)

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

	sfx_volume_slider.value_changed.connect(
		_on_sfx_volume_changed
	)

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

	radio_volume_slider.value_changed.connect(
		_on_radio_volume_changed
	)


func create_gameplay_settings() -> void:
	create_section_title(
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


func create_section_title(
	title_text: String,
	title_position: Vector2
) -> void:
	create_label(
		title_text,
		title_position,
		Vector2(350.0, 28.0),
		16,
		Color(
			0.10,
			0.62,
			1.0,
			1.0
		)
	)


func create_setting_text(
	title_text: String,
	subtitle_text: String,
	row_position: Vector2
) -> void:
	create_label(
		title_text,
		row_position,
		Vector2(245.0, 24.0),
		14,
		Color(
			0.91,
			0.93,
			0.97,
			1.0
		)
	)

	create_label(
		subtitle_text,
		Vector2(
			row_position.x,
			row_position.y + 25.0
		),
		Vector2(265.0, 24.0),
		11,
		Color(
			0.52,
			0.57,
			0.64,
			1.0
		)
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

	option.size = Vector2(
		200.0,
		42.0
	)

	settings_panel.add_child(
		option
	)


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

	toggle.size = Vector2(
		145.0,
		42.0
	)

	settings_panel.add_child(
		toggle
	)


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

	slider.size = Vector2(
		165.0,
		38.0
	)

	slider.min_value = minimum_value
	slider.max_value = maximum_value
	slider.step = step_value

	settings_panel.add_child(
		slider
	)

	value_label.position = Vector2(
		row_position.x + 420.0,
		row_position.y + 8.0
	)

	value_label.size = Vector2(
		60.0,
		30.0
	)

	value_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_RIGHT
	)

	value_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	value_label.add_theme_font_size_override(
		"font_size",
		14
	)

	value_label.add_theme_color_override(
		"font_color",
		Color(
			0.90,
			0.94,
			1.0,
			1.0
		)
	)

	settings_panel.add_child(
		value_label
	)


func create_label(
	text_value: String,
	position_value: Vector2,
	size_value: Vector2,
	font_size: int,
	font_color: Color
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

	settings_panel.add_child(
		label
	)

	return label


func create_horizontal_line(
	line_y: float
) -> void:
	var line: ColorRect = ColorRect.new()
	line.position = Vector2(
		25.0,
		line_y
	)
	line.size = Vector2(
		1030.0,
		1.0
	)
	line.color = Color(
		0.35,
		0.38,
		0.43,
		0.63
	)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE

	settings_panel.add_child(
		line
	)


func create_panel_style(
	background_color: Color,
	border_color: Color,
	border_width: int,
	corner_radius: int
) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color

	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.border_width_left = border_width
	style.border_width_right = border_width

	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius

	style.shadow_color = Color(
		0.0,
		0.0,
		0.0,
		0.70
	)
	style.shadow_size = 16

	return style


func show_overlay() -> void:
	load_settings_values()
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

	window_mode_option.grab_focus()


func hide_overlay() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func update_panel_position() -> void:
	if settings_panel == null:
		return

	var viewport_size: Vector2 = (
		get_viewport_rect().size
	)

	settings_panel.position = Vector2(
		(
			viewport_size.x
			- settings_panel.size.x
		) * 0.5,
		(
			viewport_size.y
			- settings_panel.size.y
		) * 0.5
	)


func load_settings_values() -> void:
	updating_settings = true

	var window_mode: String = str(
		SettingsManager.get_setting(
			"display",
			"window_mode",
			"windowed"
		)
	)

	var window_mode_index: int = (
		window_modes.find(
			window_mode
		)
	)

	if window_mode_index < 0:
		window_mode_index = 0

	window_mode_option.select(
		window_mode_index
	)

	resolution_option.disabled = (
		window_mode != "windowed"
	)

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

	var resolution_index: int = (
		resolution_values.find(
			current_resolution
		)
	)

	if resolution_index < 0:
		resolution_values.append(
			current_resolution
		)

		resolution_option.add_item(
			str(current_resolution.x)
			+ " × "
			+ str(current_resolution.y)
		)

		resolution_index = (
			resolution_values.size()
			- 1
		)

	resolution_option.select(
		resolution_index
	)

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

	var frame_limit_index: int = (
		frame_limit_values.find(
			frame_limit
		)
	)

	if frame_limit_index < 0:
		frame_limit_values.append(
			frame_limit
		)

		frame_limit_option.add_item(
			str(frame_limit)
			+ " FPS"
		)

		frame_limit_index = (
			frame_limit_values.size()
			- 1
		)

	frame_limit_option.select(
		frame_limit_index
	)

	var render_scale: float = float(
		SettingsManager.get_setting(
			"graphics",
			"render_scale",
			1.0
		)
	)

	render_scale_slider.value = (
		render_scale * 100.0
	)

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

	var sensitivity: float = (
		get_safe_mouse_sensitivity()
	)

	mouse_sensitivity_slider.value = (
		sensitivity * 1000.0
	)

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

	slider.value = float(
		percent
	)

	value_label.text = (
		str(percent)
		+ "%"
	)


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


func _on_window_mode_selected(
	index: int
) -> void:
	if (
		updating_settings
		or index < 0
		or index >= window_modes.size()
	):
		return

	var selected_mode: String = (
		window_modes[index]
	)

	SettingsManager.set_setting(
		"display",
		"window_mode",
		selected_mode
	)

	resolution_option.disabled = (
		selected_mode != "windowed"
	)


func _on_resolution_selected(
	index: int
) -> void:
	if (
		updating_settings
		or index < 0
		or index >= resolution_values.size()
	):
		return

	var resolution: Vector2i = (
		resolution_values[index]
	)

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


func _on_vsync_toggled(
	enabled: bool
) -> void:
	if updating_settings:
		return

	SettingsManager.set_setting(
		"display",
		"vsync",
		enabled
	)


func _on_frame_limit_selected(
	index: int
) -> void:
	if (
		updating_settings
		or index < 0
		or index >= frame_limit_values.size()
	):
		return

	SettingsManager.set_setting(
		"display",
		"frame_rate_limit",
		frame_limit_values[index]
	)


func _on_render_scale_changed(
	value: float
) -> void:
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


func _on_master_volume_changed(
	value: float
) -> void:
	update_volume_setting(
		"master_volume",
		value,
		master_volume_value
	)


func _on_music_volume_changed(
	value: float
) -> void:
	update_volume_setting(
		"music_volume",
		value,
		music_volume_value
	)


func _on_sfx_volume_changed(
	value: float
) -> void:
	update_volume_setting(
		"sfx_volume",
		value,
		sfx_volume_value
	)


func _on_radio_volume_changed(
	value: float
) -> void:
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


func _on_mouse_sensitivity_changed(
	value: float
) -> void:
	mouse_sensitivity_value.text = str(
		int(
			round(value)
		)
	)

	if updating_settings:
		return

	SettingsManager.set_setting(
		"gameplay",
		"mouse_sensitivity",
		value * 0.001
	)


func _on_reset_settings_pressed() -> void:
	SettingsManager.reset_all_settings()
	load_settings_values()
