extends CharacterBody2D
class_name Player

## Classe base: movimento, mira, vida, tiro carregado (lógica comum) e sinais.
## Jogabilidade específica fica em PistoleiroPlayer e ArqueiroPlayer.

enum CharacterKind { PISTOLEIRO, ARQUEIRO, MAGO }

signal shoot_requested(owner_player: Player, spawn_position: Vector2, initial_velocity: Vector2, shot_flags: Dictionary)
signal health_changed(current_hp: int)
signal special_requested(owner_player: Player, spawn_position: Vector2)
signal shots_requested(owner_player: Player, shots: Array)
signal special_buff_changed(active: bool, uses_left: int, time_left: float)
signal archer_split_now_requested(owner_player: Player)
## Arqueiro: tiros de espinho restantes e se F+G armou o leque de 5.
signal archer_spike_hud_changed(remaining_spike_shots: int, g_combo_volley_armed: bool)
signal grenade_requested(owner_player: Player, spawn_position: Vector2, throw_velocity: Vector2)
signal grenade_detonate_requested(owner_player: Player)
signal mage_ice_requested(owner_player: Player, spawn_position: Vector2, initial_velocity: Vector2)
signal mage_ice_detonate_requested(owner_player: Player)
signal mage_orb_requested(owner_player: Player, spawn_position: Vector2, charge_t: float)

@export var player_id: int = 1
@export var move_speed: float = 260.0
@export var input_enabled: bool = true

@export var gravity_accel: float = 1800.0
@export var jump_speed: float = 650.0
@export_range(1, 5, 1) var max_jumps: int = 2
@export var hit_stun_time: float = 0.14
@export var knockback_friction: float = 2400.0

@export var max_hp: int = 100
@export var shoot_cooldown: float = 0.4
@export var special_cooldown: float = 3.0

@export var min_launch_speed: float = 420.0
@export var max_launch_speed: float = 900.0
@export var max_charge_time: float = 1.0
@export var launch_angle_degrees: float = 0.0
@export_range(10.0, 89.0, 1.0) var aim_limit_deg: float = 85.0
@export var projectile_gravity_accel: float = 1200.0
@export var trajectory_points: int = 24
@export var trajectory_step: float = 0.08
@export var arena_padding_x: float = 36.0

@export var recoil_normal: float = 170.0
@export var recoil_special: float = 290.0
@export var recoil_special_big: float = 480.0
@export_range(0.0, 1.0, 0.05) var recoil_y_factor: float = 0.25
@export var recoil_decay: float = 2400.0
@onready var muzzle: Marker2D = $Muzzle
@onready var muzzle_top: Marker2D = get_node_or_null("MuzzleTop")
@onready var muzzle_bottom: Marker2D = get_node_or_null("MuzzleBottom")
@onready var charge_bar: ProgressBar = $ChargeBar
@onready var bow: Node2D = $Bow
@onready var trajectory: Line2D = $Trajectory
@onready var shield_visual: Polygon2D = get_node_or_null("ShieldVisual") as Polygon2D
@onready var _body_visual: CanvasItem = get_node_or_null("Body") as CanvasItem
@onready var _bow_visual: CanvasItem = bow as CanvasItem

var hp: int
var _cooldown_left := 0.0
var _special_cd_left := 0.0
var _is_charging := false
var _charge_time := 0.0
var _jumps_left: int = 0
var _control_lock_left := 0.0
var _recoil_vel: Vector2 = Vector2.ZERO
var _special_buff_left := 0.0
var _was_special_active := false
var _traj_color_normal := Color.WHITE
var _dash_time_left := 0.0
var _dash_cd_left := 0.0
var _dash_dir_sign := 1.0
var _shield_charges: int = 0
var _shield_cd_left := 0.0
var _frozen_left: float = 0.0
var _frozen_anchor_pos: Vector2 = Vector2.ZERO
var _frozen_prev: bool = false
var _orig_body_modulate: Color = Color.WHITE
var _orig_bow_modulate: Color = Color.WHITE
var _hover_float_left: float = 0.0


func is_pistoleiro() -> bool:
	return false


func is_arqueiro() -> bool:
	return false


func is_mago() -> bool:
	return false


func _extra_timer_tick(_delta: float) -> void:
	pass


func _special_uses_left() -> int:
	return 0


func _clear_special_state_on_buff_end() -> void:
	pass


func _archer_special_glow() -> bool:
	return false


func _is_grenade_charging_active() -> bool:
	return false


