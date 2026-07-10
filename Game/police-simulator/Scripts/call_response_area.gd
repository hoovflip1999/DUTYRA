extends Area3D

@export var call_name: String = "Suspicious Person"
@export var location_name: String = "Gas Station"

var player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		player_inside = true

		if body.has_method("set_active_call_area"):
			body.set_active_call_area(self)

func _on_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		player_inside = false

		if body.has_method("clear_active_call_area"):
			body.clear_active_call_area(self)

func get_prompt_text() -> String:
	return ""

func interact() -> void:
	return
