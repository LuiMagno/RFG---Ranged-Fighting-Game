extends Area2D
class_name EsqueletoSpectralJaw

## Mandíbula espectral: surge, persegue em cima do inimigo e morde (dano + podridão + knockback).

enum State { EMERGING, CHASING, BITING, DONE }

const SPECTRAL_COLOR := Color(0.55, 0.35, 1.15, 0.9)
const MOUTH_DARK := Color(0.12, 0.05, 0.2, 0.92)
const TOOTH_COLOR := Color(0.94, 0.92, 1.0, 0.98)
const BITE_CLOSE_S := 0.12
const FADE_OUT_S := 0.22
const CHASE_BOB_S := 0.22
const CHASE_SNAP_RADIUS := 34.0
const EMERGE_RISE_Y := 52.0

var _owner: Player
var _victim: Player
var _state: State = State.EMERGING
var _bite_damage: int = 22
var _podridao_damage_per_tick: int = 5
var _podridao_duration_s: float = 3.0
var _podridao_tick_interval_s: float = 0.5
var _podridao_slow_mul: float = 0.9
var _knockback_x: float = 300.0
var _knockback_up: float = 150.0
var _emerge_s: float = 0.7
var _chase_duration_s: float = 2.5
var _chase_speed: float = 200.0
var _chase_time_left: float = 0.0
var _chase_bob_left: float = 0.0
var _bite_applied := false
var _fading_out := false
var _visual_base_y: float = 0.0

@onready var _visual_root: Node2D = $VisualRoot
@onready var _upper_jaw: Polygon2D = $VisualRoot/UpperJaw
@onready var _lower_pivot: Node2D = $VisualRoot/LowerJawPivot
@onready var _glow: Polygon2D = $VisualRoot/Glow
@onready var _mouth_cavity: Polygon2D = $VisualRoot/MouthCavity
@onready var _bite_hitbox: CollisionShape2D = $VisualRoot/BiteHitbox


func setup(owner_player: Player, victim: Player, config: Dictionary) -> void:
	_owner = owner_player
	_victim = victim
	_bite_damage = int(config.get("bite_damage", 22))
	_podridao_damage_per_tick = int(config.get("podridao_damage_per_tick", 5))
	_podridao_duration_s = float(config.get("podridao_duration_s", 3.0))
	_podridao_tick_interval_s = float(config.get("podridao_tick_interval_s", 0.5))
	_podridao_slow_mul = float(config.get("podridao_slow_mul", 0.9))
	_knockback_x = float(config.get("knockback_x", 300.0))
	_knockback_up = float(config.get("knockback_up", 150.0))
	_emerge_s = maxf(0.12, float(config.get("emerge_s", 0.7)))
	_chase_duration_s = maxf(0.2, float(config.get("chase_duration_s", 2.5)))
	_chase_speed = maxf(80.0, float(config.get("chase_speed", 200.0)))
	_apply_spectral_colors()
	_place_spawn_on_victim()
	_start_emergence()


func _ready() -> void:
	z_index = 14
	monitoring = false
	_apply_spectral_colors()


func _physics_process(delta: float) -> void:
	if _state == State.DONE or _fading_out:
		return
	if _victim == null or not is_instance_valid(_victim):
		_fade_out_and_free()
		return
	match _state:
		State.CHASING:
			_process_chase(delta)


func _place_spawn_on_victim() -> void:
	global_position = _chase_target_global() + Vector2(0.0, EMERGE_RISE_Y)
	_visual_root.scale = Vector2(0.12, 0.12)
	_visual_root.modulate = Color(SPECTRAL_COLOR.r, SPECTRAL_COLOR.g, SPECTRAL_COLOR.b, 0.0)
	_visual_root.position = Vector2.ZERO
	_upper_jaw.position = Vector2(0.0, -14.0)
	_lower_pivot.rotation_degrees = 28.0
	if _glow != null:
		_glow.modulate = Color(1.0, 1.0, 1.0, 0.2)


func _start_emergence() -> void:
	_state = State.EMERGING
	SfxManager.play("shoot_magic", global_position, 0.78, -2.0)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual_root, "modulate:a", 1.0, _emerge_s)
	tween.tween_property(_visual_root, "scale", Vector2(1.0, 1.0), _emerge_s).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "global_position", _chase_target_global(), _emerge_s).set_trans(Tween.TRANS_BACK)
	tween.chain().tween_callback(_begin_chase)


func _begin_chase() -> void:
	_state = State.CHASING
	monitoring = true
	_chase_time_left = _chase_duration_s
	_visual_base_y = _visual_root.position.y
	_chase_bob_left = CHASE_BOB_S
	if _glow != null:
		_glow.modulate = Color(1.1, 0.8, 1.3, 0.85)


