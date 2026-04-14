extends Player
class_name ArqueiroPlayer

@export_range(0.0, 22.0, 0.5) var archer_split_spread_deg: float = 7.0
## Tecla F/K: carrega buff; os próximos 3 disparos (mouse) viram projéteis que grudam como espinhos.
@export var archer_spike_buff_cooldown: float = 5.5
@export var shield_reflect_heal: int = 6

var _archer_phase: int = 0
var _archer_spike_buff_cd_left: float = 0.0
var _archer_spike_shots_left: int = 0
## Depois do buff (F/K), tecla especial (G/`;`): próximo tiro solta 5 espinhos em leque.
var _archer_spike_g_volley_armed: bool = false


func is_arqueiro() -> bool:
	return true


func _max_shield_charges() -> int:
	return 3


func _shield_reload_seconds() -> float:
	return 4.0


func _shield_handle_arrow(arrow: Arrow) -> void:
	arrow.reflect_from_shield(self)
	hp = mini(max_hp, hp + shield_reflect_heal)
	health_changed.emit(hp)


func _extra_timer_tick(delta: float) -> void:
	_archer_spike_buff_cd_left = maxf(0.0, _archer_spike_buff_cd_left - delta)


func _archer_special_glow() -> bool:
	return _archer_phase > 0


func _process_combat(delta: float) -> void:
	if _cooldown_left <= 0.0 and input_enabled:
		if _archer_phase == 2 and _shoot_just_pressed():
			archer_split_now_requested.emit(self)
		elif (not _is_charging) and _shoot_just_pressed():
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
			if _archer_phase == 1:
				var v_arch := _compute_launch_velocity(speed)
				var shot_flags: Dictionary = {"archer_split": true}
				_archer_phase = 2
				special_buff_changed.emit(true, 1, 0.0)
				shoot_requested.emit(self, muzzle.global_position, v_arch, shot_flags)
				_apply_recoil(v_arch, recoil_normal)
				_cooldown_left = shoot_cooldown
			else:
				var shot_flags: Dictionary = {}
				if _archer_spike_g_volley_armed:
					shot_flags["spike_volley"] = true
					_archer_spike_g_volley_armed = false
				elif _archer_spike_shots_left > 0:
					shot_flags["spike_shot"] = true
					_archer_spike_shots_left -= 1
				var v0 := _compute_launch_velocity(speed)
				shoot_requested.emit(self, muzzle.global_position, v0, shot_flags)
				_apply_recoil(v0, recoil_normal)
				_cooldown_left = shoot_cooldown
				_sync_archer_spike_hud()
			_hide_charge_trajectory_ui()
	else:
		if _is_charging:
			_is_charging = false
		_hide_charge_trajectory_ui()

	# F antes de G no mesmo frame: o combo F→G enxerga os 3 tiros buffados.
	if (
		input_enabled
		and _archer_spike_buff_cd_left <= 0.0
		and _control_lock_left <= 0.0
		and _archer_spike_buff_just_pressed()
	):
		_archer_spike_shots_left = 3
		_archer_spike_g_volley_armed = false
		_archer_spike_buff_cd_left = archer_spike_buff_cooldown
		_sync_archer_spike_hud()

	if input_enabled and _special_cd_left <= 0.0 and _special_just_pressed() and _archer_phase == 0:
		if _archer_spike_shots_left > 0:
			_archer_spike_g_volley_armed = true
			_archer_spike_shots_left = 0
			_special_cd_left = special_cooldown
			_sync_archer_spike_hud()
		else:
			_special_cd_left = special_cooldown
			_archer_phase = 1
			special_buff_changed.emit(true, 2, 0.0)


func archer_after_manual_split() -> void:
	if _archer_phase != 2:
		return
	_archer_phase = 0
	special_buff_changed.emit(false, 0, 0.0)


func archer_carrier_cancelled() -> void:
	if _archer_phase != 2:
		return
	_archer_phase = 0
	special_buff_changed.emit(false, 0, 0.0)


func is_archer_waiting_split_click() -> bool:
	return _archer_phase == 2


func _archer_spike_buff_just_pressed() -> bool:
	if player_id == 1:
		return Input.is_action_just_pressed("p1_archer_spike")
	return Input.is_action_just_pressed("p2_archer_spike")


func _sync_archer_spike_hud() -> void:
	archer_spike_hud_changed.emit(_archer_spike_shots_left, _archer_spike_g_volley_armed)


func _extra_reset_for_vs_round() -> void:
	_archer_phase = 0
	_archer_spike_buff_cd_left = 0.0
	_archer_spike_shots_left = 0
	_archer_spike_g_volley_armed = false
	archer_spike_hud_changed.emit(0, false)


func _ready() -> void:
	super._ready()
	call_deferred("_sync_archer_spike_hud")
