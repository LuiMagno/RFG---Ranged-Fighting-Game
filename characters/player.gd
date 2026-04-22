extends CharacterBody2D
class_name Player

## Classe base: movimento, mira, vida, tiro carregado (lógica comum) e sinais.
## Jogabilidade específica: PistoleiroPlayer, ArqueiroPlayer, MagoPlayer, EsqueletoPlayer, OngmaEpilefPlayer.

enum CharacterKind { PISTOLEIRO, ARQUEIRO, MAGO, ESQUELETO, ONGMA_EPILEF }

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

## Janela temporal para duplo toque frente/trás (ativa dash). Corrida: `sprint_mechanic_enabled` + `sprint_forward_hold_seconds`.
@export var sprint_double_tap_window: float = 0.50
@export_range(1.05, 1.75, 0.01) var sprint_speed_multiplier: float = 1.42
## Multiplicador de cor no corpo / arco enquanto a corrida está ativa (sobre `modulate` original).
@export var sprint_visual_body_mult: Color = Color(1.2, 1.05, 0.72, 1.0)
@export var sprint_visual_bow_mult: Color = Color(1.12, 1.02, 0.78, 1.0)

@export var gravity_accel: float = 1800.0
@export var jump_speed: float = 700.0
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
## Pulo durante o dash: `(v_dash + v_jump) * dash_jump_impulse_mul` — arco **diagonal forte**, pouca sensação de “só para cima”.
@export_range(0.70, 1.30, 0.01) var dash_jump_vertical_mul: float = 0.80
## Peso do dash no eixo X antes da soma; valores mais altos = mais força na diagonal / frente.
@export_range(0.5, 2.5, 0.01) var dash_jump_horizontal_scale: float = 1.9
## Reforço global do impulso composto (um bocadinho mais forte sem repor demasiado o Y vs. o X).
@export_range(1.0, 1.5, 0.01) var dash_jump_impulse_mul: float = 1.3
## Bónus de velocidade ao manter só “frente” (corrida). **Falso** = desligado por defeito para não testar essa mecânica; dash por duplo toque mantém-se.
@export var sprint_mechanic_enabled: bool = false
## Tempo a manter só “para frente” antes de ativar sprint (só se `sprint_mechanic_enabled`).
@export_range(0.0, 0.5, 0.01) var sprint_forward_hold_seconds: float = 0.12
## Wall jump: impulso diagonal na parede (no máximo uma vez por voo até ao solo).
@export var wall_jump_horizontal_speed: float = 950.0
@export var wall_jump_vertical_speed: float = 900.0
@export_range(0.05, 0.6, 0.01) var wall_jump_visual_duration: float = 0.22
@export var wall_jump_body_flash: Color = Color(1.38, 0.78, 1.52, 1.0)
@export_range(4.0, 40.0, 1.0) var wall_detect_distance: float = 40.0
@export var wall_detect_vertical_offset: float = -18.0
@export_range(0.0, 0.35, 0.01) var wall_jump_move_grace: float = 0.14
## Controle: zona morta no vetor do stick direito (após sensibilidade), ~0,2–0,3 reduz drift.
@export_range(0.20, 0.30, 0.01) var gamepad_aim_deadzone: float = 0.25
## Controle: multiplica o vetor cru antes da deadzone; depois limita ao círculo unitário.
@export_range(0.50, 2.00, 0.05) var gamepad_aim_sensitivity: float = 1.0
## Controle: tempo de suavização (1ª ordem, segundos); menor = mais “seco”, maior = mais fluido.
@export_range(0.03, 0.35, 0.01) var gamepad_aim_smooth_time: float = 0.10

