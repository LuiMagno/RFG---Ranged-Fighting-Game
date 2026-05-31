extends Player
class_name EsqueletoPlayer

## Baseline de duelo: tiro carregado (velocidade proporcional à carga), flecha sem gravidade no voo.
## Três skills + ULT do Esqueleto (mapeamento em `game.gd` / `project.godot`):
## - **Skill Esqueleto — Feixe:** ação `p*_grenade` (teclado **F**, controle **X**) — segura e solta para disparar o projétil grande.
## - **Skill Esqueleto — Buff de velocidade do tiro carregado:** ação `p*_special` (teclado **G**, controle **Y**) — ativa um período em que o **tiro carregado** (RB / mouse) sai com velocidade maior.
## - **Skill Esqueleto — ULT Chuva de ossos:** ação `p*_ult` (teclado **R**, controle **LB**) — chuva automática de ossos verticais na metade inimiga (~3 s).
## Tiro base: mínimo 1 s entre disparos após soltar o carregamento (`MIN_SHOOT_COOLDOWN_S`).

const MIN_SHOOT_COOLDOWN_S := 1.0

## Skill Esqueleto — Feixe (`*_grenade`)
@export var esqueleto_skill_feixe_recarga_s: float = 4.25
@export var esqueleto_skill_feixe_tempo_max_carga_s: float = 0.65
@export var esqueleto_skill_feixe_escala_min: float = 1.85
@export var esqueleto_skill_feixe_escala_max: float = 3.45
@export var esqueleto_skill_feixe_dano: int = 36
@export var esqueleto_skill_feixe_velocidade_mul_min: float = 1.05
@export var esqueleto_skill_feixe_velocidade_mul_max: float = 1.42
## Recoil do feixe: horizontal em `add_carry_knockback_x` (sobrevive ao `velocity.x = dir*speed` no próximo frame); vertical **uma vez** em `velocity` — arco baixo pela gravidade.
@export_range(5.0, 16.0, 0.5) var esqueleto_skill_feixe_recoil_angulo_acima_horizontal_graus: float = 10.0
@export_range(500.0, 1200.0, 10.0) var esqueleto_skill_feixe_recoil_forca: float = 2000.0

## Skill Esqueleto — Buff de velocidade do tiro carregado (`*_special`)
@export var esqueleto_skill_buff_velocidade_tiro_duracao_s: float = 4.0
@export var esqueleto_skill_buff_velocidade_tiro_recarga_s: float = 10.0
@export var esqueleto_skill_buff_velocidade_tiro_multiplicador: float = 2.0

## Skill Esqueleto — ULT Chuva de ossos (`*_ult`: teclado R, controle LB)
@export var esqueleto_skill_ult_chuva_ossos_recarga_s: float = 38.0
@export var esqueleto_skill_ult_chuva_ossos_fase_super_s: float = 2.2
@export var esqueleto_skill_ult_chuva_ossos_super_zoom: float = 1.42
@export var esqueleto_skill_ult_chuva_ossos_duracao_s: float = 3.0
@export var esqueleto_skill_ult_chuva_ossos_intervalo_s: float = 0.14
@export var esqueleto_skill_ult_chuva_ossos_dano: int = 10
@export var esqueleto_skill_ult_chuva_ossos_velocidade_queda: float = 720.0
@export var esqueleto_skill_ult_chuva_ossos_knockback_x: float = 380.0
@export var esqueleto_skill_ult_chuva_ossos_knockback_up: float = 180.0
@export var esqueleto_skill_ult_chuva_ossos_modulate: Color = Color(1.35, 1.15, 0.55)
@export var esqueleto_skill_ult_chuva_ossos_shake_intensidade: float = 4.0
@export var esqueleto_skill_ult_chuva_ossos_shake_duracao_s: float = 0.18

var _esqueleto_buff_velocidade_tiro_ativo := false
var _esqueleto_buff_velocidade_tiro_tempo_restante_s := 0.0
var _esqueleto_buff_velocidade_tiro_cd_restante_s := 0.0
var _feixe_cd_restante_s := 0.0
var _feixe_carregando := false
var _feixe_tempo_carga_s := 0.0
var _esqueleto_ult_cd_restante_s := 0.0
var _esqueleto_chuva_ossos_ativa := false
var _esqueleto_chuva_ossos_fase_super_restante_s := 0.0
var _esqueleto_chuva_ossos_tempo_restante_s := 0.0


func is_esqueleto() -> bool:
	return true


func _ready() -> void:
	shoot_cooldown = maxf(MIN_SHOOT_COOLDOWN_S, shoot_cooldown)
	super._ready()


