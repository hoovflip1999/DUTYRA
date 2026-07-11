extends Node

signal duty_status_changed(is_on_duty: bool)
signal performance_xp_changed(current_xp: int, amount_added: int)
signal career_progress_changed()
signal shift_ended(
	shift_counted: bool,
	calls_cleared_this_shift: int,
	shifts_completed_total: int
)
signal game_time_changed()
signal report_logged()
signal player_profile_changed()
signal save_slots_changed()

const SLOT_ONE_PATH: String = "user://dutyra_career_slot_1.json"
const SLOT_TWO_PATH: String = "user://dutyra_career_slot_2.json"
const MENU_STATE_PATH: String = "user://dutyra_menu_state.json"

var active_save_slot: int = 0

var is_on_duty: bool = false

var player_profile_created: bool = false
var officer_first_name: String = ""
var officer_last_name: String = ""
var officer_badge_number: String = "024"
var officer_callsign: String = "Unit 24"
var officer_department: String = "DUTYRA™ Police Department"

var career_track: String = "Patrol Division"

var patrol_ranks: Array[String] = [
	"Recruit",
	"Rookie Officer",
	"Patrol Officer",
	"Corporal",
	"Sergeant",
	"Patrol Supervisor"
]

var current_rank_index: int = 1

var performance_xp: int = 0
var promotion_eligibility_xp: int = 500

var calls_cleared: int = 0
var required_calls_for_promotion: int = 5

var shifts_completed: int = 0
var required_shifts_for_promotion: int = 5

var current_shift_active: bool = false
var current_shift_calls_cleared: int = 0
var required_calls_to_complete_shift: int = 1

var game_year: int = 2026
var game_month: int = 7
var game_day: int = 11
var game_hour: int = 8
var game_minute: int = 0

var game_minutes_per_real_second: float = 1.0
var game_clock_accumulator: float = 0.0

var report_log: Array[Dictionary] = []
var next_report_number: int = 1001


func _ready() -> void:
	load_last_active_slot()


func _process(delta: float) -> void:
	game_clock_accumulator += delta * game_minutes_per_real_second

	while game_clock_accumulator >= 1.0:
		game_clock_accumulator -= 1.0
		advance_game_minute()


func get_save_slot_path(slot_number: int) -> String:
	if slot_number == 1:
		return SLOT_ONE_PATH

	if slot_number == 2:
		return SLOT_TWO_PATH

	return ""


func is_valid_save_slot(slot_number: int) -> bool:
	return slot_number == 1 or slot_number == 2


func has_save_in_slot(slot_number: int) -> bool:
	var save_path: String = get_save_slot_path(slot_number)

	if save_path == "":
		return false

	return FileAccess.file_exists(save_path)


func get_first_empty_save_slot() -> int:
	if not has_save_in_slot(1):
		return 1

	if not has_save_in_slot(2):
		return 2

	return 0


func create_player_profile(first_name: String, last_name: String) -> void:
	var selected_slot: int = get_first_empty_save_slot()

	if selected_slot == 0:
		selected_slot = 1

	var entered_name: String = last_name.strip_edges()

	if entered_name == "":
		entered_name = first_name.strip_edges()

	create_new_career_in_slot(selected_slot, entered_name)


func create_new_career_in_slot(
	slot_number: int,
	last_name: String
) -> bool:
	if not is_valid_save_slot(slot_number):
		print("Invalid save slot: " + str(slot_number))
		return false

	var clean_last_name: String = last_name.strip_edges()

	if clean_last_name == "":
		return false

	reset_loaded_career_data()

	active_save_slot = slot_number
	player_profile_created = true
	officer_first_name = ""
	officer_last_name = clean_last_name

	save_active_career()
	save_menu_state()

	player_profile_changed.emit()
	career_progress_changed.emit()
	save_slots_changed.emit()

	print(
		"Created career in slot "
		+ str(active_save_slot)
		+ ": "
		+ get_officer_display_name()
	)

	return true


func save_active_career() -> bool:
	if not player_profile_created:
		return false

	if not is_valid_save_slot(active_save_slot):
		return false

	var save_path: String = get_save_slot_path(active_save_slot)
	var save_file := FileAccess.open(save_path, FileAccess.WRITE)

	if save_file == null:
		print("Could not save career slot " + str(active_save_slot))
		return false

	var save_data: Dictionary = build_current_save_data()

	save_file.store_string(JSON.stringify(save_data))
	save_file.close()

	save_menu_state()
	save_slots_changed.emit()

	return true


