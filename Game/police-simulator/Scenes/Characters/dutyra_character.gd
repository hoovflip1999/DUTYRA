extends Node3D

const IDLE_ANIMATION: StringName = &"Armature|mixamo_com|Layer0"
const WALK_ANIMATION: StringName = &"walk/Armature|mixamo_com|Layer0"

const WALK_LIBRARY_PATH := \
	"res://Assets/Characters/Animations/DUTYRA_Walk.glb"

@onready var animation_player := find_child(
	"AnimationPlayer",
	true,
	false
) as AnimationPlayer


func _ready() -> void:
	if animation_player == null:
		push_error("Could not find the character AnimationPlayer.")
		return

	var walk_library := load(WALK_LIBRARY_PATH) as AnimationLibrary

	if walk_library == null:
		push_error("Could not load the Walk animation library.")
		return

	if not animation_player.has_animation_library("walk"):
		animation_player.add_animation_library(
			"walk",
			walk_library
		)

	_set_animation_loop(IDLE_ANIMATION)
	_set_animation_loop(WALK_ANIMATION)
	play_idle()


func set_moving(
	is_moving: bool,
	movement_animation_speed: float = 1.0
) -> void:
	if animation_player == null:
		return

	if is_moving:
		animation_player.play(
			WALK_ANIMATION,
			0.15,
			movement_animation_speed
		)
	else:
		animation_player.play(
			IDLE_ANIMATION,
			0.15,
			1.0
		)


func play_idle() -> void:
	_play_animation(IDLE_ANIMATION)


func play_walk() -> void:
	_play_animation(WALK_ANIMATION)


func _play_animation(animation_name: StringName) -> void:
	if animation_player == null:
		return

	if (
		animation_player.current_animation == animation_name
		and animation_player.is_playing()
	):
		return

	animation_player.play(animation_name, 0.2)


func _set_animation_loop(animation_name: StringName) -> void:
	if not animation_player.has_animation(animation_name):
		push_warning("Missing animation: " + String(animation_name))
		return

	var animation := animation_player.get_animation(animation_name)
	animation.loop_mode = Animation.LOOP_LINEAR