func _get_dash_stats() -> Dictionary:
	return {
		"speed": 700.0,
		"duration": 0.18,
		"cooldown": 0.9,
		"gravity_scale": 0.42,
	}


func _can_start_dash() -> bool:
	if not input_enabled:
		return false
	if _dash_cd_left > 0.0:
		return false
	if _is_charging:
		return false
	if _is_grenade_charging_active():
		return false
	return true


func _dash_just_pressed() -> bool:
	if player_id == 1:
		return Input.is_action_just_pressed("p1_dash")
	return Input.is_action_just_pressed("p2_dash")


func _dash_direction_sign() -> float:
	var axis := _get_move_axis() if input_enabled else 0.0
	if absf(axis) > 0.01:
		return signf(axis)
	return 1.0 if player_id == 1 else -1.0


func _max_shield_charges() -> int:
	return 0


func _shield_reload_seconds() -> float:
	return 4.0


func _shield_key_pressed() -> bool:
	if player_id == 1:
		return Input.is_action_pressed("p1_shield")
	return Input.is_action_pressed("p2_shield")


func _shield_handle_arrow(arrow: Arrow) -> void:
	arrow.queue_free()


func _arrow_in_front_for_shield(arrow: Arrow) -> bool:
	var fwd := Vector2.RIGHT if player_id == 1 else Vector2.LEFT
	var rel := arrow.global_position - global_position
	return fwd.dot(rel) > -14.0


func try_block_arrow_with_shield(arrow: Arrow) -> bool:
	if _max_shield_charges() <= 0:
		return false
	if arrow._owner == null or arrow._owner == self:
		return false
	if shield_visual == null or not shield_visual.visible:
		return false
	if not _arrow_in_front_for_shield(arrow):
		return false
	_shield_charges -= 1
	_shield_handle_arrow(arrow)
	if _shield_charges <= 0:
		_shield_cd_left = _shield_reload_seconds()
		shield_visual.visible = false
	return true


func _update_shield(delta: float) -> void:
	var max_c := _max_shield_charges()
	if max_c <= 0:
		if shield_visual != null:
			shield_visual.visible = false
		return
	_shield_cd_left = maxf(0.0, _shield_cd_left - delta)
	if _shield_charges <= 0 and _shield_cd_left <= 0.0:
		_shield_charges = max_c
	var can := (
		input_enabled
		and _control_lock_left <= 0.0
		and _shield_cd_left <= 0.0
		and _shield_charges > 0
	)
	var hold := can and _shield_key_pressed()
	if shield_visual != null:
		shield_visual.visible = hold


## Tiro, especial e granada (subclasses).
func _process_combat(_delta: float) -> void:
	pass


func _trajectory_preview_origin() -> Vector2:
	return muzzle.global_position


func _preview_gravity_for_shot() -> float:
	return projectile_gravity_accel