func save_player_profile() -> void:
	save_active_career()


func build_current_save_data() -> Dictionary:
	return {
		"save_version": 3,
		"slot_number": active_save_slot,
		"profile_created": player_profile_created,
		"first_name": officer_first_name,
		"last_name": officer_last_name,
		"badge_number": officer_badge_number,
		"callsign": officer_callsign,
		"department": officer_department,
		"career_track": career_track,
		"current_rank_index": current_rank_index,
		"performance_xp": performance_xp,
		"calls_cleared": calls_cleared,
		"shifts_completed": shifts_completed,
		"game_year": game_year,
		"game_month": game_month,
		"game_day": game_day,
		"game_hour": game_hour,
		"game_minute": game_minute,
		"next_report_number": next_report_number,
		"report_log": report_log
	}


func load_career_slot(slot_number: int) -> bool:
	if not is_valid_save_slot(slot_number):
		return false

	var save_data: Dictionary = read_save_slot_data(slot_number)

	if save_data.is_empty():
		return false

	apply_save_data(save_data)

	active_save_slot = slot_number
	player_profile_created = true

	is_on_duty = false
	current_shift_active = false
	current_shift_calls_cleared = 0
	game_clock_accumulator = 0.0

	save_menu_state()

	player_profile_changed.emit()
	career_progress_changed.emit()

	print(
		"Loaded career slot "
		+ str(active_save_slot)
		+ ": "
		+ get_officer_display_name()
	)

	return true


func load_player_profile() -> void:
	load_last_active_slot()


func load_last_active_slot() -> void:
	var saved_slot: int = read_last_active_slot()

	if is_valid_save_slot(saved_slot):
		if load_career_slot(saved_slot):
			return

	var first_available_slot: int = 0

	if has_save_in_slot(1):
		first_available_slot = 1
	elif has_save_in_slot(2):
		first_available_slot = 2

	if first_available_slot > 0:
		load_career_slot(first_available_slot)
	else:
		reset_loaded_career_data()
		active_save_slot = 0


func save_menu_state() -> void:
	var menu_file := FileAccess.open(
		MENU_STATE_PATH,
		FileAccess.WRITE
	)

	if menu_file == null:
		return

	var menu_data: Dictionary = {
		"last_active_slot": active_save_slot
	}

	menu_file.store_string(JSON.stringify(menu_data))
	menu_file.close()


func read_last_active_slot() -> int:
	if not FileAccess.file_exists(MENU_STATE_PATH):
		return 0

	var menu_file := FileAccess.open(
		MENU_STATE_PATH,
		FileAccess.READ
	)

	if menu_file == null:
		return 0

	var file_text: String = menu_file.get_as_text()
	menu_file.close()

	var parsed_data: Variant = JSON.parse_string(file_text)

	if typeof(parsed_data) != TYPE_DICTIONARY:
		return 0

	var menu_data: Dictionary = parsed_data

	return int(menu_data.get("last_active_slot", 0))


func read_save_slot_data(slot_number: int) -> Dictionary:
	var save_path: String = get_save_slot_path(slot_number)

	if save_path == "":
		return {}

	if not FileAccess.file_exists(save_path):
		return {}

	var save_file := FileAccess.open(save_path, FileAccess.READ)

	if save_file == null:
		return {}

	var file_text: String = save_file.get_as_text()
	save_file.close()

	var parsed_data: Variant = JSON.parse_string(file_text)

	if typeof(parsed_data) != TYPE_DICTIONARY:
		return {}

	return parsed_data


