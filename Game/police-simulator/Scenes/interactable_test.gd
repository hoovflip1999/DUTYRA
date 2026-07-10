extends StaticBody3D

@export var prompt_text: String = "Press E to inspect test box"

@onready var mesh: MeshInstance3D = $TestInteractableMesh

var has_been_interacted_with: bool = false

func interact() -> void:
	has_been_interacted_with = !has_been_interacted_with

	if has_been_interacted_with:
		prompt_text = "Press E to reset test box"
		print("Test box inspected")

		var material := StandardMaterial3D.new()
		material.albedo_color = Color.GREEN
		mesh.material_override = material
	else:
		prompt_text = "Press E to inspect test box"
		print("Test box reset")

		var material := StandardMaterial3D.new()
		material.albedo_color = Color.WHITE
		mesh.material_override = material