func _ready() -> void:
	hp = max_hp
	add_to_group("players")
	_jumps_left = max_jumps
	_traj_color_normal = trajectory.default_color
	trajectory.clear_points()
	trajectory.visible = false
	if _max_shield_charges() > 0:
		_shield_charges = _max_shield_charges()
	if _body_visual != null:
		_orig_body_modulate = _body_visual.modulate
	if _bow_visual != null:
		_orig_bow_modulate = _bow_visual.modulate
	_frozen_prev = false


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	_special_cd_left = maxf(0.0, _special_cd_left - delta)
	_control_lock_left = maxf(0.0, _control_lock_left - delta)
	_hover_float_left = maxf(0.0, _hover_float_left - delta)
	_frozen_left = maxf(0.0, _frozen_left - delta)
	_special_buff_left = maxf(0.0, _special_buff_left - delta)
	_dash_cd_left = maxf(0.0, _dash_cd_left - delta)
	_extra_timer_tick(delta)

	if _control_lock_left > 0.0 and _dash_time_left > 0.0:
		_dash_time_left = 0.0

	var is_active := _special_buff_left > 0.0
	if not is_active:
		_clear_special_state_on_buff_end()
	if is_active != _was_special_active:
		_was_special_active = is_active
		special_buff_changed.emit(is_active, _special_uses_left(), _special_buff_left)

	_update_aim(delta)
	_update_shield(delta)

	var frozen := _frozen_left > 0.0
	if frozen != _frozen_prev:
		_frozen_prev = frozen
		_set_frozen_visual(frozen)
		if frozen:
			_frozen_anchor_pos = global_position

	# Frozen = travado no lugar (sem gravidade, sem slide, sem input).
	if frozen:
		velocity = Vector2.ZERO
		global_position = _frozen_anchor_pos
		return

	var hovering := _hover_float_left > 0.0

	if _dash_time_left > 0.0:
		_dash_time_left = maxf(0.0, _dash_time_left - delta)
		var st_d: Dictionary = _get_dash_stats()
		velocity.x = _dash_dir_sign * float(st_d.get("speed", 700.0))
		if _dash_time_left <= 0.0:
			_dash_cd_left = float(st_d.get("cooldown", 0.9))
	elif _control_lock_left <= 0.0:
		if hovering:
			# hy>0 = intenção “para cima” na tela; em 2D velocity.y positivo é para baixo.
			var hv := _get_hover_move_vector() if input_enabled else Vector2.ZERO
			velocity = Vector2(hv.x * move_speed, -hv.y * move_speed)
		else:
			var dir := 0.0 if not input_enabled else _get_move_axis()
			velocity.x = dir * move_speed
		if _can_start_dash() and _dash_just_pressed():
			_dash_dir_sign = _dash_direction_sign()
			var st0: Dictionary = _get_dash_stats()
			_dash_time_left = float(st0.get("duration", 0.18))
			velocity.x = _dash_dir_sign * float(st0.get("speed", 700.0))
	else:
		if hovering:
			velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)

	velocity += _recoil_vel
	_recoil_vel = _recoil_vel.move_toward(Vector2.ZERO, recoil_decay * delta)

	if not is_on_floor():
		var gmul := 1.0
		if _dash_time_left > 0.0:
			gmul = float(_get_dash_stats().get("gravity_scale", 0.42))
		if not hovering:
			velocity.y += gravity_accel * gmul * delta
	else:
		if velocity.y > 0.0:
			velocity.y = 0.0

	if is_on_floor():
		_jumps_left = max_jumps

	if (not hovering) and _jump_just_pressed() and _jumps_left > 0 and _allow_jump_while_concentrating():
		velocity.y = -jump_speed
		_jumps_left -= 1

	move_and_slide()
	_enforce_arena_half()
	_process_combat(delta)


func start_hover_float(seconds: float) -> void:
	if seconds <= 0.0:
		return
	_hover_float_left = maxf(_hover_float_left, seconds)


func _get_hover_move_vector() -> Vector2:
	var hx := _get_move_axis()
	var hy := 0.0
	if player_id == 1:
		hy = Input.get_axis("p1_hover_down", "p1_hover_up")
		# Space continua “subindo” na flutuação (não gasta pulo; pulo normal segue bloqueado).
		if Input.is_action_pressed("p1_jump"):
			hy = maxf(hy, 1.0)
	else:
		hy = Input.get_axis("p2_hover_down", "p2_hover_up")
		if Input.is_action_pressed("p2_jump"):
			hy = maxf(hy, 1.0)
	var v := Vector2(hx, hy)
	if v.length_squared() > 1.0001:
		v = v.normalized()
	return v


func freeze_for(seconds: float) -> void:
	if seconds <= 0.0:
		return
	if _frozen_left <= 0.0:
		_frozen_anchor_pos = global_position
	_frozen_left = maxf(_frozen_left, seconds)
	velocity = Vector2.ZERO


func _set_frozen_visual(active: bool) -> void:
	# "Filtro menos saturado": puxa para um azul pálido / gelo.
	if _body_visual != null:
		_body_visual.modulate = Color(0.75, 0.9, 1.0, 1.0) if active else _orig_body_modulate
	if _bow_visual != null:
		_bow_visual.modulate = Color(0.85, 0.95, 1.0, 1.0) if active else _orig_bow_modulate


func _allow_jump_while_concentrating() -> bool:
	return true


func _apply_mouse_aim() -> void:
	var to_mouse := get_global_mouse_position() - muzzle.global_position
	if to_mouse.length_squared() <= 0.0001:
		return
	var dir := to_mouse.normalized()
	var forward := Vector2.RIGHT if player_id == 1 else Vector2.LEFT
	var signed_from_axis := forward.angle_to(dir)
	if forward.dot(dir) < 0.0:
		launch_angle_degrees = aim_limit_deg if dir.y < 0.0 else -aim_limit_deg
	else:
		var clamped := clampf(signed_from_axis, deg_to_rad(-aim_limit_deg), deg_to_rad(aim_limit_deg))
		launch_angle_degrees = -rad_to_deg(clamped)