func apply_save_data(save_data: Dictionary) -> void:
	officer_first_name = str(
		save_data.get("first_name", "")
	)

	officer_last_name = str(
		save_data.get("last_name", "")
	)

	officer_badge_number = str(
		save_data.get("badge_number", "024")
	)

	officer_callsign = str(
		save_data.get("callsign", "Unit 24")
	)

	officer_department = str(
		save_data.get(
			"department",
			"DUTYRA™ Police Department"
		)
	)

	career_track = str(
		save_data.get("career_track", "Patrol Division")
	)

	current_rank_index = clampi(
		int(save_data.get("current_rank_index", 1)),
		0,
		patrol_ranks.size() - 1
	)

	performance_xp = maxi(
		int(save_data.get("performance_xp", 0)),
		0
	)

	calls_cleared = maxi(
		int(save_data.get("calls_cleared", 0)),
		0
	)

	shifts_completed = maxi(
		int(save_data.get("shifts_completed", 0)),
		0
	)

	game_year = int(
		save_data.get("game_year", 2026)
	)

	game_month = clampi(
		int(save_data.get("game_month", 7)),
		1,
		12
	)

	game_day = clampi(
		int(save_data.get("game_day", 11)),
		1,
		30
	)

	game_hour = clampi(
		int(save_data.get("game_hour", 8)),
		0,
		23
	)

	game_minute = clampi(
		int(save_data.get("game_minute", 0)),
		0,
		59
	)

	next_report_number = maxi(
		int(save_data.get("next_report_number", 1001)),
		1001
	)

	report_log.clear()

	var saved_reports: Variant = save_data.get(
		"report_log",
		[]
	)

	if typeof(saved_reports) == TYPE_ARRAY:
		for saved_report in saved_reports:
			if typeof(saved_report) == TYPE_DICTIONARY:
				report_log.append(saved_report)


func get_save_slot_summary(slot_number: int) -> Dictionary:
	var save_data: Dictionary = read_save_slot_data(slot_number)

	if save_data.is_empty():
		return {
			"slot_number": slot_number,
			"occupied": false,
			"display_name": "EMPTY CAREER SLOT",
			"rank": "",
			"last_name": "",
			"performance_xp": 0,
			"calls_cleared": 0,
			"shifts_completed": 0,
			"date": "",
			"time": ""
		}

	var saved_rank_index: int = clampi(
		int(save_data.get("current_rank_index", 1)),
		0,
		patrol_ranks.size() - 1
	)

	var saved_last_name: String = str(
		save_data.get("last_name", "Unknown")
	)

	var saved_rank: String = patrol_ranks[saved_rank_index]

	return {
		"slot_number": slot_number,
		"occupied": true,
		"display_name": saved_rank + " " + saved_last_name,
		"rank": saved_rank,
		"last_name": saved_last_name,
		"performance_xp": maxi(
			int(save_data.get("performance_xp", 0)),
			0
		),
		"calls_cleared": maxi(
			int(save_data.get("calls_cleared", 0)),
			0
		),
		"shifts_completed": maxi(
			int(save_data.get("shifts_completed", 0)),
			0
		),
		"date": format_saved_date(save_data),
		"time": format_saved_time(save_data)
	}


func format_saved_date(save_data: Dictionary) -> String:
	var saved_month: int = clampi(
		int(save_data.get("game_month", 7)),
		1,
		12
	)

	var saved_day: int = clampi(
		int(save_data.get("game_day", 11)),
		1,
		30
	)

	var saved_year: int = int(
		save_data.get("game_year", 2026)
	)

	return (
		str(saved_month).pad_zeros(2)
		+ "/"
		+ str(saved_day).pad_zeros(2)
		+ "/"
		+ str(saved_year)
	)


func format_saved_time(save_data: Dictionary) -> String:
	var saved_hour: int = clampi(
		int(save_data.get("game_hour", 8)),
		0,
		23
	)

	var saved_minute: int = clampi(
		int(save_data.get("game_minute", 0)),
		0,
		59
	)

	return (
		str(saved_hour).pad_zeros(2)
		+ ":"
		+ str(saved_minute).pad_zeros(2)
	)


func delete_career_slot(slot_number: int) -> bool:
	if not is_valid_save_slot(slot_number):
		return false

	var save_path: String = get_save_slot_path(slot_number)

	if not FileAccess.file_exists(save_path):
		return false

	var absolute_path: String = ProjectSettings.globalize_path(
		save_path
	)

	var delete_result: Error = DirAccess.remove_absolute(
		absolute_path
	)

	if delete_result != OK:
		print(
			"Could not delete career slot "
			+ str(slot_number)
			+ ". Error: "
			+ str(delete_result)
		)
		return false

	if active_save_slot == slot_number:
		reset_loaded_career_data()
		active_save_slot = 0
		save_menu_state()

		player_profile_changed.emit()
		career_progress_changed.emit()

	save_slots_changed.emit()

	print("Deleted career slot " + str(slot_number))

	return true