@export var wall_slide_speed: float = 150.0

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
var _sprint_active: bool = false
var _last_forward_tap_time_s: float = -100.0
var _last_back_tap_time_s: float = -100.0
## Valores no fim do frame anterior — invalidar duplo toque com input vertical (teclado: W/S + triggers; comando: `move_up`/`move_down` = stick Y + D-pad).
var _prev_vertical_hover_axis: float = 0.0
var _prev_gamepad_move_vertical: float = 0.0
var _forward_only_hold_s: float = 0.0
var _wall_jump_used_this_airborne: bool = false
var _wall_jump_flash_left: float = 0.0
var _wall_jump_move_grace_left: float = 0.0
var _wall_jump_free_axis_sign: float = 0.0
## Direção de mira no plano do jogo (normalizado). Mouse atualiza de imediato; controle com deadzone + smoothing.
var _aim_direction: Vector2 = Vector2.RIGHT
#verificar tempo de clique para baixo do fall slide.
var _last_down_tap_time_s: float = -100.0


func is_pistoleiro() -> bool:
	return false


func is_arqueiro() -> bool:
	return false


func is_mago() -> bool:
	return false


func is_esqueleto() -> bool:
	return false


func is_ongma_epilef() -> bool:
	return false


func _extra_timer_tick(_delta: float) -> void:
	pass


## Subclasses limpam buffs / estados de combate entre rounds no Vs.
func _extra_reset_for_vs_round() -> void:
	pass


func _special_uses_left() -> int:
	return 0


func _clear_special_state_on_buff_end() -> void:
	pass


func _archer_special_glow() -> bool:
	return false


func _is_grenade_charging_active() -> bool:
	return false


## Se true, `_can_start_dash` bloqueia enquanto `_is_grenade_charging_active()` (ex.: feixe do Esqueleto). Esqueleto pode devolver false para permitir dash durante o carregamento.
func _dash_blocked_by_grenade_skill() -> bool:
	return true


func _get_dash_stats() -> Dictionary:
	# Igual ao Esqueleto / Ongma Epilef para todos os duelistas (velocidade, duração, distância e CD).
	return {
		"speed": 620.0,
		"duration": 0.2,
		"cooldown": 0.1,
		"gravity_scale": 0.0,
	}


func _can_start_dash() -> bool:
	if not input_enabled:
		return false
	if _dash_cd_left > 0.0:
		return false
	if _is_charging:
		return false
	if _dash_blocked_by_grenade_skill() and _is_grenade_charging_active():
		return false
	return true


func start_dash_with_direction(dir_sign: float) -> void:
	if not _can_start_dash():
		return
	_interrupt_sprint()
	_dash_dir_sign = signf(dir_sign) if absf(dir_sign) > 0.001 else _dash_direction_sign()
	var st0: Dictionary = _get_dash_stats()
	_dash_time_left = float(st0.get("duration", 0.18))
	velocity.x = _dash_dir_sign * float(st0.get("speed", 700.0))


