class_name EquipmentPoseModifier
extends SkeletonModifier3D


@export_category("Bone Setup")

@export var right_upper_arm_bone_name: StringName = (
	&"mixamorig_RightArm"
)

@export var right_forearm_bone_name: StringName = (
	&"mixamorig_RightForeArm"
)

@export var right_hand_bone_name: StringName = (
	&"mixamorig_RightHand"
)


@export_category("Flashlight Pose")

@export var upper_arm_rotation_degrees := Vector3(
	30.0,
	0.0,
	35.0
)

@export var forearm_rotation_degrees := Vector3(
	0.0,
	0.0,
	70.0
)

@export var hand_rotation_degrees := Vector3(
	0.0,
	0.0,
	0.0
)

@export var blend_speed: float = 8.0


var target_pose_influence: float = 0.0
var current_pose_influence: float = 0.0

var skeleton: Skeleton3D = null

var right_upper_arm_bone_index: int = -1
var right_forearm_bone_index: int = -1
var right_hand_bone_index: int = -1

var upper_arm_base_rotation := Quaternion.IDENTITY
var forearm_base_rotation := Quaternion.IDENTITY
var hand_base_rotation := Quaternion.IDENTITY

var has_saved_base_pose: bool = false


func _ready() -> void:
	cache_bones()

	target_pose_influence = 0.0
	current_pose_influence = 0.0
	influence = 0.0


func cache_bones() -> void:
	skeleton = get_skeleton()

	if skeleton == null:
		push_warning(
			"EquipmentPoseModifier must be under Skeleton3D."
		)
		return

	right_upper_arm_bone_index = skeleton.find_bone(
		right_upper_arm_bone_name
	)

	right_forearm_bone_index = skeleton.find_bone(
		right_forearm_bone_name
	)

	right_hand_bone_index = skeleton.find_bone(
		right_hand_bone_name
	)

	if right_hand_bone_index == -1:
		push_warning(
			"Right-hand bone was not found."
		)

	if right_forearm_bone_index == -1:
		push_warning(
			"Right-forearm bone was not found."
		)

	if right_upper_arm_bone_index == -1:
		push_warning(
			"Right-upper-arm bone was not found."
		)


func save_base_pose() -> void:
	if skeleton == null:
		return

	if (
		right_upper_arm_bone_index == -1
		or right_forearm_bone_index == -1
		or right_hand_bone_index == -1
	):
		return

	upper_arm_base_rotation = (
		skeleton.get_bone_pose_rotation(
			right_upper_arm_bone_index
		)
	)

	forearm_base_rotation = (
		skeleton.get_bone_pose_rotation(
			right_forearm_bone_index
		)
	)

	hand_base_rotation = (
		skeleton.get_bone_pose_rotation(
			right_hand_bone_index
		)
	)

	has_saved_base_pose = true


func set_flashlight_pose(enabled: bool) -> void:
	target_pose_influence = (
		1.0
		if enabled
		else 0.0
	)


func _process_modification_with_delta(
	delta: float
) -> void:
	if skeleton == null:
		cache_bones()

	if skeleton == null:
		return

	if not has_saved_base_pose:
		save_base_pose()

	if not has_saved_base_pose:
		return

	current_pose_influence = move_toward(
		current_pose_influence,
		target_pose_influence,
		blend_speed * delta
	)

	influence = current_pose_influence

	if current_pose_influence <= 0.001:
		return

	apply_fixed_pose(
		right_upper_arm_bone_index,
		upper_arm_base_rotation,
		upper_arm_rotation_degrees
	)

	apply_fixed_pose(
		right_forearm_bone_index,
		forearm_base_rotation,
		forearm_rotation_degrees
	)

	apply_fixed_pose(
		right_hand_bone_index,
		hand_base_rotation,
		hand_rotation_degrees
	)


func apply_fixed_pose(
	bone_index: int,
	base_rotation: Quaternion,
	rotation_degrees: Vector3
) -> void:
	if bone_index == -1:
		return

	var rotation_radians := Vector3(
		deg_to_rad(rotation_degrees.x),
		deg_to_rad(rotation_degrees.y),
		deg_to_rad(rotation_degrees.z)
	)

	var rotation_offset: Quaternion = (
		Quaternion.from_euler(
			rotation_radians
		)
	)

	skeleton.set_bone_pose_rotation(
		bone_index,
		base_rotation * rotation_offset
	)
