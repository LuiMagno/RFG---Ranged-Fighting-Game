class_name CameraSystem
extends Node

enum DominantState { NORMAL, HIT_STOP, SLOW_MO, FOCUS, CINEMATIC, CUSTOM }
enum HitStopScope { GLOBAL, PARTIAL }

const VIEWPORT_SIZE := Vector2(1920.0, 864.0)
const VIEWPORT_CENTER := Vector2(960.0, 432.0)
const KO_IMPACT_SLOW_MOTION := 0
const KO_IMPACT_HIT_STOP := 1
const KO_IMPACT_HYBRID := 2

const _KO_ROUND_CONFIG := preload("res://levels/duel/camera/presets/ko_round_default.tres")

@export var ko_round_config: CameraKoRoundConfig

@onready var _camera: Camera2D = _resolve_camera()
@onready var _flash_overlay: ColorRect = _resolve_flash_overlay()

var _dominant_state: DominantState = DominantState.NORMAL
var _time_scale_end_usec: int = 0
var _time_scale_before_override: float = 1.0
var _time_scale_override_value: float = 1.0

var _shake_time_left: float = 0.0
var _shake_duration: float = 0.0
var _shake_intensity: float = 0.0
var _shake_curve: Curve

var _flash_tween: Tween
var _camera_tween: Tween
var _last_process_usec: int = 0
var _ko_sequence_generation: int = 0
var _ko_sequence_running: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("camera_system")
	if ko_round_config == null:
		ko_round_config = _KO_ROUND_CONFIG
	_last_process_usec = Time.get_ticks_usec()
	reset_to_default()


func _exit_tree() -> void:
	_restore_time_scale()


func _resolve_camera() -> Camera2D:
	var rig := get_parent()
	if rig == null:
		return null
	return rig.get_node_or_null("Camera2D") as Camera2D


func _resolve_flash_overlay() -> ColorRect:
	var rig := get_parent()
	if rig == null:
		return null
	return rig.get_node_or_null("CameraFxLayer/FlashOverlay") as ColorRect


func _process(_delta: float) -> void:
	var now_usec := Time.get_ticks_usec()
	var real_delta := float(now_usec - _last_process_usec) / 1_000_000.0
	_last_process_usec = now_usec

	if get_tree().paused:
		if _dominant_state == DominantState.HIT_STOP or _dominant_state == DominantState.SLOW_MO:
			cancel_dominant_effect()
		if _ko_sequence_running:
			_abort_ko_sequence()
		return

	_update_time_scale_override(now_usec)
	_update_shake(real_delta)


func get_dominant_state() -> DominantState:
	return _dominant_state


func is_ko_sequence_running() -> bool:
	return _ko_sequence_running


func request_apply_preset(preset: CameraEffectPreset) -> void:
	if preset == null or _ko_sequence_running:
		return
	if preset.shake_duration > 0.0 and preset.shake_intensity > 0.0:
		request_shake(preset.shake_intensity, preset.shake_duration, preset.shake_curve)
	if preset.hit_stop_duration > 0.0:
		request_hit_stop(preset.hit_stop_duration)
	if preset.flash_duration > 0.0 and preset.flash_intensity > 0.0:
		request_flash(preset.flash_color, preset.flash_intensity, preset.flash_duration)


func request_shake(intensity: float, duration: float, curve: Curve = null) -> void:
	if intensity <= 0.0 or duration <= 0.0 or _camera == null:
		return
	if intensity >= _shake_intensity or _shake_time_left <= 0.0:
		_shake_intensity = intensity
		_shake_duration = duration
		_shake_time_left = duration
		_shake_curve = curve


func request_hit_stop(duration: float, scope: HitStopScope = HitStopScope.GLOBAL) -> void:
	if duration <= 0.0:
		return
	if get_tree().paused:
		return
	if scope == HitStopScope.PARTIAL:
		push_warning("CameraSystem: HitStopScope.PARTIAL not implemented yet.")
		return
	if _dominant_state == DominantState.CINEMATIC and not _ko_sequence_running:
		return
	_apply_time_scale_override(0.0, duration)