func _apply_jump_during_dash() -> void:
	_dash_time_left = 0.0
	var dash_spd := float(_get_dash_stats().get("speed", 620.0))
	var v_dash := Vector2(_dash_dir_sign * dash_spd * dash_jump_horizontal_scale, 0.0)
	var v_jump := Vector2(0.0, -jump_speed * dash_jump_vertical_mul)
	velocity = (v_dash + v_jump) * dash_jump_impulse_mul
	_jumps_left -= 1


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
	_reset_aim_direction_to_forward()
	_sync_launch_angle_from_aim_direction()


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	_special_cd_left = maxf(0.0, _special_cd_left - delta)
	_control_lock_left = maxf(0.0, _control_lock_left - delta)
	_hover_float_left = maxf(0.0, _hover_float_left - delta)
	_frozen_left = maxf(0.0, _frozen_left - delta)
	_special_buff_left = maxf(0.0, _special_buff_left - delta)
	_dash_cd_left = maxf(0.0, _dash_cd_left - delta)
	_extra_timer_tick(delta)

		
	if _frozen_left <= 0.0:
		_update_double_tap_forward_movement()
		_update_sprint_from_forward_hold(delta)
		if sprint_mechanic_enabled and _sprint_active and not _is_holding_forward_only():
			_interrupt_sprint()

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
		_prev_vertical_hover_axis = _get_vertical_hover_axis()
		_prev_gamepad_move_vertical = _get_gamepad_move_vertical_axis()
		return

	var hovering := _hover_float_left > 0.0

	_tick_wall_jump_pre_movement(delta)

	if _dash_time_left > 0.0:
		_dash_time_left = maxf(0.0, _dash_time_left - delta)
		var st_d: Dictionary = _get_dash_stats()
		velocity.x = _dash_dir_sign * float(st_d.get("speed", 700.0))
		if _dash_time_left <= 0.0:
			_dash_cd_left = float(st_d.get("cooldown", 0.3))
	elif _control_lock_left <= 0.0:
		if hovering:
			# hy>0 = intenção “para cima” na tela; em 2D velocity.y positivo é para baixo.
			var hv := _get_hover_move_vector() if input_enabled else Vector2.ZERO
			var sp0 := _get_sprint_speed_mult()
			velocity = Vector2(hv.x * move_speed * sp0, -hv.y * move_speed * sp0)
		else:
			var dir := 0.0 if not input_enabled else _get_move_axis()
			var sp := _get_sprint_speed_mult()
			velocity.x = dir * move_speed * sp
	else:
		if hovering:
			velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, knockback_friction * delta)

	velocity += _recoil_vel
	_recoil_vel = _recoil_vel.move_toward(Vector2.ZERO, recoil_decay * delta)
	

	if not is_on_floor():
		if not hovering:
			var gmul := 1.0
			if _dash_time_left > 0.0:
				gmul = float(_get_dash_stats().get("gravity_scale", 0.42))
			if gmul > 0.0001:
				velocity.y += gravity_accel * gmul * delta
	else:
		if velocity.y > 0.0:
			velocity.y = 0.0
	
	#função de wallslide.
	if not is_on_floor() and is_on_wall():
		# Verifica se o jogador está tentando se mover contra a parede
		var move_dir = _get_move_axis() if input_enabled else 0.0
		var wall_normal = get_wall_normal()
		
		# Se estiver caindo e empurrando o direcional contra a parede
		if velocity.y > 0 and move_dir != 0 and sign(move_dir) != sign(wall_normal.x):
			velocity.y = min(velocity.y, wall_slide_speed)
		
	if is_on_floor():
		_jumps_left = max_jumps

	if (not hovering) and _jump_just_pressed() and _allow_jump_while_concentrating():
		var special := _try_special_air_jump()
		if not special and _jumps_left > 0:
			if _dash_time_left > 0.0:
				_apply_jump_during_dash()
			else:
				velocity.y = -jump_speed
				_jumps_left -= 1

	# Dash com gravidade “zerada”: sem aceleração para baixo e sem continuar acumulando queda (vy > 0).
	if _dash_time_left > 0.0 and not is_on_floor() and not hovering:
		var gs := float(_get_dash_stats().get("gravity_scale", 0.42))
		if gs <= 0.0001:
			velocity.y = minf(velocity.y, 0.0)
	

	_refresh_sprint_body_modulate()
	move_and_slide()
	_enforce_arena_half()
	if is_on_floor():
		_wall_jump_used_this_airborne = false
	_process_combat(delta)
	_apply_wall_jump_visual_flash(delta)
	_prev_vertical_hover_axis = _get_vertical_hover_axis()
	_prev_gamepad_move_vertical = _get_gamepad_move_vertical_axis()

#função de dash para baixo.
func _start_ground_pound_dash() -> void:
		
		
	_hover_float_left = 0.0
	_interrupt_sprint()
		
	velocity.x = 0
	velocity.y = 2000.0 

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
	_interrupt_sprint()
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


func _refresh_sprint_body_modulate() -> void:
	if _body_visual == null:
		return
	if _is_sprint_speed_boost_active():
		_body_visual.modulate = _orig_body_modulate * sprint_visual_body_mult
	else:
		_body_visual.modulate = _orig_body_modulate


