extends Player
class_name PistoleiroPlayer

@export var special_buff_duration: float = 8.0
@export var special_multi_spread_deg: float = 4.0
@export var special_ricochet_bounces: int = 1
@export var special_big_charge_time: float = 1.0
@export var special_big_size: float = 2.8
@export var special_big_damage: int = 45

@export var pistol_chain_reset_time: float = 1.5
@export var pistol_chain_shoot_cooldown: float = 0.64

@export var grenade_skill_cooldown: float = 4.0
@export var grenade_min_throw_speed: float = 320.0
@export var grenade_max_throw_speed: float = 960.0
@export var grenade_max_charge_time: float = 0.55
@export var grenade_trajectory_gravity: float = 1650.0
@export var grenade_lob_angle_deg: float = 22.0

var _special_attack_index := 0
var _is_special_concentrating := false
var _pistol_chain_step: int = 0
var _last_pistol_chain_time_s: float = -100.0
var _grenade_cd_left: float = 0.0
var _is_grenade_charging := false
var _grenade_charge_time := 0.0
var _grenade_active: bool = false


func set_grenade_active(active: bool) -> void:
	_grenade_active = active


func is_pistoleiro() -> bool:
	return true


func _max_shield_charges() -> int:
	return 4


func _shield_reload_seconds() -> float:
	return 4.25


func _extra_timer_tick(delta: float) -> void:
	_grenade_cd_left = maxf(0.0, _grenade_cd_left - delta)


func _special_uses_left() -> int:
	return maxi(0, 3 - _special_attack_index)


func _clear_special_state_on_buff_end() -> void:
	_is_special_concentrating = false


func _is_grenade_charging_active() -> bool:
	# Granada do pistoleiro não usa mais carregamento (alcance fixo no máximo).
	return false


func _allow_jump_while_concentrating() -> bool:
	return not _is_special_concentrating


func _trajectory_preview_origin() -> Vector2:
	var now_s := Time.get_ticks_msec() * 0.001
	var step := _pistol_chain_step
	if now_s - _last_pistol_chain_time_s > pistol_chain_reset_time:
		step = 0
	match step:
		0:
			return muzzle_top.global_position if muzzle_top != null else muzzle.global_position
		1:
			return muzzle_bottom.global_position if muzzle_bottom != null else muzzle.global_position
		_:
			return muzzle.global_position


func _preview_gravity_for_shot() -> float:
	return 0.0


func _process_combat(delta: float) -> void:
	# Granada (alcance fixo): mesma tecla faz "arremessar" ou "detonar" se já houver uma ativa.
	if input_enabled and _control_lock_left <= 0.0 and _grenade_just_pressed():
		if _grenade_active:
			grenade_detonate_requested.emit(self)
			return
		if _grenade_cd_left <= 0.0:
			var lob_deg := launch_angle_degrees + grenade_lob_angle_deg
			var v_throw := _compute_launch_velocity_with_angle(grenade_max_throw_speed, lob_deg)
			grenade_requested.emit(self, muzzle.global_position, v_throw)
			_grenade_cd_left = grenade_skill_cooldown
			_grenade_charge_time = 0.0

	if _cooldown_left <= 0.0 and input_enabled:
		if (not _is_charging) and not _is_grenade_charging and _shoot_just_pressed():
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
			if _special_buff_left > 0.0 and _special_attack_index < 3:
				_trigger_special_attack(speed)
				_cooldown_left = shoot_cooldown
			else:
				_fire_pistol_chain_shot(speed)
				_cooldown_left = pistol_chain_shoot_cooldown
			_hide_charge_trajectory_ui()
	else:
		if _is_charging:
			_is_charging = false
		if not _is_grenade_charging:
			_hide_charge_trajectory_ui()

	if input_enabled and _special_cd_left <= 0.0 and _special_just_pressed():
		_pistol_chain_step = 0
		_last_pistol_chain_time_s = -100.0
		_special_cd_left = special_cooldown
		_special_buff_left = special_buff_duration
		_special_attack_index = 0
		special_requested.emit(self, muzzle.global_position)
		_was_special_active = true
		special_buff_changed.emit(true, _special_uses_left(), _special_buff_left)

	# Sem lógica de carregamento/preview da granada (agora é instantânea).


