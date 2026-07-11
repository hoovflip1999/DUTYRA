extends Node

signal duty_status_changed(is_on_duty: bool)
signal performance_xp_changed(current_xp: int, amount_added: int)
signal career_progress_changed()
signal shift_ended(shift_counted: bool, calls_cleared_this_shift: int, shifts_completed_total: int)
signal game_time_changed()

var is_on_duty: bool = false

var career_track: String = "Patrol Division"
var current_rank_index: int = 1
var patrol_ranks: Array[String] = [
	"Recruit",
	"Rookie Officer",
	"Patrol Officer",
	"Corporal",
	"Sergeant",
	"Patrol Supervisor"
]

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

func toggle_duty() -> void:
	set_duty_status(!is_on_duty)

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

	if is_on_duty:
		print("Player is now ON DUTY")
	else:
		print("Player is now OFF DUTY")

func start_shift() -> void:
	current_shift_active = true
	current_shift_calls_cleared = 0
	print("Shift started")

func end_shift() -> void:
	if not current_shift_active:
		return

	var calls_cleared_this_shift: int = current_shift_calls_cleared
	var shift_counted: bool = false

	if current_shift_calls_cleared >= required_calls_to_complete_shift:
		shifts_completed += 1
		shift_counted = true
		print("Shift completed. Total shifts completed: " + str(shifts_completed))
	else:
		print("Shift ended but did not count. No calls cleared.")

	current_shift_active = false
	current_shift_calls_cleared = 0

	shift_ended.emit(shift_counted, calls_cleared_this_shift, shifts_completed)

func award_call_performance(amount: int) -> void:
	calls_cleared += 1

	if current_shift_active:
		current_shift_calls_cleared += 1

	if amount > 0:
		performance_xp += amount
		performance_xp_changed.emit(performance_xp, amount)

	career_progress_changed.emit()

	print("Call cleared. Performance XP: " + str(performance_xp) + " | Calls cleared: " + str(calls_cleared))

func get_duty_status_text() -> String:
	if is_on_duty:
		return "ON DUTY"

	return "OFF DUTY"

func get_promotion_progress_text() -> String:
	return "Promotion Eligibility: " + str(performance_xp) + " / " + str(promotion_eligibility_xp)
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
		return "Active Shift: " + str(current_shift_calls_cleared) + " / " + str(required_calls_to_complete_shift) + " calls cleared"

	return "No active shift"

func is_promotion_eligible() -> bool:
	if performance_xp < promotion_eligibility_xp:
		return false

	if calls_cleared < required_calls_for_promotion:
		return false

	if shifts_completed < required_shifts_for_promotion:
		return false

	return true

func get_promotion_status_text() -> String:
	if is_promotion_eligible():
		return "Eligible for supervisor review"

	return "Not eligible yet"

func get_career_mdt_text() -> String:
		return "CAREER / PERSONNEL FILE\n\n" \
		+ "TRACK: " + career_track + "\n" \
		+ "RANK: " + get_current_rank_name() + "\n" \
		+ "SHIFT: " + get_shift_status_text() + "\n\n" \
		+ "NEXT REVIEW: " + get_next_rank_name() + "\n" \
		+ "STATUS: " + get_promotion_status_text() + "\n\n" \
		+ "REQUIREMENTS\n" \
		+ get_requirement_line("Performance XP", performance_xp, promotion_eligibility_xp) + "\n" \
		+ get_requirement_line("Calls Cleared", calls_cleared, required_calls_for_promotion) + "\n" \
		+ get_requirement_line("Shifts Completed", shifts_completed, required_shifts_for_promotion) + "\n\n" \
		+ "MISSING\n" \
		+ get_missing_promotion_requirements_text() + "\n\n" \
		+ "NOTE: Requirements create eligibility only. Promotion requires supervisor review."
		
func get_requirement_line(requirement_name: String, current_value: int, required_value: int) -> String:
	var marker: String = "[ ]"

	if current_value >= required_value:
		marker = "[X]"

	return marker + " " + requirement_name + ": " + str(current_value) + " / " + str(required_value)

func get_missing_promotion_requirements_text() -> String:
	var missing_text: String = ""

	if performance_xp < promotion_eligibility_xp:
		missing_text += "- Performance XP: " + str(performance_xp) + " / " + str(promotion_eligibility_xp) + "\n"

	if calls_cleared < required_calls_for_promotion:
		missing_text += "- Calls Cleared: " + str(calls_cleared) + " / " + str(required_calls_for_promotion) + "\n"

	if shifts_completed < required_shifts_for_promotion:
		missing_text += "- Shifts Completed: " + str(shifts_completed) + " / " + str(required_shifts_for_promotion) + "\n"

	if missing_text == "":
		return "None. Officer is ready for supervisor review."

	return missing_text.strip_edges()
	
func _process(delta: float) -> void:
	game_clock_accumulator += delta * game_minutes_per_real_second

	while game_clock_accumulator >= 1.0:
		game_clock_accumulator -= 1.0
		advance_game_minute()

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

func get_game_time_text() -> String:
	var hour_text: String = str(game_hour)
	var minute_text: String = str(game_minute)

	if game_hour < 10:
		hour_text = "0" + hour_text

	if game_minute < 10:
		minute_text = "0" + minute_text

	return hour_text + ":" + minute_text

func get_game_date_text() -> String:
	var month_text: String = str(game_month)
	var day_text: String = str(game_day)

	if game_month < 10:
		month_text = "0" + month_text

	if game_day < 10:
		day_text = "0" + day_text

	return month_text + "/" + day_text + "/" + str(game_year)
