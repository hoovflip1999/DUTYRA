extends StaticBody3D

@export var prompt_text: String = "Press E to open door"
@export var open_angle_degrees: float = 90.0

var is_open: bool = false
var closed_rotation_y: float = 0.0

func _ready() -> void:
	closed_rotation_y = rotation.y

func interact() -> void:
	is_open = !is_open

	if is_open:
		prompt_text = "Press E to close door"
		rotation.y = closed_rotation_y + deg_to_rad(open_angle_degrees)
		print("Door opened")
	else:
		prompt_text = "Press E to open door"
		rotation.y = closed_rotation_y
		print("Door closed")
