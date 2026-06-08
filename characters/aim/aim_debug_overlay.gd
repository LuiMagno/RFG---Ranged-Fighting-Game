extends Node2D
class_name AimDebugOverlay

const DEBUG_LINE_LENGTH := 120.0
const DEBUG_RAW_LINE_LENGTH := 80.0

@export var player_id: int = 1

@onready var _line: Line2D = $AimDebugLine
@onready var _raw_line: Line2D = $AimDebugRawLine
@onready var _assist_target_line: Line2D = get_node_or_null("AimAssistTargetLine") as Line2D
@onready var _label: Label = $AimDebugLabel
@onready var _lock_on_label: Label = get_node_or_null("LockOnDebugLabel") as Label
@onready var _assist_label: Label = get_node_or_null("AimAssistDebugLabel") as Label


func _ready() -> void:
	_line.visible = false
	_raw_line.visible = false
	_label.visible = false
	if _lock_on_label != null:
		_lock_on_label.visible = false
	if _assist_target_line != null:
		_assist_target_line.visible = false
	if _assist_label != null:
		_assist_label.visible = false
	if player_id == 1:
		_line.default_color = Color(0.35, 0.95, 1.0, 0.9)
		_raw_line.default_color = Color(0.35, 0.95, 1.0, 0.45)
		_label.add_theme_color_override("font_color", Color(0.55, 0.98, 1.0, 1.0))
		if _assist_target_line != null:
			_assist_target_line.default_color = Color(0.45, 1.0, 0.55, 0.75)
	else:
		_line.default_color = Color(1.0, 0.62, 0.28, 0.9)
		_raw_line.default_color = Color(1.0, 0.62, 0.28, 0.45)
		_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.45, 1.0))
		if _assist_target_line != null:
			_assist_target_line.default_color = Color(1.0, 0.45, 0.35, 0.75)
	_label.add_theme_font_size_override("font_size", 11)


func refresh(
	muzzle_local: Vector2,
	aim_direction: Vector2,
	launch_angle_deg: float,
	raw_vector: Vector2 = Vector2.ZERO,
	quantized_mode_name: String = "",
	raw_angle_deg: float = 0.0,
	direction_slot_name: String = "",
	direction_heading: String = "Current Direction:",
	extra_lines: String = "",
	show_raw_line: bool = false,
	target_label: String = ""
) -> void:
	var lock_on_face := quantized_mode_name == "LOCK_ON_FACE"
	var show := RunConfig.test_aim_debug and (RunConfig.uses_angled_shot_test() or lock_on_face)
	var auto_aim_360 := quantized_mode_name == "AUTO_AIM_360"
	var hybrid_manual := quantized_mode_name == "HYBRID_MANUAL"
	var quantized := (
		not quantized_mode_name.is_empty()
		and not auto_aim_360
		and not hybrid_manual
		and not lock_on_face
	)
	_line.visible = show
	_raw_line.visible = show and (quantized or show_raw_line)
	_label.visible = show
	if not show:
		return
	var dir := aim_direction
	if dir.length_squared() <= 0.0001:
		dir = FreeAimUtil.forward_for_player(player_id)
	var end := muzzle_local + dir * DEBUG_LINE_LENGTH
	_line.clear_points()
	_line.add_point(muzzle_local)
	_line.add_point(end)
	if auto_aim_360:
		if raw_vector.length_squared() > 0.0001:
			var raw_dir := raw_vector.normalized()
			var raw_end := muzzle_local + raw_dir * DEBUG_RAW_LINE_LENGTH
			_raw_line.clear_points()
			_raw_line.add_point(muzzle_local)
			_raw_line.add_point(raw_end)
		else:
			_raw_line.clear_points()
		_label.text = (
			"Current Aim Mode: AUTO_AIM_360\n"
			+ "Current Target: %s\n"
			+ "Current Angle: %.1f°\n"
			+ "raw=(%.2f, %.2f)\n"
			+ "dir=(%.2f, %.2f)"
			% [
				target_label,
				raw_angle_deg,
				raw_vector.x, raw_vector.y,
				dir.x, dir.y
			]
		)
		_label.position = muzzle_local + Vector2(-72, -92)
	elif lock_on_face:
		if raw_vector.length_squared() > 0.0001:
			var raw_dir := raw_vector.normalized()
			var raw_end := muzzle_local + raw_dir * DEBUG_RAW_LINE_LENGTH
			_raw_line.clear_points()
			_raw_line.add_point(muzzle_local)
			_raw_line.add_point(raw_end)
		else:
			_raw_line.clear_points()
		_label.text = (
			"Current Aim Mode: LOCK_ON_FACE\n"
			+ "%s %s\n"
			+ "Current Target: %s\n"
			+ "Current Angle: %.1f°\n"
			+ "dir=(%.2f, %.2f)"
			% [
				direction_heading,
				direction_slot_name,
				target_label,
				raw_angle_deg,
				dir.x, dir.y
			]
		)
		_label.position = muzzle_local + Vector2(-72, -92)
	elif hybrid_manual:
		_raw_line.clear_points()
		var extra_block := ""
		if not extra_lines.is_empty():
			extra_block = extra_lines + "\n"
		_label.text = (
			"Current Aim Mode: HYBRID_MANUAL\n"
			+ "%s %s\n"
			+ extra_block
			+ "dir=(%.2f, %.2f)  angle=%.1f°"
			% [
				direction_heading,
				direction_slot_name,
				dir.x, dir.y, launch_angle_deg
			]
		)
		_label.position = muzzle_local + Vector2(-72, -88)
	elif quantized:
		if raw_vector.length_squared() > 0.0001:
			var raw_dir := raw_vector.normalized()
			var raw_end := muzzle_local + raw_dir * DEBUG_RAW_LINE_LENGTH
			_raw_line.clear_points()
			_raw_line.add_point(muzzle_local)
			_raw_line.add_point(raw_end)
		else:
			_raw_line.clear_points()
		var extra_block := ""
		if not extra_lines.is_empty():
			extra_block = extra_lines + "\n"
		_label.text = (
			"Current Aim Mode: %s\n"
			+ "%s %s\n"
			+ extra_block
			+ "raw=(%.2f, %.2f)  angle=%.1f°\n"
			+ "dir=(%.2f, %.2f)  shot=%.1f°"
			% [
				quantized_mode_name,
				direction_heading,
				direction_slot_name,
				raw_vector.x, raw_vector.y, raw_angle_deg,
				dir.x, dir.y, launch_angle_deg
			]
		)
		_label.position = muzzle_local + Vector2(-72, -76 if extra_lines.is_empty() else -88)
	elif RunConfig.is_free_aim_left_stick_test() and raw_vector.length_squared() > 0.0001:
		_label.text = (
			"stick=(%.2f, %.2f)  dir=(%.2f, %.2f)  angle=%.1f°"
			% [raw_vector.x, raw_vector.y, dir.x, dir.y, launch_angle_deg]
		)
		_label.position = muzzle_local + Vector2(-48, -36)
	else:
		_label.text = "dir=(%.2f, %.2f)  angle=%.1f°" % [dir.x, dir.y, launch_angle_deg]
		_label.position = muzzle_local + Vector2(-48, -36)