func _allow_jump_while_concentrating() -> bool:
	return true


## Subclasses podem override; por defeito aplica wall jump comum.
func _try_special_air_jump() -> bool:
	if not input_enabled or _control_lock_left > 0.0:
		return false
	if is_on_floor() or _wall_jump_used_this_airborne:
		return false
	var away_x := _get_wall_jump_away_sign()
	if absf(away_x) < 0.1:
		return false

	if _dash_time_left > 0.0:
		_dash_time_left = 0.0
		_dash_cd_left = float(_get_dash_stats().get("cooldown", 0.3))

	velocity.x = away_x * wall_jump_horizontal_speed
	velocity.y = -wall_jump_vertical_speed
	_wall_jump_used_this_airborne = true
	_wall_jump_flash_left = wall_jump_visual_duration
	_wall_jump_free_axis_sign = away_x
	_wall_jump_move_grace_left = wall_jump_move_grace
	return true


func _tick_wall_jump_pre_movement(delta: float) -> void:
	if is_on_floor():
		_wall_jump_move_grace_left = 0.0
		_wall_jump_free_axis_sign = 0.0
	else:
		_wall_jump_move_grace_left = maxf(0.0, _wall_jump_move_grace_left - delta)


func _apply_wall_jump_visual_flash(delta: float) -> void:
	if _wall_jump_flash_left <= 0.0:
		return
	var u := clampf(_wall_jump_flash_left / maxf(wall_jump_visual_duration, 0.0001), 0.0, 1.0)
	_wall_jump_flash_left = maxf(0.0, _wall_jump_flash_left - delta)
	var mult := Color.WHITE.lerp(wall_jump_body_flash, u)
	if _body_visual != null:
		_body_visual.modulate *= mult
	if _bow_visual != null:
		_bow_visual.modulate *= mult


func _get_wall_jump_away_sign() -> float:
	if is_on_wall_only():
		var wn := get_wall_normal()
		if absf(wn.x) >= 0.1:
			return signf(wn.x)
	var from := global_position + Vector2(0.0, wall_detect_vertical_offset)
	var d_left := _wall_ray_hit_dist(from, Vector2.LEFT)
	var d_right := _wall_ray_hit_dist(from, Vector2.RIGHT)
	var hit_left := d_left >= 0.0
	var hit_right := d_right >= 0.0
	if hit_left and not hit_right:
		return 1.0
	if hit_right and not hit_left:
		return -1.0
	if hit_left and hit_right:
		return 1.0 if d_left < d_right else -1.0
	return 0.0


func _wall_ray_hit_dist(from: Vector2, dir: Vector2) -> float:
	var to := from + dir.normalized() * wall_detect_distance
	var pq := PhysicsRayQueryParameters2D.create(from, to)
	pq.collision_mask = collision_mask
	pq.exclude = [get_rid()]
	var space := get_world_2d().direct_space_state
	var r := space.intersect_ray(pq)
	if r.is_empty():
		return -1.0
	return from.distance_to(r["position"] as Vector2)


func _apply_aim_from_world_direction(dir: Vector2) -> void:
	if dir.length_squared() <= 0.0001:
		return
	var d := dir.normalized()
	var forward := Vector2.RIGHT if player_id == 1 else Vector2.LEFT
	var signed_from_axis := forward.angle_to(d)
	if forward.dot(d) < 0.0:
		launch_angle_degrees = aim_limit_deg if d.y < 0.0 else -aim_limit_deg
	else:
		var clamped := clampf(signed_from_axis, deg_to_rad(-aim_limit_deg), deg_to_rad(aim_limit_deg))
		launch_angle_degrees = -rad_to_deg(clamped)


func _reset_aim_direction_to_forward() -> void:
	_aim_direction = Vector2.RIGHT if player_id == 1 else Vector2.LEFT


func _sync_launch_angle_from_aim_direction() -> void:
	if _aim_direction.length_squared() <= 0.0001:
		return
	_apply_aim_from_world_direction(_aim_direction)