func reset_player_profile() -> void:
	if is_valid_save_slot(active_save_slot):
		delete_career_slot(active_save_slot)
		return

	reset_loaded_career_data()
	active_save_slot = 0
	save_menu_state()

	player_profile_changed.emit()
	career_progress_changed.emit()
	save_slots_changed.emit()


func reset_loaded_career_data() -> void:
	is_on_duty = false

	player_profile_created = false
	officer_first_name = ""
	officer_last_name = ""
	officer_badge_number = "024"
	officer_callsign = "Unit 24"
	officer_department = "DUTYRA™ Police Department"

	career_track = "Patrol Division"
	current_rank_index = 1

	performance_xp = 0
	calls_cleared = 0
	shifts_completed = 0

	current_shift_active = false
	current_shift_calls_cleared = 0

	game_year = 2026
	game_month = 7
	game_day = 11
	game_hour = 8
	game_minute = 0
	game_clock_accumulator = 0.0

	report_log.clear()
	next_report_number = 1001


func get_officer_full_name() -> String:
	if officer_last_name == "":
		return "Unnamed"

	return officer_last_name


func get_officer_display_name() -> String:
	return get_current_rank_name() + " " + get_officer_full_name()


func get_officer_file_text() -> String:
	return "NAME: " + get_officer_display_name() + "\n" \
		+ "BADGE: " + officer_badge_number + "\n" \
		+ "CALLSIGN: " + officer_callsign + "\n" \
		+ "AGENCY: " + officer_department + "\n" \
		+ "TRACK: " + career_track


func advance_game_minute() -> void:
	game_minute += 1

	if game_minute >= 60:
		game_minute = 0
		game_hour += 1

	if game_hour >= 24:
		game_hour = 0
		game_day += 1

	if game_day > 30:
		game_day = 1
		game_month += 1

	if game_month > 12:
		game_month = 1
		game_year += 1

	game_time_changed.emit()


func toggle_duty() -> void:
	set_duty_status(not is_on_duty)


func set_duty_status(new_status: bool) -> void:
	if is_on_duty == new_status:
		return

	if new_status:
		start_shift()
	else:
		end_shift()

	is_on_duty = new_status

	duty_status_changed.emit(is_on_duty)
	career_progress_changed.emit()

	save_active_career()


func start_shift() -> void:
	current_shift_active = true
	current_shift_calls_cleared = 0


func end_shift() -> void:
	if not current_shift_active:
		return

	var cleared_this_shift: int = current_shift_calls_cleared
	var shift_counted: bool = false

	if current_shift_calls_cleared >= required_calls_to_complete_shift:
		shifts_completed += 1
		shift_counted = true

	current_shift_active = false
	current_shift_calls_cleared = 0

	save_active_career()

	shift_ended.emit(
		shift_counted,
		cleared_this_shift,
		shifts_completed
	)


func award_call_performance(amount: int) -> void:
	calls_cleared += 1

	if current_shift_active:
		current_shift_calls_cleared += 1

	if amount > 0:
		performance_xp += amount

		performance_xp_changed.emit(
			performance_xp,
			amount
		)

	career_progress_changed.emit()
	save_active_career()


func log_call_report(
	call_title: String,
	call_location: String,
	call_priority: String,
	call_response: String,
	call_status: String,
	call_notes: String
) -> void:
	var report_number: String = (
		"RPT-" + str(next_report_number)
	)

	next_report_number += 1

	var report_data: Dictionary = {
		"report_number": report_number,
		"date": get_game_date_text(),
		"time": get_game_time_text(),
		"unit": officer_callsign,
		"officer_name": get_officer_display_name(),
		"officer_rank": get_current_rank_name(),
		"badge_number": officer_badge_number,
		"title": call_title,
		"location": call_location,
		"priority": call_priority,
		"response": call_response,
		"status": call_status,
		"notes": call_notes
	}

	report_log.push_front(report_data)

	save_active_career()
	report_logged.emit()


func get_report_count() -> int:
	return report_log.size()


func get_report_at(index: int) -> Dictionary:
	if index < 0:
		return {}

	if index >= report_log.size():
		return {}

	return report_log[index]