func refresh_lock_on(active: bool, target_label: String, facing_label: String) -> void:
	if _lock_on_label == null:
		return
	var show := RunConfig.is_lock_on_face_test() and RunConfig.test_aim_debug and active
	_lock_on_label.visible = show
	if not show:
		return
	_lock_on_label.text = (
		"Lock-On: ON\nCurrent Target: %s\nFacing Direction: %s"
		% [target_label if not target_label.is_empty() else "—", facing_label if not facing_label.is_empty() else "—"]
	)
	_lock_on_label.position = Vector2(-72, -118)
	if player_id == 1:
		_lock_on_label.add_theme_color_override("font_color", Color(0.55, 0.98, 1.0, 1.0))
	else:
		_lock_on_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.45, 1.0))
	_lock_on_label.add_theme_font_size_override("font_size", 11)


func hide_aim_assist() -> void:
	if _assist_target_line != null:
		_assist_target_line.visible = false
	if _assist_label != null:
		_assist_label.visible = false


func refresh_aim_assist(
	muzzle_local: Vector2,
	base_mode_name: String,
	assist_state: String,
	player_dir: Vector2,
	target_dir: Vector2,
	final_dir: Vector2,
	angular_diff_deg: float,
	player_angle_deg: float,
	target_angle_deg: float,
	final_angle_deg: float,
	applied: bool
) -> void:
	if not RunConfig.test_aim_debug or not RunConfig.is_aim_assist_test_active():
		hide_aim_assist()
		return
	var p_dir := player_dir
	if p_dir.length_squared() <= 0.0001:
		p_dir = FreeAimUtil.forward_for_player(player_id)
	var f_dir := final_dir if final_dir.length_squared() > 0.0001 else p_dir
	var t_dir := target_dir if target_dir.length_squared() > 0.0001 else p_dir

	_line.visible = true
	_line.clear_points()
	_line.add_point(muzzle_local)
	_line.add_point(muzzle_local + p_dir.normalized() * DEBUG_LINE_LENGTH)

	_raw_line.visible = true
	_raw_line.default_color = _line.default_color * Color(1.2, 1.2, 1.2, 1.0)
	_raw_line.clear_points()
	_raw_line.add_point(muzzle_local)
	_raw_line.add_point(muzzle_local + f_dir.normalized() * DEBUG_RAW_LINE_LENGTH)

	if _assist_target_line != null:
		_assist_target_line.visible = true
		_assist_target_line.clear_points()
		_assist_target_line.add_point(muzzle_local)
		_assist_target_line.add_point(muzzle_local + t_dir.normalized() * DEBUG_RAW_LINE_LENGTH)

	if _assist_label != null:
		_assist_label.visible = true
		_assist_label.text = (
			"Current Aim Mode: %s\nAIM_ASSIST overlay\n\n"
			+ "Assist State: %s\n"
			+ "Player Direction: (%.2f, %.2f)  angle=%.1f°\n"
			+ "Target Direction: (%.2f, %.2f)  angle=%.1f°\n"
			+ "Angular Difference: %.1f°\n"
			+ "Final Direction: (%.2f, %.2f)  angle=%.1f°\n"
			+ "Applied: %s"
			% [
				base_mode_name,
				assist_state,
				p_dir.x, p_dir.y, player_angle_deg,
				t_dir.x, t_dir.y, target_angle_deg,
				angular_diff_deg,
				f_dir.x, f_dir.y, final_angle_deg,
				"yes" if applied else "no"
			]
		)
		_assist_label.position = muzzle_local + Vector2(-88, -148)
		if player_id == 1:
			_assist_label.add_theme_color_override("font_color", Color(0.55, 0.98, 1.0, 1.0))
		else:
			_assist_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.45, 1.0))
		_assist_label.add_theme_font_size_override("font_size", 11)
