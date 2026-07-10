extends StaticBody3D

@export var prompt_text: String = "Press E to clock in"

func _ready() -> void:
	update_prompt()

func interact() -> void:
	GameState.toggle_duty()
	update_prompt()
	print("Duty terminal used")

func update_prompt() -> void:
	if GameState.is_on_duty:
		prompt_text = "Press E to clock out"
	else:
		prompt_text = "Press E to clock in"