func _process_chase(delta: float) -> void:
	_chase_time_left -= delta
	_chase_bob_left -= delta
	if _chase_bob_left <= 0.0:
		_chase_bob_left = CHASE_BOB_S

	if _hitbox_touches_victim():
		_start_bite()
		return

	if _chase_time_left <= 0.0:
		_miss_and_fade()
		return

	var target := _chase_target_global()
	var to_target := target - global_position
	var dist := to_target.length()
	var step := _chase_speed * delta
	if dist <= step:
		global_position = target
	else:
		global_position += to_target / dist * step

	var bob := sin((CHASE_BOB_S - _chase_bob_left) / CHASE_BOB_S * TAU) * 3.0
	_visual_root.position.y = _visual_base_y + bob
	_lower_pivot.rotation_degrees = lerpf(26.0, 18.0, sin(Time.get_ticks_msec() * 0.014) * 0.5 + 0.5)


func _start_bite() -> void:
	if _state == State.BITING or _bite_applied:
		return
	_state = State.BITING
	monitoring = false
	global_position = _chase_target_global()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_upper_jaw, "position:y", -20.0, BITE_CLOSE_S).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_lower_pivot, "rotation_degrees", -2.0, BITE_CLOSE_S).set_trans(Tween.TRANS_BACK)
	tween.chain().tween_callback(_apply_bite_damage)
	tween.tween_interval(0.08)
	tween.tween_callback(_fade_out_and_free)


func _apply_bite_damage() -> void:
	if _bite_applied:
		return
	_bite_applied = true
	if _victim == null or not is_instance_valid(_victim):
		return
	if not _hitbox_touches_victim():
		SfxManager.play("grenade_throw", global_position, 0.55, -6.0)
		return
	if _bite_damage > 0:
		_victim.take_damage(_bite_damage)
	_apply_bite_knockback()
	_victim.apply_esqueleto_podridao(
		_podridao_damage_per_tick,
		_podridao_duration_s,
		_podridao_tick_interval_s,
		_podridao_slow_mul,
	)
	SfxManager.play("hit_heavy", _victim.global_position, 1.05, 2.0)


func _apply_bite_knockback() -> void:
	if _owner == null or not is_instance_valid(_owner):
		return
	var push_x := signf(_victim.global_position.x - _owner.global_position.x)
	if absf(push_x) < 0.01:
		push_x = _player_face_sign(_victim)
	_victim.apply_knockback(Vector2(push_x * _knockback_x, -_knockback_up))


func _hitbox_touches_victim() -> bool:
	if _victim == null or not is_instance_valid(_victim):
		return false
	var body_rect := _victim.get_body_collision_rect()
	if _rects_overlap(_get_bite_hitbox_rect(), body_rect):
		return true
	if monitoring and overlaps_body(_victim):
		return true
	return global_position.distance_to(body_rect.get_center()) <= CHASE_SNAP_RADIUS


func _get_bite_hitbox_rect() -> Rect2:
	if _bite_hitbox == null or _bite_hitbox.shape == null:
		return Rect2(global_position.x - 24.0, global_position.y - 28.0, 48.0, 56.0)
	var local_rect := _bite_hitbox.shape.get_rect()
	return _bite_hitbox.global_transform * local_rect


func _rects_overlap(a: Rect2, b: Rect2) -> bool:
	return a.intersects(b)


func _miss_and_fade() -> void:
	if _fading_out:
		return
	_state = State.DONE
	monitoring = false
	SfxManager.play("dash", global_position, 0.7, -8.0)
	_fade_out_and_free()


func _fade_out_and_free() -> void:
	if _fading_out:
		return
	_fading_out = true
	_state = State.DONE
	monitoring = false
	var tween := create_tween()
	tween.tween_property(_visual_root, "modulate:a", 0.0, FADE_OUT_S)
	tween.tween_callback(queue_free)


func _chase_target_global() -> Vector2:
	return _victim.get_body_collision_rect().get_center()


func _apply_spectral_colors() -> void:
	if _mouth_cavity != null:
		_mouth_cavity.color = MOUTH_DARK
	if _glow != null:
		_glow.color = Color(SPECTRAL_COLOR.r, SPECTRAL_COLOR.g, SPECTRAL_COLOR.b, 0.38)
	if _upper_jaw != null:
		_upper_jaw.color = SPECTRAL_COLOR
	if _lower_pivot != null:
		var lower := _lower_pivot.get_node_or_null("LowerJaw") as Polygon2D
		if lower != null:
			lower.color = SPECTRAL_COLOR
		for child in _lower_pivot.get_children():
			if child is Polygon2D and child.name.begins_with("Tooth"):
				(child as Polygon2D).color = TOOTH_COLOR
	for child in _visual_root.get_children():
		if child is Polygon2D and child.name.begins_with("UpperTooth"):
			(child as Polygon2D).color = TOOTH_COLOR


func _player_face_sign(player: Player) -> float:
	var facing := player.get_node_or_null("FacingRoot") as Node2D
	if facing != null and absf(facing.scale.x) > 0.01:
		return signf(facing.scale.x)
	return 1.0 if player.player_id == 1 else -1.0