func request_slow_motion(scale: float, duration: float) -> void:
	if duration <= 0.0:
		return
	if get_tree().paused:
		return
	if _dominant_state == DominantState.CINEMATIC and not _ko_sequence_running:
		return
	_apply_time_scale_override(clampf(scale, 0.01, 1.0), duration)


func request_flash(color: Color, intensity: float, duration: float) -> void:
	if _flash_overlay == null or duration <= 0.0 or intensity <= 0.0:
		return
	intensity = clampf(intensity, 0.0, 1.0)
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()

	var peak := Color(color.r, color.g, color.b, intensity)
	_flash_overlay.color = Color(peak.r, peak.g, peak.b, 0.0)
	_flash_overlay.visible = true

	var rise := maxf(duration * 0.15, 0.01)
	var fall := maxf(duration - rise, 0.01)
	_flash_tween = create_tween()
	_flash_tween.set_ignore_time_scale(true)
	_flash_tween.tween_property(_flash_overlay, "color", peak, rise).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_flash_tween.tween_property(_flash_overlay, "color:a", 0.0, fall).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_flash_tween.tween_callback(_hide_flash_overlay)


func request_zoom(
	target_zoom: Vector2,
	duration: float,
	hold: float = 0.0,
	return_duration: float = -1.0,
) -> void:
	if _camera == null or duration <= 0.0:
		return
	if _dominant_state == DominantState.CINEMATIC:
		return
	_kill_camera_tween()
	var ret_d := return_duration if return_duration >= 0.0 else duration
	_camera_tween = create_tween()
	_camera_tween.set_ignore_time_scale(true)
	_camera_tween.tween_property(_camera, "zoom", target_zoom, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if hold > 0.0:
		_camera_tween.tween_interval(hold)
	_camera_tween.tween_property(_camera, "zoom", Vector2.ONE, ret_d).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func request_focus(
	target: Node2D,
	duration: float,
	zoom: Vector2 = Vector2.ONE,
	padding: float = 64.0,
) -> void:
	if target == null or _camera == null or duration <= 0.0:
		return
	if _dominant_state == DominantState.CINEMATIC:
		return
	var focus_pos := _compute_focus_position(target.global_position, zoom, padding)
	_dominant_state = DominantState.FOCUS
	_kill_camera_tween()
	_camera_tween = create_tween()
	_camera_tween.set_ignore_time_scale(true)
	_camera_tween.set_parallel(true)
	_camera_tween.tween_property(_camera, "position", focus_pos, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_camera_tween.tween_property(_camera, "zoom", zoom, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_camera_tween.set_parallel(false)
	_camera_tween.tween_callback(func() -> void:
		if _dominant_state == DominantState.FOCUS:
			_dominant_state = DominantState.NORMAL
	)


func request_focus_point(
	world_pos: Vector2,
	duration: float,
	zoom: Vector2 = Vector2.ONE,
) -> void:
	if _camera == null or duration <= 0.0:
		return
	if _dominant_state == DominantState.CINEMATIC:
		return
	var focus_pos := _compute_focus_position(world_pos, zoom, 0.0)
	_dominant_state = DominantState.FOCUS
	_kill_camera_tween()
	_camera_tween = create_tween()
	_camera_tween.set_ignore_time_scale(true)
	_camera_tween.set_parallel(true)
	_camera_tween.tween_property(_camera, "position", focus_pos, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_camera_tween.tween_property(_camera, "zoom", zoom, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_camera_tween.set_parallel(false)
	_camera_tween.tween_callback(func() -> void:
		if _dominant_state == DominantState.FOCUS:
			_dominant_state = DominantState.NORMAL
	)


func request_cinematic(sequence: CameraCinematicSequence) -> void:
	push_warning("CameraSystem.request_cinematic: not implemented yet.")


func play_ko_round_sequence(victim: Node2D, winner: Node2D, impact_style: int) -> void:
	if victim == null or winner == null or _camera == null:
		return
	var cfg := ko_round_config if ko_round_config != null else _KO_ROUND_CONFIG

	_ko_sequence_generation += 1
	var gen := _ko_sequence_generation
	_ko_sequence_running = true
	_dominant_state = DominantState.CINEMATIC
	cancel_overlays()
	_kill_camera_tween()
	cancel_dominant_effect()

	await _ko_phase_impact(victim, cfg, impact_style, gen)
	if not _ko_sequence_still_valid(gen):
		return

	await _ko_phase_winner(winner, cfg, gen)
	if not _ko_sequence_still_valid(gen):
		return

	_ko_sequence_running = false
	if _dominant_state == DominantState.CINEMATIC:
		_dominant_state = DominantState.NORMAL
	_restore_time_scale()


func cancel_overlays() -> void:
	_shake_time_left = 0.0
	_shake_intensity = 0.0
	if _camera != null:
		_camera.offset = Vector2.ZERO
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_hide_flash_overlay()


func cancel_dominant_effect() -> void:
	_time_scale_end_usec = 0
	_restore_time_scale()
	if _dominant_state == DominantState.HIT_STOP or _dominant_state == DominantState.SLOW_MO:
		_dominant_state = DominantState.CINEMATIC if _ko_sequence_running else DominantState.NORMAL
	elif _dominant_state != DominantState.CINEMATIC:
		_dominant_state = DominantState.NORMAL


func reset_to_default() -> void:
	_abort_ko_sequence()
	cancel_overlays()
	cancel_dominant_effect()
	_kill_camera_tween()
	if _camera != null:
		_camera.offset = Vector2.ZERO
		_camera.zoom = Vector2.ONE
		_camera.position = VIEWPORT_CENTER
	_dominant_state = DominantState.NORMAL


func _ko_phase_impact(victim: Node2D, cfg: CameraKoRoundConfig, impact_style: int, gen: int) -> void:
	var victim_zoom := Vector2.ONE * cfg.victim_zoom
	await _tween_focus_to_node(victim, victim_zoom, cfg.victim_pan_duration, gen)
	if not _ko_sequence_still_valid(gen):
		return

	request_shake(cfg.impact_shake_intensity, cfg.impact_shake_duration)
	request_flash(cfg.impact_flash_color, cfg.impact_flash_intensity, cfg.impact_flash_duration)

	match impact_style:
		KO_IMPACT_HIT_STOP:
			request_hit_stop(cfg.hit_stop_duration)
			await _wait_real(cfg.hit_stop_duration + cfg.victim_hold, gen)
		KO_IMPACT_HYBRID:
			request_hit_stop(cfg.hybrid_hit_stop_duration)
			await _wait_real(cfg.hybrid_hit_stop_duration, gen)
			if not _ko_sequence_still_valid(gen):
				return
			cancel_dominant_effect()
			request_slow_motion(cfg.hybrid_slow_scale, cfg.hybrid_slow_duration)
			await _wait_real(cfg.hybrid_slow_duration + cfg.victim_hold, gen)
		_:
			request_slow_motion(cfg.slow_motion_scale, cfg.slow_motion_duration)
			await _wait_real(cfg.slow_motion_duration + cfg.victim_hold, gen)

	cancel_dominant_effect()


func _ko_phase_winner(winner: Node2D, cfg: CameraKoRoundConfig, gen: int) -> void:
	var winner_zoom := Vector2.ONE * cfg.winner_zoom
	await _tween_focus_to_node(winner, winner_zoom, cfg.winner_pan_duration, gen)
	if not _ko_sequence_still_valid(gen):
		return

	request_shake(cfg.winner_shake_intensity, cfg.winner_shake_duration)
	await _wait_real(cfg.winner_hold, gen)


func _tween_focus_to_node(target: Node2D, zoom: Vector2, duration: float, gen: int) -> void:
	if not is_instance_valid(target) or _camera == null:
		return
	var focus_pos := _compute_focus_position(target.global_position, zoom, 0.0)
	_kill_camera_tween()
	_camera_tween = create_tween()
	_camera_tween.set_ignore_time_scale(true)
	_camera_tween.set_parallel(true)
	_camera_tween.tween_property(_camera, "position", focus_pos, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_camera_tween.tween_property(_camera, "zoom", zoom, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await _camera_tween.finished
	if not _ko_sequence_still_valid(gen):
		return


func _compute_focus_position(world_pos: Vector2, zoom: Vector2, padding: float) -> Vector2:
	var desired := world_pos
	if padding > 0.0:
		var to_center := VIEWPORT_CENTER - world_pos
		if to_center.length_squared() > padding * padding:
			desired = world_pos + to_center.normalized() * padding
	return _clamp_camera_position(desired, zoom)


func _clamp_camera_position(desired: Vector2, zoom: Vector2) -> Vector2:
	var half_visible := VIEWPORT_SIZE / (2.0 * zoom)
	var min_pos := half_visible
	var max_pos := VIEWPORT_SIZE - half_visible
	return Vector2(
		clampf(desired.x, min_pos.x, max_pos.x),
		clampf(desired.y, min_pos.y, max_pos.y),
	)


func _apply_time_scale_override(scale: float, duration: float) -> void:
	if get_tree().paused:
		return
	if _dominant_state == DominantState.CINEMATIC and not _ko_sequence_running:
		return

	var end_usec := Time.get_ticks_usec() + int(duration * 1_000_000.0)
	_time_scale_end_usec = maxi(_time_scale_end_usec, end_usec)

	if _dominant_state != DominantState.HIT_STOP and _dominant_state != DominantState.SLOW_MO:
		_time_scale_before_override = Engine.time_scale

	_time_scale_override_value = scale
	if scale <= 0.01:
		_dominant_state = DominantState.HIT_STOP
	else:
		_dominant_state = DominantState.SLOW_MO
	Engine.time_scale = scale


func _update_time_scale_override(now_usec: int) -> void:
	if _dominant_state != DominantState.HIT_STOP and _dominant_state != DominantState.SLOW_MO:
		return
	if now_usec >= _time_scale_end_usec:
		cancel_dominant_effect()


func _update_shake(real_delta: float) -> void:
	if _camera == null:
		return
	if _shake_time_left <= 0.0:
		_camera.offset = Vector2.ZERO
		return

	var t := 1.0 - (_shake_time_left / maxf(_shake_duration, 0.0001))
	var envelope := 1.0 - t
	if _shake_curve != null:
		envelope = _shake_curve.sample(t)

	_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_intensity * envelope
	_shake_time_left = maxf(0.0, _shake_time_left - real_delta)


func _restore_time_scale() -> void:
	if _dominant_state == DominantState.HIT_STOP or _dominant_state == DominantState.SLOW_MO:
		Engine.time_scale = _time_scale_before_override if _time_scale_before_override > 0.0 else 1.0
	elif Engine.time_scale <= 0.0 or Engine.time_scale < 1.0:
		Engine.time_scale = 1.0


func _wait_real(seconds: float, gen: int) -> void:
	if seconds <= 0.0:
		return
	var timer := get_tree().create_timer(seconds, true, false, true)
	await timer.timeout
	if not _ko_sequence_still_valid(gen):
		return


func _ko_sequence_still_valid(gen: int) -> bool:
	return gen == _ko_sequence_generation and is_inside_tree() and not get_tree().paused


func _abort_ko_sequence() -> void:
	_ko_sequence_generation += 1
	_ko_sequence_running = false
	_kill_camera_tween()
	cancel_overlays()
	cancel_dominant_effect()
	if _camera != null:
		_camera.offset = Vector2.ZERO
		_camera.zoom = Vector2.ONE
		_camera.position = VIEWPORT_CENTER
	_dominant_state = DominantState.NORMAL


func _kill_camera_tween() -> void:
	if _camera_tween != null and _camera_tween.is_valid():
		_camera_tween.kill()
	_camera_tween = null


func _hide_flash_overlay() -> void:
	if _flash_overlay == null:
		return
	_flash_overlay.visible = false
	_flash_overlay.color = Color(_flash_overlay.color.r, _flash_overlay.color.g, _flash_overlay.color.b, 0.0)
