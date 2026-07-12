extends Node

signal settings_loaded
signal setting_changed(section: String, key: String, value: Variant)

const SETTINGS_PATH := "user://dutyra_settings.json"

const BASE_DEFAULT_SETTINGS := {
	"display": {
		"window_mode": "windowed",
		"resolution_width": 1920,
		"resolution_height": 1080,
		"vsync": true,
		"frame_rate_limit": 0
	},
	"graphics": {
		"quality_preset": "high",
		"shadow_quality": "high",
		"anti_aliasing": "taa",
		"render_scale": 1.0,
		"texture_filter": "high"
	},
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 0.9,
		"radio_volume": 0.9
	},
	"gameplay": {
		"mouse_sensitivity": 0.003,
		"invert_vertical_look": false,
		"hud_scale": 1.0,
		"subtitles": true,
		"camera_shake": true
	},
	"controls": {
		"move_forward": 87,
		"move_back": 83,
		"move_left": 65,
		"move_right": 68,
		"sprint": 4194325,
		"crouch": 4194326,
		"interact": 69,
		"toggle_flashlight": 84,
		"toggle_mdt": 77,
		"toggle_radio_menu": 81
	}
}
var settings: Dictionary = {}

func _ready() -> void:
	load_settings()
	call_deferred("apply_all_settings")


func _build_default_settings() -> Dictionary:
	var defaults: Dictionary = BASE_DEFAULT_SETTINGS.duplicate(true)

	var current_size := DisplayServer.window_get_size()

	defaults["display"]["resolution_width"] = current_size.x
	defaults["display"]["resolution_height"] = current_size.y
	defaults["display"]["frame_rate_limit"] = Engine.max_fps

	var current_mode := DisplayServer.window_get_mode()

	match current_mode:
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			defaults["display"]["window_mode"] = "fullscreen"

		DisplayServer.WINDOW_MODE_FULLSCREEN:
			defaults["display"]["window_mode"] = "borderless"

		_:
			defaults["display"]["window_mode"] = "windowed"

	var current_vsync := DisplayServer.window_get_vsync_mode()

	defaults["display"]["vsync"] = (
		current_vsync != DisplayServer.VSYNC_DISABLED
	)

	return defaults


func load_settings() -> void:
	settings = _build_default_settings()

	if not FileAccess.file_exists(SETTINGS_PATH):
		save_settings()
		settings_loaded.emit()
		return

	var file := FileAccess.open(
		SETTINGS_PATH,
		FileAccess.READ
	)

	if file == null:
		push_error(
			"SettingsManager could not open the settings file."
		)
		settings_loaded.emit()
		return

	var file_text := file.get_as_text()
	var json := JSON.new()
	var parse_result := json.parse(file_text)

	if parse_result != OK:
		push_error(
			"SettingsManager could not read the settings file: "
			+ json.get_error_message()
		)

		save_settings()
		settings_loaded.emit()
		return

	var loaded_data: Variant = json.data

	if loaded_data is Dictionary:
		_merge_dictionary(
			settings,
			loaded_data as Dictionary
		)
	else:
		push_error(
			"SettingsManager found invalid settings data."
		)

		save_settings()

	settings_loaded.emit()


func save_settings() -> void:
	var file := FileAccess.open(
		SETTINGS_PATH,
		FileAccess.WRITE
	)

	if file == null:
		push_error(
			"SettingsManager could not save the settings file."
		)
		return

	file.store_string(
		JSON.stringify(
			settings,
			"\t"
		)
	)


func get_setting(
	section: String,
	key: String,
	fallback: Variant = null
) -> Variant:
	if not settings.has(section):
		return fallback

	if not settings[section] is Dictionary:
		return fallback

	var section_data: Dictionary = settings[section]

	if not section_data.has(key):
		return fallback

	return section_data[key]


func set_setting(
	section: String,
	key: String,
	value: Variant,
	save_immediately: bool = true
) -> void:
	if not settings.has(section):
		settings[section] = {}

	if not settings[section] is Dictionary:
		settings[section] = {}

	settings[section][key] = value

	apply_setting(
		section,
		key
	)

	if save_immediately:
		save_settings()

	setting_changed.emit(
		section,
		key,
		value
	)


func reset_section(section: String) -> void:
	var defaults := _build_default_settings()

	if not defaults.has(section):
		return

	settings[section] = defaults[section].duplicate(true)

	apply_section(section)
	save_settings()


func reset_all_settings() -> void:
	settings = _build_default_settings()

	apply_all_settings()
	save_settings()