func _update_aim(_delta: float) -> void:
	if not input_enabled:
		_update_bow_visual()
		return
	_apply_mouse_aim()
	launch_angle_degrees = clampf(launch_angle_degrees, -aim_limit_deg, aim_limit_deg)
	_update_bow_visual()


func _update_bow_visual() -> void:
	bow.modulate = Color(1.0, 0.88, 0.45, 1.0) if _archer_special_glow() else Color.WHITE
	var angle_rad := deg_to_rad(launch_angle_degrees)
	if player_id == 1:
		bow.rotation = -angle_rad
	else:
		bow.rotation = PI + angle_rad


func _get_move_axis() -> float:
	if player_id == 1:
		return Input.get_axis("p1_left", "p1_right")
	return Input.get_axis("p2_left", "p2_right")


func _shoot_just_pressed() -> bool:
	return Input.is_action_just_pressed("p1_shoot" if player_id == 1 else "p2_shoot")


func _shoot_pressed() -> bool:
	return Input.is_action_pressed("p1_shoot" if player_id == 1 else "p2_shoot")


func _shoot_just_released() -> bool:
	return Input.is_action_just_released("p1_shoot" if player_id == 1 else "p2_shoot")


func _jump_just_pressed() -> bool:
	return Input.is_action_just_pressed("p1_jump" if player_id == 1 else "p2_jump")


func _special_just_pressed() -> bool:
	if player_id == 1:
		return Input.is_action_just_pressed("p1_special")
	return Input.is_action_just_pressed("p2_special")


func _special_just_released() -> bool:
	if player_id == 1:
		return Input.is_action_just_released("p1_special")
	return Input.is_action_just_released("p2_special")


func _compute_launch_velocity(speed: float) -> Vector2:
	var sign_x := 1.0 if player_id == 1 else -1.0
	var angle := deg_to_rad(launch_angle_degrees)
	var vx := cos(angle) * speed * sign_x
	var vy := -sin(angle) * speed
	return Vector2(vx, vy)


func _compute_launch_velocity_with_angle(speed: float, angle_deg: float) -> Vector2:
	var sign_x := 1.0 if player_id == 1 else -1.0
	var angle := deg_to_rad(angle_deg)
	var vx := cos(angle) * speed * sign_x
	var vy := -sin(angle) * speed
	return Vector2(vx, vy)


func _update_trajectory_preview(speed: float) -> void:
	var v := _compute_launch_velocity(speed)
	var p := _trajectory_preview_origin()
	var viewport := get_viewport_rect()
	var g := _preview_gravity_for_shot()

	trajectory.clear_points()
	for i in range(trajectory_points):
		trajectory.add_point(to_local(p))
		v.y += g * trajectory_step
		p += v * trajectory_step
		if not viewport.has_point(p):
			break


func _hide_charge_trajectory_ui() -> void:
	charge_bar.visible = false
	charge_bar.value = 0.0
	trajectory.visible = false
	trajectory.clear_points()
	trajectory.default_color = _traj_color_normal


func _enforce_arena_half() -> void:
	var rect := get_viewport_rect()
	var w := rect.size.x
	if w <= 0.0:
		return
	var mid := w * 0.5
	var min_x := arena_padding_x
	var max_x := w - arena_padding_x
	var x := clampf(global_position.x, min_x, max_x)
	if player_id == 1:
		x = minf(x, mid - arena_padding_x)
	else:
		x = maxf(x, mid + arena_padding_x)
	if not is_equal_approx(x, global_position.x):
		global_position.x = x
		velocity.x = 0.0


func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	health_changed.emit(hp)
	print("Player ", player_id, " HP: ", hp)


func apply_knockback(knockback: Vector2) -> void:
	velocity += knockback
	_control_lock_left = maxf(_control_lock_left, hit_stun_time)


func apply_external_force(force: Vector2) -> void:
	# For forças contínuas (ex.: gravidade de orbe). Não aplica stun.
	velocity += force


func archer_after_manual_split() -> void:
	pass


func archer_carrier_cancelled() -> void:
	pass


func is_archer_waiting_split_click() -> bool:
	return false


func _apply_recoil(shot_velocity: Vector2, strength: float) -> void:
	if strength <= 0.0:
		return
	if shot_velocity.length_squared() < 0.001:
		return
	var dir := shot_velocity.normalized()
	var impulse := -dir * strength
	impulse.y *= recoil_y_factor
	_recoil_vel += impulse
