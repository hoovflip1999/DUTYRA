extends Node

signal duty_status_changed(is_on_duty: bool)
signal performance_xp_changed(current_xp: int, amount_added: int)
signal career_progress_changed()

var is_on_duty: bool = false

var current_rank: String = "Officer"
var performance_xp: int = 0
var promotion_eligibility_xp: int = 500

var calls_cleared: int = 0
var required_calls_for_promotion: int = 5

var shifts_completed: int = 0
var required_shifts_for_promotion: int = 5

var current_shift_active: bool = false
var current_shift_calls_cleared: int = 0
var required_calls_to_complete_shift: int = 1

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

	if current_shift_calls_cleared >= required_calls_to_complete_shift:
		shifts_completed += 1
		print("Shift completed. Total shifts completed: " + str(shifts_completed))
	else:
		print("Shift ended but did not count. No calls cleared.")

	current_shift_active = false
	current_shift_calls_cleared = 0

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
	return "MDT / CAREER\n\n" \
		+ "CURRENT RANK\n" \
		+ current_rank + "\n\n" \
		+ "CURRENT SHIFT\n" \
		+ get_shift_status_text() + "\n\n" \
		+ "PROMOTION ELIGIBILITY\n" \
		+ "Performance XP: " + str(performance_xp) + " / " + str(promotion_eligibility_xp) + "\n" \
		+ "Calls Cleared: " + str(calls_cleared) + " / " + str(required_calls_for_promotion) + "\n" \
		+ "Shifts Completed: " + str(shifts_completed) + " / " + str(required_shifts_for_promotion) + "\n\n" \
		+ "STATUS\n" \
		+ get_promotion_status_text() + "\n\n" \
		+ "NOTE\n" \
		+ "Promotion is not automatic. Eligibility means the officer can be considered later."