func _fire_pistol_chain_shot(speed: float) -> void:
	var now_s := Time.get_ticks_msec() * 0.001
	if now_s - _last_pistol_chain_time_s > pistol_chain_reset_time:
		_pistol_chain_step = 0
	var v0 := _compute_launch_velocity(speed)
	var step := _pistol_chain_step
	match step:
		0:
			var pos_t := muzzle_top.global_position if muzzle_top != null else muzzle.global_position
			shoot_requested.emit(self, pos_t, v0, {})
			_apply_recoil(v0, recoil_normal)
		1:
			var pos_b := muzzle_bottom.global_position if muzzle_bottom != null else muzzle.global_position
			shoot_requested.emit(self, pos_b, v0, {})
			_apply_recoil(v0, recoil_normal)
		2:
			var shots: Array = []
			if muzzle_top != null and muzzle_bottom != null:
				shots.append({"pos": muzzle_top.global_position, "vel": v0, "gravity": 0.0, "bounces": 1})
				shots.append({"pos": muzzle_bottom.global_position, "vel": v0, "gravity": 0.0, "bounces": 1})
			else:
				shots.append({"pos": muzzle.global_position, "vel": v0, "gravity": 0.0, "bounces": 1})
			shots_requested.emit(self, shots)
			_apply_recoil(v0, recoil_normal * 1.12)
	_pistol_chain_step = (step + 1) % 3
	_last_pistol_chain_time_s = now_s


func _get_multi_muzzle_positions() -> Array:
	var arr: Array = []
	arr.append(muzzle.global_position)
	if muzzle_top != null:
		arr.append(muzzle_top.global_position)
	if muzzle_bottom != null:
		arr.append(muzzle_bottom.global_position)
	return arr


func _trigger_special_attack(speed: float) -> void:
	var idx := _special_attack_index
	_special_attack_index += 1

	if idx == 0:
		var shots: Array = []
		for pos in _get_multi_muzzle_positions():
			for a in [-special_multi_spread_deg, 0.0, special_multi_spread_deg]:
				var vel := _compute_launch_velocity_with_angle(speed, launch_angle_degrees + a)
				shots.append({"pos": pos, "vel": vel, "gravity": 0.0, "bounces": 0})
		shots_requested.emit(self, shots)
		_apply_recoil(_compute_launch_velocity(speed), recoil_special)
	elif idx == 1:
		var shots2: Array = []
		var positions := _get_multi_muzzle_positions()
		for i in range(min(3, positions.size())):
			var pos2: Vector2 = positions[i]
			var vel2 := _compute_launch_velocity(speed)
			shots2.append({"pos": pos2, "vel": vel2, "gravity": 0.0, "bounces": special_ricochet_bounces})
		shots_requested.emit(self, shots2)
		_apply_recoil(_compute_launch_velocity(speed), recoil_special)
	else:
		_start_concentrated_special(speed)

	if _special_attack_index >= 3:
		_special_buff_left = 0.0
	special_buff_changed.emit(_special_buff_left > 0.0, _special_uses_left(), _special_buff_left)


func _start_concentrated_special(speed: float) -> void:
	if _is_special_concentrating:
		return
	_is_special_concentrating = true
	_control_lock_left = maxf(_control_lock_left, special_big_charge_time)
	call_deferred("_fire_concentrated_special_deferred", speed)


func _fire_concentrated_special_deferred(speed: float) -> void:
	await get_tree().create_timer(special_big_charge_time).timeout
	if not is_instance_valid(self):
		return
	_is_special_concentrating = false
	var boosted_speed := max_launch_speed * 1.25
	var vel := _compute_launch_velocity(boosted_speed)
	var shots: Array = []
	var dir := vel.normalized()
	var spawn_pos := muzzle.global_position + dir * (18.0 * special_big_size)
	shots.append({
		"pos": spawn_pos,
		"vel": vel,
		"gravity": 0.0,
		"bounces": special_ricochet_bounces,
		"damage": special_big_damage,
		"size": special_big_size
	})
	shots_requested.emit(self, shots)
	_apply_recoil(vel, recoil_special_big)


func _grenade_just_pressed() -> bool:
	if player_id == 1:
		return Input.is_action_just_pressed("p1_grenade")
	return Input.is_action_just_pressed("p2_grenade")


func _grenade_pressed() -> bool:
	return Input.is_action_pressed("p1_grenade" if player_id == 1 else "p2_grenade")


func _grenade_just_released() -> bool:
	return Input.is_action_just_released("p1_grenade" if player_id == 1 else "p2_grenade")


func _update_grenade_trajectory_preview(speed: float) -> void:
	var lob_deg := launch_angle_degrees + grenade_lob_angle_deg
	var v := _compute_launch_velocity_with_angle(speed, lob_deg)
	var p := muzzle.global_position
	var viewport := get_viewport_rect()
	var g := grenade_trajectory_gravity
	trajectory.clear_points()
	for i in range(trajectory_points):
		trajectory.add_point(to_local(p))
		v.y += g * trajectory_step
		p += v * trajectory_step
		if not viewport.has_point(p):
			break


func _extra_reset_for_vs_round() -> void:
	_special_attack_index = 0
	_is_special_concentrating = false
	_pistol_chain_step = 0
	_grenade_cd_left = 0.0
	_is_grenade_charging = false
	_grenade_charge_time = 0.0
	_grenade_active = false
