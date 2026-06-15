extends Node2D
class_name EsqueletoCarnivorousPlant

## Planta carnívora: pescoço estica e aponta para morder inimigos próximos.

const POT_RIM_COLOR := Color(0.4, 0.24, 0.12, 1.0)
const POT_BODY_COLOR := Color(0.58, 0.36, 0.22, 1.0)
const POT_HIGHLIGHT_COLOR := Color(0.72, 0.48, 0.3, 0.55)
const POT_SOIL_COLOR := Color(0.26, 0.16, 0.1, 1.0)
const LEAF_DARK_COLOR := Color(0.12, 0.42, 0.14, 1.0)
const LEAF_COLOR := Color(0.2, 0.62, 0.22, 1.0)
const LEAF_VEIN_COLOR := Color(0.34, 0.82, 0.36, 0.7)
const NECK_SHADOW_COLOR := Color(0.08, 0.32, 0.1, 0.65)
const NECK_COLOR := Color(0.16, 0.54, 0.2, 1.0)
const NECK_STRIPE_COLOR := Color(0.28, 0.72, 0.32, 0.75)
const HEAD_SPINE_COLOR := Color(0.14, 0.48, 0.18, 1.0)
const CAVITY_COLOR := Color(0.14, 0.04, 0.06, 0.95)
const MOUTH_COLOR := Color(0.82, 0.2, 0.16, 0.98)
const LIP_COLOR := Color(0.95, 0.42, 0.34, 0.85)
const LOWER_MOUTH_COLOR := Color(0.78, 0.18, 0.14, 0.98)
const TONGUE_COLOR := Color(0.72, 0.22, 0.28, 0.9)
const TOOTH_COLOR := Color(0.96, 0.94, 0.86, 1.0)
const NECK_BASE_LEN := 48.0
const NECK_MIN_STRETCH := 1.0
const NECK_MAX_STRETCH := 2.75
const NECK_REST_ROTATION := 0.0
const NECK_TRACK_SPEED := 9.0
const NECK_STRETCH_SPEED := 10.0
const IDLE_SWAY_SPEED := 2.2
const IDLE_SWAY_AMOUNT := 0.12

var _owner: Player
var _life_left: float = 10.0
var _bite_radius: float = 104.0
var _bite_damage: int = 8
var _bite_interval_s: float = 0.55
var _putrefacao_stacks: int = 1
var _putrefacao_duration_s: float = 4.0
var _putrefacao_dmg_per_stack: int = 2
var _putrefacao_tick_interval_s: float = 0.6
var _bite_cd_by_player: Dictionary = {}
var _emerge_left: float = 0.35
var _lower_open: float = 22.0
var _neck_angle: float = NECK_REST_ROTATION
var _neck_stretch: float = NECK_MIN_STRETCH
var _biting: bool = false
var _idle_phase: float = 0.0

@onready var _visual: Node2D = $VisualRoot
@onready var _neck_pivot: Node2D = $VisualRoot/NeckPivot
@onready var _neck_mesh: Node2D = $VisualRoot/NeckPivot/NeckMesh
@onready var _head_pivot: Node2D = $VisualRoot/NeckPivot/HeadPivot
@onready var _lower_jaw: Node2D = $VisualRoot/NeckPivot/HeadPivot/LowerJawPivot
@onready var _mouth_cavity: Polygon2D = $VisualRoot/NeckPivot/HeadPivot/MouthCavity


func setup(owner_player: Player, config: Dictionary) -> void:
	_owner = owner_player
	_life_left = float(config.get("lifetime_s", 10.0))
	_bite_radius = float(config.get("bite_radius", 104.0))
	_bite_damage = int(config.get("bite_damage", 8))
	_bite_interval_s = float(config.get("bite_interval_s", 0.55))
	_putrefacao_stacks = int(config.get("putrefacao_stacks_per_bite", 1))
	_putrefacao_duration_s = float(config.get("putrefacao_duration_s", 4.0))
	_putrefacao_dmg_per_stack = int(config.get("putrefacao_damage_per_stack", 2))
	_putrefacao_tick_interval_s = float(config.get("putrefacao_tick_interval_s", 0.6))
	_neck_angle = NECK_REST_ROTATION
	_neck_stretch = NECK_MIN_STRETCH
	_apply_colors()
	_sync_neck_transform()
	_visual.scale = Vector2(0.15, 0.15)
	_visual.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_visual, "modulate:a", 1.0, 0.28)


