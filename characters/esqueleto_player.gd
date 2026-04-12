extends Player
class_name EsqueletoPlayer

## Personagem base: tiro carregado (velocidade ∝ carga), trajetória reta (sem gravidade) como o pistoleiro.
## Tiro base: mínimo 1 s entre disparos (cooldown após soltar o carregamento).
## Dash, salto duplo. G: arma o próximo disparo do mouse como 3 tiros (uma vez, cooldown).
## F/J: segura para carregar um projétil grande em linha reta (tamanho e impulso ∝ carga).

const MIN_SHOOT_COOLDOWN_S := 1.0

## Pulo no meio do dash: mais horizontal, menos vertical que o pulo normal.
@export_range(0.2, 1.0, 0.01) var dash_jump_vertical_mul: float = 0.5
@export var dash_jump_horizontal_speed: float = 520.0

## Espaçamento lateral entre os 3 tiros paralelos (mesma direção que o tiro normal).
@export var triple_parallel_lane_spacing: float = 10.0
@export var triple_shot_cooldown: float = 5.0
@export var beam_skill_cooldown: float = 4.25
@export var beam_max_charge_time: float = 0.65
@export var beam_min_scale: float = 1.85
@export var beam_max_scale: float = 3.45
@export var beam_damage: int = 36
@export var beam_speed_mul_min: float = 1.05
@export var beam_speed_mul_max: float = 1.42

var _triple_cd_left := 0.0
var _triple_armed := false
var _beam_cd_left := 0.0
var _beam_charging := false
var _beam_charge_time := 0.0
var _last_back_tap_time_s := -100.0


func is_esqueleto() -> bool:
	return true


func _ready() -> void:
	shoot_cooldown = maxf(MIN_SHOOT_COOLDOWN_S, shoot_cooldown)
	super._ready()


func _get_dash_stats() -> Dictionary:
	return {
		"speed": 620.0,
		"duration": 0.2,
		"cooldown": 0.1,
		"gravity_scale": 0.0,
	}


func _dash_just_pressed() -> bool:
	return false


func _update_double_tap_forward_movement() -> void:
	if not input_enabled:
		return
	if _forward_action_just_pressed():
		var now_s := Time.get_ticks_msec() * 0.001
		var dt := now_s - _last_forward_tap_time_s
		_last_forward_tap_time_s = now_s
		if dt > 0.0 and dt <= sprint_double_tap_window:
			var fwd := 1.0 if player_id == 1 else -1.0
			start_dash_with_direction(fwd)
			_last_forward_tap_time_s = -100.0
	if _backward_action_just_pressed():
		var now_b := Time.get_ticks_msec() * 0.001
		var dtb := now_b - _last_back_tap_time_s
		_last_back_tap_time_s = now_b
		if dtb > 0.0 and dtb <= sprint_double_tap_window:
			var back := -1.0 if player_id == 1 else 1.0
			start_dash_with_direction(back)
			_last_back_tap_time_s = -100.0


func _apply_jump_during_dash() -> void:
	_dash_time_left = 0.0
	velocity.y = -jump_speed * dash_jump_vertical_mul
	var h := maxf(absf(velocity.x), dash_jump_horizontal_speed)
	velocity.x = _dash_dir_sign * h
	_jumps_left -= 1


func _extra_timer_tick(delta: float) -> void:
	_triple_cd_left = maxf(0.0, _triple_cd_left - delta)
	_beam_cd_left = maxf(0.0, _beam_cd_left - delta)


func _is_grenade_charging_active() -> bool:
	return _beam_charging


func _allow_jump_while_concentrating() -> bool:
	return not _beam_charging


func _special_uses_left() -> int:
	return 1 if _triple_armed else 0


func _preview_gravity_for_shot() -> float:
	return 0.0


func _grenade_just_pressed() -> bool:
	if player_id == 1:
		return Input.is_action_just_pressed("p1_grenade")
	return Input.is_action_just_pressed("p2_grenade")


func _grenade_pressed() -> bool:
	return Input.is_action_pressed("p1_grenade" if player_id == 1 else "p2_grenade")


func _grenade_just_released() -> bool:
	return Input.is_action_just_released("p1_grenade" if player_id == 1 else "p2_grenade")


func _refresh_beam_preview() -> void:
	var t := 0.0 if beam_max_charge_time <= 0.0 else clampf(_beam_charge_time / beam_max_charge_time, 0.0, 1.0)
	var speed := lerpf(min_launch_speed * beam_speed_mul_min, max_launch_speed * beam_speed_mul_max, t)
	_update_trajectory_preview(speed)