func get_game_time_text() -> String:
	return (
		str(game_hour).pad_zeros(2)
		+ ":"
		+ str(game_minute).pad_zeros(2)
	)


func get_game_date_text() -> String:
	return (
		str(game_month).pad_zeros(2)
		+ "/"
		+ str(game_day).pad_zeros(2)
		+ "/"
		+ str(game_year)
	)


func get_duty_status_text() -> String:
	if is_on_duty:
		return "ON DUTY"

	return "OFF DUTY"


func get_promotion_progress_text() -> String:
	return (
		"Promotion Eligibility: "
		+ str(performance_xp)
		+ " / "
		+ str(promotion_eligibility_xp)
	)


func get_current_rank_name() -> String:
	if current_rank_index < 0:
		return "Unknown"

	if current_rank_index >= patrol_ranks.size():
		return "Unknown"

	return patrol_ranks[current_rank_index]


func get_next_rank_name() -> String:
	var next_rank_index: int = current_rank_index + 1

	if next_rank_index >= patrol_ranks.size():
		return "No further patrol rank"

	return patrol_ranks[next_rank_index]


func get_shift_status_text() -> String:
	if current_shift_active:
		return (
			"Active Shift: "
			+ str(current_shift_calls_cleared)
			+ " / "
			+ str(required_calls_to_complete_shift)
			+ " calls cleared"
		)

	return "No active shift"


func is_promotion_eligible() -> bool:
	if current_rank_index >= patrol_ranks.size() - 1:
		return false

	if performance_xp < promotion_eligibility_xp:
		return false

	if calls_cleared < required_calls_for_promotion:
		return false

	if shifts_completed < required_shifts_for_promotion:
		return false

	return true


func get_promotion_status_text() -> String:
	if current_rank_index >= patrol_ranks.size() - 1:
		return "Maximum patrol rank reached"

	if is_promotion_eligible():
		return "Eligible for supervisor review"

	return "Not eligible yet"


func get_career_mdt_text() -> String:
	return "CAREER / PERSONNEL FILE\n\n" \
		+ "NAME: " + get_officer_display_name() + "\n" \
		+ "BADGE: " + officer_badge_number + "\n" \
		+ "CALLSIGN: " + officer_callsign + "\n" \
		+ "TRACK: " + career_track + "\n" \
		+ "SHIFT: " + get_shift_status_text() + "\n\n" \
		+ "NEXT REVIEW: " + get_next_rank_name() + "\n" \
		+ "STATUS: " + get_promotion_status_text() + "\n\n" \
		+ "REQUIREMENTS\n" \
		+ get_requirement_line(
			"Performance XP",
			performance_xp,
			promotion_eligibility_xp
		) + "\n" \
		+ get_requirement_line(
			"Calls Cleared",
			calls_cleared,
			required_calls_for_promotion
		) + "\n" \
		+ get_requirement_line(
			"Shifts Completed",
			shifts_completed,
			required_shifts_for_promotion
		) + "\n\n" \
		+ "MISSING\n" \
		+ get_missing_promotion_requirements_text()


func get_requirement_line(
	requirement_name: String,
	current_value: int,
	required_value: int
) -> String:
	var marker: String = "[ ]"

	if current_value >= required_value:
		marker = "[X]"

	return (
		marker
		+ " "
		+ requirement_name
		+ ": "
		+ str(current_value)
		+ " / "
		+ str(required_value)
	)


func get_missing_promotion_requirements_text() -> String:
	var missing_text: String = ""

	if performance_xp < promotion_eligibility_xp:
		missing_text += (
			"- Performance XP: "
			+ str(performance_xp)
			+ " / "
			+ str(promotion_eligibility_xp)
			+ "\n"
		)

	if calls_cleared < required_calls_for_promotion:
		missing_text += (
			"- Calls Cleared: "
			+ str(calls_cleared)
			+ " / "
			+ str(required_calls_for_promotion)
			+ "\n"
		)

	if shifts_completed < required_shifts_for_promotion:
		missing_text += (
			"- Shifts Completed: "
			+ str(shifts_completed)
			+ " / "
			+ str(required_shifts_for_promotion)
			+ "\n"
		)

	if missing_text == "":
		return "None. Officer is ready for supervisor review."

	return missing_text.strip_edges()