func _ready() -> void:
	add_to_group("esqueleto_carnivorous_plants")
	z_index = 6
	_idle_phase = randf() * TAU
	_apply_colors()
	_sync_neck_transform()


func _physics_process(delta: float) -> void:
	if _emerge_left > 0.0:
		_emerge_left -= delta
	_life_left -= delta
	_idle_phase += delta * IDLE_SWAY_SPEED
	if _life_left <= 0.0:
		_fade_and_free()
		return
	if not _biting:
		_update_neck_tracking(delta)
	_tick_bite_cooldowns(delta)
	_try_bite_nearby()


func _update_neck_tracking(delta: float) -> void:
	var target := _find_nearest_victim()
	var want_angle := NECK_REST_ROTATION
	var want_stretch := NECK_MIN_STRETCH
	if target != null:
		want_angle = _angle_to_global_point(target.global_position)
		want_stretch = _stretch_for_global_point(target.global_position, 0.92)
	else:
		want_angle += sin(_idle_phase) * IDLE_SWAY_AMOUNT
	_neck_angle = lerp_angle(_neck_angle, want_angle, clampf(NECK_TRACK_SPEED * delta, 0.0, 1.0))
	_neck_stretch = lerpf(_neck_stretch, want_stretch, clampf(NECK_STRETCH_SPEED * delta, 0.0, 1.0))
	_sync_neck_transform()


func _stretch_for_global_point(world_pos: Vector2, mul: float = 1.0) -> float:
	var dist := _neck_pivot.global_position.distance_to(world_pos)
	var stretch := dist / NECK_BASE_LEN
	return clampf(stretch * mul, NECK_MIN_STRETCH, NECK_MAX_STRETCH)


func _angle_to_global_point(world_pos: Vector2) -> float:
	var dir := world_pos - _neck_pivot.global_position
	if dir.length_squared() < 1.0:
		return NECK_REST_ROTATION
	return atan2(dir.y, dir.x) + PI * 0.5


func _sync_neck_transform() -> void:
	if _neck_pivot == null:
		return
	_neck_pivot.rotation = _neck_angle
	if _neck_mesh != null:
		_neck_mesh.scale = Vector2(1.0, _neck_stretch)
	if _head_pivot != null:
		_head_pivot.position = Vector2(0.0, -NECK_BASE_LEN * _neck_stretch)


func _find_nearest_victim() -> Player:
	var best: Player = null
	var best_dist := INF
	for n in get_tree().get_nodes_in_group("players"):
		if not (n is Player):
			continue
		var pl := n as Player
		if pl == _owner or pl.hp <= 0:
			continue
		var dist := global_position.distance_to(pl.global_position)
		if dist > _bite_radius or dist >= best_dist:
			continue
		best = pl
		best_dist = dist
	return best


func _tick_bite_cooldowns(delta: float) -> void:
	for key in _bite_cd_by_player.keys():
		_bite_cd_by_player[key] = float(_bite_cd_by_player[key]) - delta
		if _bite_cd_by_player[key] <= 0.0:
			_bite_cd_by_player.erase(key)


func _try_bite_nearby() -> void:
	if _biting:
		return
	var victim := _find_nearest_victim()
	if victim == null:
		return
	if _bite_cd_by_player.has(victim.get_instance_id()):
		return
	_bite_target(victim)


func _bite_target(victim: Player) -> void:
	_bite_cd_by_player[victim.get_instance_id()] = _bite_interval_s
	if _bite_damage > 0:
		victim.take_damage(_bite_damage)
	victim.add_esqueleto_putrefacao_charge(
		_putrefacao_stacks,
		_putrefacao_duration_s,
		_putrefacao_dmg_per_stack,
		_putrefacao_tick_interval_s,
	)
	SfxManager.play("hit_heavy", victim.global_position, 0.92, 1.0)
	_play_bite_anim(victim)


