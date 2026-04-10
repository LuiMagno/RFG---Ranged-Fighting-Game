extends Player
class_name MagoPlayer

@export var missile_min_speed: float = 360.0
@export var missile_max_speed: float = 520.0
@export var missile_charge_time: float = 0.85
@export var ice_skill_cooldown: float = 6.0
@export var ice_throw_speed: float = 420.0
@export var orb_max_charge_time: float = 1.25
@export var orb_skill_cooldown: float = 5.0
@export var orb_visual_scale_min: float = 0.32
@export var orb_visual_scale_max: float = 1.15
## Segurar G além de orb_hold_threshold = carregar orbe. Levitar = C (P1) / Y (P2).
@export var orb_hold_threshold: float = 0.42
@export var float_duration: float = 3.2
@export var float_skill_cooldown: float = 6.0

var _ice_cd_left: float = 0.0
var _ice_active: bool = false
var _float_cd_left: float = 0.0
var _orb_skill_hold: float = 0.0
var _orb_press_armed: bool = false

@onready var _orb_charge_vis: Polygon2D = muzzle.get_node_or_null("OrbChargeVisual") as Polygon2D


func set_ice_active(active: bool) -> void:
	_ice_active = active


func is_mago() -> bool:
	return true


func _extra_timer_tick(delta: float) -> void:
	_float_cd_left = maxf(0.0, _float_cd_left - delta)


func _preview_gravity_for_shot() -> float:
	return 0.0


func _get_dash_stats() -> Dictionary:
	return {
		"speed": 760.0,
		"duration": 0.16,
		"cooldown": 1.0,
		"gravity_scale": 0.42,
	}


func _is_orb_charge_active() -> bool:
	return _orb_press_armed and _special_pressed() and _orb_skill_hold >= orb_hold_threshold


func _process_combat(delta: float) -> void:
	_ice_cd_left = maxf(0.0, _ice_cd_left - delta)

	if input_enabled and _control_lock_left <= 0.0 and _ice_just_pressed():
		if _ice_active:
			mage_ice_detonate_requested.emit(self)
		elif _ice_cd_left <= 0.0 and not _is_orb_charge_active():
			var v_ice := _compute_launch_velocity(ice_throw_speed)
			mage_ice_requested.emit(self, muzzle.global_position, v_ice)
			_ice_cd_left = ice_skill_cooldown

	if input_enabled and _control_lock_left <= 0.0 and _mage_float_just_pressed():
		if _float_cd_left <= 0.0 and not _is_orb_charge_active():
			start_hover_float(float_duration)
			_float_cd_left = float_skill_cooldown

	# G: segurar = carregar orbe gravitacional; soltar com carga = disparar orbe.
	if _special_just_pressed():
		_orb_skill_hold = 0.0
		_orb_press_armed = (_special_cd_left <= 0.0)
		_hide_orb_visual()

	if _special_pressed() and _orb_press_armed:
		_orb_skill_hold = minf(orb_max_charge_time, _orb_skill_hold + delta)
		if _orb_skill_hold >= orb_hold_threshold:
			var ot := 0.0 if orb_max_charge_time <= 0.0 else (_orb_skill_hold / orb_max_charge_time)
			_update_orb_visual(ot)

	if _special_just_released():
		if input_enabled and _control_lock_left <= 0.0:
			if _orb_press_armed and _orb_skill_hold >= orb_hold_threshold:
				var t_orb := 0.0 if orb_max_charge_time <= 0.0 else (_orb_skill_hold / orb_max_charge_time)
				mage_orb_requested.emit(self, muzzle.global_position, t_orb)
				var v := _compute_launch_velocity(420.0)
				_apply_recoil(v, lerpf(140.0, 260.0, t_orb))
				_special_cd_left = orb_skill_cooldown
		_hide_orb_visual()
		_orb_skill_hold = 0.0
		_orb_press_armed = false

	if _orb_press_armed and _special_pressed() and (not input_enabled or _control_lock_left > 0.0):
		_hide_orb_visual()

	if _cooldown_left <= 0.0 and input_enabled and not _is_orb_charge_active():
		if (not _is_charging) and _shoot_just_pressed():
			_is_charging = true
			_charge_time = 0.0
			charge_bar.visible = true
			charge_bar.value = 0.0
			trajectory.visible = true
			_update_trajectory_preview(missile_min_speed)

		if _is_charging and _shoot_pressed():
			_charge_time = minf(missile_charge_time, _charge_time + delta)
			var t_hold := 0.0 if missile_charge_time <= 0.0 else (_charge_time / missile_charge_time)
			charge_bar.value = clampf(t_hold * 100.0, 0.0, 100.0)
			var speed_hold := lerpf(missile_min_speed, missile_max_speed, t_hold)
			_update_trajectory_preview(speed_hold)

		if _is_charging and _shoot_just_released():
			_is_charging = false
			var t := 0.0 if missile_charge_time <= 0.0 else (_charge_time / missile_charge_time)
			var speed := lerpf(missile_min_speed, missile_max_speed, t)
			var v0 := _compute_launch_velocity(speed)
			shoot_requested.emit(self, muzzle.global_position, v0, {})
			_apply_recoil(v0, recoil_normal * 0.82)
			_cooldown_left = shoot_cooldown
			_hide_charge_trajectory_ui()
	else:
		if _is_charging:
			_is_charging = false
		if not _is_orb_charge_active():
			_hide_charge_trajectory_ui()


func _special_pressed() -> bool:
	return Input.is_action_pressed("p1_special" if player_id == 1 else "p2_special")


func _update_orb_visual(charge_normalized: float) -> void:
	if _orb_charge_vis == null:
		return
	charge_normalized = clampf(charge_normalized, 0.0, 1.0)
	var s := lerpf(orb_visual_scale_min, orb_visual_scale_max, charge_normalized)
	_orb_charge_vis.visible = true
	_orb_charge_vis.scale = Vector2.ONE * s


func _hide_orb_visual() -> void:
	if _orb_charge_vis == null:
		return
	_orb_charge_vis.visible = false
	_orb_charge_vis.scale = Vector2.ONE * orb_visual_scale_min


func _ice_just_pressed() -> bool:
	if player_id == 1:
		return Input.is_action_just_pressed("p1_grenade")
	return Input.is_action_just_pressed("p2_grenade")


func _mage_float_just_pressed() -> bool:
	if player_id == 1:
		return Input.is_action_just_pressed("p1_mage_float")
	return Input.is_action_just_pressed("p2_mage_float")
