extends StaticBody3D
class_name Interactable

@export var prompt_text: String = "Press E to interact"

func interact() -> void:
	print("Interacted with object")