func _fire_beam() -> void:
	var t := 0.0 if beam_max_charge_time <= 0.0 else clampf(_beam_charge_time / beam_max_charge_time, 0.0, 1.0)
	var speed := lerpf(min_launch_speed * beam_speed_mul_min, max_launch_speed * beam_speed_mul_max, t)
	var size := lerpf(beam_min_scale, beam_max_scale, t)
	var vel := _compute_launch_velocity(speed)
	if vel.length_squared() < 1.0:
		vel = (Vector2.RIGHT * speed) if player_id == 1 else (Vector2.LEFT * speed)
	var dir := vel.normalized()
	var spawn_pos := muzzle.global_position + dir * (22.0 * size)
	var shots: Array = [{
		"pos": spawn_pos,
		"vel": vel,
		"gravity": 0.0,
		"bounces": 0,
		"damage": beam_damage,
		"size": size,
	}]
	shots_requested.emit(self, shots)
	_apply_recoil(vel, recoil_special_big * 0.82)


func _process_combat(delta: float) -> void:
	if input_enabled and _control_lock_left <= 0.0 and not _is_charging:
		if _beam_cd_left <= 0.0 and _grenade_just_pressed() and not _beam_charging:
			_beam_charging = true
			_beam_charge_time = 0.0
			charge_bar.visible = true
			charge_bar.value = 0.0
			trajectory.visible = true
			_refresh_beam_preview()
		if _beam_charging and _grenade_pressed():
			_beam_charge_time = minf(beam_max_charge_time, _beam_charge_time + delta)
			var tb := 0.0 if beam_max_charge_time <= 0.0 else (_beam_charge_time / beam_max_charge_time)
			charge_bar.value = clampf(tb * 100.0, 0.0, 100.0)
			_refresh_beam_preview()
		if _beam_charging and _grenade_just_released():
			_fire_beam()
			_beam_charging = false
			_beam_cd_left = beam_skill_cooldown
			_hide_charge_trajectory_ui()

	if (
		input_enabled
		and _control_lock_left <= 0.0
		and _triple_cd_left <= 0.0
		and not _triple_armed
		and _special_just_pressed()
	):
		_triple_armed = true
		special_buff_changed.emit(true, 1, 0.0)

	if _cooldown_left <= 0.0 and input_enabled and not _beam_charging:
		if (not _is_charging) and _shoot_just_pressed():
			_is_charging = true
			_charge_time = 0.0
			charge_bar.visible = true
			charge_bar.value = 0.0
			trajectory.visible = true
			_update_trajectory_preview(min_launch_speed)

		if _is_charging and _shoot_pressed():
			_charge_time = minf(max_charge_time, _charge_time + delta)
			var t_hold := 0.0 if max_charge_time <= 0.0 else (_charge_time / max_charge_time)
			charge_bar.value = clampf(t_hold * 100.0, 0.0, 100.0)
			var speed_hold := lerpf(min_launch_speed, max_launch_speed, t_hold)
			_update_trajectory_preview(speed_hold)

		if _is_charging and _shoot_just_released():
			_is_charging = false
			var t := 0.0 if max_charge_time <= 0.0 else (_charge_time / max_charge_time)
			var speed := lerpf(min_launch_speed, max_launch_speed, t)
			if _triple_armed:
				_triple_armed = false
				_triple_cd_left = triple_shot_cooldown
				special_buff_changed.emit(false, 0, 0.0)
				var v0 := _compute_launch_velocity(speed)
				var perp := Vector2(-v0.y, v0.x)
				if perp.length_squared() < 0.0001:
					perp = Vector2.UP
				else:
					perp = perp.normalized()
				var shots: Array = []
				for lane in [-1, 0, 1]:
					var pos := muzzle.global_position + perp * (float(lane) * triple_parallel_lane_spacing)
					shots.append({"pos": pos, "vel": v0})
				shots_requested.emit(self, shots)
				_apply_recoil(v0, recoil_normal * 1.12)
			else:
				var v0 := _compute_launch_velocity(speed)
				shoot_requested.emit(self, muzzle.global_position, v0, {})
				_apply_recoil(v0, recoil_normal)
			_cooldown_left = shoot_cooldown
			_hide_charge_trajectory_ui()
	else:
		if _is_charging and not _beam_charging:
			_is_charging = false
			_hide_charge_trajectory_ui()


func _extra_reset_for_vs_round() -> void:
	_triple_cd_left = 0.0
	_triple_armed = false
	_beam_cd_left = 0.0
	_beam_charging = false
	_beam_charge_time = 0.0
	_last_forward_tap_time_s = -100.0
	_last_back_tap_time_s = -100.0