func _extra_timer_tick(delta: float) -> void:
	_feixe_cd_restante_s = maxf(0.0, _feixe_cd_restante_s - delta)
	_esqueleto_buff_velocidade_tiro_cd_restante_s = maxf(0.0, _esqueleto_buff_velocidade_tiro_cd_restante_s - delta)
	_esqueleto_ult_cd_restante_s = maxf(0.0, _esqueleto_ult_cd_restante_s - delta)
	if _esqueleto_chuva_ossos_ativa:
		if _esqueleto_chuva_ossos_fase_super_restante_s > 0.0:
			_esqueleto_chuva_ossos_fase_super_restante_s -= delta
			if _esqueleto_chuva_ossos_fase_super_restante_s <= 0.0:
				ult_status_changed.emit(true, _esqueleto_chuva_ossos_tempo_restante_s, false)
			else:
				ult_status_changed.emit(true, _esqueleto_chuva_ossos_fase_super_restante_s, true)
		else:
			_esqueleto_chuva_ossos_tempo_restante_s -= delta
			if _esqueleto_chuva_ossos_tempo_restante_s <= 0.0:
				_finalizar_chuva_ossos()
			else:
				ult_status_changed.emit(true, _esqueleto_chuva_ossos_tempo_restante_s, false)
	if _esqueleto_buff_velocidade_tiro_ativo and not _esqueleto_chuva_ossos_ativa:
		_esqueleto_buff_velocidade_tiro_tempo_restante_s -= delta
		if _esqueleto_buff_velocidade_tiro_tempo_restante_s <= 0.0:
			_esqueleto_buff_velocidade_tiro_ativo = false
			self.modulate = Color(1, 1, 1)
			special_buff_changed.emit(false, 0, 0.0)
		else:
			special_buff_changed.emit(true, 1, _esqueleto_buff_velocidade_tiro_tempo_restante_s)


func _is_grenade_charging_active() -> bool:
	return _feixe_carregando


func _dash_blocked_by_grenade_skill() -> bool:
	return false


func uses_dash_action_button() -> bool:
	return true


func _special_uses_left() -> int:
	return 1 if _esqueleto_buff_velocidade_tiro_ativo else 0


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


func _ult_just_pressed() -> bool:
	if player_id == 1:
		return Input.is_action_just_pressed("p1_ult")
	return Input.is_action_just_pressed("p2_ult")


func is_chuva_ossos_ativa() -> bool:
	return _esqueleto_chuva_ossos_ativa


func is_buff_velocidade_tiro_ativo() -> bool:
	return _esqueleto_buff_velocidade_tiro_ativo


func get_buff_velocidade_tiro_tempo_restante_s() -> float:
	return _esqueleto_buff_velocidade_tiro_tempo_restante_s


func end_ult_super_phase_visual() -> void:
	if not _esqueleto_chuva_ossos_ativa:
		return
	_esqueleto_chuva_ossos_fase_super_restante_s = 0.0
	if _esqueleto_buff_velocidade_tiro_ativo:
		self.modulate = Color(0.5, 1.5, 2.0)
	else:
		self.modulate = Color(1, 1, 1)
	ult_status_changed.emit(true, _esqueleto_chuva_ossos_tempo_restante_s, false)


func _finalizar_chuva_ossos() -> void:
	_esqueleto_chuva_ossos_ativa = false
	_esqueleto_chuva_ossos_tempo_restante_s = 0.0
	if _esqueleto_buff_velocidade_tiro_ativo:
		self.modulate = Color(0.5, 1.5, 2.0)
	else:
		self.modulate = Color(1, 1, 1)
	ult_status_changed.emit(false, 0.0, false)


func _tentar_ativar_ult_chuva_ossos() -> void:
	if not input_enabled or _control_lock_left > 0.0:
		return
	if _esqueleto_ult_cd_restante_s > 0.0 or _esqueleto_chuva_ossos_ativa:
		return
	if _feixe_carregando or _is_charging or _esqueleto_buff_velocidade_tiro_ativo:
		return
	if not _ult_just_pressed():
		return
	_esqueleto_ult_cd_restante_s = esqueleto_skill_ult_chuva_ossos_recarga_s
	_esqueleto_chuva_ossos_ativa = true
	_esqueleto_chuva_ossos_fase_super_restante_s = esqueleto_skill_ult_chuva_ossos_fase_super_s
	_esqueleto_chuva_ossos_tempo_restante_s = esqueleto_skill_ult_chuva_ossos_duracao_s
	self.modulate = esqueleto_skill_ult_chuva_ossos_modulate
	ult_status_changed.emit(true, _esqueleto_chuva_ossos_fase_super_restante_s, true)
	bone_rain_requested.emit(self)


func _refresh_feixe_preview() -> void:
	var t := (
		0.0
		if esqueleto_skill_feixe_tempo_max_carga_s <= 0.0
		else clampf(_feixe_tempo_carga_s / esqueleto_skill_feixe_tempo_max_carga_s, 0.0, 1.0)
	)
	var speed := lerpf(
		min_launch_speed * esqueleto_skill_feixe_velocidade_mul_min,
		max_launch_speed * esqueleto_skill_feixe_velocidade_mul_max,
		t
	)
	_update_trajectory_preview(speed)