func _play_bite_anim(victim: Player) -> void:
	_biting = true
	var strike_angle := _angle_to_global_point(victim.global_position)
	var strike_stretch := _stretch_for_global_point(victim.global_position, 1.15)
	var recover_stretch := _stretch_for_global_point(victim.global_position, 0.88)

	var tween := create_tween()
	tween.tween_method(_set_neck_angle, _neck_angle, strike_angle, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_method(_set_neck_stretch, _neck_stretch, strike_stretch, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_mouth_cavity, "scale", Vector2(0.82, 0.82), 0.07)
	tween.tween_property(_lower_jaw, "rotation_degrees", -10.0, 0.07).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_method(_set_neck_stretch, strike_stretch, recover_stretch, 0.18)
	tween.parallel().tween_property(_mouth_cavity, "scale", Vector2.ONE, 0.12)
	tween.tween_property(_lower_jaw, "rotation_degrees", _lower_open, 0.1)
	tween.tween_callback(func() -> void: _biting = false)


func _set_neck_angle(angle: float) -> void:
	_neck_angle = angle
	_sync_neck_transform()


func _set_neck_stretch(stretch: float) -> void:
	_neck_stretch = stretch
	_sync_neck_transform()


func _fade_and_free() -> void:
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(_visual, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)


func _apply_colors() -> void:
	_set_poly_color("VisualRoot/PotRim", POT_RIM_COLOR)
	_set_poly_color("VisualRoot/PotBody", POT_BODY_COLOR)
	_set_poly_color("VisualRoot/PotHighlight", POT_HIGHLIGHT_COLOR)
	_set_poly_color("VisualRoot/PotSoil", POT_SOIL_COLOR)
	_set_poly_color("VisualRoot/LeafBackL", LEAF_DARK_COLOR)
	_set_poly_color("VisualRoot/LeafBackR", LEAF_DARK_COLOR)
	_set_poly_color("VisualRoot/LeafL", LEAF_COLOR)
	_set_poly_color("VisualRoot/LeafR", LEAF_COLOR)
	_set_poly_color("VisualRoot/LeafVeinL", LEAF_VEIN_COLOR)
	_set_poly_color("VisualRoot/LeafVeinR", LEAF_VEIN_COLOR)
	_set_poly_color("VisualRoot/NeckPivot/NeckMesh/NeckShadow", NECK_SHADOW_COLOR)
	_set_poly_color("VisualRoot/NeckPivot/NeckMesh/Neck", NECK_COLOR)
	_set_poly_color("VisualRoot/NeckPivot/NeckMesh/NeckStripe", NECK_STRIPE_COLOR)
	_set_poly_color("VisualRoot/NeckPivot/HeadPivot/HeadSpine", HEAD_SPINE_COLOR)
	_set_poly_color("VisualRoot/NeckPivot/HeadPivot/MouthCavity", CAVITY_COLOR)
	_set_poly_color("VisualRoot/NeckPivot/HeadPivot/UpperMouth", MOUTH_COLOR)
	_set_poly_color("VisualRoot/NeckPivot/HeadPivot/UpperLip", LIP_COLOR)
	_set_poly_color("VisualRoot/NeckPivot/HeadPivot/LowerJawPivot/LowerMouth", LOWER_MOUTH_COLOR)
	_set_poly_color("VisualRoot/NeckPivot/HeadPivot/LowerJawPivot/Tongue", TONGUE_COLOR)
	if _head_pivot != null:
		for child in _head_pivot.get_children():
			if child is Polygon2D and child.name.begins_with("Tooth"):
				child.color = TOOTH_COLOR
	if _lower_jaw != null:
		for child in _lower_jaw.get_children():
			if child is Polygon2D and child.name.begins_with("Tooth"):
				child.color = TOOTH_COLOR


func _set_poly_color(path: String, color: Color) -> void:
	if not has_node(path):
		return
	var node := get_node(path)
	if node is Polygon2D:
		node.color = color