func get_all_settings() -> Dictionary:
	return settings.duplicate(true)


func apply_all_settings() -> void:
	_apply_display_settings()
	_apply_graphics_settings()
	_apply_audio_settings()
	_apply_control_settings()


func apply_section(section: String) -> void:
	match section:
		"display":
			_apply_display_settings()

		"graphics":
			_apply_graphics_settings()

		"audio":
			_apply_audio_settings()
		
		"gameplay":

			pass

		"controls":
			_apply_control_settings()


func apply_setting(
	section: String,
	_key: String
) -> void:
	apply_section(section)


func _apply_display_settings() -> void:
	var window_mode := str(
		get_setting(
			"display",
			"window_mode",
			"windowed"
		)
	)

	match window_mode:
		"borderless":
			DisplayServer.window_set_flag(
				DisplayServer.WINDOW_FLAG_BORDERLESS,
				false
			)

			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_FULLSCREEN
			)

		"fullscreen":
			DisplayServer.window_set_flag(
				DisplayServer.WINDOW_FLAG_BORDERLESS,
				false
			)

			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
			)

		_:
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_WINDOWED
			)

			DisplayServer.window_set_flag(
				DisplayServer.WINDOW_FLAG_BORDERLESS,
				false
			)

			var width: int = maxi(
				int(
					get_setting(
						"display",
						"resolution_width",
						1280
					)
				),
				800
			)

			var height: int = maxi(
				int(
					get_setting(
						"display",
						"resolution_height",
						720
					)
				),
				600
			)

			DisplayServer.window_set_size(
				Vector2i(
					width,
					height
				)
			)

	var vsync_enabled := bool(
		get_setting(
			"display",
			"vsync",
			true
		)
	)

	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED
		if vsync_enabled
		else DisplayServer.VSYNC_DISABLED
	)

	Engine.max_fps = maxi(
		int(
			get_setting(
				"display",
				"frame_rate_limit",
				0
			)
		),
		0
	)
	


func _apply_graphics_settings() -> void:
	if get_tree() == null:
		return

	if get_tree().root == null:
		return

	var render_scale: float = clampf(
		float(
			get_setting(
				"graphics",
				"render_scale",
				1.0
			)
		),
		0.5,
		1.0
	)

	get_tree().root.scaling_3d_scale = render_scale


func _apply_audio_settings() -> void:
	_apply_audio_bus(
		"Master",
		float(
			get_setting(
				"audio",
				"master_volume",
				1.0
			)
		)
	)

	_apply_audio_bus(
		"Music",
		float(
			get_setting(
				"audio",
				"music_volume",
				0.8
			)
		)
	)

	_apply_audio_bus(
		"SFX",
		float(
			get_setting(
				"audio",
				"sfx_volume",
				0.9
			)
		)
	)

	_apply_audio_bus(
		"Radio",
		float(
			get_setting(
				"audio",
				"radio_volume",
				0.9
			)
		)
	)

	_apply_audio_bus(
		"Dialogue",
		float(
			get_setting(
				"audio",
				"radio_volume",
				0.9
			)
		)
	)


func _apply_audio_bus(
	bus_name: String,
	volume: float
) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		return

	var safe_volume: float = clampf(
		volume,
		0.0,
		1.0
	)

	if safe_volume <= 0.001:
		AudioServer.set_bus_mute(
			bus_index,
			true
		)

		return

	AudioServer.set_bus_mute(
		bus_index,
		false
	)

	AudioServer.set_bus_volume_db(
		bus_index,
		linear_to_db(safe_volume)
	)

func _apply_control_settings() -> void:
	if not settings.has("controls"):
		return

	if not settings["controls"] is Dictionary:
		return

	var control_settings: Dictionary = settings["controls"]

	for action_value: Variant in control_settings.keys():
		var action_name: String = str(action_value)

		if not InputMap.has_action(action_name):
			continue

		var physical_keycode: int = int(
			control_settings[action_value]
		)

		if physical_keycode <= 0:
			continue

		var key_event: InputEventKey = InputEventKey.new()
		key_event.physical_keycode = physical_keycode

		InputMap.action_erase_events(action_name)
		InputMap.action_add_event(
			action_name,
			key_event
		)
func _merge_dictionary(
	target: Dictionary,
	source: Dictionary
) -> void:
	for key in source.keys():
		var source_value: Variant = source[key]

		if (
			target.has(key)
			and target[key] is Dictionary
			and source_value is Dictionary
		):
			_merge_dictionary(
				target[key] as Dictionary,
				source_value as Dictionary
			)
		else:
			target[key] = source_value