func _disparar_feixe() -> void:
	var t := (
		0.0
		if esqueleto_skill_feixe_tempo_max_carga_s <= 0.0
		else clampf(_feixe_tempo_carga_s / esqueleto_skill_feixe_tempo_max_carga_s, 0.0, 1.0)
	)
	var speed := lerpf(
		min_launch_speed * esqueleto_skill_feixe_velocidade_mul_min,
		max_launch_speed * esqueleto_skill_feixe_velocidade_mul_max,
		t
	)
	var size := lerpf(esqueleto_skill_feixe_escala_min, esqueleto_skill_feixe_escala_max, t)
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
		"damage": esqueleto_skill_feixe_dano,
		"size": size,
		"flags": {"esqueleto_feixe": true},
	}]
	shots_requested.emit(self, shots)
	var f := esqueleto_skill_feixe_recoil_forca
	var pitch := deg_to_rad(esqueleto_skill_feixe_recoil_angulo_acima_horizontal_graus)
	var back_x_sign := -signf(dir.x) if absf(dir.x) > 0.02 else (-1.0 if player_id == 1 else 1.0)
	var horiz := back_x_sign * f * cos(pitch)
	var vert := -f * sin(pitch)
	add_carry_knockback_x(horiz)
	_apply_velocity_knockback_once(Vector2(0.0, vert))


func _ativar_buff_velocidade_tiro_carregado() -> void:
	_esqueleto_buff_velocidade_tiro_ativo = true
	_esqueleto_buff_velocidade_tiro_tempo_restante_s = esqueleto_skill_buff_velocidade_tiro_duracao_s
	_esqueleto_buff_velocidade_tiro_cd_restante_s = esqueleto_skill_buff_velocidade_tiro_recarga_s
	self.modulate = Color(0.5, 1.5, 2.0)
	special_buff_changed.emit(true, 1, esqueleto_skill_buff_velocidade_tiro_duracao_s)


func _process_combat(delta: float) -> void:
	if input_enabled and _control_lock_left <= 0.0:
		_tentar_ativar_ult_chuva_ossos()

	if input_enabled and _control_lock_left <= 0.0 and not _is_charging and not _esqueleto_chuva_ossos_ativa:
		if _feixe_cd_restante_s <= 0.0 and _grenade_just_pressed() and not _feixe_carregando:
			_feixe_carregando = true
			_feixe_tempo_carga_s = 0.0
			charge_bar.visible = true
			charge_bar.value = 0.0
			trajectory.visible = true
			_refresh_feixe_preview()
		if _feixe_carregando and _grenade_pressed():
			_feixe_tempo_carga_s = minf(esqueleto_skill_feixe_tempo_max_carga_s, _feixe_tempo_carga_s + delta)
			var tb := (
				0.0
				if esqueleto_skill_feixe_tempo_max_carga_s <= 0.0
				else (_feixe_tempo_carga_s / esqueleto_skill_feixe_tempo_max_carga_s)
			)
			charge_bar.value = clampf(tb * 100.0, 0.0, 100.0)
			_refresh_feixe_preview()
		if _feixe_carregando and _grenade_just_released():
			_disparar_feixe()
			_feixe_carregando = false
			_feixe_cd_restante_s = esqueleto_skill_feixe_recarga_s
			_hide_charge_trajectory_ui()

		if input_enabled and _control_lock_left <= 0.0:
			if (
				_special_just_pressed()
				and _esqueleto_buff_velocidade_tiro_cd_restante_s <= 0.0
				and not _esqueleto_buff_velocidade_tiro_ativo
				and not _esqueleto_chuva_ossos_ativa
			):
				_ativar_buff_velocidade_tiro_carregado()

	if _cooldown_left <= 0.0 and input_enabled and not _feixe_carregando and not _esqueleto_chuva_ossos_ativa:
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
			if _esqueleto_buff_velocidade_tiro_ativo:
				speed *= esqueleto_skill_buff_velocidade_tiro_multiplicador
			var v0 := _compute_launch_velocity(speed)
			shoot_requested.emit(self, muzzle.global_position, v0, {})
			_apply_recoil(v0, recoil_normal)
			_cooldown_left = shoot_cooldown
			_hide_charge_trajectory_ui()
	else:
		if _is_charging and not _feixe_carregando:
			_is_charging = false
			_hide_charge_trajectory_ui()


func _extra_reset_for_vs_round() -> void:
	_feixe_cd_restante_s = 0.0
	_feixe_carregando = false
	_feixe_tempo_carga_s = 0.0
	_esqueleto_buff_velocidade_tiro_ativo = false
	_esqueleto_buff_velocidade_tiro_tempo_restante_s = 0.0
	_esqueleto_buff_velocidade_tiro_cd_restante_s = 0.0
	_esqueleto_ult_cd_restante_s = 0.0
	_esqueleto_chuva_ossos_ativa = false
	_esqueleto_chuva_ossos_fase_super_restante_s = 0.0
	_esqueleto_chuva_ossos_tempo_restante_s = 0.0
	self.modulate = Color(1, 1, 1)
	_last_forward_tap_time_s = -100.0
	_last_back_tap_time_s = -100.0
	special_buff_changed.emit(false, 0, 0.0)
	ult_status_changed.emit(false, 0.0, false)