func _get_gamepad_aim_vector_raw() -> Vector2:
	var ax_l := "p1_aim_left" if player_id == 1 else "p2_aim_left"
	var ax_r := "p1_aim_right" if player_id == 1 else "p2_aim_right"
	var ax_u := "p1_aim_up" if player_id == 1 else "p2_aim_up"
	var ax_d := "p1_aim_down" if player_id == 1 else "p2_aim_down"
	# deadzone 0.0: a zona morta “oficial” é só `gamepad_aim_deadzone` abaixo.
	return Input.get_vector(ax_l, ax_r, ax_u, ax_d, 0.0)


func _update_aim_direction_mouse() -> void:
	var raw := get_global_mouse_position() - muzzle.global_position
	if raw.length_squared() <= 0.0001:
		return
	_aim_direction = raw.normalized()


func _update_aim_direction_gamepad(delta: float) -> void:
	var raw_stick := _get_gamepad_aim_vector_raw()
	var v := raw_stick * gamepad_aim_sensitivity
	if v.length_squared() > 1.0001:
		v = v.limit_length(1.0)
	if v.length() < gamepad_aim_deadzone:
		return
	var target := v.normalized()
	var tau := maxf(gamepad_aim_smooth_time, 0.0001)
	var alpha := 1.0 - exp(-delta / tau)
	_aim_direction = _aim_direction.lerp(target, alpha)
	if _aim_direction.length_squared() > 0.0001:
		_aim_direction = _aim_direction.normalized()
	else:
		_aim_direction = target


func _update_aim(delta: float) -> void:
	if not input_enabled:
		_update_bow_visual()
		return
	if RunConfig.is_player_using_gamepad(player_id):
		_update_aim_direction_gamepad(delta)
	else:
		_update_aim_direction_mouse()
	_sync_launch_angle_from_aim_direction()
	launch_angle_degrees = clampf(launch_angle_degrees, -aim_limit_deg, aim_limit_deg)
	_update_bow_visual()


func _update_bow_visual() -> void:
	var bow_col := Color(1.0, 0.88, 0.45, 1.0) if _archer_special_glow() else Color.WHITE
	if _is_sprint_speed_boost_active():
		bow_col = bow_col * sprint_visual_bow_mult
	bow.modulate = bow_col
	var angle_rad := deg_to_rad(launch_angle_degrees)
	if player_id == 1:
		bow.rotation = -angle_rad
	else:
		bow.rotation = PI + angle_rad


func _get_move_axis() -> float:
	var a := Input.get_axis("p1_left", "p1_right") if player_id == 1 else Input.get_axis("p2_left", "p2_right")
	if _wall_jump_move_grace_left <= 0.0:
		return a
	if absf(a) < 0.02:
		return a
	if a * _wall_jump_free_axis_sign < 0.0:
		return 0.0
	return a


func _forward_action_just_pressed() -> bool:
	if player_id == 1:
		return Input.is_action_just_pressed("p1_right")
	return Input.is_action_just_pressed("p2_left")


func _is_holding_forward_only() -> bool:
	if player_id == 1:
		return Input.is_action_pressed("p1_right") and not Input.is_action_pressed("p1_left")
	return Input.is_action_pressed("p2_left") and not Input.is_action_pressed("p2_right")


func _get_sprint_speed_mult() -> float:
	if not sprint_mechanic_enabled:
		return 1.0
	if not _sprint_active:
		return 1.0
	if not _is_holding_forward_only():
		return 1.0
	return sprint_speed_multiplier


func _is_sprint_speed_boost_active() -> bool:
	return sprint_mechanic_enabled and input_enabled and _sprint_active and _is_holding_forward_only()


func _interrupt_sprint() -> void:
	_sprint_active = false
	_forward_only_hold_s = 0.0


