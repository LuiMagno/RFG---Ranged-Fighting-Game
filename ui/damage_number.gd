extends Node2D
class_name DamageNumber

const DURATION_S := 0.75
const FLOAT_Y := -48.0

@onready var _label: Label = $Label

var _elapsed_s := 0.0
var _start_pos := Vector2.ZERO
var _tier := "normal"


func setup(amount: int, tier: String, world_pos: Vector2) -> void:
	_tier = tier
	_start_pos = world_pos
	global_position = world_pos
	_label.text = str(amount)
	_apply_tier_style(tier)
	if tier == "heavy":
		scale = Vector2(1.25, 1.25)


func _apply_tier_style(tier: String) -> void:
	match tier:
		"heavy":
			_label.add_theme_font_size_override("font_size", 44)
			_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4, 1.0))
			_label.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.02, 1.0))
			_label.add_theme_constant_override("outline_size", 6)
		"normal":
			_label.add_theme_font_size_override("font_size", 32)
			_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
			_label.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.1, 1.0))
			_label.add_theme_constant_override("outline_size", 4)
		_:
			_label.add_theme_font_size_override("font_size", 24)
			_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 1.0))
			_label.add_theme_color_override("font_outline_color", Color(0.2, 0.2, 0.25, 1.0))
			_label.add_theme_constant_override("outline_size", 3)


func _process(delta: float) -> void:
	_elapsed_s += delta
	var t := clampf(_elapsed_s / DURATION_S, 0.0, 1.0)
	var ease := 1.0 - pow(1.0 - t, 2.0)
	global_position = _start_pos + Vector2(0.0, FLOAT_Y * ease)
	modulate.a = 1.0 - t
	if _tier == "heavy":
		if t < 0.25:
			var pop := t / 0.25
			scale = Vector2.ONE * lerpf(1.25, 1.0, pop)
		else:
			scale = Vector2.ONE
	if _elapsed_s >= DURATION_S:
		queue_free()