func _update_sprint_from_forward_hold(delta: float) -> void:
	if not sprint_mechanic_enabled:
		_interrupt_sprint()
		return
	if sprint_forward_hold_seconds <= 0.0:
		_forward_only_hold_s = 0.0
		return
	if not input_enabled:
		_forward_only_hold_s = 0.0
		return
	if _dash_time_left > 0.0 or _hover_float_left > 0.0 or _control_lock_left > 0.0:
		_forward_only_hold_s = 0.0
		return
	if _is_holding_forward_only():
		_forward_only_hold_s += delta
		if _forward_only_hold_s >= sprint_forward_hold_seconds:
			_sprint_active = true
	else:
		_forward_only_hold_s = 0.0


func _update_double_tap_forward_movement() -> void:
	if not input_enabled:
		return
	var now_s := Time.get_ticks_msec() * 0.001
	# Input vertical sustentado (teclado: W/S + gatilhos; comando: idem + stick esquerdo Y) anula a janela do duplo toque.
	if _forward_double_tap_window_open(now_s) and _double_tap_vertical_input_active():
		_last_forward_tap_time_s = -100.0
	if _backward_double_tap_window_open(now_s) and _double_tap_vertical_input_active():
		_last_back_tap_time_s = -100.0
	_invalidate_double_tap_chains_on_contaminant(now_s)
	if _forward_action_just_pressed():
		var dt := now_s - _last_forward_tap_time_s
		_last_forward_tap_time_s = now_s
		if dt > 0.0 and dt <= sprint_double_tap_window:
			var fwd := 1.0 if player_id == 1 else -1.0
			start_dash_with_direction(fwd)
			_last_forward_tap_time_s = -100.0
	if _backward_action_just_pressed():
		var dtb := now_s - _last_back_tap_time_s
		_last_back_tap_time_s = now_s
		if dtb > 0.0 and dtb <= sprint_double_tap_window:
			var back := -1.0 if player_id == 1 else 1.0
			start_dash_with_direction(back)
			_last_back_tap_time_s = -100.0
      
	# --- DASH PARA BAIXO (Ground Pound) ---
	if _down_action_just_pressed():
		if not is_on_floor():
			_start_ground_pound_dash()
	# Mesmo frame: primeiro toque horizontal + W/S invalida o par (contaminação após atualizar tempos).
	_invalidate_double_tap_chains_on_contaminant(now_s)


func _forward_double_tap_window_open(now_s: float) -> bool:
	return _last_forward_tap_time_s > -1.0 and (now_s - _last_forward_tap_time_s) <= sprint_double_tap_window


func _backward_double_tap_window_open(now_s: float) -> bool:
	return _last_back_tap_time_s > -1.0 and (now_s - _last_back_tap_time_s) <= sprint_double_tap_window


func _invalidate_double_tap_chains_on_contaminant(now_s: float) -> void:
	if _forward_double_tap_window_open(now_s):
		if _backward_action_just_pressed() or _vertical_locomotion_contaminates_double_tap():
			_last_forward_tap_time_s = -100.0
	if _backward_double_tap_window_open(now_s):
		if _forward_action_just_pressed() or _vertical_locomotion_contaminates_double_tap():
			_last_back_tap_time_s = -100.0


func _get_vertical_hover_axis() -> float:
	if player_id == 1:
		return Input.get_axis("p1_hover_down", "p1_hover_up")
	return Input.get_axis("p2_hover_down", "p2_hover_up")


## Mesmo pipeline que o InputMap do comando (device + deadzone); inclui stick Y e D-pad ↑/↓.
func _get_gamepad_move_vertical_axis() -> float:
	if player_id == 1:
		return Input.get_axis("p1_move_down", "p1_move_up")
	return Input.get_axis("p2_move_down", "p2_move_up")


## Teclado + comando: qualquer vertical “ligado” entre os dois toques horizontais cancela o par.
func _double_tap_vertical_input_active() -> bool:
	if absf(_get_vertical_hover_axis()) > 0.01:
		return true
	if RunConfig.is_player_using_gamepad(player_id) and absf(_get_gamepad_move_vertical_axis()) > 0.01:
		return true
	return false


## Entre dois toques horizontais: oposto, ou transição neutro→ativo no eixo de hover ou em move_up/move_down (comando).
func _vertical_locomotion_contaminates_double_tap() -> bool:
	if _hover_up_just_pressed() or _hover_down_just_pressed():
		return true
	var h := _get_vertical_hover_axis()
	if absf(_prev_vertical_hover_axis) < 0.01 and absf(h) > 0.01:
		return true
	if RunConfig.is_player_using_gamepad(player_id):
		if _gamepad_move_up_just_pressed() or _gamepad_move_down_just_pressed():
			return true
		var mv := _get_gamepad_move_vertical_axis()
		if absf(_prev_gamepad_move_vertical) < 0.01 and absf(mv) > 0.01:
			return true
	return false


func _gamepad_move_up_just_pressed() -> bool:
	if player_id == 1:
		return Input.is_action_just_pressed("p1_move_up")
	return Input.is_action_just_pressed("p2_move_up")


func _gamepad_move_down_just_pressed() -> bool:
	if player_id == 1:
		return Input.is_action_just_pressed("p1_move_down")
	return Input.is_action_just_pressed("p2_move_down")


func _hover_up_just_pressed() -> bool:
	if player_id == 1:
		return Input.is_action_just_pressed("p1_hover_up")
	return Input.is_action_just_pressed("p2_hover_up")


func _hover_down_just_pressed() -> bool:
	if player_id == 1:
		return Input.is_action_just_pressed("p1_hover_down")
	return Input.is_action_just_pressed("p2_hover_down")

#dash para baixo.
func _down_action_just_pressed() -> bool:
	if player_id == 1:
		return Input.is_action_just_pressed("p1_down")
	return Input.is_action_just_pressed("p2_down")	

func _backward_action_just_pressed() -> bool:
	if player_id == 1:
		return Input.is_action_just_pressed("p1_left")
	return Input.is_action_just_pressed("p2_right")


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
	_interrupt_sprint()
	hp = maxi(0, hp - amount)
	health_changed.emit(hp)
	print("Player ", player_id, " HP: ", hp)


## Respawn entre rounds (modo Vs): posição local na arena, vida cheia, cooldowns zerados.
func prepare_for_vs_round_respawn(local_spawn: Vector2) -> void:
	_interrupt_sprint()
	position = local_spawn
	velocity = Vector2.ZERO
	hp = max_hp
	health_changed.emit(hp)
	_cooldown_left = 0.0
	_special_cd_left = 0.0
	_is_charging = false
	_charge_time = 0.0
	_jumps_left = max_jumps
	_control_lock_left = 0.0
	_recoil_vel = Vector2.ZERO
	_special_buff_left = 0.0
	_was_special_active = false
	_frozen_left = 0.0
	_frozen_prev = false
	_hover_float_left = 0.0
	_dash_time_left = 0.0
	_dash_cd_left = 0.0
	_wall_jump_used_this_airborne = false
	_wall_jump_flash_left = 0.0
	_wall_jump_move_grace_left = 0.0
	_wall_jump_free_axis_sign = 0.0
	_forward_only_hold_s = 0.0
	_last_forward_tap_time_s = -100.0
	_last_back_tap_time_s = -100.0
	_prev_vertical_hover_axis = 0.0
	_prev_gamepad_move_vertical = 0.0
	_set_frozen_visual(false)
	_hide_charge_trajectory_ui()
	if shield_visual != null:
		shield_visual.visible = false
	var max_c := _max_shield_charges()
	if max_c > 0:
		_shield_charges = max_c
		_shield_cd_left = 0.0
	special_buff_changed.emit(false, 0, 0.0)
	_reset_aim_direction_to_forward()
	_sync_launch_angle_from_aim_direction()
	_extra_reset_for_vs_round()


func apply_knockback(knockback: Vector2) -> void:
	_interrupt_sprint()
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
